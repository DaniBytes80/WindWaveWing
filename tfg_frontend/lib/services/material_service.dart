import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tfg_clima_malaga/models/material_usuario.dart';

class MaterialService {
  final supabase = Supabase.instance.client;

  /// INSERTAR MATERIAL
  Future<bool> insertarMaterial(MaterialUsuario material) async {
    try {
      await supabase.from('MaterialUsuario').insert(material.toJson());
      return true;
    } catch (e) {
      print('Error insertando material: $e');
      return false;
    }
  }

  /// OBTENER LISTA DE MATERIALES DEL USUARIO
  Future<List<MaterialUsuario>> obtenerMaterialUsuario(String userId) async {
    try {
      final response = await supabase
          .from('MaterialUsuario')
          .select()
          .eq('user_id', userId)
          .order('fecha_creacion', ascending: false);

      return response
          .map<MaterialUsuario>((json) => MaterialUsuario.fromJson(json))
          .toList();
    } catch (e) {
      print('Error obteniendo material del usuario: $e');
      return [];
    }
  }

  /// OBTENER MATERIAL POR ID
  Future<MaterialUsuario?> obtenerMaterialPorId(String id) async {
    try {
      final response = await supabase
          .from('MaterialUsuario')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return MaterialUsuario.fromJson(response);
    } catch (e) {
      print('Error obteniendo material por ID: $e');
      return null;
    }
  }

  /// ACTUALIZAR MATERIAL
  Future<bool> actualizarMaterial(MaterialUsuario material) async {
    try {
      await supabase
          .from('MaterialUsuario')
          .update(material.toJson())
          .eq('id', material.id);

      return true;
    } catch (e) {
      print('Error actualizando material: $e');
      return false;
    }
  }

  /// ELIMINAR MATERIAL
  Future<bool> eliminarMaterial(String id) async {
    try {
      await supabase.from('MaterialUsuario').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error eliminando material: $e');
      return false;
    }
  }
}
