import 'package:firebase_messaging/firebase_messaging.dart';

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

			// Topic subscribe
			const topic = "requester_test";

			print("BEACON FCM => subscribe start => $topic");

			await _messaging.subscribeToTopic(topic);

			print("BEACON FCM => subscribe success => $topic");
		} catch (e) {
			print("BEACON FCM ERROR => $e");
		}
	}
}