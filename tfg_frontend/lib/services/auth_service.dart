import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Biometría moderna
  final LocalAuthentication _localAuth = LocalAuthentication();

  // Almacenamiento seguro para email/contraseña
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // ============================================================
  // LOGIN EMAIL
  // ============================================================
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    // Guardamos credenciales para biometría
    await _secure.write(key: 'email', value: email);
    await _secure.write(key: 'password', value: password);

    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // ============================================================
  // REGISTRO EMAIL
  // ============================================================
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ============================================================
  // LOGOUT
  // ============================================================
  Future<void> logout() async {
    await _secure.deleteAll();
    await _supabase.auth.signOut();
  }

  // ============================================================
  // EMAIL ACTUAL
  // ============================================================
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    return session?.user.email;
  }

  // ============================================================
  // LOGIN GOOGLE
  // ============================================================
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: "com.windwavewing.app://login-callback",
    );
  }

  // ============================================================
  // AUTENTICACIÓN BIOMÉTRICA (MODERNA, 2026+)
  // ============================================================
  Future<bool> signInWithBiometrics() async {
    try {
      // 1️⃣ Comprobar si hay biometría disponible
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      // 2️⃣ Autenticación nativa
      final didAuth = await _localAuth.authenticate(
        localizedReason: "Accede con tu huella o FaceID",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!didAuth) return false;

      // 3️⃣ Recuperar credenciales guardadas
      final email = await _secure.read(key: 'email');
      final password = await _secure.read(key: 'password');

      if (email == null || password == null) return false;

      // 4️⃣ Login real en Supabase
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      return res.session != null;
    } catch (e) {
      print("Error biometría: $e");
      return false;
    }
  }
}
