import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/mis_favoritos_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/widgets/editar_perfil_dialog.dart'; // ⭐ IMPORTANTE

class DrawerUsuario extends StatelessWidget {
  const DrawerUsuario({super.key});

  // ⭐ AÑADE ESTA FUNCIÓN AQUÍ
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
          margin: const EdgeInsets.only(top: 55),
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ⭐ AVATAR
              Center(
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white24,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl == null
                      ? Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : "U",
                          style: const TextStyle(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),

              const SizedBox(height: 12),

              Center(
                child: Text(
                  "Hola, $nombre",
                  style: TextStyle(
                    color: EstilosWWW.colorLetra,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // ⭐ ENLACES
              _enlace(context, "Mi perfil", () {
                _abrirEditarPerfil(context); // ⭐ YA FUNCIONA
              }),

              _enlace(context, "Mis favoritos", () async {
                final spotSeleccionado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MisFavoritosPage()),
                );

                // Si el usuario selecciona un spot → actualizar spotActual
                if (spotSeleccionado != null) {
                  SpotManager().cambiarSpot(spotSeleccionado);
                }
              }),

              _enlace(context, "Mis alertas", () {
                // TODO
              }),

              const SizedBox(height: 20),

              _enlace(context, "Cerrar sesión", () async {
                await UserManager().logout();
                if (context.mounted) Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _enlace(BuildContext context, String texto, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          texto,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
