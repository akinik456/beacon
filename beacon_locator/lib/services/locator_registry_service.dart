import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:ui';

import 'identity_service.dart';

class LocatorRegistryService {
  LocatorRegistryService._();

  static final _firestore =
      FirebaseFirestore.instance;
			

  static Future<void> registerLocator() async {
	final packageInfo =
    await PackageInfo.fromPlatform();
		print(
			"BEACON PACKAGE => "
			"${packageInfo.version} "
			"${packageInfo.buildNumber}",
		);

	final deviceInfo = DeviceInfoPlugin();
	final androidInfo = await deviceInfo.androidInfo;
	final locale =
			PlatformDispatcher.instance.locale;

	final countryCode =
			locale.countryCode;
		
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
						'appVersion': packageInfo.version,
						'buildNumber': packageInfo.buildNumber,
						'androidVersion': androidInfo.version.release,
						'sdkInt': androidInfo.version.sdkInt,

						'brand': androidInfo.brand,
						'manufacturer': androidInfo.manufacturer,
						'model': androidInfo.model,
						'device': androidInfo.device,
						'countryCode': countryCode,
						
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