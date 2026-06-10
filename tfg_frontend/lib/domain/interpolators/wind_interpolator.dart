import 'dart:math' as math;
import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';
import 'package:tfg_clima_malaga/models/spot.dart';



// ============================================================
//  WindInterpolator
//  Convierte una lista de Spots con valores meteorológicos
//  en un grid regular interpolado con IDW
//  (Inverse Distance Weighting — el mismo algoritmo que
//  usan Windy y Meteoblue para rellenar entre estaciones).
// ============================================================
class WindInterpolator {
  /// Genera una lista de WeatherPoints a partir de los Spots.
  /// [getSpeed] extrae el valor principal (velocidad, lluvia, temp)
  /// [getDir]   extrae la dirección (solo aplica a viento/olas)
  static List<WeatherPoint> fromSpots({
    required List<Spot> spots,
    required double Function(Spot) getSpeed,
    required double Function(Spot) getDir,
    int gridCols = 30, // columnas del grid interpolado
    int gridRows = 20, // filas del grid interpolado
    double power = 2.0, // potencia IDW (2 = cuadrática estándar)
  }) {
    if (spots.isEmpty) return [];

    // Bounding box de los spots
    final lats = spots.map((s) => s.lat).toList();
    final lngs = spots.map((s) => s.lng).toList();
    final minLat = lats.reduce(math.min) - 0.5;
    final maxLat = lats.reduce(math.max) + 0.5;
    final minLng = lngs.reduce(math.min) - 0.5;
    final maxLng = lngs.reduce(math.max) + 0.5;

    final result = <WeatherPoint>[];
    final stepLat = (maxLat - minLat) / gridRows;
    final stepLng = (maxLng - minLng) / gridCols;

    for (int row = 0; row < gridRows; row++) {
      for (int col = 0; col < gridCols; col++) {
        final lat = minLat + row * stepLat;
        final lng = minLng + col * stepLng;

        double sumW = 0;
        double sumSpeed = 0;
        double sumDirX = 0; // componentes vectoriales para interpolar
        double sumDirY = 0; // ángulos no se promedian directamente

        for (final spot in spots) {
          final d = _haversine(lat, lng, spot.lat, spot.lng);
          if (d < 0.001) {
            // El punto coincide exactamente con el spot
            sumSpeed = getSpeed(spot);
            sumDirX = math.cos(_toRad(getDir(spot)));
            sumDirY = math.sin(_toRad(getDir(spot)));
            sumW = 1;
            break;
          }
          final w = 1.0 / math.pow(d, power);
          sumW += w;
          sumSpeed += w * getSpeed(spot);
          sumDirX += w * math.cos(_toRad(getDir(spot)));
          sumDirY += w * math.sin(_toRad(getDir(spot)));
        }

        final speed = sumW > 0 ? sumSpeed / sumW : 0.0;
        final dir = sumW > 0
            ? _toDeg(math.atan2(sumDirY / sumW, sumDirX / sumW))
            : 0.0;

        result.add(
          WeatherPoint(
            lat: lat,
            lng: lng,
            value: speed,
            dir: (dir + 360) % 360,
          ),
        );
      }
    }

    return result;
  }

  // ── Distancia Haversine en grados (aproximada, suficiente para IDW) ──
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371.0; // km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;
}
