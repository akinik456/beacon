import 'package:firebase_messaging/firebase_messaging.dart';
import 'identity_service.dart';
import 'requester_registry_service.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'notification_service.dart';
import '../utils/log.dart';

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

    Log.d(
      "BEACON FCM => permission => ${settings.authorizationStatus}",
    );

    final token = await _messaging.getToken();

    Log.d("BEACON FCM => token => $token");

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      Log.d("BEACON FCM => token refreshed => $newToken");
      await _setupTopicSubscription();
    });

    if (token == null || token.isEmpty) {
      Log.d("BEACON FCM => token empty");
      return;
    }

    await _setupTopicSubscription();

    _initialized = true;
    Log.d("BEACON FCM => initialized");
  } catch (e) {
    Log.e("BEACON FCM ERROR => $e");

    if (_initAttempt < 5) {
      final delay = Duration(seconds: _initAttempt * 10);

      Log.d(
        "BEACON FCM => retry init later "
        "attempt=$_initAttempt delay=${delay.inSeconds}s",
      );

      Future.delayed(delay, () {
        initialize();
      });
    } else {
			Log.d("BEACON FCM => init postponed, trying token reset once");

			try {
				await _messaging.deleteToken();

				Log.d("BEACON FCM => token deleted");

				await Future.delayed(const Duration(seconds: 2));

				final token = await _messaging.getToken();

				Log.d("BEACON FCM => token after reset => $token");

				if (token != null && token.isNotEmpty) {
					await _setupTopicSubscription();

					_initialized = true;

					Log.d("BEACON FCM => initialized after token reset");
				} else {
					Log.d("BEACON FCM => token still empty after reset");
				}
			} catch (e) {
				Log.e("BEACON FCM => token reset failed => $e");
			}
		}
  } finally {
    _initializing = false;
  }
// ================= FOREGROUND LISTENER =================

		FirebaseMessaging.onMessage.listen((message) {
			Log.d("BEACON FCM => FOREGROUND MESSAGE RECEIVED");

			Log.d("BEACON FCM => data => ${message.data}");

			Log.d(
				"BEACON FCM => notification => "
				"${message.notification?.title}",
			);
		});

		// ================= APP OPENED FROM NOTIFICATION =================

		FirebaseMessaging.onMessageOpenedApp.listen((message) {
			Log.d("BEACON FCM => OPENED FROM NOTIFICATION");

			Log.d("BEACON FCM => data => ${message.data}");
		});

		// ================= TERMINATED STATE CHECK =================

		final initialMessage =
				await FirebaseMessaging.instance.getInitialMessage();

		if (initialMessage != null) {
			Log.d("BEACON FCM => INITIAL MESSAGE");

			Log.d(
				"BEACON FCM => initial data => "
				"${initialMessage.data}",
			);
		}				
	
	
}	
	static Future<void> _setupTopicSubscription() async {
		final requesterId = await IdentityService.getRequesterId();

		if (requesterId == null || requesterId.isEmpty) {
			Log.d("BEACON FCM => requesterId missing");
			return;
		}

		final requesterTopic = "requester_$requesterId";

		await subscribeToTopicWithRetry(requesterTopic);
		await subscribeToTopicWithRetry("lynra_news");
	}
	
	static Future<void> subscribeToTopicWithRetry(
		String topic, {
		int maxAttempts = 5,
	}) async {
		for (int attempt = 1; attempt <= maxAttempts; attempt++) {
			try {
				Log.d("BEACON FCM => subscribe attempt $attempt => $topic");

				await _messaging.subscribeToTopic(topic);

				Log.d("BEACON FCM => subscribe success => $topic");
				return;
			} catch (e) {
				Log.e(
					"BEACON FCM => subscribe failed "
					"attempt=$attempt topic=$topic error=$e",
				);

				if (attempt == maxAttempts) {
					Log.e("BEACON FCM => subscribe give up => $topic");
					return;
				}

				await Future.delayed(Duration(seconds: attempt * 3));
			}
		}
	}

}
