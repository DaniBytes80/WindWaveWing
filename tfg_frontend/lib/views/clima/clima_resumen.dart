import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'clima_utils.dart';

Map<String, dynamic> calcularResumen(List<ClimaModelo> datos) {
  final direcciones = <String, int>{};
  for (final c in datos) {
    direcciones[c.direccionViento] = (direcciones[c.direccionViento] ?? 0) + 1;
  }

  final dirDominante = direcciones.entries
      .reduce((a, b) => a.value > b.value ? a : b)
      .key;

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
    "dir": dirDominante,
    "viento": kmhToKnots(vientoMedio).toStringAsFixed(0),
    "ola": olaMedia.toStringAsFixed(1),
    "lluvia": lluviaMedia.round(),
    "temp": tempMedia.toStringAsFixed(0),
  };
}
