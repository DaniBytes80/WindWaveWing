import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'clima_colores.dart';
import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class ClimaTablaHoras extends StatefulWidget {
  final List<ClimaModelo> datos;
  final DateTime fechaDia;
  final void Function(DateTime) onHoraSeleccionada;
  final int horaInicial;

  const ClimaTablaHoras({
    super.key,
    required this.datos,
    required this.fechaDia,
    required this.onHoraSeleccionada,
    this.horaInicial = 0,
  });

  @override
  State<ClimaTablaHoras> createState() => _ClimaTablaHorasState();
}

class _ClimaTablaHorasState extends State<ClimaTablaHoras> {
  DateTime? _activa;
  late final ScrollController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = ScrollController();
    if (widget.horaInicial > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final offset = widget.horaInicial * 54.0;
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            offset.clamp(0.0, _scrollCtrl.position.maxScrollExtent),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ordenados = [...widget.datos]
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

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
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollCtrl,
              scrollDirection: Axis.horizontal,
              child: Row(children: ordenados.map(_celdaHora).toList()),
            ),
          ),
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

  Widget _celdaHora(ClimaModelo c) {
    final local = c.fechaHora.toLocal();
    final hora = DateFormat('HH:mm').format(local);
    final isActiva =
        _activa != null &&
        _activa!.day == local.day &&
        _activa!.hour == local.hour;

    final dirOlaAngle = _parseDireccion(c.direccionOla);

    return GestureDetector(
      onTap: () {
        setState(() => _activa = local);
        widget.onHoraSeleccionada(c.fechaHora);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isActiva
              ? Colors.amber.withValues(alpha: 0.22)
              : EstilosWWW.colorFondoPantalla.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: isActiva ? Border.all(color: Colors.amber, width: 1.2) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Hora
            Text(
              hora,
              style: TextStyle(
                color: isActiva ? Colors.amber : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Viento
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: colorViento(c.velocidadViento),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: _parseDireccion(c.direccionViento),
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    c.velocidadViento.toStringAsFixed(0),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),

            // Ola con dirección
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: colorOla(c.alturaOla),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Transform.rotate(
                    angle: dirOlaAngle,
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 1),
                  Text(
                    "${c.alturaOla.toStringAsFixed(1)}m",
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ],
              ),
            ),

            // Periodo de ola
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: colorOla(c.alturaOla).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                c.periodoOla > 0 ? "${c.periodoOla.toStringAsFixed(0)}s" : "-",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),

            // Lluvia
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: colorLluvia(c.probabilidadLluvia.round()),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _iconoLluvia(c.probabilidadLluvia.round()),
                    style: const TextStyle(fontSize: 9),
                  ),
                  Text(
                    "${c.probabilidadLluvia.toStringAsFixed(0)}%",
                    style: const TextStyle(color: Colors.white, fontSize: 9),
                  ),
                ],
              ),
            ),

            // Temperatura
            Container(
              width: double.infinity,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: colorTemperatura(c.temperatura),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${c.temperatura.toStringAsFixed(0)}°",
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _parseDireccion(String dir) {
    const pi = 3.14159265358979;
    final num = double.tryParse(dir.trim());
    if (num != null) return num * pi / 180;
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
    final grados = cardinal[dir.trim().toUpperCase()] ?? 0.0;
    return grados * pi / 180;
  }

  String _iconoLluvia(int p) {
    if (p == 0) return "☀️";
    if (p < 30) return "🌤️";
    if (p < 60) return "🌦️";
    if (p < 90) return "🌧️";
    return "⛈️";
  }
}
