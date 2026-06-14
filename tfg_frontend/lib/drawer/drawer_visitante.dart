import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/register_page.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';
import 'package:tfg_clima_malaga/utils/validadores.dart';

class DrawerVisitante extends StatefulWidget {
  const DrawerVisitante({super.key});
  @override
  State<DrawerVisitante> createState() => _DrawerVisitanteState();
}

class _DrawerVisitanteState extends State<DrawerVisitante> {
  final authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();
    if (!Validadores.esEmailValido(email)) {
      _snack("Introduce un email válido.");
      return;
    }
    if (password.isEmpty) {
      _snack("Introduce tu contraseña.");
      return;
    }
    try {
      await authService.signInWithEmailPassword(email, password);
      await UserManager().cargarPerfilSiExiste();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) _snack("Email o contraseña incorrectos.");
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: EstilosWWW.colorFondoPantalla,
    ),
  );

  void loginGoogle() async {
    Navigator.pop(context);
    await authService.signInWithGoogle();
  }

  void loginBiometria() async {
    Navigator.pop(context);
    final ok = await authService.signInWithBiometrics();
    if (!ok) return;
    await UserManager().cargarPerfilSiExiste();
  }

  void abrirRegistro() {
    Navigator.pop(context);
    Future.delayed(const Duration(milliseconds: 150), () {
      showDialog(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Container(
            decoration: EstilosWWW.decoracionDialog,
            child: const RegisterPage(),
          ),
        ),
      );
    });
  }

  Widget _iconoSocial({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: EstilosWWW.colorAzulMedio,
          shape: BoxShape.circle,
          border: Border.all(color: EstilosWWW.colorAzulBorde),
        ),
        child: Icon(icon, size: 20, color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topLeft,
        child: Container(
          margin: const EdgeInsets.only(top: 55),
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.95),
            border: Border(
              right: BorderSide(
                color: EstilosWWW.colorAzulBorde.withValues(alpha: 0.5),
              ),
              bottom: BorderSide(
                color: EstilosWWW.colorAzulBorde.withValues(alpha: 0.5),
              ),
            ),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _email,
                style: const TextStyle(color: EstilosWWW.colorLetra),
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: "Email"),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _password,
                obscureText: true,
                style: const TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(labelText: "Contraseña"),
              ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: EstilosWWW.botonOscuro,
                onPressed: login,
                child: const Text("Acceso"),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconoSocial(icon: Icons.g_mobiledata, onTap: loginGoogle),
                  const SizedBox(width: 16),
                  _iconoSocial(icon: Icons.fingerprint, onTap: loginBiometria),
                ],
              ),
              const SizedBox(height: 18),

              Center(
                child: Text.rich(
                  TextSpan(
                    text: "¿No estás registrado? ",
                    style: EstilosWWW.textoSecundario,
                    children: [
                      TextSpan(
                        text: "Regístrate",
                        style: EstilosWWW.linkRegistro,
                        recognizer: TapGestureRecognizer()
                          ..onTap = abrirRegistro,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
