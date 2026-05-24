import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'identity_service.dart';

class RequesterRegistryService {
  RequesterRegistryService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> registerRequester() async {
    try {
      final requesterId =
          await IdentityService.getOrCreateRequesterId();

      final token =
          await FirebaseMessaging.instance.getToken();

      final topic = "requester_$requesterId";

      await _firestore
          .collection('requesters')
          .doc(requesterId)
          .set({
        'requesterId': requesterId,
        'token': token,
        'topic': topic,
        'platform': Platform.operatingSystem,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
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
	
	static Future<void> updateToken(String token) async {
		try {
			final requesterId =
					await IdentityService.getOrCreateRequesterId();

			await _firestore
					.collection('requesters')
					.doc(requesterId)
					.set({
				'token': token,
				'lastTokenRefreshAt': FieldValue.serverTimestamp(),
				'lastSeen': FieldValue.serverTimestamp(),
			}, SetOptions(merge: true));

			print("BEACON REQUESTER TOKEN REFRESH => SUCCESS => $requesterId");
		} catch (e) {
			print("BEACON REQUESTER TOKEN REFRESH ERROR => $e");
		}
	}	
}