import 'package:supabase_flutter/supabase_flutter.dart';
import '/models/alerta.dart';
import 'package:tfg_clima_malaga/models/alerta_generada.dart';

class AlertasService {
  final supabase = Supabase.instance.client;

  Future<bool> crearAlerta(Map<String, dynamic> data) async {
    try {
      await supabase.from('AlertasUsuario').insert(data);
      return true;
    } catch (e) {
      print("ERROR creando alerta: $e");
      return false;
    }
  }

  Future<bool> insertarAlerta(Alerta alerta) async {
    try {
      await supabase.from('AlertasUsuario').insert(alerta.toJson());
      return true;
    } catch (e) {
      print("ERROR insertando alerta: $e");
      return false;
    }
  }

  Future<List<Alerta>> obtenerAlertasUsuario(String userId) async {
    try {
      final data = await supabase
          .from('AlertasUsuario')
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion', ascending: false);
      return data.map<Alerta>((json) => Alerta.fromJson(json)).toList();
    } catch (e) {
      print("ERROR obteniendo alertas: $e");
      return [];
    }
  }

  Future<bool> actualizarAlerta(Alerta alerta) async {
    try {
      await supabase
          .from('AlertasUsuario')
          .update(alerta.toJson())
          .eq('id', alerta.id);
      return true;
    } catch (e) {
      print("ERROR actualizando alerta: $e");
      return false;
    }
  }

  Future<bool> borrarAlerta(String alertaId) async {
    try {
      await supabase.from('AlertasUsuario').delete().eq('id', alertaId);
      return true;
    } catch (e) {
      print("ERROR borrando alerta: $e");
      return false;
    }
  }

  Future<bool> cambiarEstadoAlerta(String alertaId, bool activa) async {
    try {
      await supabase
          .from('AlertasUsuario')
          .update({'activa': activa})
          .eq('id', alertaId);
      return true;
    } catch (e) {
      print("ERROR cambiando estado alerta: $e");
      return false;
    }
  }

  Future<List<Alerta>> obtenerAlertasPorSpot(String spotId) async {
    try {
      final data = await supabase
          .from('AlertasUsuario')
          .select()
          .eq('spot_id', spotId)
          .eq('activa', true);
      return data.map<Alerta>((json) => Alerta.fromJson(json)).toList();
    } catch (e) {
      print("ERROR obteniendo alertas por spot: $e");
      return [];
    }
  }

  // obtener AlertasGeneradas con info del material
  Future<List<AlertaGenerada>> obtenerAlertasGeneradas(String userId) async {
    try {
      final data = await supabase
          .from('AlertasGeneradas')
          .select('''
            id, user_id, spot_id, fecha, mensaje,
            material_usado,
            MaterialUsuario (
              nombre, tipo, medida, disciplina, marca, modelo
            )
          ''')
          .eq('user_id', userId)
          .order('fecha', ascending: false);

      return data
          .map<AlertaGenerada>((json) => AlertaGenerada.fromJson(json))
          .toList();
    } catch (e) {
      print("ERROR obteniendo alertas generadas: $e");
      return [];
    }
  }

  Future<bool> borrarAlertaGenerada(String id) async {
    try {
      await supabase.from('AlertasGeneradas').delete().eq('id', id);
      return true;
    } catch (e) {
      print("ERROR borrando alerta generada: $e");
      return false;
    }
  }

  Future<bool> borrarAlertasGeneradasDeSpot(
      String userId, String spotId) async {
    try {
      await supabase
          .from('AlertasGeneradas')
          .delete()
          .eq('user_id', userId)
          .eq('spot_id', spotId);
      return true;
    } catch (e) {
      print("ERROR borrando alertas generadas del spot: $e");
      return false;
    }
  }
}
