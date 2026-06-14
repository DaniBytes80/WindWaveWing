import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/models/perfil.dart';
import 'package:tfg_clima_malaga/utils/notificaciones.dart';
import 'package:tfg_clima_malaga/main.dart';
import 'package:tfg_clima_malaga/services/spot_manager.dart';

class UserManager extends ChangeNotifier {
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  final _supabase = Supabase.instance.client;

  Perfil? _perfil;
  bool _isLogueado = false;

  Perfil? get usuario => _perfil;
  Perfil? get perfil => _perfil;
  bool get isLogueado => _isLogueado;

  bool estaInicializado = false;

  Timer? _timerInactividad;

  // Cargar perfil si existe (arranque silencioso)
  Future<void> cargarPerfilSiExiste() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _perfil = null;
      _isLogueado = false;
      estaInicializado = true;
      notifyListeners();
      return;
    }

    try {
      final data = await _supabase
          .from("Perfiles")
          .select()
          .eq("id", user.id)
          .maybeSingle();

      if (data == null) {
        _perfil = null;
        _isLogueado = false;
        estaInicializado = true;
        notifyListeners();
        return;
      }

      _perfil = Perfil.fromJson(data);
      _isLogueado = true;

      // CARGAR SPOTS + FAVORITOS + SPOT ACTUAL + PREDICCIÓN
      await SpotManager().inicializar();

      estaInicializado = true;
      iniciarContadorInactividad();
      notifyListeners();
    } catch (e) {
      _perfil = null;
      _isLogueado = false;
      estaInicializado = true;
      notifyListeners();
    }
  }

  // Cargar perfil (usado en login)
  Future<void> cargarPerfil() async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _perfil = null;
      _isLogueado = false;
      notifyListeners();
      return;
    }

    try {
      final data = await _supabase
          .from("Perfiles")
          .select()
          .eq("id", user.id)
          .single();

      _perfil = Perfil.fromJson(data);
      _isLogueado = true;

      // CARGAR SPOTS + FAVORITOS + SPOT ACTUAL + PREDICCIÓN
      await SpotManager().inicializar();

      iniciarContadorInactividad();
      notifyListeners();
    } catch (e) {
      _perfil = null;
      _isLogueado = false;
      notifyListeners();
    }
  }

  // Establecer perfil manualmente
  void setPerfil(Perfil perfil) {
    _perfil = perfil;
    _isLogueado = true;

    // Cargar spots y favoritos al establecer perfil
    SpotManager().inicializar();

    iniciarContadorInactividad();
    notifyListeners();
  }

  // Actualizar perfil localmente
  void actualizarPerfilLocal(Perfil nuevoPerfil) {
    _perfil = nuevoPerfil;
    notifyListeners();
  }

  // LOGOUT manual o automático
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _perfil = null;
    _isLogueado = false;

    estaInicializado = false;

    _timerInactividad?.cancel();
    _timerInactividad = null;

    notifyListeners();
  }

  // INACTIVIDAD: iniciar temporizador de 10 minutos
  void iniciarContadorInactividad() {
    _timerInactividad?.cancel();

    _timerInactividad = Timer(const Duration(minutes: 120), () async {
      await logout();

      if (navigatorKey.currentContext != null) {
        mostrarVentanaInactividad(navigatorKey.currentContext!);
      }
    });
  }

  // LLAMAR ESTO EN CUALQUIER INTERACCIÓN DEL USUARIO
  void actividadDetectada() {
    if (_isLogueado) {
      iniciarContadorInactividad();
    }
  }
}
