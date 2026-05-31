import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // LOGIN EMAIL
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // REGISTRO EMAIL
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
  ) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  // RESET PASSWORD
  Future<void> resetPassword(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  // LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // EMAIL ACTUAL
  String? getCurrentUserEmail() {
    final session = _supabase.auth.currentSession;
    return session?.user.email;
  }

  // GOOGLE
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: "com.windwavewing.app://login-callback",
    );
  }

  // BIOMETRÍA
  Future<bool> signInWithBiometrics() async {
    final auth = LocalAuthentication();

    final canCheck = await auth.canCheckBiometrics;
    if (!canCheck) return false;

    final didAuth = await auth.authenticate(
      localizedReason: "Accede con tu huella o FaceID",
      biometricOnly: true,
    );

    return didAuth;
  }
}
