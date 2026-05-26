import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class MisFavoritosPage extends StatelessWidget {
  const MisFavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spotsFavoritos = SpotManager().spots
        .where((s) => SpotManager().favoritos.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(
        alpha: 0.5,
      ), // ⭐ 50% transparencia
      body: Center(
        child: Container(
          width: 220, // estrecho, tipo menú
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: EstilosWWW.colorFondoPantalla,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // ⭐ alto según nº de spots
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mis favoritos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
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
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  onTap: () {
                    SpotManager().cambiarSpot(spot); // ⭐ actualiza spotActual
                    Navigator.pop(context, spot); // ⭐ devolvemos el spot
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
