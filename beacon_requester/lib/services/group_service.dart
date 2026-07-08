import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'dart:ui';

import 'identity_service.dart';
import 'code_service.dart';
import 'requester_registry_service.dart';
import '../services/firebase_authentication_service.dart';
import '../utils/log.dart';

class GroupService {
  GroupService._();

  static final _firestore = FirebaseFirestore.instance;

  static const _groupIdKey = 'group_id';
	
	static const _isMasterKey = 'is_master';
	
	static const _pendingGroupIdKey = 'pending_group_id';

	static Future<void> setLocalIsMaster(bool value) async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool(_isMasterKey, value);
	}

	static Future<bool> getLocalIsMaster() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getBool(_isMasterKey) ?? false;
	}
	

  static Future<String> createGroup({
    required String groupName,
  }) async {
    final requesterId = await IdentityService.getRequesterId();
    final requesterCode = await IdentityService.getRequesterCode();
    final groupId = const Uuid().v4();
    final groupCode = CodeService.shortCodeFromId(groupId);

    final groupRef = _firestore.collection('groups').doc(groupId);
    final requesterRef = groupRef.collection('devices').doc(requesterId);
		final locale =
				PlatformDispatcher.instance.locale;
		final countryCode =
				locale.countryCode;

    final now = FieldValue.serverTimestamp();

    await _firestore.runTransaction((tx) async {
      tx.set(groupRef, {
				'activeRequesterCount': 1,
				'countryCode': countryCode,
        'createdAt': now,
				'entitlementUpdatedAt': now,				
        'groupId': groupId,
        'groupCode': groupCode,
        'groupName': groupName.trim(),
        'masterRequesterId': requesterId,
        'maxRequesters': 1,
        'maxLocators': 1,
        'planStatus': 'trial',
 				'purchaseStatus': 'none',
				'purchaseOwnerRequesterId': null,
				'purchasedAt': null,
        'trialStartedAt': now,
				'trialEndsAt': Timestamp.fromDate(
					DateTime.now().add(
						const Duration(days: 7),
					),
				),
      });

      tx.set(requesterRef, {
        'active': true,
				'authUid': AuthService.uid,
        'isMaster': true,
        'joinedAt': now,
        'pairedLocators': {},
        'requesterCode': requesterCode,
        'requesterId': requesterId,
        'role': 'requester',
				'updatedAt': FieldValue.serverTimestamp(),
      });
    });
		
		await RequesterRegistryService.registerRequester();
		await _firestore.collection('requesters').doc(requesterId).set({
			'groupId':groupId,
			'updatedAt': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupIdKey, groupId);
    await prefs.setString('group_code', groupCode);

    Log.d("BEACON GROUP => CREATE SUCCESS => $groupId");

    return groupId;
  }

  static Future<String?> getLocalGroupId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_groupIdKey);
  }

  static Future<String?> joinGroup({
  required String groupCode,
  required String requesterName,
}) async {
  final requesterId = await IdentityService.getRequesterId();
  final requesterCode = await IdentityService.getRequesterCode();

  if (requesterId == null) {
    Log.d("BEACON GROUP => requesterId not found");
    return null;
  }

  final normalizedCode =
      CodeService.normalizeCode(groupCode);

  final query = await _firestore
      .collection('groups')
      .where('groupCode', isEqualTo: normalizedCode)
      .limit(1)
      .get();

  if (query.docs.isEmpty) {
    Log.d("BEACON GROUP => group not found");
    return null;
  }

  final groupDoc = query.docs.first;
  final groupId = groupDoc.id;

  final joinRequestRef = _firestore
      .collection('groups')
      .doc(groupId)
      .collection('join_requests')
      .doc(requesterId);

  final pendingRequests = await _firestore
			.collection('groups')
			.doc(groupId)
			.collection('join_requests')
			.limit(1)
			.get();

	if (pendingRequests.docs.isNotEmpty) {
		Log.d("BEACON GROUP => another join request is already pending");
		return null;
	}

  await joinRequestRef.set({
    'requesterCode': requesterCode,
    'requesterName': requesterName.trim(),
		'authUid': AuthService.uid,
    'status': 'pending',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString('pending_group_id', groupId);
	await prefs.setString('group_code', normalizedCode);
	await prefs.setString('join_status', 'pending');

  Log.d("BEACON GROUP => JOIN REQUEST SENT => $groupId");

  return groupId;
}
  static Future<String?> getLocalGroupCode() async {
    final prefs = await SharedPreferences.getInstance();

    final groupCode = prefs.getString('group_code');

    if (groupCode != null && groupCode.isNotEmpty) {
      Log.d(
        "BEACON GROUP => groupCode found => "
        "$groupCode",
      );

      return groupCode;
    }

    Log.d("BEACON GROUP => groupCode not found");

    return null;
  }
	
static Future<void> addPairedLocatorToRequester({
  required String locatorId,
}) async {

  final requesterId =
      await IdentityService.getRequesterId();

  final groupId =
      await getLocalGroupId();

  if (requesterId == null ||
      groupId == null) {

    Log.d(
      "BEACON GROUP => "
      "paired locator update failed",
    );

    return;
  }

  final locatorSnap =
      await _firestore
          .collection('locators')
          .doc(locatorId)
          .get();

  final locatorData =
      locatorSnap.data() ?? {};


  final locatorCode =
      locatorData['locatorCode'] ?? '------';

  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(requesterId)
      .set({
    'pairedLocators': {
      locatorId: {
        'locatorCode': locatorCode,
				'pairedAt': FieldValue.serverTimestamp(),
      },
    },

    'updatedAt':
        FieldValue.serverTimestamp(),

  }, SetOptions(merge: true));

  Log.d(
    "BEACON GROUP => "
    "paired locator added => $locatorId",
  );
}

static Future<void> addPairedRequesterToLocator({
  required String locatorId,
}) async {
  final requesterId =
      await IdentityService.getRequesterId();

  final groupId =
      await getLocalGroupId();
			
	final requesterCode =
    await IdentityService.getRequesterCode();

  if (requesterId == null || groupId == null) {
    Log.d(
      "BEACON GROUP => "
      "paired requester update failed",
    );
    return;
  }

  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('devices')
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
    "BEACON GROUP => "
    "paired requester added => $requesterId",
  );
}

static Future<void> ensureLocatorDefaultSettings({
  required String locatorId,
}) async {
  final groupId = await getLocalGroupId();

  if (groupId == null) {
    Log.d("GROUP SERVICE => groupId missing");
    return;
  }

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .collection('settings')
      .doc('config')
      .set({
    'gpsOffAlert': true,
    'batteryLowAlert': true,
    'batteryLowLevel': 20,
    'geofenceAlert': false,
		'movementAlert': false,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

static Future<void> ensureRequesterNotifySettings({
  required String locatorId,
}) async {
  final groupId = await getLocalGroupId();
  final requesterId = await IdentityService.getRequesterId();

  if (groupId == null || requesterId == null) {
    Log.d("GROUP SERVICE => groupId/requesterId missing");
    return;
  }

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .collection('notifyRequesters')
      .doc(requesterId)
      .set({
    'callMe': true,
    'gpsOff': true,
    'batteryLow': true,
    'geofence': false,
		'movement': false,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

static Future<void> removePairedLocator({
  required String locatorId,
}) async {
  final groupId = await getLocalGroupId();
  final requesterId = await IdentityService.getRequesterId();

  if (groupId == null || requesterId == null) {
    Log.d("GROUP SERVICE => remove locator missing ids");
    return;
  }

  final groupRef = _firestore.collection('groups').doc(groupId);

  final requesterDeviceRef =
      groupRef.collection('devices').doc(requesterId);

  final locatorDeviceRef =
      groupRef.collection('devices').doc(locatorId);

  final locatorRef =
      _firestore.collection('locators').doc(locatorId);

  await _firestore.runTransaction((tx) async {
    final locatorDeviceSnap = await tx.get(locatorDeviceRef);

    final locatorData = locatorDeviceSnap.data() ?? {};

    final pairedRequesters =
        Map<String, dynamic>.from(
          locatorData['pairedRequesters'] ?? {},
        );
    pairedRequesters.remove(requesterId);
    tx.set(requesterDeviceRef, {
      'pairedLocators': {
        locatorId: FieldValue.delete(),
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (pairedRequesters.isEmpty) {
      tx.delete(locatorDeviceRef);

      /*tx.set(locatorRef, {
        'groupId': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));*/

      tx.update(groupRef, {
        'activeLocatorCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      tx.set(locatorDeviceRef, {
        'pairedRequesters': {
          requesterId: FieldValue.delete(),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  });

  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .collection('notifyRequesters')
      .doc(requesterId)
      .delete();

  Log.d("GROUP SERVICE => locator removed => $locatorId");
}

static Future<void> clearLocalGroup() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove(_groupIdKey);
  await prefs.remove('group_code');
  await prefs.remove('join_status');
  await prefs.remove(_isMasterKey);
	await prefs.remove(_pendingGroupIdKey);
}

}
