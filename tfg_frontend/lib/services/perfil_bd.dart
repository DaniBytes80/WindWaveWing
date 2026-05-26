import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/perfil.dart';

class PerfilBd {
  final _supabase = Supabase.instance.client;

  // ============================================================
  // 1. Registrar un nuevo usuario + crear su perfil
  // ============================================================
  Future<Perfil?> registrarPerfil({
    required String nombre,
    required String email,
    required String password,
    required String telefono,
    required Map<String, bool> deportes,
  }) async {
    // 1. Crear usuario en Supabase Auth
    final AuthResponse res = await _supabase.auth.signUp(
      email: email,
      password: password,
    );

    final String? idUsuario = res.user?.id;

    if (idUsuario == null) return null;

    // 2. Insertar perfil en la tabla Perfiles
    final data = await _supabase
        .from("Perfiles")
        .insert({
          'id': idUsuario,
          'nombre': nombre,
          'email': email,
          'rol': 'USUARIO',
          'fecha_registro': DateTime.now().toIso8601String(),
          'telefono': telefono,
          'surf': deportes['Surf'] ?? false,
          'kite_surf': deportes['Kitesurf'] ?? false,
          'windsurf': deportes['Windsurf'] ?? false,
          'wing': deportes['Wingfoil'] ?? false,
          'sail': deportes['Vela'] ?? false, // ← CORRECTO
          'avatar_url': null,
        })
        .select()
        .single();

    return Perfil.fromJson(data);
  }

  // ============================================================
  // 2. Actualizar perfil por email
  // ============================================================
  Future<void> updateWithAll({
    required String email,
    String? nombre,
    String? telefono,
    Map<String, bool>? deportes,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> updates = {};

    if (nombre != null) updates['nombre'] = nombre;
    if (telefono != null) updates['telefono'] = telefono;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (deportes != null) {
      updates['surf'] = deportes['Surf'] ?? false;
      updates['kite_surf'] = deportes['Kitesurf'] ?? false;
      updates['windsurf'] = deportes['Windsurf'] ?? false;
      updates['wing'] = deportes['Wingfoil'] ?? false;
      updates['sail'] = deportes['Vela'] ?? false;
    }

    await _supabase.from("Perfiles").update(updates).eq('email', email);
  }
}
