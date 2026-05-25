import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/services/estado_app.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/update_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final authService = AuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //resizeToAvoidBottomInset: false,
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),

      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          // Cabecera de avatar y usuario.
          Column(
            children: [
              const Icon(Icons.account_circle, size: 20, color: Colors.white),
              const SizedBox(height: 5),
              Text(
                EstadoApp()
                    .nombreUsuarioLogueado, // Muestra el nombre del usuario
                style: TextStyle(color: EstilosWWW.colorLetra, fontSize: 10),
              ),
            ],
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.white, size: 10),
            title: const Text(
              "Editar Perfil",
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            onTap: () {
              // Cuando el usuario pulse en Editar Perfil
              showDialog(
                context: context,
                barrierColor: EstilosWWW.colorFondoPantalla.withValues(
                  alpha: 0.5,
                ),
                builder: (BuildContext context) {
                  // Usamos Dialog o AlertDialog para envolver tu widget
                  return Dialog(
                    backgroundColor: EstilosWWW.colorFondoPantalla,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: UpdatePage(),
                  );
                },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.favorite, color: Colors.white, size: 10),
            title: const Text(
              "Spots Favoritos",
              style: TextStyle(color: Colors.white, fontSize: 10),
            ),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: 10,
            ),
            title: const Text(
              "Cerrar Sesión",
              style: TextStyle(color: Colors.redAccent, fontSize: 10),
            ),
            onTap: () async {
              await authService.logout();
            },
          ),
        ],
      ),
    );
  }
}
