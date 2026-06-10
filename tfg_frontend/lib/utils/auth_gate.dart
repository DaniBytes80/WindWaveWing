import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/menu_principal_usuario/login_page.dart';
import 'package:tfg_clima_malaga/views/principal/principal.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _cargando = true;

  @override
  void initState() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null && mounted) {
        // Usuario confirmado y logueado → ir a pantalla principal
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const VentanaInicioUsuario()),
        );
      }
    });
    super.initState();
    _cargarDatosIniciales();
  }

  Future<void> _cargarDatosIniciales() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      await _cargarTodo();
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _cargarTodo() async {
    await UserManager().cargarPerfilSiExiste();
    await SpotManager().inicializar();
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = snapshot.data?.session;

        if (session == null) {
          UserManager().logout();
          return const LoginPage();
        }

        // ⭐ Cargar datos cuando se detecta sesión nueva
        return FutureBuilder(
          future: _cargarTodo(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return const VentanaInicioUsuario();
          },
        );
      },
    );
  }
}
