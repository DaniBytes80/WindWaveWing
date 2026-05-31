import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/notifications_service.dart';
import 'package:tfg_clima_malaga/views/register_page.dart';
import 'package:tfg_clima_malaga/views/tema.dart';
import 'package:tfg_clima_malaga/views/principal.dart';
import 'package:tfg_clima_malaga/utils/validadores.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ============================================================
  // LOGIN NORMAL (EMAIL + PASSWORD)
  // ============================================================
  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // ============================================================
    // VALIDACIONES
    // ============================================================

    if (!Validadores.esEmailValido(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Introduce un email válido.")),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Introduce tu contraseña.")));
      return;
    }

    // ============================================================
    // LOGIN
    // ============================================================
    try {
      await authService.signInWithEmailPassword(email, password);

      await UserManager().cargarPerfil();

      final userId = UserManager().perfil?.id;
      if (userId == null) throw Exception("No se pudo obtener user_id");

      await NotificationsService().init(userId);

      if (!UserManager().estaInicializado) {
        await SpotManager().inicializar();
        await SpotManager().cargarFavoritos();
        UserManager().estaInicializado = true;
      }

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
            "Error de acceso. El correo electrónico o la contraseña no es correcta.",
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

  // ============================================================
  // LOGIN SOCIAL (GOOGLE + BIOMETRÍA)
  // ============================================================
  Future<void> loginGoogle() async {
    await authService.signInWithGoogle();
  }

  Future<void> loginBiometria() async {
    final ok = await authService.signInWithBiometrics();
    if (!ok) return;

    await UserManager().cargarPerfil();

    final userId = UserManager().perfil?.id;
    if (userId != null) {
      await NotificationsService().init(userId);
    }

    if (!UserManager().estaInicializado) {
      await SpotManager().inicializar();
      await SpotManager().cargarFavoritos();
      UserManager().estaInicializado = true;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VentanaInicioUsuario()),
      );
    }
  }

  // ============================================================
  // WIDGET ICONO REDONDO (B3)
  // ============================================================
  Widget socialIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: EstilosWWW.colorLetra.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: EstilosWWW.colorLetra),
      ),
    );
  }

  // ============================================================
  // BOTÓN DE ACCESO ESTILO C (ANCHO + ICONO EMAIL)
  // ============================================================
  Widget botonAccesoEmail() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.email),
      label: const Text("Acceder con email"),
      onPressed: login,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 45),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),

      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 50),
        children: [
          // EMAIL
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            style: TextStyle(color: EstilosWWW.colorLetra),
          ),

          // PASSWORD
          TextField(
            controller: _passwordController,
            decoration: const InputDecoration(labelText: "Contraseña"),
            style: TextStyle(color: EstilosWWW.colorLetra),
            obscureText: true,
          ),

          const SizedBox(height: 20),

          // BOTÓN EMAIL (ESTILO C)
          botonAccesoEmail(),

          const SizedBox(height: 25),

          // ICONOS SOCIALES (GOOGLE + BIOMETRÍA)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              socialIcon(icon: Icons.g_mobiledata, onTap: loginGoogle),
              const SizedBox(width: 18),
              socialIcon(icon: Icons.fingerprint, onTap: loginBiometria),
            ],
          ),

          const SizedBox(height: 25),

          // REGISTRO
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
