import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(' Push en background: ${message.notification?.title}');
}

class NotificationsService {
  final _messaging = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  static const _channel = AndroidNotificationChannel(
    'wwwing_alerts',
    'Alertas WindWaveWing',
    description: 'Notificaciones de condiciones meteorológicas',
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> init(String userId) async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permisos: ${settings.authorizationStatus}');

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _localNotifications.initialize(initSettings);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    final token = await _messaging.getToken();
    if (token == null) {
      debugPrint('⚠️ No se pudo obtener token FCM');
      return;
    }
    debugPrint('FCM TOKEN: $token');

    try {
      // borrar token antiguo del usuario y guardar el nuevo
      await _supabase.from('Dispositivos').delete().eq('user_id', userId);

      await _supabase.from('Dispositivos').upsert({
        'user_id': userId,
        'token': token,
        'fecha_registro': DateTime.now().toIso8601String(),
      });
      debugPrint(' Token FCM guardado en Supabase');
    } catch (e) {
      debugPrint(' Error guardando token FCM: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('Token FCM actualizado: $newToken');
      try {
        await _supabase.from('Dispositivos').delete().eq('user_id', userId);

        await _supabase.from('Dispositivos').insert({
          'user_id': userId,
          'token': newToken,
          'fecha_registro': DateTime.now().toIso8601String(),
        });
      } catch (e) {
        debugPrint(' Error actualizando token: $e');
      }
    });
  }
}
