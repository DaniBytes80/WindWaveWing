import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:app_links/app_links.dart';

import 'package:tfg_clima_malaga/services/spot_manager.dart';
import 'package:tfg_clima_malaga/services/user_manager.dart';
import 'package:tfg_clima_malaga/services/notifications_service.dart';
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

class WindWaveWingApp extends StatefulWidget {
  const WindWaveWingApp({super.key});

  @override
  State<WindWaveWingApp> createState() => _WindWaveWingAppState();
}

class _WindWaveWingAppState extends State<WindWaveWingApp> {
  late final StreamSubscription<AuthState> _authSub;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _escucharAuth();
    _escucharDeepLinks();
  }

  // ─────────────────────────────────────────────────────────
  //  Escucha cambios de sesión de Supabase
  //  Cuando Google (o cualquier OAuth) completa el login,
  //  Supabase emite AuthChangeEvent.signedIn → navegamos
  // ─────────────────────────────────────────────────────────
  void _escucharAuth() {
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        // Usuario autenticado → cargar perfil y navegar
        final userManager = UserManager();
        await userManager.cargarPerfil();

        final userId = userManager.perfil?.id;
        if (userId != null) {
          await NotificationsService().init(userId);
        }

        if (!UserManager().estaInicializado) {
          await SpotManager().inicializar();
          await SpotManager().cargarFavoritos();
          UserManager().estaInicializado = true;
        }

        // Navegar a la pantalla principal si no estamos ya en ella
        final context = navigatorKey.currentContext;
        if (context != null && context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const VentanaInicioUsuario()),
            (route) => false,
          );
        }
      }

      if (event == AuthChangeEvent.signedOut) {
        // Si se cierra sesión, el WWWDrawer ya maneja la navegación
        UserManager().estaInicializado = false;
      }
    });
  }

  // ─────────────────────────────────────────────────────────
  //  Escucha deep links (windwavewing://auth/callback)
  //  Necesario para que el callback de Google OAuth
  //  llegue a la app desde el navegador externo
  // ─────────────────────────────────────────────────────────
  void _escucharDeepLinks() {
    _appLinks = AppLinks();

    // Deep link que abrió la app (si estaba cerrada)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _procesarLink(uri);
    });

    // Deep links mientras la app está abierta
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _procesarLink(uri),
      onError: (e) => debugPrint('❌ Deep link error: $e'),
    );
  }

  Future<void> _procesarLink(Uri uri) async {
    debugPrint('🔗 Deep link recibido: $uri');
    // Supabase procesa automáticamente el token del callback
    // El onAuthStateChange se dispara solo — no hace falta hacer nada más
  }

  @override
  void dispose() {
    _authSub.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

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

// ─────────────────────────────────────────────────────────────
//  SplashPage — sin cambios
// ─────────────────────────────────────────────────────────────
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
    await spotManager.cargarFavoritos();
    await userManager.cargarPerfilSiExiste();
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
