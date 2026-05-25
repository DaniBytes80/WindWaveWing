import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: EstilosWWW.fondoTransparente,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: [
                const DataColumn(
                  label: Text(
                    "Métricas",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...datosMeteorologicos.map((clima) {
                  final horaLocal = clima.fechaHora.toLocal();
                  return DataColumn(
                    label: Text(
                      DateFormat('HH:mm').format(horaLocal),
                      style: EstilosWWW.textoNegritaTabla,
                    ),
                  );
                }),
              ],
              rows: [
                // Dirección del viento
                DataRow(
                  cells: [
                    const DataCell(
                      Icon(Icons.explore, color: Colors.white, size: 20),
                    ),
                    ...datosMeteorologicos.map(
                      (clima) => DataCell(
                        Text(
                          clima.direccionViento,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // Velocidad del viento
                DataRow(
                  cells: [
                    const DataCell(
                      Icon(Icons.speed, color: Colors.white, size: 20),
                    ),
                    ...datosMeteorologicos.map(
                      (clima) => DataCell(
                        Text(
                          "${clima.velocidadViento.toStringAsFixed(1)} km/h",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // Rachas
                DataRow(
                  cells: [
                    const DataCell(
                      Icon(Icons.air, color: Colors.white, size: 20),
                    ),
                    ...datosMeteorologicos.map(
                      (clima) => DataCell(
                        Text(
                          "${clima.rachaViento.toStringAsFixed(1)} km/h",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // Altura de ola
                DataRow(
                  cells: [
                    const DataCell(
                      Icon(Icons.waves, color: Colors.white, size: 20),
                    ),
                    ...datosMeteorologicos.map(
                      (clima) => DataCell(
                        Text(
                          "${clima.alturaOla.toStringAsFixed(1)} m",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),

                // Periodo de ola
                DataRow(
                  cells: [
                    const DataCell(
                      Icon(Icons.timer, color: Colors.white, size: 20),
                    ),
                    ...datosMeteorologicos.map(
                      (clima) => DataCell(
                        Text(
                          "${clima.periodoOla.toStringAsFixed(0)} s",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
