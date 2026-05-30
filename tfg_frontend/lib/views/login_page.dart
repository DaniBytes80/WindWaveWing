import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/notifications_service.dart'; // ← AÑADIDO
import 'package:tfg_clima_malaga/views/register_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/principal.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // 1. Login en Supabase
      await authService.signInWithEmailPassword(email, password);

      // 2. Cargar perfil del usuario
      await UserManager().cargarPerfil();

      // 3. Obtener el user_id REAL desde Supabase
      final userId = UserManager().perfil?.id;
      if (userId == null) {
        throw Exception("No se pudo obtener user_id del perfil");
      }

      // 4. Registrar token FCM en Supabase
      await NotificationsService().init(userId);

      // 5. SOLO recargar spots/favoritos si NO vienen del arranque
      if (!UserManager().estaInicializado) {
        await SpotManager().inicializar();
        await SpotManager().cargarFavoritos();
        UserManager().estaInicializado = true;
      }

      // 6. Navegar a la pantalla principal
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VentanaInicioUsuario()),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Error de acceso. El correo electrónico u contraseña no es correcta.",
          ),
        ),
      );

      showDialog(
        context: context,
        barrierColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: EstilosWWW.colorFondoPantalla,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: const RegisterPage(),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            style: TextStyle(color: EstilosWWW.colorLetra),
          ),
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Contraseña"),
            style: TextStyle(color: EstilosWWW.colorLetra),
            obscureText: true,
          ),

          const SizedBox(height: 12.0),
          ElevatedButton(onPressed: login, child: const Text("Acceso")),
          const SizedBox(height: 12.0),

          Center(
            child: Text.rich(
              TextSpan(
                text: '¿No estás registrado? ',
                style: TextStyle(color: EstilosWWW.colorLetra, fontSize: 10),
                children: [
                  TextSpan(
                    text: 'Registrate',
                    style: TextStyle(
                      color: EstilosWWW.colorLetra,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showDialog(
                          context: context,
                          barrierColor: EstilosWWW.colorFondoPantalla
                              .withValues(alpha: 0.5),
                          builder: (BuildContext context) {
                            return Dialog(
                              backgroundColor: EstilosWWW.colorFondoPantalla,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const RegisterPage(),
                            );
                          },
                        );
                      },
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
