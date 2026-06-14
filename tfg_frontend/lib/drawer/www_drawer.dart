import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/drawer/drawer_visitante.dart';
import 'package:tfg_clima_malaga/drawer/drawer_usuario.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';

class WWWDrawer extends StatelessWidget {
  const WWWDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userManager = UserManager(); // referencia única

    return AnimatedBuilder(
      animation: userManager, // escucha cambios del perfil
      builder: (context, _) {
        final user = userManager.usuario;

        return Drawer(
          backgroundColor: Colors.transparent,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          child: user == null ? const DrawerVisitante() : const DrawerUsuario(),
        );
      },
    );
  }
}
