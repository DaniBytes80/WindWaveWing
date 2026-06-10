import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tfg_clima_malaga/services/auth_service.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/notifications_service.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/register_page.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';
import 'package:tfg_clima_malaga/views/principal/principal.dart';
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
  bool _cargando = false;
  bool _verPassword = false; // ✅ toggle ver contraseña

  Future<void> _postLogin() async {
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
  }

  Future<void> login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (!Validadores.esEmailValido(email)) {
      _snack("Introduce un email válido.");
      return;
    }
    if (password.isEmpty) {
      _snack("Introduce tu contraseña.");
      return;
    }

    setState(() => _cargando = true);
    try {
      await authService.signInWithEmailPassword(email, password);
      await _postLogin();
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message.toLowerCase().contains('email not confirmed')) {
        _snack("Debes confirmar tu email antes de iniciar sesión.");
      } else {
        _snack("Email o contraseña incorrectos.");
      }
    } catch (e) {
      if (mounted) _snack("Error de conexión. Inténtalo de nuevo.");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> loginGoogle() async {
    setState(() => _cargando = true);
    try {
      await authService.signInWithGoogle();
    } catch (e) {
      if (mounted) _snack("Error con Google: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> loginBiometria() async {
    setState(() => _cargando = true);
    try {
      final ok = await authService.signInWithBiometrics();
      if (!ok) {
        if (mounted) _snack("Biometría no verificada.");
        return;
      }
      await _postLogin();
    } catch (e) {
      if (mounted) _snack("Error de biometría: $e");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: EstilosWWW.colorFondoPantalla,
      duration: const Duration(seconds: 4),
    ),
  );

  Widget _socialIcon({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: _cargando ? null : onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: EstilosWWW.colorLetra.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white24),
        ),
        child: Icon(icon, size: 22, color: EstilosWWW.colorLetra),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: EstilosWWW.colorFondoPantalla.withValues(alpha: 0.9),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 50),
        children: [
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(labelText: "Email"),
            style: TextStyle(color: EstilosWWW.colorLetra),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // ✅ Campo contraseña con toggle ver/ocultar
          TextField(
            controller: _passwordController,
            obscureText: !_verPassword,
            style: TextStyle(color: EstilosWWW.colorLetra),
            decoration: InputDecoration(
              labelText: "Contraseña",
              suffixIcon: IconButton(
                icon: Icon(
                  _verPassword ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _verPassword = !_verPassword),
              ),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            icon: _cargando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.email),
            label: const Text("Acceder"),
            onPressed: _cargando ? null : login,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 45),
            ),
          ),
          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(icon: Icons.g_mobiledata, onTap: loginGoogle),
              const SizedBox(width: 20),
              _socialIcon(icon: Icons.fingerprint, onTap: loginBiometria),
            ],
          ),
          const SizedBox(height: 28),

          Center(
            child: Text.rich(
              TextSpan(
                text: '¿No estás registrado? ',
                style: TextStyle(color: EstilosWWW.colorLetra, fontSize: 13),
                children: [
                  TextSpan(
                    text: 'Regístrate',
                    style: TextStyle(
                      color: EstilosWWW.colorLetra,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => showDialog(
                        context: context,
                        barrierColor: EstilosWWW.colorFondoPantalla.withValues(
                          alpha: 0.5,
                        ),
                        builder: (_) => Dialog(
                          backgroundColor: EstilosWWW.colorFondoPantalla,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const RegisterPage(),
                        ),
                      ),
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
