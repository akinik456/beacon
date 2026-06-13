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

      final topic = "locator_$locatorId";

      await _firestore
          .collection('locators')
          .doc(locatorId)
          .set({
						'locatorCode': locatorCode,
						'locatorName': locatorName,
						'platform': Platform.operatingSystem,
						'active': true,
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
}