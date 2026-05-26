import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'identity_service.dart';

class LocatorRegistryService {
  LocatorRegistryService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Future<void> registerLocator() async {
    try {
      final locatorId =
          await IdentityService.getLocatorId();

      final locatorCode =
          await IdentityService.getLocatorCode();
					
			final locatorName = 
					await IdentityService.getLocatorName();

      final token =
          await FirebaseMessaging.instance.getToken();

      final topic = "locator_$locatorId";

      await _firestore
          .collection('locators')
          .doc(locatorId)
          .set({
        'locatorId': locatorId,
        'locatorCode': locatorCode,
				'locatorName': locatorName,
        'role': 'locator',
        'token': token,
        'topic': topic,
        'platform': Platform.operatingSystem,
        'active': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
        "BEACON LOCATOR REGISTRY => SUCCESS => "
        "$locatorId",
      );
    } catch (e) {
      print(
        "BEACON LOCATOR REGISTRY ERROR => $e",
      );
    }
  }

  static Future<void> updateToken(
    String token,
  ) async {
    try {
      final locatorId =
          await IdentityService.getLocatorId();

      await _firestore
          .collection('locators')
          .doc(locatorId)
          .set({
        'token': token,
        'lastTokenRefreshAt':
            FieldValue.serverTimestamp(),
        'lastSeen':
            FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print(
        "BEACON LOCATOR TOKEN REFRESH => "
        "SUCCESS => $locatorId",
      );
    } catch (e) {
      print(
        "BEACON LOCATOR TOKEN REFRESH ERROR "
        "=> $e",
      );
    }
  }
}