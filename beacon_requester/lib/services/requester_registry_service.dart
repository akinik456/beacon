import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:ui';

import 'identity_service.dart';
import 'code_service.dart';

class RequesterRegistryService {
  RequesterRegistryService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> registerRequester() async {
	
		final packageInfo =
			await PackageInfo.fromPlatform();
	
		final deviceInfo = DeviceInfoPlugin();
		final androidInfo = await deviceInfo.androidInfo;
		final locale =
				PlatformDispatcher.instance.locale;

		final countryCode =
				locale.countryCode;
	
    try {
      final requesterId =
          await IdentityService.getRequesterId();
			
			final requesterCode = await IdentityService.getRequesterCode();

			final requesterName = await IdentityService.getRequesterName();
      
			final token =
          await FirebaseMessaging.instance.getToken();

      final topic = "requester_$requesterId";

      await _firestore.collection('requesters').doc(requesterId).set({
			'active': true,
			'createdAt': FieldValue.serverTimestamp(),
			'platform': Platform.operatingSystem,
			'requesterCode': requesterCode,
			'requesterName': requesterName,

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
			
		}, SetOptions(merge: true));

      print(
        "BEACON REQUESTER REGISTRY => SUCCESS => $requesterId",
      );
    } catch (e) {
      print(
        "BEACON REQUESTER REGISTRY ERROR => $e",
      );
    }
  }
}