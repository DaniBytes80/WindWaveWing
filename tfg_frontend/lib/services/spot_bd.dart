import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/models/spot.dart';

class SpotBd {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Método que SpotManager espera
  Future<List<Spot>> getTodosLosSpots() async {
    return obtenerSpots();
  }

  /// Obtiene todos los spots desde la tabla `spot`
  Future<List<Spot>> obtenerSpots() async {
    try {
      final response = await _supabase
          .from('spot')
          .select('''
            id,
            nombre,
            icono,
            cam_url,
            is_surf,
            is_kitesurf,
            is_windsurf,
            is_wing,
            is_sail,
            created_at,
            pointjson,
            id_boya
          ''')
          .order('nombre');

      return response.map<Spot>((json) => Spot.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Método que SpotManager espera
  Future<List<Map<String, dynamic>>> getClimaPorSpot(String spotId) async {
    try {
      final response = await _supabase
          .from('clima')
          .select('*')
          .eq('spot_id', spotId)
          .order('fecha_hora');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Obtiene un spot por ID
  Future<Spot?> obtenerSpotPorId(String id) async {
    try {
      final response = await _supabase
          .from('spot')
          .select('''
            id,
            nombre,
            icono,
            cam_url,
            is_surf,
            is_kitesurf,
            is_windsurf,
            is_wing,
            is_sail,
            created_at,
            pointjson,
            id_boya
          ''')
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return Spot.fromJson(response);
    } catch (e) {
      return null;
    }
  }
}
