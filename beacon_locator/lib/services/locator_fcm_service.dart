import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import 'smart_presence_scheduler.dart';

class LocatorFcmService {
  LocatorFcmService._();
	
static Future<void> init() async {

  await subscribeLocatorTopic();

  await updateFcmToken();

  FirebaseMessaging.instance
      .onTokenRefresh
      .listen((token) async {

    print(
      "BEACON FCM => token refreshed",
    );

    final locatorId =
        await IdentityService.getLocatorId();

    if (locatorId == null) return;

    await FirebaseFirestore.instance
        .collection('locators')
        .doc(locatorId)
        .set({
      'fcmToken': token,
      'lastTokenRefreshAt':
          FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  });
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

  static Future<void> subscribeLocatorTopic() async {

  print(
    "BEACON FCM => subscribe start",
  );

  final locatorId =
      await IdentityService.getLocatorId();

  print(
    "BEACON FCM => locatorId => $locatorId",
  );

  if (locatorId == null || locatorId.isEmpty) {

    print(
      "BEACON FCM ERROR => locatorId not found",
    );

    return;
  }

  final topic = 'locator_$locatorId';

  print(
    "BEACON FCM => topic => $topic",
  );

  try {

    await FirebaseMessaging.instance
        .subscribeToTopic(topic);

    print(
      "BEACON FCM => SUCCESS => $topic",
    );

  } catch (e) {

    print(
      "BEACON FCM ERROR => subscribe failed => $e",
    );
  }
}

static Future<void> updateFcmToken() async {

  final locatorId =
      await IdentityService.getLocatorId();

  if (locatorId == null || locatorId.isEmpty) {
    return;
  }

  final token =
      await FirebaseMessaging.instance
          .getToken();

  print(
    "BEACON FCM => token => $token",
  );

  await FirebaseFirestore.instance
      .collection('locators')
      .doc(locatorId)
      .set({
    'fcmToken': token,
    'lastTokenRefreshAt':
        FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  print(
    "BEACON FCM => token updated",
  );
}
}