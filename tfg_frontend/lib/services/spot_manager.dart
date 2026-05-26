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
  Spot get spotActual => _spotActual!;

  List<ClimaModelo> _prediccionActual = [];
  List<ClimaModelo> get prediccionActual => _prediccionActual;

  // -------------------------------------------------------------
  // 1. Cargar todos los spots
  // -------------------------------------------------------------
  Future<void> inicializar() async {
    _spots = await _db.getTodosLosSpots();
  }

  // -------------------------------------------------------------
  // 2. Seleccionar spot inicial
  // -------------------------------------------------------------
  void seleccionarSpotInicial() {
    if (_spots.isEmpty) return;

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

  // -------------------------------------------------------------
  // 3. Cargar predicción inicial
  // -------------------------------------------------------------
  Future<void> cargarPrediccionInicial() async {
    if (_spotActual == null) return;
    await cargarPrediccion(_spotActual!.id);
  }

  // -------------------------------------------------------------
  // 4. Cargar predicción de un spot
  // -------------------------------------------------------------
  Future<void> cargarPrediccion(String spotId) async {
    final datos = await _db.getClimaPorSpot(spotId);

    _prediccionActual = datos.map((json) {
      return ClimaModelo.fromJson(json);
    }).toList();

    notifyListeners();
  }

  // -------------------------------------------------------------
  // 5. Cambiar spot
  // -------------------------------------------------------------
  Future<void> cambiarSpot(Spot nuevoSpot) async {
    _spotActual = nuevoSpot;
    await cargarPrediccion(nuevoSpot.id);
    notifyListeners();
  }

  // -------------------------------------------------------------
  // 6. Buscar spot en memoria
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
  // 7. Cargar favoritos del usuario
  // -------------------------------------------------------------
  Future<void> cargarFavoritos() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('favoritos_spots')
        .select('spot_id')
        .eq('perfil_id', user.id);

    favoritos = data.map<String>((e) => e['spot_id'] as String).toList();

    notifyListeners(); // ⭐ AHORA LA UI SE ENTERA
  }

  // -------------------------------------------------------------
  // 8. Añadir o quitar favorito
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
      // ⭐ Añadir favorito
      await supabase.from('favoritos_spots').insert({
        'perfil_id': user.id,
        'spot_id': spotId,
      });
    } else {
      // ⭐ Quitar favorito
      await supabase.from('favoritos_spots').delete().eq('id', existe['id']);
    }

    await cargarFavoritos(); // Actualiza lista
    notifyListeners(); // ⭐ Refresca UI (estrella incluida)
  }
}
