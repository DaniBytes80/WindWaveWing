import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/register_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
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

  // ============================================================
  // LOGIN EMAIL
  // ============================================================
  void login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    // VALIDAR EMAIL
    if (!Validadores.esEmailValido(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce un email válido.")),
      );
      return;
    }

    // VALIDAR CONTRASEÑA
    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Introduce tu contraseña.")));
      return;
    }

    try {
      await authService.signInWithEmailPassword(email, password);

      await UserManager().cargarPerfilSiExiste();

      if (!mounted) return;
      Navigator.pop(context); // Cierra el Drawer
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email o contraseña incorrectos.")),
      );
    }
  }

  // ============================================================
  // LOGIN GOOGLE
  // ============================================================
  void loginGoogle() async {
    Navigator.pop(context); // Cierra el Drawer antes del login
    await authService.signInWithGoogle();
  }

  // ============================================================
  // LOGIN BIOMETRÍA
  // ============================================================
  void loginBiometria() async {
    Navigator.pop(context); // Cierra el Drawer antes del login

    final ok = await authService.signInWithBiometrics();
    if (!ok) return;

    await UserManager().cargarPerfilSiExiste();
  }

  // ============================================================
  // ABRIR REGISTRO
  // ============================================================
  void abrirRegistro() {
    Navigator.pop(context); // Cierra el Drawer

    Future.delayed(const Duration(milliseconds: 150), () {
      showDialog(
        context: context,
        barrierColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.0),
        builder: (_) => Dialog(
          backgroundColor: EstilosWWW.colorFondoPantalla.withValues(
            alpha: 0.85,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const RegisterPage(),
        ),
      );
    });
  }

  // ============================================================
  // ICONO SOCIAL REDONDO
  // ============================================================
  Widget socialIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================
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
            color: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // EMAIL
              TextField(
                controller: _email,
                style: TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(
                  labelText: "Email",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              // PASSWORD
              TextField(
                controller: _password,
                obscureText: true,
                style: TextStyle(color: EstilosWWW.colorLetra),
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  labelStyle: TextStyle(color: Colors.white70),
                ),
              ),

              const SizedBox(height: 16),

              // BOTÓN ACCESO EMAIL
              ElevatedButton(
                style: EstilosWWW.botonOscuro,
                onPressed: login,
                child: const Text("Acceso"),
              ),

              const SizedBox(height: 18),

              // ICONOS SOCIALES (GOOGLE + BIOMETRÍA)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  socialIcon(icon: Icons.g_mobiledata, onTap: loginGoogle),
                  const SizedBox(width: 18),
                  socialIcon(icon: Icons.fingerprint, onTap: loginBiometria),
                ],
              ),

              const SizedBox(height: 18),

              // REGISTRO
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "¿No estás registrado? ",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    children: [
                      TextSpan(
                        text: "Regístrate",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
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
