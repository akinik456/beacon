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
	
	static Future<void> showMovementAlert({
		required String locatorName,
		required double movedMeters,
	}) async {
		await _plugin.show(
			2001,
			'Movement Alert',
			'$locatorName moved ${movedMeters.toStringAsFixed(0)}m.',
			const NotificationDetails(
				android: AndroidNotificationDetails(
					'call_me',
					'Call Me',
					channelDescription: 'Call me notifications',
					importance: Importance.max,
					priority: Priority.high,
				),
			),
		);
	}
	
	static Future<void> showAlert({
		required String title,
		required String body,
	}) async {
		await _plugin.show(
			DateTime.now().millisecondsSinceEpoch ~/ 1000,
			title,
			body,
			const NotificationDetails(
				android: AndroidNotificationDetails(
					'call_me',
					'Call Me',
					channelDescription: 'Call me notifications',
					importance: Importance.max,
					priority: Priority.high,
				),
			),
		);
	}
	
}