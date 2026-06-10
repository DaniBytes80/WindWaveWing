import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';

class MisFavoritosPage extends StatelessWidget {
  const MisFavoritosPage({super.key});

  @override
  Widget build(BuildContext context) {
    final spotManager = SpotManager();
    final spotsFavoritos = spotManager.spots
        .where((s) => spotManager.favoritos.contains(s.id))
        .toList();

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // Fondo semitransparente — pulsar fuera cierra
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
              ),
            ),
          ),

          Center(
            child: Container(
              width: 270,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + X
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
                        child: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 22,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (spotsFavoritos.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        "No tienes favoritos aún",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ),

                  // ✅ FIX: al pulsar un favorito navega correctamente
                  // Devuelve el Spot seleccionado al caller (principal.dart)
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
                        // ✅ Devuelve el Spot — principal.dart lo recibe
                        // y llama a actualizarSpot(spot)
                        Navigator.pop(context, spot);
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

// ============================================================
//  CÓMO ABRIR MisFavoritosPage desde el drawer o donde sea:
//
//  final spot = await Navigator.push<Spot>(
//    context,
//    MaterialPageRoute(builder: (_) => const MisFavoritosPage()),
//  );
//  if (spot != null && context.mounted) {
//    // Obtener VentanaInicioUsuarioState y llamar actualizarSpot
//    // O usar un callback/provider según tu arquitectura
//  }
// ============================================================
