import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import 'smart_presence_scheduler.dart';
import 'active_watcher_service.dart';

class FCMService {
  FCMService._();
	static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;
			
static bool _initializing = false;
static bool _initialized = false;
static int _initAttempt = 0;
			
	static Future<void> initialize() async {
	if (_initialized || _initializing) return;

  _initializing = true;
  _initAttempt++;

  try {
    final settings = await _messaging.requestPermission();

    print(
      "BEACON FCM => permission => ${settings.authorizationStatus}",
    );

    final token = await _messaging.getToken();

    print("BEACON FCM => token => $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      print("BEACON FCM => token refreshed => $newToken");
      await _setupTopicSubscription();
    });

    if (token == null || token.isEmpty) {
      print("BEACON FCM => token empty");
      return;
    }

    await _setupTopicSubscription();

    _initialized = true;
    print("BEACON FCM => initialized");
  } catch (e) {
    print("BEACON FCM ERROR => $e");

    if (_initAttempt < 5) {
      final delay = Duration(seconds: _initAttempt * 10);

      print(
        "BEACON FCM => retry init later "
        "attempt=$_initAttempt delay=${delay.inSeconds}s",
      );

      Future.delayed(delay, () {
        initialize();
      });
    } else {
			print("BEACON FCM => init postponed, trying token reset once");

			try {
				await _messaging.deleteToken();

				print("BEACON FCM => token deleted");

				await Future.delayed(const Duration(seconds: 2));

				final token = await _messaging.getToken();

				print("BEACON FCM => token after reset => $token");

				if (token != null && token.isNotEmpty) {
					await _setupTopicSubscription();

					_initialized = true;

					print("BEACON FCM => initialized after token reset");
				} else {
					print("BEACON FCM => token still empty after reset");
				}
			} catch (e) {
				print("BEACON FCM => token reset failed => $e");
			}
		}
  } finally {
    _initializing = false;
  }
		
		
		// ================= FOREGROUND LISTENER =================

	FirebaseMessaging.onMessage.listen((message) async {
		print("BEACON FCM => foreground message");
		print("BEACON FCM => data => ${message.data}");

		final type = message.data['type'];

		switch (type) {
			case 'request_location':
				print(
					"BEACON FCM => REQUEST LOCATION received",
				);

				await SmartPresenceScheduler.boostAndUpdateNow(
					reason: 'fcm_foreground',
				);

				print(
					"BEACON FCM => REQUEST LOCATION completed",
				);
				break;

			case 'active_watchers_changed':
				print(
					"BEACON FCM => ACTIVE WATCHERS changed",
				);

				await ActiveWatcherService.updateNotificationFromServer();

				print(
					"BEACON FCM => ACTIVE WATCHERS updated",
				);
				break;
		}
	});
	
	// ================= APP OPENED FROM NOTIFICATION =================

	FirebaseMessaging.onMessageOpenedApp.listen((message) {
		print("BEACON FCM => OPENED FROM NOTIFICATION");

		print("BEACON FCM => data => ${message.data}");
	});
	
	// ================= TERMINATED STATE CHECK =================

		final initialMessage =
				await FirebaseMessaging.instance.getInitialMessage();

		if (initialMessage != null) {
			print("BEACON FCM => INITIAL MESSAGE");

			print(
				"BEACON FCM => initial data => "
				"${initialMessage.data}",
			);
		}		
	

	}

	static Future<void> _setupTopicSubscription() async {
				
		final locatorId = await IdentityService.getLocatorId();

		if (locatorId == null || locatorId.isEmpty) {
			print("BEACON FCM => locatorId missing");
			return;
		}

		final topic = 'locator_$locatorId';

		await subscribeToTopicWithRetry(topic);
	}
	
	static Future<void> subscribeToTopicWithRetry(
		String topic, {
		int maxAttempts = 5,
	}) async {
		for (int attempt = 1; attempt <= maxAttempts; attempt++) {
			try {
				print("BEACON FCM => subscribe attempt $attempt => $topic");

				await _messaging.subscribeToTopic(topic);

				print("BEACON FCM => subscribe success => $topic");
				return;
			} catch (e) {
				print(
					"BEACON FCM => subscribe failed "
					"attempt=$attempt topic=$topic error=$e",
				);

				if (attempt == maxAttempts) {
					print("BEACON FCM => subscribe give up => $topic");
					return;
				}

				await Future.delayed(Duration(seconds: attempt * 3));
			}
		}
	}	
}