import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../clima/clima_utils.dart';
import '../clima/clima_colores.dart';
import '../clima/clima_resumen.dart';
import '../clima/clima_tabla_horas.dart';

import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class WWWTablaClima extends StatelessWidget {
  final List<ClimaModelo> datosMeteorologicos;
  final void Function(DateTime) onHoraSeleccionada;

  const WWWTablaClima({
    super.key,
    required this.datosMeteorologicos,
    required this.onHoraSeleccionada,
  });

  @override
  Widget build(BuildContext context) {
    if (datosMeteorologicos.isEmpty) return const SizedBox.shrink();

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
      height: 165,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _columnaIzquierda(),
          const SizedBox(width: 4),
          _tablaDias(context, diasOrdenados),
        ],
      ),
    );
  }

  Widget _columnaIzquierda() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(" ", style: TextStyle(color: Colors.white, fontSize: 12)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Viento", style: TextStyle(color: Colors.white, fontSize: 12)),
            Text(
              "knots",
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
        Text("Ola", style: TextStyle(color: Colors.white, fontSize: 12)),
        Text("Periodo", style: TextStyle(color: Colors.white, fontSize: 12)),
        Text("Lluvia", style: TextStyle(color: Colors.white, fontSize: 12)),
        Text("Temp", style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }

  Widget _tablaDias(
    BuildContext context,
    List<MapEntry<String, List<ClimaModelo>>> dias,
  ) {
    return Expanded(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: dias.map((entry) {
            final fecha = DateTime.parse(entry.key);
            final nombreDia = DateFormat('EEE', 'es_ES').format(fecha);
            final fechaCorta = DateFormat('d MMM', 'es_ES').format(fecha);
            final resumen = calcularResumen(entry.value);
            return GestureDetector(
              onTap: () => _mostrarTablaHoras(context, entry.value, fecha),
              child: _celdaDia(nombreDia, fechaCorta, resumen),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _celdaDia(
    String nombreDia,
    String fechaCorta,
    Map<String, dynamic> resumen,
  ) {
    final dirOlaAngle = _dirGradosToAngle(resumen["dirOla"] ?? 0);
    final periodo = resumen["periodo"] ?? 0.0;

    return Container(
      width: 52,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      padding: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Fecha
          Column(
            children: [
              Text(
                capitalizar(nombreDia),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                fechaCorta,
                style: const TextStyle(color: Colors.white70, fontSize: 10),
              ),
            ],
          ),

          // Viento
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorViento(double.parse(resumen["viento"])),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: _dirGradosToAngle(resumen["dir"]),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  resumen["viento"],
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),

          // Ola con dirección
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorOla(double.parse(resumen["ola"])),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.rotate(
                  angle: dirOlaAngle,
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 11,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  "${resumen["ola"]}m",
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),

          // Periodo de ola
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorOla(
                double.parse(resumen["ola"]),
              ).withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              periodo > 0 ? "${periodo.toStringAsFixed(0)}s" : "-",
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),

          // Lluvia
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorLluvia(resumen["lluvia"]),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _iconoLluvia(resumen["lluvia"]),
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "${resumen["lluvia"]}%",
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),

          // Temperatura
          Container(
            width: double.infinity,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: colorTemperatura(double.parse(resumen["temp"])),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "${resumen["temp"]}°",
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarTablaHoras(
    BuildContext context,
    List<ClimaModelo> datosDia,
    DateTime fecha,
  ) {
    final nombreDia = DateFormat('EEEE', 'es_ES').format(fecha);
    final numeroDia = DateFormat('d MMMM', 'es_ES').format(fecha);
    final ahora = DateTime.now();
    final esHoy =
        fecha.year == ahora.year &&
        fecha.month == ahora.month &&
        fecha.day == ahora.day;
    final horaInicial = esHoy ? ahora.hour : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                "${capitalizar(nombreDia)}  •  $numeroDia",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ClimaTablaHoras(
                datos: datosDia,
                fechaDia: fecha,
                horaInicial: horaInicial,
                onHoraSeleccionada: (hora) {
                  Navigator.pop(context);
                  onHoraSeleccionada(hora);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  double _dirGradosToAngle(dynamic dir) {
    const pi = 3.14159265358979;
    if (dir is num) return dir.toDouble() * pi / 180;
    return direccionToAngle(dir.toString());
  }

  String _iconoLluvia(int p) {
    if (p == 0) return "☀️";
    if (p < 30) return "🌤️";
    if (p < 60) return "🌦️";
    if (p < 90) return "🌧️";
    return "⛈️";
  }

  Map<String, List<ClimaModelo>> _agruparPorDia(List<ClimaModelo> datos) {
    final mapa = <String, List<ClimaModelo>>{};
    for (final c in datos) {
      final clave = DateFormat('yyyy-MM-dd').format(c.fechaHora.toLocal());
      mapa.putIfAbsent(clave, () => []);
      mapa[clave]!.add(c);
    }
    return mapa;
  }
}
