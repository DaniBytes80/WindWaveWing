import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ============================================================
  // 1. Login con email y contraseña
  // ============================================================
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // 2. Registro en Supabase Auth (NO crea perfil)
  // ============================================================
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // ============================================================
  // 3. Reset de contraseña
  // ============================================================
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw Exception("Error al enviar recuperación: $e");
    }
  }

  // ============================================================
  // 4. Logout
  // ============================================================
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // ============================================================
  // 5. Obtener email del usuario actual
  // ============================================================
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    return session?.user.email;
  }
}
