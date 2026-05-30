import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/widgets/editar_perfil_dialog.dart';

class ProfileWidget extends StatelessWidget {
  const ProfileWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserManager().usuario;

    if (user == null) {
      return const Center(
        child: Text(
          "No hay usuario cargado",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ⭐ AVATAR
          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white24,
            backgroundImage:
                user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                ? const Icon(Icons.person, size: 50, color: Colors.white)
                : null,
          ),

          const SizedBox(height: 12),

          // ⭐ NOMBRE
          Text(
            user.nombre ?? "",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          // ⭐ EMAIL
          Text(
            user.email,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),

          const SizedBox(height: 20),

          // ⭐ TELÉFONO
          if (user.telefono != null && user.telefono!.isNotEmpty)
            Text(
              "📞 ${user.telefono}",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),

          const SizedBox(height: 10),

          // ⭐ PESO
          if (user.pesoKg != null)
            Text(
              "⚖️ ${user.pesoKg} kg",
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),

          const SizedBox(height: 10),

          // ⭐ NOTIFICACIONES
          Text(
            user.notificacionesActivas
                ? "🔔 Notificaciones activas"
                : "🔕 Notificaciones desactivadas",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),

          const SizedBox(height: 20),

          // ⭐ DEPORTES
          Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              if (user.surf) _chip("Surf", Icons.waves),
              if (user.kiteSurf) _chip("Kitesurf", Icons.air),
              if (user.windsurf) _chip("Windsurf", Icons.sailing),
              if (user.wing) _chip("Wingfoil", Icons.flight),
              if (user.sail) _chip("Vela", Icons.directions_boat),
            ],
          ),

          const SizedBox(height: 25),

          // ⭐ BOTÓN EDITAR PERFIL
          ElevatedButton(
            style: EstilosWWW.botonOscuro,
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const EditarPerfilDialog(),
              );
            },
            child: const Text("Editar Perfil"),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, IconData icono) {
    return Chip(
      backgroundColor: Colors.white24,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, color: Colors.white, size: 16),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
