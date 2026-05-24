import 'package:firebase_messaging/firebase_messaging.dart';

class FCMService {
  FCMService._();

  static final FirebaseMessaging _messaging =
      FirebaseMessaging.instance;

  static Future<void> initialize() async {
    try {
      // Notification izni
      await _messaging.requestPermission();

      // Token al
      final token = await _messaging.getToken();

      print("BEACON FCM TOKEN => $token");

      // Topic subscribe test
      await _messaging.subscribeToTopic("requester_test");

      print("BEACON FCM TOPIC => SUCCESS");
    } catch (e) {
      print("BEACON FCM ERROR => $e");
    }
  }
}