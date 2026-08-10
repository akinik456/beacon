import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'dart:ui';

import 'identity_service.dart';
import 'code_service.dart';
import 'requester_registry_service.dart';
import '../services/firebase_authentication_service.dart';
import '../utils/log.dart';
import 'analytics_service.dart';

class GroupService {
  GroupService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> addPairedLocatorToRequester({
    required String locatorId,
  }) async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null) {
      Log.d(
        "BEACON PAIRING => paired locator update failed",
      );
      return;
    }

    final locatorSnap = await _firestore
        .collection('locators')
        .doc(locatorId)
        .get();

    final locatorData = locatorSnap.data() ?? {};

    final locatorCode =
        locatorData['locatorCode'] ?? '------';

    await _firestore
        .collection('requesters')
        .doc(requesterId)
        .set({
      'pairedLocators': {
        locatorId: {
          'locatorCode': locatorCode,
          'pairedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Log.d(
      "BEACON PAIRING => paired locator added => $locatorId",
    );
  }

  static Future<void> addPairedRequesterToLocator({
    required String locatorId,
  }) async {
    final requesterId = await IdentityService.getRequesterId();
    final requesterCode = await IdentityService.getRequesterCode();

    if (requesterId == null) {
      Log.d(
        "BEACON PAIRING => paired requester update failed",
      );
      return;
    }

    await _firestore
        .collection('locators')
        .doc(locatorId)
        .set({
      'pairedRequesters': {
        requesterId: {
          'pairedAt': FieldValue.serverTimestamp(),
          'requesterCode': requesterCode,
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Log.d(
      "BEACON PAIRING => paired requester added => $requesterId",
    );
  }

  static Future<void> ensureLocatorDefaultSettings({
    required String locatorId,
  }) async {
    await _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('settings')
        .doc('config')
        .set({
      'gpsOffAlert': true,
      'batteryLowAlert': true,
      'batteryLowLevel': 20,
      'geofenceAlert': true,
      'movementAlert': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> ensureRequesterNotifySettings({
    required String locatorId,
  }) async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null) {
      Log.d(
        "BEACON PAIRING => requesterId missing for notify settings",
      );
      return;
    }

    await _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('notifyRequesters')
        .doc(requesterId)
        .set({
      'callMe': true,
      'gpsOff': true,
      'batteryLow': true,
      'geofence': true,
      'movement': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> removePairedLocator({
    required String locatorId,
  }) async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null) {
      Log.d(
        "BEACON PAIRING => remove locator requesterId missing",
      );
      return;
    }

    final requesterRef =
        _firestore.collection('requesters').doc(requesterId);

    final locatorRef =
        _firestore.collection('locators').doc(locatorId);

    await _firestore.runTransaction((tx) async {
      tx.set(
        requesterRef,
        {
          'pairedLocators': {
            locatorId: FieldValue.delete(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.set(
        locatorRef,
        {
          'pairedRequesters': {
            requesterId: FieldValue.delete(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });

    await locatorRef
        .collection('notifyRequesters')
        .doc(requesterId)
        .delete();

    Log.d(
      "BEACON PAIRING => locator removed => $locatorId",
    );
  }
	
	static Future<String?> getLocalGroupId() async {
    final String Id="0ef2b956-c5de-4046-a1ed-ef368546e534";
		return Id;
  }

	static Future<void> clearLocalGroup() async {
}
	
}
