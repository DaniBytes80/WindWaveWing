import 'package:tfg_clima_malaga/domain/interpolators/weather_point.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/domain/interpolators/wind_interpolator.dart';

// ============================================================
//  WaveInterpolator
//  Igual que WindInterpolator pero semántica de olas:
//  value = altura en metros, dir = dirección de propagación.
//  Separado para poder ajustar parámetros de grid y potencia
//  de forma independiente (las olas se propagan más suavemente
//  que el viento → power más bajo, grid más grueso).
// ============================================================
class WaveInterpolator {
  static List<WeatherPoint> fromSpots({
    required List<Spot> spots,
    required double Function(Spot) getHeight,
    required double Function(Spot) getDir,
  }) {
    return WindInterpolator.fromSpots(
      spots: spots,
      getSpeed: getHeight,
      getDir: getDir,
      gridCols: 20, // grid más grueso que el viento
      gridRows: 14,
      power: 1.5, // suavizado mayor → transiciones más suaves de oleaje
    );
    
  }
}
