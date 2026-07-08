import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:ui';

import 'identity_service.dart';
import 'code_service.dart';
import 'firebase_authentication_service.dart';
import '../utils/log.dart';


class RequesterRegistryService {
  RequesterRegistryService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> registerRequester() async {
  final packageInfo = await PackageInfo.fromPlatform();

  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  final locale = PlatformDispatcher.instance.locale;

  final countryCode = locale.countryCode;

  try {
    final requesterId =
        await IdentityService.getRequesterId();

    final requesterCode =
        await IdentityService.getRequesterCode();

    final requesterName =
        await IdentityService.getRequesterName();

    Log.d("registerRequester IdentityService.getRequesterName");

    String? token;

    try {
      token = await FirebaseMessaging.instance.getToken();
    } catch (e) {
      Log.e("BEACON REQUESTER REGISTRY FCM TOKEN ERROR => $e");
    }

    await _firestore.collection('requesters').doc(requesterId).set({
      'active': true,
			'authUid': AuthService.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
      'requesterCode': requesterCode,
      'requesterName': requesterName,
      'name': requesterName,

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

    Log.d(
      "BEACON REQUESTER REGISTRY => SUCCESS => $requesterId",
    );
  } catch (e) {
    Log.e(
      "BEACON REQUESTER REGISTRY ERROR => $e",
    );
  }
}

static Future<void> ensureRequesterAuthUid() async {
  final requesterId = await IdentityService.getRequesterId();
  final authUid = AuthService.uid;

  if (requesterId == null || requesterId.isEmpty) {
    Log.d("BEACON AUTH MIGRATION => requesterId missing");
    return;
  }

  if (authUid == null || authUid.isEmpty) {
    Log.d("BEACON AUTH MIGRATION => authUid missing");
    return;
  }

  final requesterRef =
      _firestore.collection('requesters').doc(requesterId);

  final doc = await requesterRef.get();
  final currentAuthUid = doc.data()?['authUid'];

  if (currentAuthUid != null && currentAuthUid.toString().isNotEmpty) {
    Log.d("BEACON AUTH MIGRATION => requester authUid already exists");
    return;
  }

  await requesterRef.set({
    'authUid': authUid,
  }, SetOptions(merge: true));

  Log.d("BEACON AUTH MIGRATION => requester authUid written");
}
}