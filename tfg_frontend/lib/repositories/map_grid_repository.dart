import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';

// ============================================================
//  MapGridData — contenedor de los 4 grids meteorológicos
// ============================================================
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

// ============================================================
//  MapGridRepository
//  Consulta la tabla clima_grid de Supabase via RPC.
//  Caché local de 30 min para no saturar Supabase.
// ============================================================
class MapGridRepository {
  static final MapGridRepository _instance = MapGridRepository._internal();
  factory MapGridRepository() => _instance;
  MapGridRepository._internal();

  final _supabase = Supabase.instance.client;

  MapGridData? _cache;
  DateTime? _lastFetch;
  double? _lastMinLat, _lastMaxLat, _lastMinLng, _lastMaxLng;

  static const _cacheDuration = Duration(minutes: 30);
  static const _bboxThreshold = 3.0;

  Future<MapGridData> obtenerGrid({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    final ahora = DateTime.now();

    final cacheValida =
        _cache != null &&
        _lastFetch != null &&
        ahora.difference(_lastFetch!) < _cacheDuration;

    final bboxSimilar =
        _lastMinLat != null &&
        (minLat - _lastMinLat!).abs() < _bboxThreshold &&
        (maxLat - _lastMaxLat!).abs() < _bboxThreshold &&
        (minLng - _lastMinLng!).abs() < _bboxThreshold &&
        (maxLng - _lastMaxLng!).abs() < _bboxThreshold;

    if (cacheValida && bboxSimilar) {
      debugPrint('📦 Grid desde caché (${_cache!.wind.length} puntos)');
      return _cache!;
    }

    final grid = await _consultarSupabase(
      minLat: minLat - 3,
      maxLat: maxLat + 3,
      minLng: minLng - 3,
      maxLng: maxLng + 3,
    );

    _cache = grid;
    _lastFetch = ahora;
    _lastMinLat = minLat;
    _lastMaxLat = maxLat;
    _lastMinLng = minLng;
    _lastMaxLng = maxLng;

    return grid;
  }

  Future<MapGridData> _consultarSupabase({
    required double minLat,
    required double maxLat,
    required double minLng,
    required double maxLng,
  }) async {
    try {
      final response = await _supabase.rpc(
        'obtener_grid_actual',
        params: {
          'p_min_lat': minLat,
          'p_max_lat': maxLat,
          'p_min_lng': minLng,
          'p_max_lng': maxLng,
        },
      );

      final rows = response as List<dynamic>;
      if (rows.isEmpty) {
        debugPrint('⚠️ clima_grid vacío — ejecuta ingesta_grid.py');
        return MapGridData.empty();
      }

      final wind = <WeatherPoint>[];
      final wave = <WeatherPoint>[];
      final rain = <WeatherPoint>[];
      final temp = <WeatherPoint>[];

      for (final row in rows) {
        final lat = (row['lat'] as num).toDouble();
        final lng = (row['lng'] as num).toDouble();

        wind.add(
          WeatherPoint(
            lat: lat,
            lng: lng,
            value: (row['velocidad_viento'] as num?)?.toDouble() ?? 0,
            dir: (row['direccion_viento'] as num?)?.toDouble() ?? 0,
          ),
        );
        wave.add(
          WeatherPoint(
            lat: lat,
            lng: lng,
            value: (row['altura_ola'] as num?)?.toDouble() ?? 0,
            dir: (row['direccion_ola'] as num?)?.toDouble() ?? 0,
          ),
        );
        rain.add(
          WeatherPoint(
            lat: lat,
            lng: lng,
            value: (row['precipitacion'] as num?)?.toDouble() ?? 0,
          ),
        );
        temp.add(
          WeatherPoint(
            lat: lat,
            lng: lng,
            value: (row['temperatura'] as num?)?.toDouble() ?? 0,
          ),
        );
      }

      debugPrint('✅ Grid: ${rows.length} puntos cargados');
      return MapGridData(wind: wind, wave: wave, rain: rain, temp: temp);
    } catch (e) {
      debugPrint('❌ Error clima_grid: $e');
      return _cache ?? MapGridData.empty();
    }
  }

  void invalidarCache() {
    _cache = null;
    _lastFetch = null;
  }
}
