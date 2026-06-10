import 'dart:math' as math;
import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'clima_utils.dart';

// ============================================================
//  calcularResumen
//
//  ✅ FIX dirección viento: usaba moda de strings cardinales
//     → ahora usa promedio vectorial de grados (correcto)
//     Acepta tanto "95.0" (grados float) como "N","SE" (cardinal)
// ============================================================
Map<String, dynamic> calcularResumen(List<ClimaModelo> datos) {
  // ── Dirección: promedio vectorial ──────────────────────────
  // La media aritmética de ángulos es incorrecta (350°+10°=180° ≠ 0°)
  // El promedio vectorial es el método correcto (igual que Windy/AEMET)
  double sumX = 0;
  double sumY = 0;
  for (final c in datos) {
    final grados = _parseDirToGrados(c.direccionViento);
    final rad = grados * math.pi / 180;
    sumX += math.cos(rad);
    sumY += math.sin(rad);
  }
  final dirMedia =
      math.atan2(sumY / datos.length, sumX / datos.length) * 180 / math.pi;
  final dirFinal = (dirMedia + 360) % 360; // normalizar 0-360

  // ── Resto de valores: media aritmética ────────────────────
  final vientoMedio =
      datos.map((c) => c.velocidadViento).reduce((a, b) => a + b) /
      datos.length;

  final olaMedia =
      datos.map((c) => c.alturaOla).reduce((a, b) => a + b) / datos.length;

  final lluviaMedia =
      datos.map((c) => c.probabilidadLluvia).reduce((a, b) => a + b) /
      datos.length;

  final tempMedia =
      datos.map((c) => c.temperatura).reduce((a, b) => a + b) / datos.length;

  return {
    "dir": dirFinal, // double grados 0-360
    "viento": kmhToKnots(vientoMedio).toStringAsFixed(0),
    "ola": olaMedia.toStringAsFixed(1),
    "lluvia": lluviaMedia.round(),
    "temp": tempMedia.toStringAsFixed(0),
  };
}

// ── Convierte String a grados float ───────────────────────────
// Acepta "95.0" (datos nuevos ingesta v3) y "N","SE" (datos antiguos)
double _parseDirToGrados(String dir) {
  final num = double.tryParse(dir.trim());
  if (num != null) return num;

  const cardinal = {
    'N': 0.0,
    'NNE': 22.5,
    'NE': 45.0,
    'ENE': 67.5,
    'E': 90.0,
    'ESE': 112.5,
    'SE': 135.0,
    'SSE': 157.5,
    'S': 180.0,
    'SSO': 202.5,
    'SO': 225.0,
    'OSO': 247.5,
    'O': 270.0,
    'ONO': 292.5,
    'NO': 315.0,
    'NNO': 337.5,
    'NNW': 337.5,
    'NW': 315.0,
    'WNW': 292.5,
    'W': 270.0,
    'WSW': 247.5,
    'SW': 225.0,
    'SSW': 202.5,
  };
  return cardinal[dir.trim().toUpperCase()] ?? 0.0;
}
