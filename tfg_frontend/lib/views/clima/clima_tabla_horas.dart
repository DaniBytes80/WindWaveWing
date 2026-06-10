import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'clima_colores.dart';
import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class ClimaTablaHoras extends StatefulWidget {
  final List<ClimaModelo> datos;
  final DateTime fechaDia;
  final void Function(DateTime) onHoraSeleccionada;

  const ClimaTablaHoras({
    super.key,
    required this.datos,
    required this.fechaDia,
    required this.onHoraSeleccionada,
  });

  @override
  State<ClimaTablaHoras> createState() => _ClimaTablaHorasState();
}

class _ClimaTablaHorasState extends State<ClimaTablaHoras> {
  DateTime? _activa;

  @override
  Widget build(BuildContext context) {
    final ordenados = [...widget.datos]
      ..sort((a, b) => a.fechaHora.compareTo(b.fechaHora));

    return Container(
      height: 130,
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
            Text(
              hora,
              style: TextStyle(
                color: isActiva ? Colors.amber : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),

            // Viento — ✅ FIX: direccionViento es String en el modelo
            //          _parseDireccion() lo convierte siempre a double
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

            // Ola
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
              decoration: BoxDecoration(
                color: colorOla(c.alturaOla),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "${c.alturaOla.toStringAsFixed(1)}m",
                style: const TextStyle(color: Colors.white, fontSize: 10),
                textAlign: TextAlign.center,
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

  // ✅ FIX CLAVE: acepta tanto String ("N","SE"...) como número ("95.0")
  // porque la BD puede tener datos antiguos en cardinal y nuevos en grados
  double _parseDireccion(String dir) {
    const pi = 3.14159265358979;

    // Intentar parsear como número primero (datos nuevos: "95.0")
    final num = double.tryParse(dir.trim());
    if (num != null) return num * pi / 180;

    // Si no, convertir de cardinal a grados (datos antiguos: "N", "SE"...)
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
