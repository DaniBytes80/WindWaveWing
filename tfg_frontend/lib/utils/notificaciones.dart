import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

OverlayEntry? _ventanaInactividadActiva;

void mostrarVentanaInactividad(BuildContext context) {
  final overlay = Overlay.maybeOf(context);

  if (overlay == null) {
    debugPrint("⚠ No se pudo mostrar la ventana: Overlay no disponible");
    return;
  }

  // evitar duplicados
  if (_ventanaInactividadActiva != null) return;

  _ventanaInactividadActiva = OverlayEntry(
    builder: (context) => Stack(
      children: [
        Positioned.fill(
          child: Container(
            color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "⏳ Sesión cerrada por inactividad",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  overlay.insert(_ventanaInactividadActiva!);

  Future.delayed(const Duration(seconds: 20), () {
    _ventanaInactividadActiva?.remove();
    _ventanaInactividadActiva = null;
  });
}
