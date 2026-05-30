import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> init(String userId) async {
    // 1. Pedir permisos
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Obtener token FCM
    final token = await _messaging.getToken();
    if (token == null) {
      print('No se pudo obtener token FCM');
      return;
    }

    print('FCM TOKEN: $token');

    // 3. Guardar en Supabase
    await _supabase.from('Dispositivos').upsert({
      'user_id': userId,
      'token': token,
    }, onConflict: 'user_id');
  }
}
