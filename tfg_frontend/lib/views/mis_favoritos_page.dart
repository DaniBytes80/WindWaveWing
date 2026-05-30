import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class MisFavoritosPage extends StatelessWidget {
  const MisFavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spotManager = SpotManager(); // ⭐ referencia única

    final spotsFavoritos = spotManager.spots
        .where((s) => spotManager.favoritos.contains(s.id))
        .toList();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // ⭐ Fondo semitransparente
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
              ),
            ),
          ),

          // ⭐ Ventana centrada
          Center(
            child: Container(
              width: 260,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐ Título + botón X
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mis favoritos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ⭐ Si no hay favoritos
                  if (spotsFavoritos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "No tienes favoritos aún",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),

                  // ⭐ Lista de favoritos
                  ...spotsFavoritos.map(
                    (spot) => ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.star,
                        color: Colors.yellow,
                        size: 20,
                      ),
                      title: Text(
                        spot.nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, spot); // ⭐ devolvemos el spot
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
