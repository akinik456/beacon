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
			print("BEACON FCM => initialize start");

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

				await RequesterRegistryService.updateToken(newToken);
			});

			final requesterId =
					await IdentityService.getRequesterId();

			final topic = "requester_$requesterId";

			print("BEACON FCM => subscribe start => $topic");

			await _messaging.subscribeToTopic(topic);

			print("BEACON FCM => subscribe success => $topic");
		} catch (e) {
			print("BEACON FCM ERROR => $e");
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
}