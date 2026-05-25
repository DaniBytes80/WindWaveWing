import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/models/spot.dart';

class MisFavoritosPage extends StatefulWidget {
  const MisFavoritosPage({super.key});

  @override
  State<MisFavoritosPage> createState() => _MisFavoritosPageState();
}

class _MisFavoritosPageState extends State<MisFavoritosPage> {
  @override
  Widget build(BuildContext context) {
    final spotManager = SpotManager();
    final favoritosIds = spotManager.favoritos;

    // Obtener los spots completos
    final List<Spot> favoritos = spotManager.spots
        .where((s) => favoritosIds.contains(s.id))
        .toList();

    return Scaffold(
      backgroundColor: EstilosWWW.colorFondoPantalla,
      appBar: AppBar(
        backgroundColor: EstilosWWW.colorFondoPantalla,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Mis favoritos",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: favoritos.isEmpty
          ? const Center(
              child: Text(
                "No tienes spots favoritos",
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            )
          : ListView.builder(
              itemCount: favoritos.length,
              itemBuilder: (context, index) {
                final spot = favoritos[index];

                return ListTile(
                  leading: const Icon(Icons.star, color: Colors.yellow),
                  title: Text(
                    spot.nombre,
                    style: const TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    // Volver a la pantalla principal con este spot seleccionado
                    Navigator.pop(context, spot);
                  },
                );
              },
            ),
    );
  }
}
