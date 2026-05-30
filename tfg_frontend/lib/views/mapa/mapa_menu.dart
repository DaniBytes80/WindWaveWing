import 'package:flutter/material.dart';

class MapaMenu extends StatelessWidget {
  const MapaMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white.withValues(alpha: 0.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Capas del mapa",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 18),

            _opcion(context, icono: Icons.air, texto: "Viento", modo: "viento"),

            _opcion(context, icono: Icons.waves, texto: "Olas", modo: "olas"),

            _opcion(
              context,
              icono: Icons.thermostat,
              texto: "Temperatura",
              modo: "temperatura",
            ),

            _opcion(
              context,
              icono: Icons.cloudy_snowing,
              texto: "Lluvia",
              modo: "lluvia",
            ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cerrar",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _opcion(
    BuildContext context, {
    required IconData icono,
    required String texto,
    required String modo,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context, modo); // devolvemos el modo seleccionado
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icono, size: 26, color: Colors.blueAccent),
            const SizedBox(width: 12),
            Text(
              texto,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
