import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notification_text_service.dart';


class NotificationService {
  NotificationService._();

  static const int _callMeNotificationId = 1001;
  static const int _activeWatchersNotificationId = 2001;

  static const String _callMeChannelId = 'call_me';
  static const String _activeWatchersChannelId = 'active_watchers';

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
      ),
    );

    const callMeChannel = AndroidNotificationChannel(
      _callMeChannelId,
      'Call Me',
      description: 'Call me notifications',
      importance: Importance.max,
    );

    const activeWatchersChannel = AndroidNotificationChannel(
      _activeWatchersChannelId,
      'Being watched',
      description: 'Active watcher notifications',
      importance: Importance.low,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(callMeChannel);
    await androidPlugin?.createNotificationChannel(activeWatchersChannel);
  }

  static Future<void> showCallMe({
    required String requesterName,
    required String requesterCode,
  }) async {
    await _plugin.show(
      _callMeNotificationId,
      'Call Me',
      '$requesterName - $requesterCode wants you to call.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _callMeChannelId,
          'Call Me',
          channelDescription: 'Call me notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
    );
  }

  static Future<void> showActiveWatchers({
		required List<String> names,
		required String langCode,
	}) async {
		if (names.isEmpty) {
			await cancelActiveWatchers();
			return;
		}

		final title =
				await NotificationTextService.beingWatched(langCode);

		final body =
				await NotificationTextService.watchingLocation(
			names: names,
		);

		await _plugin.show(
			_activeWatchersNotificationId,
			title,
			body,
			const NotificationDetails(
				android: AndroidNotificationDetails(
					_activeWatchersChannelId,
					'Being watched',
					channelDescription:
							'Active watcher notifications',
					importance: Importance.low,
					priority: Priority.low,
					ongoing: true,
					autoCancel: false,
					onlyAlertOnce: true,
					showWhen: false,
				),
			),
		);
	}

  static Future<void> cancelActiveWatchers() async {
    await _plugin.cancel(_activeWatchersNotificationId);
  }
}