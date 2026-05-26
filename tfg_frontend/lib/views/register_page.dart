import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/www_widgets.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  void signUp() async {
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseña no coincide.")),
      );
      return;
    }
    try {
      await authService.signUpWithEmailPassword(email, password);
      // ignore: use_build_context_synchronously
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // <--- AJUSTE INDISPENSABLE AL CONTENIDO
          children: [
            Text(
              "Registrarse",
              style: TextStyle(
                color: EstilosWWW.colorLetra,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Usamos tus campos de texto personalizados
            WWWWidgets.campoTexto(
              controller: _emailController,
              label: "Email",
              icono: Icons.email_outlined,
              tipoTeclado: TextInputType.emailAddress,
              readOnly: true,
            ),
            WWWWidgets.campoTexto(
              controller: _passwordController,
              label: "Contraseña",
              icono: Icons.lock_outline,
              obscure: true,
              readOnly: true,
            ),
            WWWWidgets.campoTexto(
              controller: _confirmPasswordController,
              label: "Confirmar contraseña",
              icono: Icons.lock_reset_outlined,
              obscure: true,
              readOnly: true,
            ),

            const SizedBox(height: 24.0),

            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: EstilosWWW.botonOscuro,
                  onPressed: signUp,
                  child: const Text("Confirmar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
