import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/update_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserManager().usuario;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.account_circle, size: 60, color: Colors.white),
          const SizedBox(height: 10),

          Text(
            user?.nombre ?? "",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Text(
            user?.email ?? "",
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: EstilosWWW.colorFondoPantalla,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const UpdatePage(),
                ),
              );
            },
            child: const Text("Editar Perfil"),
          ),
        ],
      ),
    );
  }
}
