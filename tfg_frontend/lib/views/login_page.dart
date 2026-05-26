import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/views/register_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await authService.signInWithEmailPassword(email, password);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Error de acceso. El correo electrónico u contraseña no es correcta.",
            ),
          ),
        );
        showDialog(
          context: context,
          barrierColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.5),
          builder: (BuildContext context) {
            // Usamos Dialog o AlertDialog para envolver tu widget
            return Dialog(
              backgroundColor: EstilosWWW.colorFondoPantalla,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: const RegisterPage(), // Tu widget de registro
            );
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),

      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          // Recoge el texto del correo electrónico
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            style: TextStyle(color: EstilosWWW.colorLetra),
          ),
          // Recoge el texto de la contraseña
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Contraseña"),
            style: TextStyle(color: EstilosWWW.colorLetra),
            obscureText: true,
          ),

          // Boton del evento.
          const SizedBox(height: 12.0),
          ElevatedButton(onPressed: login, child: Text("Acceso")),
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
                      decoration: TextDecoration
                          .underline, // Opcional: para resaltar el link
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        showDialog(
                          context: context,
                          barrierColor: EstilosWWW.colorFondoPantalla
                              .withValues(alpha: 0.5),
                          builder: (BuildContext context) {
                            // Usamos Dialog o AlertDialog para envolver tu widget
                            return Dialog(
                              backgroundColor: EstilosWWW.colorFondoPantalla,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child:
                                  const RegisterPage(), // Tu widget de registro
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
