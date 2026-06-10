import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/views/principal/principal.dart';
import 'package:tfg_clima_malaga/utils/tema.dart';
import 'configuration.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es_ES', null);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    url: Configuration.supabaseUrl,
    publishableKey: Configuration.supabaseAnonKey,
  );

  runApp(const WindWaveWingApp());
}

class WindWaveWingApp extends StatelessWidget {
  const WindWaveWingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: EstilosWWW.colorFondoPantalla,
      ),
      home: const SplashPage(),
    );
  }
}

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    final spotManager = SpotManager();
    final userManager = UserManager();
    await spotManager.inicializar();
    await spotManager.cargarFavoritos();// Cargar favoritos
    await userManager.cargarPerfilSiExiste();// Cargar perfil si existe
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const VentanaInicioUsuario()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/wwwIntro.png', fit: BoxFit.fill),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.10,
            left: 0,
            right: 0,
            child: const Column(
              children: [
                CircularProgressIndicator(color: EstilosWWW.colorLetra),
                SizedBox(height: 10),
                Text(
                  'Cargando...',
                  style: TextStyle(color: EstilosWWW.colorLetra, fontSize: 18),
                ),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: EdgeInsets.all(25.0),
              child: Text(
                'v1.0.0-Beta',
                style: TextStyle(
                  color: EstilosWWW.colorLetra,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
