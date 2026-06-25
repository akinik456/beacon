import 'package:firebase_messaging/firebase_messaging.dart';
import 'identity_service.dart';
import 'requester_registry_service.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  FCMService._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
		try {
		// Permission
			final settings = await _messaging.requestPermission();

			print(
				"BEACON FCM => permission => ${settings.authorizationStatus}",
			);

			// Token
			final token = await _messaging.getToken();

			print("BEACON FCM => token => $token");
			
			FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
				print("BEACON FCM => token refreshed => $newToken");
			});
		
		} catch (e) {
			print("BEACON FCM ERROR => $e");
		}
		
		try {
			await _setupTopicSubscription();
		} catch (e) {
			print("BEACON FCM => setup topic error => $e");
		}
		
		// ================= FOREGROUND LISTENER =================

		FirebaseMessaging.onMessage.listen((message) {
			print("BEACON FCM => FOREGROUND MESSAGE RECEIVED");

			print("BEACON FCM => data => ${message.data}");

			print(
				"BEACON FCM => notification => "
				"${message.notification?.title}",
			);
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
		final requesterId = await IdentityService.getRequesterId();

		if (requesterId == null || requesterId.isEmpty) {
			print("BEACON FCM => requesterId missing");
			return;
		}

		final topic = "requester_$requesterId";

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