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
			print("BEACON FCM => initialize start");

			// Permission
			final settings = await _messaging.requestPermission();

			print(
				"BEACON FCM => permission => ${settings.authorizationStatus}",
			);

			// Token
			final token = await _messaging.getToken();
			if (token != null && token.isNotEmpty) {
				await updateFcmToken(token);
			}

			print("BEACON FCM => token => $token");
			
			FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
				print("BEACON FCM => token refreshed => $newToken");

				await updateFcmToken(newToken);
			});

			final locatorId =
      await IdentityService.getLocatorId();
			if (locatorId == null) return;

			final safeLocatorId = locatorId.replaceAll('-', '_');
			final topic = 'locator_$safeLocatorId';

			print("BEACON FCM => subscribe start => $topic");

			await _messaging.subscribeToTopic(topic);

			print("BEACON FCM => subscribe success => $topic");
		} catch (e) {
			print("BEACON FCM ERROR => $e");
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

	}	
	
	static Future<void> updateFcmToken(String token) async {
  final locatorId =
      await IdentityService.getLocatorId();

  if (locatorId == null || locatorId.isEmpty) {
    return;
  }

  await FirebaseFirestore.instance
      .collection('locators')
      .doc(locatorId)
      .set({
    'fcmToken': token,
    'lastTokenRefreshAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  print("BEACON FCM => token updated");
}
}