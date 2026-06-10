import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';
import 'package:tfg_clima_malaga/views/principal/www_widgets.dart';
import 'package:tfg_clima_malaga/utils/validadores.dart';

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
  bool _cargando = false;
  bool _verPassword = false; // ✅
  bool _verConfirm = false; // ✅

  Future<void> signUp() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    if (!Validadores.esEmailValido(email)) {
      _snack("Introduce un email válido.");
      return;
    }
    if (!Validadores.esContrasenaSegura(pass)) {
      _snack(
        "La contraseña necesita 8+ caracteres, mayúscula, número y carácter especial.",
      );
      return;
    }
    if (pass != confirm) {
      _snack("Las contraseñas no coinciden.");
      return;
    }

    setState(() => _cargando = true);
    try {
      await authService.signUpWithEmailPassword(email, pass);
      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            backgroundColor: EstilosWWW.colorFondoPantalla,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.mark_email_unread, color: Colors.amber),
                SizedBox(width: 8),
                Text(
                  "Confirma tu email",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
            content: Text(
              "Hemos enviado un enlace de confirmación a:\n\n$email\n\n"
              "Revisa tu bandeja de entrada (y spam).\n"
              "Una vez confirmado ya puedes iniciar sesión.",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            actions: [
              ElevatedButton(
                style: EstilosWWW.botonOscuro,
                onPressed: () => Navigator.pop(context),
                child: const Text("Entendido"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) _snack("Error al registrar: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: EstilosWWW.colorFondoPantalla,
    ),
  );

  // ✅ Campo con toggle ver/ocultar
  Widget _campoPassword({
    required TextEditingController controller,
    required String label,
    required bool verTexto,
    required VoidCallback onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: !verTexto,
        style: TextStyle(color: EstilosWWW.colorLetra),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: EstilosWWW.colorLetra.withValues(alpha: 0.7),
          ),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: EstilosWWW.colorLetra.withValues(alpha: 0.7),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              verTexto ? Icons.visibility_off : Icons.visibility,
              color: Colors.white54,
            ),
            onPressed: onToggle,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white30),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Crear cuenta",
              style: TextStyle(
                color: EstilosWWW.colorLetra,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            WWWWidgets.campoTexto(
              controller: _emailController,
              label: "Email",
              icono: Icons.email_outlined,
              tipoTeclado: TextInputType.emailAddress,
              readOnly: false,
            ),

            _campoPassword(
              controller: _passwordController,
              label: "Contraseña",
              verTexto: _verPassword,
              onToggle: () => setState(() => _verPassword = !_verPassword),
            ),

            _campoPassword(
              controller: _confirmPasswordController,
              label: "Confirmar contraseña",
              verTexto: _verConfirm,
              onToggle: () => setState(() => _verConfirm = !_verConfirm),
            ),

            const SizedBox(height: 24),
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
                  onPressed: _cargando ? null : signUp,
                  child: _cargando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text("Registrarse"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
