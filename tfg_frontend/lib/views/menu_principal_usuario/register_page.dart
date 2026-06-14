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
  bool _verPassword = false;
  bool _verConfirm = false;

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
          barrierDismissible: true,
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Container(
              decoration: EstilosWWW.decoracionDialog,
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EstilosWWW.cabeceraDialog(
                    context,
                    "Confirma tu email",
                    icono: Icons.mark_email_unread,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Hemos enviado un enlace de confirmación a:\n\n$email\n\n"
                    "Revisa tu bandeja de entrada (y spam).\n"
                    "Una vez confirmado ya puedes iniciar sesión.",
                    style: EstilosWWW.textoSecundario,
                  ),
                ],
              ),
            ),
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
        style: const TextStyle(color: EstilosWWW.colorLetra),
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
              color: EstilosWWW.colorLetra,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Crear cuenta", style: EstilosWWW.tituloDialog),
                EstilosWWW.botonCerrar(context),
              ],
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

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: EstilosWWW.colorBordeTabla,
                  foregroundColor: EstilosWWW.colorLetra,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: Colors.white38, width: 1),
                  ),
                ),
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
            ),
          ],
        ),
      ),
    );
  }
}
