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

// Clase que contiene la configuración de la aplicación
// Versión de la aplicación
// Muestra una pantalla de carga mientras se inicializan los servicios
// Maneja la navegación a la pantalla principal del usuario una vez que se completa la inicialización

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // Inicialización de Flutter y Firebase
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para inicializar Firebase antes de runApp
  await initializeDateFormatting(
    'es_ES',
    null,
  ); // Inicializa la localización para fechas en español
  // Inicializa Firebase con la configuración específica de la plataforma
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Supabase.initialize(
    // Inicializa Supabase con la URL y la clave pública
    url: Configuration.supabaseUrl, // URL del proyecto Supabase
    publishableKey:
        Configuration.supabaseAnonKey, // Clave pública para autenticación
  );

  runApp(const WindWaveWingApp());
}

class WindWaveWingApp extends StatefulWidget {
  const WindWaveWingApp({super.key});

  @override
  State<WindWaveWingApp> createState() => _WindWaveWingAppState();
}

class _WindWaveWingAppState extends State<WindWaveWingApp> {
  // Suscripción para escuchar cambios de estado de autenticación
  late final StreamSubscription<AuthState> _authSub;
  late final AppLinks _appLinks; // Instancia para manejar deep links
  StreamSubscription<Uri>?
  _linkSub; // Suscripción para escuchar deep links entrantes

  @override
  void initState() {
    super.initState();
    _escucharAuth(); // Configura la escucha de cambios de autenticación
    _escucharDeepLinks(); // Configura la escucha de deep links
  }

  void _escucharAuth() {
    // Escucha cambios de estado de autenticación en Supabase
    _authSub = Supabase.instance.client.auth.onAuthStateChange.listen((
      data,
    ) async {
      // Callback que se ejecuta cuando cambia el estado de autenticación
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

  void _escucharDeepLinks() {
    // Configura la escucha de deep links entrantes
    _appLinks = AppLinks();

    // Deep link que abrió la app (si estaba cerrada)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _procesarLink(uri);
    });

    // Deep links mientras la app está abierta
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _procesarLink(uri),
      onError: (e) => debugPrint('Deep link error: $e'),
    );
  }

  Future<void> _procesarLink(Uri uri) async {
    debugPrint('Deep link recibido: $uri');
    // Supabase procesa automáticamente el token del callback
    // El onAuthStateChange se dispara solo — no hace falta hacer nada más
  }

  @override
  void dispose() {
    // Cancela las suscripciones al cerrar la app
    _authSub.cancel();
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Construye la app principal con tema oscuro y pantalla de splash
    return MaterialApp(
      // MaterialApp es el widget raíz de la app
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
  // Pantalla de carga inicial mientras se inicializa la app
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // Estado de la pantalla de carga
  @override
  void initState() {
    super.initState();
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    // Inicializa los managers y carga datos necesarios antes de mostrar la pantalla principal
    final spotManager = SpotManager();
    final userManager = UserManager();
    await spotManager.inicializar();
    await spotManager.cargarFavoritos();
    await userManager.cargarPerfilSiExiste();
    if (!mounted) {
      return; // Verifica que el widget sigue montado antes de navegar
    }
    // Navega a la pantalla principal del usuario
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
