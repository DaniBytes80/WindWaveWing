import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';

import 'package:tfg_clima_malaga/views/login_page.dart';
import 'package:tfg_clima_malaga/views/principal.dart'; // ← aquí el cambio

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _inicializar();
  }

  Future<void> _inicializar() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session != null) {
      await UserManager().cargarPerfilSiExiste();
      await SpotManager().inicializar();
      SpotManager().seleccionarSpotInicial();
      await SpotManager().cargarPrediccionInicial();
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
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
          return const LoginPage();
        }

        return const VentanaInicioUsuario(); // ← tu widget de inicio
      },
    );
  }
}
