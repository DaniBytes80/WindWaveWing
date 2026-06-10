import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';

// ============================================================
//  OpenMeteoSource
//
//  Obtiene un grid de puntos meteorológicos de Open-Meteo.
//  - API gratuita, sin API key, sin límite razonable
//  - Marine API: viento, olas, temperatura superficial del mar
//  - Weather API: temperatura aire, lluvia, nubosidad
//
//  El grid cubre el área visible del mapa (bbox) con puntos
//  cada ~grados según el zoom. A zoom 5 → cada 3°, a zoom 10
//  → cada 0.5°. Así no se piden más datos de los necesarios.
// ============================================================

class OpenMeteoSource {
  static const String _weatherBase = 'https://api.open-meteo.com/v1/forecast';
  static const String _marineBase =
      'https://marine-api.open-meteo.com/v1/marine';

  // ─────────────────────────────────────────────────────────
  //  Genera un grid de puntos en el bbox visible del mapa
  //  y descarga los datos de todos en paralelo.
  // ─────────────────────────────────────────────────────────
  static Future<MapGridData> cargarGrid({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
    double paso = 2.0, // grados entre puntos del grid
  }) async {
    // Generar lista de coordenadas del grid
    final coords = <_Coord>[];
    for (double lat = minLat; lat <= maxLat; lat += paso) {
      for (double lng = minLng; lng <= maxLng; lng += paso) {
        coords.add(_Coord(lat: lat.clamp(-85, 85), lng: lng));
      }
    }

    if (coords.isEmpty) return MapGridData.empty();

    // Descargar en paralelo (máximo 10 peticiones simultáneas
    // para no saturar Open-Meteo)
    final chunks = _chunks(coords, 10);
    final windPoints = <WeatherPoint>[];
    final wavePoints = <WeatherPoint>[];
    final rainPoints = <WeatherPoint>[];
    final tempPoints = <WeatherPoint>[];

    for (final chunk in chunks) {
      final futures = chunk.map((c) => _fetchPunto(c));
      final results = await Future.wait(futures);
      for (final r in results) {
        if (r == null) continue;
        windPoints.add(r.wind);
        wavePoints.add(r.wave);
        rainPoints.add(r.rain);
        tempPoints.add(r.temp);
      }
    }

    return MapGridData(
      wind: windPoints,
      wave: wavePoints,
      rain: rainPoints,
      temp: tempPoints,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Descarga datos para UN punto (weather + marine en paralelo)
  // ─────────────────────────────────────────────────────────
  static Future<_PuntoData?> _fetchPunto(_Coord c) async {
    try {
      final weatherFuture = _fetchWeather(c);
      final marineFuture = _fetchMarine(c);
      final results = await Future.wait([weatherFuture, marineFuture]);

      final weather = results[0];
      final marine = results[1];
      
      if (weather == null) return null;

      // Extraer la hora actual (índice 0 = primera hora disponible)
      final wCurrent = weather['current'] as Map<String, dynamic>? ?? {};
      final mCurrent = marine?['current'] as Map<String, dynamic>? ?? {};

      return _PuntoData(
        wind: WeatherPoint(
          lat: c.lat,
          lng: c.lng,
          value: (wCurrent['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
          dir: (wCurrent['wind_direction_10m'] as num?)?.toDouble() ?? 0.0,
        ),
        wave: WeatherPoint(
          lat: c.lat,
          lng: c.lng,
          value: (mCurrent['wave_height'] as num?)?.toDouble() ?? 0.0,
          dir: (mCurrent['wave_direction'] as num?)?.toDouble() ?? 0.0,
        ),
        rain: WeatherPoint(
          lat: c.lat,
          lng: c.lng,
          value: (wCurrent['precipitation'] as num?)?.toDouble() ?? 0.0,
          dir: 0,
        ),
        temp: WeatherPoint(
          lat: c.lat,
          lng: c.lng,
          value: (wCurrent['temperature_2m'] as num?)?.toDouble() ?? 20.0,
          dir: 0,
        ),
      );
    } catch (e) {
      return null; // Si falla un punto, ignorarlo
    }
  }

  static Future<Map<String, dynamic>?> _fetchWeather(_Coord c) async {
    final uri = Uri.parse(_weatherBase).replace(
      queryParameters: {
        'latitude': c.lat.toString(),
        'longitude': c.lng.toString(),
        'current':
            'temperature_2m,wind_speed_10m,wind_direction_10m,precipitation',
        'wind_speed_unit': 'kn', // nudos para deportes náuticos
        'timezone': 'auto',
        'forecast_days': '1',
      },
    );

    final resp = await http.get(uri).timeout(const Duration(seconds: 8));
    if (resp.statusCode != 200) return null;
    return jsonDecode(resp.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>?> _fetchMarine(_Coord c) async {
    final uri = Uri.parse(_marineBase).replace(
      queryParameters: {
        'latitude': c.lat.toString(),
        'longitude': c.lng.toString(),
        'current': 'wave_height,wave_direction,wave_period',
        'timezone': 'auto',
        'forecast_days': '1',
      },
    );

    try {
      final resp = await http.get(uri).timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return null;
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (_) {
      return null; // Marine API no cubre zonas de interior → ignorar
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────
  static List<List<T>> _chunks<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (int i = 0; i < list.length; i += size) {
      result.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return result;
  }
}

class _Coord {
  final double lat, lng;
  const _Coord({required this.lat, required this.lng});
}

class _PuntoData {
  final WeatherPoint wind, wave, rain, temp;
  const _PuntoData({
    required this.wind,
    required this.wave,
    required this.rain,
    required this.temp,
  });
}

// ─────────────────────────────────────────────────────────
//  Contenedor de los 4 grids de datos
// ─────────────────────────────────────────────────────────
class MapGridData {
  final List<WeatherPoint> wind;
  final List<WeatherPoint> wave;
  final List<WeatherPoint> rain;
  final List<WeatherPoint> temp;

  const MapGridData({
    required this.wind,
    required this.wave,
    required this.rain,
    required this.temp,
  });

  factory MapGridData.empty() =>
      const MapGridData(wind: [], wave: [], rain: [], temp: []);

  bool get isEmpty => wind.isEmpty;
}
