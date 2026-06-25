import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import 'smart_presence_scheduler.dart';

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

		FirebaseMessaging.onMessage.listen((message) async {
		print("BEACON FCM => foreground message");
		print("BEACON FCM => data => ${message.data}");

		final type = message.data['type'];

		if (type == 'request_location') {
			print(
				"BEACON FCM => REQUEST LOCATION received",
			);

			await SmartPresenceScheduler.boostAndUpdateNow(
				reason: 'fcm_foreground',
			);

			print(
				"BEACON FCM => REQUEST LOCATION completed",
			);
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