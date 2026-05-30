import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class WWWTablaClima extends StatelessWidget {
  final List<ClimaModelo> datosMeteorologicos;

  const WWWTablaClima({super.key, required this.datosMeteorologicos});

  double _kmhToKnots(double kmh) => kmh / 1.852;

  @override
  Widget build(BuildContext context) {
    if (datosMeteorologicos.isEmpty) {
      return const SizedBox.shrink();
    }

    final diasAgrupados = _agruparPorDia(datosMeteorologicos);

    final diasOrdenados =
        diasAgrupados.entries
            .where(
              (e) => DateTime.parse(
                e.key,
              ).isAfter(DateTime.now().subtract(const Duration(days: 1))),
            )
            .toList()
          ..sort(
            (a, b) => DateTime.parse(a.key).compareTo(DateTime.parse(b.key)),
          );

    return Container(
      height: 130,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(" ", style: TextStyle(color: Colors.white, fontSize: 12)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Viento",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  Text(
                    "knots",
                    style: TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
              Text("Ola", style: TextStyle(color: Colors.white, fontSize: 12)),
              Text(
                "Lluvia",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),

          const SizedBox(width: 4),

          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: diasOrdenados.map((entry) {
                  final fecha = DateTime.parse(entry.key);
                  final nombreDia = DateFormat('EEE', 'es_ES').format(fecha);
                  final fechaCorta = DateFormat('d MMM', 'es_ES').format(fecha);
                  final resumen = _calcularResumen(entry.value);

                  return GestureDetector(
                    onTap: () =>
                        _mostrarBottomSheet(context, entry.value, fecha),
                    child: Container(
                      width: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      decoration: BoxDecoration(
                        color: EstilosWWW.colorFondoPantalla.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                _capitalizar(nombreDia),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                fechaCorta,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Transform.rotate(
                                angle: _direccionToAngle(resumen["dir"]),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                resumen["viento"],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),

                          Text(
                            "${resumen["ola"]}m",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _iconoLluvia(resumen["lluvia"]),
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "${resumen["lluvia"]}%",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<ClimaModelo>> _agruparPorDia(List<ClimaModelo> datos) {
    final mapa = <String, List<ClimaModelo>>{};
    for (final clima in datos) {
      final fecha = clima.fechaHora.toLocal();
      final clave = DateFormat('yyyy-MM-dd').format(fecha);
      mapa.putIfAbsent(clave, () => []);
      mapa[clave]!.add(clima);
    }
    return mapa;
  }

  Map<String, dynamic> _calcularResumen(List<ClimaModelo> datos) {
    final direcciones = <String, int>{};
    for (final c in datos) {
      direcciones[c.direccionViento] =
          (direcciones[c.direccionViento] ?? 0) + 1;
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

    return {
      "dir": dirDominante,
      "viento": _kmhToKnots(vientoMedio).toStringAsFixed(0),
      "ola": olaMedia.toStringAsFixed(1),
      "lluvia": lluviaMedia.round(),
    };
  }

  String _iconoLluvia(int p) {
    if (p == 0) return "☀️";
    if (p < 30) return "🌤️";
    if (p < 60) return "🌦️";
    if (p < 90) return "🌧️";
    return "⛈️";
  }

  void _mostrarBottomSheet(
    BuildContext context,
    List<ClimaModelo> datosDia,
    DateTime fecha,
  ) {
    final nombreDia = DateFormat('EEEE', 'es_ES').format(fecha);
    final numeroDia = DateFormat('d MMMM', 'es_ES').format(fecha);

    showModalBottomSheet(
      context: context,
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.85),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.22,
          minChildSize: 0.18,
          maxChildSize: 0.75,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    "${_capitalizar(nombreDia)}  •  $numeroDia",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: controller,
                      child: _tablaHoras(datosDia),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _tablaHoras(List<ClimaModelo> datos) {
    final listaOrdenada = [...datos]
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

    final ahora = DateTime.now();
    final formatoDia = DateFormat('yyyy-MM-dd');
    final esHoy =
        formatoDia.format(listaOrdenada.first.fechaHora.toLocal()) ==
        formatoDia.format(ahora);

    List<ClimaModelo> listaFiltrada = esHoy
        ? listaOrdenada
              .where((c) => c.fechaHora.toLocal().hour >= ahora.hour)
              .toList()
        : listaOrdenada;

    if (listaFiltrada.isEmpty) {
      listaFiltrada = listaOrdenada;
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 24,
        dataRowMaxHeight: 26,
        columnSpacing: 14,
        horizontalMargin: 6,
        headingRowHeight: 26,
        columns: [
          const DataColumn(
            label: Text("⏱", style: TextStyle(color: Colors.white)),
          ),
          ...listaFiltrada.map((clima) {
            final hora = DateFormat('HH:mm').format(clima.fechaHora.toLocal());
            return DataColumn(
              label: Text(
                hora,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            );
          }),
        ],
        rows: [
          DataRow(
            cells: [
              const DataCell(
                Text("Viento", style: TextStyle(color: Colors.white)),
              ),
              ...listaFiltrada.map(
                (clima) => DataCell(
                  Row(
                    children: [
                      Transform.rotate(
                        angle: _direccionToAngle(clima.direccionViento),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _kmhToKnots(clima.velocidadViento).toStringAsFixed(0),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          DataRow(
            cells: [
              const DataCell(
                Text("Racha", style: TextStyle(color: Colors.white)),
              ),
              ...listaFiltrada.map(
                (clima) => DataCell(
                  Text(
                    _kmhToKnots(clima.rachaViento).toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),

          DataRow(
            cells: [
              const DataCell(
                Text("Ola", style: TextStyle(color: Colors.white)),
              ),
              ...listaFiltrada.map(
                (clima) => DataCell(
                  Text(
                    clima.alturaOla.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),

          DataRow(
            cells: [
              const DataCell(
                Text("Periodo", style: TextStyle(color: Colors.white)),
              ),
              ...listaFiltrada.map(
                (clima) => DataCell(
                  Text(
                    clima.periodoOla.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),

          DataRow(
            cells: [
              const DataCell(
                Text("Lluvia", style: TextStyle(color: Colors.white)),
              ),
              ...listaFiltrada.map(
                (clima) => DataCell(
                  Text(
                    "${clima.probabilidadLluvia.toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _direccionToAngle(String direccion) {
    final d = direccion.toUpperCase();

    if (d == "VARIABLE" || d == "---") return 0;

    if (d.contains("N") && d.contains("E")) return 45 * math.pi / 180;
    if (d.contains("S") && d.contains("E")) return 135 * math.pi / 180;
    if (d.contains("S") && d.contains("W")) return 225 * math.pi / 180;
    if (d.contains("N") && d.contains("W")) return 315 * math.pi / 180;

    final mapa = {
      "N": 0,
      "NE": 45,
      "E": 90,
      "SE": 135,
      "S": 180,
      "SW": 225,
      "W": 270,
      "NW": 315,
    };

    final grados = mapa[d] ?? 0;
    return grados * math.pi / 180;
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }
}
