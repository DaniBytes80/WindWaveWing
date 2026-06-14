import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/alerta.dart';

class AlertasService {
  final supabase = Supabase.instance.client;

  Future<bool> crearAlerta(Map<String, dynamic> data) async {
    try {
      print("DEBUG crearAlerta data: $data");

      final res = await supabase.from('AlertasUsuario').insert(data);

      print("DEBUG crearAlerta res: $res");
      return true;
    } catch (e, st) {
      print("ERROR creando alerta: $e");
      print("STACK: $st");
      return false;
    }
  }

  // INSERTAR ALERTA (usando modelo Alerta)
  Future<bool> insertarAlerta(Alerta alerta) async {
    try {
      final res = await supabase.from('AlertasUsuario').insert(alerta.toJson());
      print("DEBUG insertarAlerta res: $res");
      return true;
    } catch (e, st) {
      print("ERROR insertando alerta: $e");
      print("STACK: $st");
      return false;
    }
  }

  // OBTENER ALERTAS DEL USUARIO
  Future<List<Alerta>> obtenerAlertasUsuario(String userId) async {
    try {
      final data = await supabase
          .from('AlertasUsuario')
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion', ascending: false);

      return data.map<Alerta>((json) => Alerta.fromJson(json)).toList();
    } catch (e, st) {
      print("ERROR obteniendo alertas: $e");
      print("STACK: $st");
      return [];
    }
  }

  // ACTUALIZAR ALERTA
  Future<bool> actualizarAlerta(Alerta alerta) async {
    try {
      final res = await supabase
          .from('AlertasUsuario')
          .update(alerta.toJson())
          .eq('id', alerta.id);

      print("DEBUG actualizarAlerta res: $res");
      return true;
    } catch (e, st) {
      print("ERROR actualizando alerta: $e");
      print("STACK: $st");
      return false;
    }
  }

  // BORRAR ALERTA
  Future<bool> borrarAlerta(String alertaId) async {
    try {
      final res = await supabase
          .from('AlertasUsuario')
          .delete()
          .eq('id', alertaId);

      print("DEBUG borrarAlerta res: $res");
      return true;
    } catch (e, st) {
      print("ERROR borrando alerta: $e");
      print("STACK: $st");
      return false;
    }
  }

  // ACTIVAR / DESACTIVAR ALERTA
  Future<bool> cambiarEstadoAlerta(String alertaId, bool activa) async {
    try {
      final res = await supabase
          .from('AlertasUsuario')
          .update({'activa': activa})
          .eq('id', alertaId);

      print("DEBUG cambiarEstadoAlerta res: $res");
      return true;
    } catch (e, st) {
      print("ERROR cambiando estado alerta: $e");
      print("STACK: $st");
      return false;
    }
  }

  // OBTENER ALERTAS POR SPOT
  Future<List<Alerta>> obtenerAlertasPorSpot(String spotId) async {
    try {
      final data = await supabase
          .from('AlertasUsuario')
          .select()
          .eq('spot_id', spotId)
          .eq('activa', true);

      return data.map<Alerta>((json) => Alerta.fromJson(json)).toList();
    } catch (e, st) {
      print("ERROR obteniendo alertas por spot: $e");
      print("STACK: $st");
      return [];
    }
  }
}
