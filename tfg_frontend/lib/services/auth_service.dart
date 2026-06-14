import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  // ── Login email ────────────────────────────────────────────
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    await _secure.write(key: 'email', value: email);
    await _secure.write(key: 'password', value: password);
    return _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // ── Registro email ─────────────────────────────────────────
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return _supabase.auth.signUp(email: email, password: password);
  }

  // ── Reset password ─────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // ── Logout ─────────────────────────────────────────────────
  Future<void> logout() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId != null) {
      await _supabase.from('AlertasGeneradas').delete().eq('user_id', userId);
    }
    await _secure.deleteAll();
    await _supabase.auth.signOut();
  }

  // ── Email actual ───────────────────────────────────────────
  String? getCurrentUserEmail() => _supabase.auth.currentSession?.user.email;

  // ── Login Google ───────────────────────────────────────────
  Future<void> signInWithGoogle() async {
    // ✅ FIX: el redirectTo debe coincidir EXACTAMENTE con lo
    // configurado en Supabase → Authentication → URL Configuration
    // Y debe estar registrado en AndroidManifest.xml como intent-filter
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'windwavewing://auth/callback',
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  // ── Biometría ──────────────────────────────────────────────
  Future<bool> signInWithBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final didAuth = await _localAuth.authenticate(
        localizedReason: "Accede con tu huella o FaceID",
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      if (!didAuth) return false;

      final email = await _secure.read(key: 'email');
      final password = await _secure.read(key: 'password');
      if (email == null || password == null) return false;

      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return res.session != null;
    } catch (e) {
      return false;
    }
  }
}
