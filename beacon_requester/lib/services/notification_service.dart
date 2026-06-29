import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
      ),
    );

    const channel = AndroidNotificationChannel(
      'call_me',
      'Call Me',
      description: 'Call me notifications',
      importance: Importance.max,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
	
}