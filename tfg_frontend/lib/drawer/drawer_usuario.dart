import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/mis_favoritos_page.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';
import 'package:tfg_clima_malaga/widgets/editar_perfil_dialog.dart';
import 'package:tfg_clima_malaga/views/principal/principal.dart';
import 'package:tfg_clima_malaga/main.dart';

// ⭐ IMPORTA TUS PÁGINAS REALES
import 'package:tfg_clima_malaga/views/menu_principal_usuario/alertas/mis_alertas_page.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/material/mis_materiales_page.dart';

class DrawerUsuario extends StatefulWidget {
  const DrawerUsuario({super.key});

  @override
  State<DrawerUsuario> createState() => _DrawerUsuarioState();
}

class _DrawerUsuarioState extends State<DrawerUsuario> {
  final userManager = UserManager();

  @override
  void initState() {
    super.initState();
    userManager.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    userManager.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (mounted) setState(() {});
  }

  void _abrirEditarPerfil(BuildContext context) {
    Navigator.pop(context);

    showDialog(
      context: navigatorKey.currentContext!,
      barrierColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
      builder: (_) => const EditarPerfilDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = userManager.usuario;

    final nombre = user?.nombre ?? "Usuario";
    final avatarUrl = user?.avatarUrl;

    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 55),
          width: 160,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 25),
          decoration: BoxDecoration(
            color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.92),
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(22),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ⭐ AVATAR
              Center(
                child: CircleAvatar(
                  key: ValueKey(avatarUrl),
                  radius: 28,
                  backgroundColor: Colors.white24,
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
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
                  " $nombre ",
                  style: TextStyle(
                    color: EstilosWWW.colorLetra,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              _item(context, Icons.person_outline, "Mi perfil", () {
                _abrirEditarPerfil(context);
              }),

              _item(context, Icons.star_border, "Mis favoritos", () async {
                Navigator.pop(context);

                final spotSeleccionado = await showDialog(
                  context: navigatorKey.currentContext!,
                  barrierColor: Colors.transparent,
                  builder: (_) => const MisFavoritosPage(),
                );

                if (spotSeleccionado != null) {
                  final state = navigatorKey.currentContext
                      ?.findAncestorStateOfType<VentanaInicioUsuarioState>();

                  state?.actualizarSpot(spotSeleccionado);
                }
              }),

              // ⭐ MIS ALERTAS
              _item(
                context,
                Icons.notifications_active_outlined,
                "Mis alertas",
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    navigatorKey.currentContext!,
                    MaterialPageRoute(builder: (_) => const MisAlertasPage()),
                  );
                },
              ),

              // ⭐ MI MATERIAL (TU PANTALLA REAL)
              _item(context, Icons.inventory_2_outlined, "Mi material", () {
                Navigator.pop(context);
                Navigator.push(
                  navigatorKey.currentContext!,
                  MaterialPageRoute(builder: (_) => const MisMaterialesPage()),
                );
              }),

              const SizedBox(height: 20),

              _item(context, Icons.logout, "Cerrar sesión", () async {
                await userManager.logout();
                if (navigatorKey.currentContext != null) {
                  Navigator.pop(navigatorKey.currentContext!);
                }
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
