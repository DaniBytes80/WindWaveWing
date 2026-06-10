import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> init(String userId) async {
    // 1. Pedir permisos
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('FCM permisos: ${settings.authorizationStatus}');

    // 2. Obtener token FCM
    final token = await _messaging.getToken();
    if (token == null) {
      print('⚠️ No se pudo obtener token FCM');
      return;
    }
    print('FCM TOKEN: $token');

    // 3. Guardar en Supabase
    // ✅ FIX: onConflict por 'user_id' requiere unique constraint.
    // Usamos upsert por 'token' (que sí tiene unique) y actualizamos user_id.
    try {
      await _supabase.from('Dispositivos').upsert(
        {
          'user_id': userId,
          'token': token,
          'fecha_registro': DateTime.now().toIso8601String(),
        },
        onConflict: 'token', // ✅ token tiene UNIQUE constraint
      );
      print('✅ Token FCM guardado en Supabase');
    } catch (e) {
      print('❌ Error guardando token FCM: $e');
    }
  }
}
