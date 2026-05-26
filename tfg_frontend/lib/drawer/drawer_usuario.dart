import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/mis_favoritos_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/widgets/editar_perfil_dialog.dart';

class DrawerUsuario extends StatelessWidget {
  const DrawerUsuario({super.key});

  void _abrirEditarPerfil(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
      builder: (_) => const EditarPerfilDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = UserManager().usuario;

    final nombre = user?.nombre ?? "Usuario";
    final avatarUrl = user?.avatarUrl;

    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          width: 180, // 🍏 ULTRAFINO
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
          decoration: BoxDecoration(
            color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(22),
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🍏 AVATAR MINIMALISTA
              Center(
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white24,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 26,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  "Hola, $nombre",
                  style: TextStyle(
                    color: EstilosWWW.colorLetra,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🍏 ENLACES ESTILO APPLE
              _item(context, Icons.person_outline, "Mi perfil", () {
                _abrirEditarPerfil(context);
              }),

              _item(context, Icons.star_border, "Mis favoritos", () async {
                final spotSeleccionado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MisFavoritosPage()),
                );

                if (spotSeleccionado != null) {
                  SpotManager().cambiarSpot(spotSeleccionado);
                }
              }),

              _item(context, Icons.notifications_none, "Mis alertas", () {}),

              const SizedBox(height: 20),

              _item(context, Icons.logout, "Cerrar sesión", () async {
                await UserManager().logout();
                if (context.mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icono,
    String texto,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icono, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
