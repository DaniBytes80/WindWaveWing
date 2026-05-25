import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

import 'tema.dart';
import 'package:tfg_clima_malaga/models/clima_modelo.dart';

class WWWTablaClima extends StatelessWidget {
  final List<ClimaModelo> datosMeteorologicos;

  const WWWTablaClima({super.key, required this.datosMeteorologicos});

  @override
  Widget build(BuildContext context) {
    if (datosMeteorologicos.isEmpty) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: EstilosWWW.fondoTransparente,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "Selecciona un spot para ver el parte de viento y olas",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final diasAgrupados = _agruparPorDia(datosMeteorologicos);

    return SizedBox(
      height: 160,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: diasAgrupados.entries.map((entry) {
          final fecha = DateTime.parse(entry.key);
          final nombreDia = DateFormat('EEEE', 'es_ES').format(fecha);
          final numeroDia = DateFormat('d MMM', 'es_ES').format(fecha);

          final resumen = _calcularResumen(entry.value);

          return GestureDetector(
            onTap: () => _mostrarBottomSheet(context, entry.value, fecha),
            child: Container(
              width: 130,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.60),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${_capitalizar(nombreDia)}\n$numeroDia",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dirección dominante
                  Transform.rotate(
                    angle: _direccionToAngle(resumen["dir"]),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Viento medio
                  Text(
                    "${resumen["viento"]} km/h",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),

                  // Ola media
                  Text(
                    "${resumen["ola"]} m",
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),

                  // Lluvia
                  Row(
                    children: [
                      Text(
                        _iconoLluvia(resumen["lluvia"]),
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${resumen["lluvia"]}%",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
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
    );
  }

  // ============================================================
  // AGRUPAR POR DÍA
  // ============================================================
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

  // ============================================================
  // RESUMEN DIARIO (dirección dominante, viento medio, ola media, lluvia)
  // ============================================================
  Map<String, dynamic> _calcularResumen(List<ClimaModelo> datos) {
    // Dirección dominante
    final direcciones = <String, int>{};
    for (final c in datos) {
      direcciones[c.direccionViento] =
          (direcciones[c.direccionViento] ?? 0) + 1;
    }
    final dirDominante = direcciones.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Viento medio
    final vientoMedio =
        datos.map((c) => c.velocidadViento).reduce((a, b) => a + b) /
        datos.length;

    // Ola media
    final olaMedia =
        datos.map((c) => c.alturaOla).reduce((a, b) => a + b) / datos.length;

    // Lluvia media
    final lluviaMedia =
        datos.map((c) => c.probabilidadLluvia).reduce((a, b) => a + b) /
        datos.length;

    return {
      "dir": dirDominante,
      "viento": vientoMedio.toStringAsFixed(0),
      "ola": olaMedia.toStringAsFixed(1),
      "lluvia": lluviaMedia.toStringAsFixed(0),
    };
  }

  // ============================================================
  // ICONO DE LLUVIA SEGÚN INTENSIDAD
  // ============================================================
  String _iconoLluvia(String porcentaje) {
    final p = int.tryParse(porcentaje) ?? 0;

    if (p == 0) return "☀️";
    if (p < 30) return "🌤️";
    if (p < 60) return "🌦️";
    if (p < 90) return "🌧️";
    return "⛈️";
  }

  // ============================================================
  // BOTTOMSHEET DESLIZABLE
  // ============================================================
  void _mostrarBottomSheet(
    BuildContext context,
    List<ClimaModelo> datosDia,
    DateTime fecha,
  ) {
    final nombreDia = DateFormat('EEEE', 'es_ES').format(fecha);
    final numeroDia = DateFormat('d MMMM', 'es_ES').format(fecha);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.85),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.30,
          maxChildSize: 0.85,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                children: [
                  Text(
                    "${_capitalizar(nombreDia)}  •  $numeroDia",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
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

  // ============================================================
  // TABLA POR HORAS (DETALLE)
  // ============================================================
  Widget _tablaHoras(List<ClimaModelo> datos) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        dataRowMinHeight: 26,
        dataRowMaxHeight: 28,
        columnSpacing: 18,
        horizontalMargin: 10,
        headingRowHeight: 28,
        columns: [
          const DataColumn(
            label: Text("⏱", style: TextStyle(color: Colors.white)),
          ),
          ...datos.map((clima) {
            final hora = DateFormat('HH:mm').format(clima.fechaHora.toLocal());
            return DataColumn(
              label: Text(
                hora,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            );
          }),
        ],
        rows: [
          // Dirección del viento
          DataRow(
            cells: [
              const DataCell(Icon(Icons.air, color: Colors.white, size: 18)),
              ...datos.map(
                (clima) => DataCell(
                  Transform.rotate(
                    angle: _direccionToAngle(clima.direccionViento),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Velocidad del viento
          DataRow(
            cells: [
              const DataCell(Icon(Icons.speed, color: Colors.white, size: 18)),
              ...datos.map(
                (clima) => DataCell(
                  Text(
                    clima.velocidadViento.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          // Rachas
          DataRow(
            cells: [
              const DataCell(
                Icon(Icons.air_outlined, color: Colors.white, size: 18),
              ),
              ...datos.map(
                (clima) => DataCell(
                  Text(
                    clima.rachaViento.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          // Dirección de ola
          DataRow(
            cells: [
              const DataCell(Icon(Icons.waves, color: Colors.white, size: 18)),
              ...datos.map(
                (clima) => DataCell(
                  Transform.rotate(
                    angle: _direccionToAngle(clima.direccionOla),
                    child: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Altura de ola
          DataRow(
            cells: [
              const DataCell(Icon(Icons.water, color: Colors.white, size: 18)),
              ...datos.map(
                (clima) => DataCell(
                  Text(
                    clima.alturaOla.toStringAsFixed(1),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          // Periodo de ola
          DataRow(
            cells: [
              const DataCell(Icon(Icons.timer, color: Colors.white, size: 18)),
              ...datos.map(
                (clima) => DataCell(
                  Text(
                    clima.periodoOla.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          // Lluvia
          DataRow(
            cells: [
              const DataCell(Icon(Icons.cloud, color: Colors.white, size: 18)),
              ...datos.map(
                (clima) => DataCell(
                  Text(
                    "${clima.probabilidadLluvia.toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONVERTIR DIRECCIÓN (N, NE, E...) → ÁNGULO
  // ============================================================
  double _direccionToAngle(String direccion) {
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

    final grados = mapa[direccion.toUpperCase()] ?? 0;
    return grados * math.pi / 180;
  }

  // ============================================================
  // CAPITALIZAR PRIMERA LETRA
  // ============================================================
  String _capitalizar(String texto) {
    return texto[0].toUpperCase() + texto.substring(1);
  }
}
