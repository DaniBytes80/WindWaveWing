import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/models/clima_modelo.dart';
import 'package:tfg_clima_malaga/models/spot.dart';
import 'package:tfg_clima_malaga/services/spot_bd.dart';

class SpotManager extends ChangeNotifier {
  static final SpotManager _instance = SpotManager._internal();
  factory SpotManager() => _instance;
  SpotManager._internal();

  final SpotBd _db = SpotBd();
  final supabase = Supabase.instance.client;

  List<String> favoritos = [];

  List<Spot> _spots = [];
  List<Spot> get spots => _spots;

  Spot? _spotActual;
  Spot? get spotActual => _spotActual;

  List<ClimaModelo> _prediccionActual = [];
  List<ClimaModelo> get prediccionActual => _prediccionActual;

  // -------------------------------------------------------------
  // INICIALIZACIÓN COMPLETA (llamar SIEMPRE al entrar logueado)
  // -------------------------------------------------------------
  Future<void> inicializar() async {
    // 1️⃣ Cargar spots
    _spots = await _db.getTodosLosSpots();

    // 2️⃣ Seleccionar spot inicial
    if (_spots.isNotEmpty) {
      try {
        _spotActual = _spots.firstWhere(
          (s) =>
              s.nombre.toLowerCase().contains('málaga') ||
              s.nombre.toLowerCase().contains('malaga'),
        );
      } catch (_) {
        _spotActual = _spots.first;
      }
    }

    // 3️⃣ Cargar favoritos
    await cargarFavoritos(silencioso: true);

    // 4️⃣ Cargar predicción del spot inicial
    if (_spotActual != null) {
      await cargarPrediccion(_spotActual!.id);
    }

    notifyListeners();
  }

  // -------------------------------------------------------------
  // Cargar predicción de un spot
  // -------------------------------------------------------------
  Future<void> cargarPrediccion(String spotId) async {
    final datos = await _db.getClimaPorSpot(spotId);

    _prediccionActual = datos.map((json) {
      return ClimaModelo.fromJson(json);
    }).toList();

    notifyListeners();
  }

  // -------------------------------------------------------------
  // Cambiar spot
  // -------------------------------------------------------------
  Future<void> cambiarSpot(Spot nuevoSpot) async {
    _spotActual = nuevoSpot;
    await cargarPrediccion(nuevoSpot.id);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // Buscar spot
  // -------------------------------------------------------------
  Spot? buscarSpot(String nombre) {
    try {
      return _spots.firstWhere(
        (s) => s.nombre.toLowerCase().contains(nombre.toLowerCase()),
      );
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------
  // Cargar favoritos
  // -------------------------------------------------------------
  Future<void> cargarFavoritos({bool silencioso = false}) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('favoritos_spots')
        .select('spot_id')
        .eq('perfil_id', user.id);

    favoritos = data.map<String>((e) => e['spot_id'] as String).toList();

    if (!silencioso) notifyListeners();
  }

  // -------------------------------------------------------------
  // Añadir o quitar favorito
  // -------------------------------------------------------------
  Future<void> toggleFavorito(String spotId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final existe = await supabase
        .from('favoritos_spots')
        .select()
        .eq('perfil_id', user.id)
        .eq('spot_id', spotId)
        .maybeSingle();

    if (existe == null) {
      await supabase.from('favoritos_spots').insert({
        'perfil_id': user.id,
        'spot_id': spotId,
        'notificaciones': true,
      });
    } else {
      await supabase.from('favoritos_spots').delete().eq('id', existe['id']);
    }

    await cargarFavoritos();
    notifyListeners();
  }
}
