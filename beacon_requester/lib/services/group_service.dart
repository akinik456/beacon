import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'dart:ui';

import 'identity_service.dart';
import 'code_service.dart';

class GroupService {
  GroupService._();

  static final _firestore = FirebaseFirestore.instance;

  static const _groupIdKey = 'group_id';
	
	static const _isMasterKey = 'is_master';

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
    required String requesterName,
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
				'countryCode': countryCode,
        'groupId': groupId,
        'groupName': groupName.trim(),
        'groupCode': groupCode,
        'masterRequesterId': requesterId,
        'planStatus': 'trial',
        'maxRequesters': 1,
        'maxLocators': 1,
				'activeRequesterCount': 1,
        'createdAt': now,
        'trialStartedAt': now,
      });

      tx.set(requesterRef, {
        'active': true,
        'isMaster': true,
        'joinedAt': now,
        'pairedLocators': {},
        'requesterCode': requesterCode,
        'requesterId': requesterId,
        'requesterName': requesterName.trim(),
        'role': 'requester',
				'updatedAt': FieldValue.serverTimestamp(),
      });
    });
		
		await _firestore.collection('requesters').doc(requesterId).set({
			'groupId':groupId,
			'updatedAt': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_groupIdKey, groupId);
    await prefs.setString('group_code', groupCode);

    print("BEACON GROUP => CREATE SUCCESS => $groupId");

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
			print("BEACON GROUP => requesterId not found");
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
			print("BEACON GROUP => group not found");
			return null;
		}

		final groupDoc = query.docs.first;
		final groupId = groupDoc.id;

		final joinRequestRef = _firestore
				.collection('groups')
				.doc(groupId)
				.collection('join_requests')
				.doc(requesterId);

		await joinRequestRef.set({
			'requesterId': requesterId,
			'requesterCode': requesterCode,
			'requesterName': requesterName.trim(),
			'status': 'pending',
			'createdAt': FieldValue.serverTimestamp(),
			'updatedAt': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));

		final prefs = await SharedPreferences.getInstance();

		await prefs.setString(_groupIdKey, groupId);
		await prefs.setString('group_code', normalizedCode);
		await prefs.setString('join_status', 'pending');

		print(
			"BEACON GROUP => JOIN REQUEST SENT => $groupId",
		);

		return groupId;
	}

  static Future<String?> getLocalGroupCode() async {
    final prefs = await SharedPreferences.getInstance();

    final groupCode = prefs.getString('group_code');

    if (groupCode != null && groupCode.isNotEmpty) {
      print(
        "BEACON GROUP => groupCode found => "
        "$groupCode",
      );

      return groupCode;
    }

    print("BEACON GROUP => groupCode not found");

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

    print(
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

  final locatorName =
      locatorData['locatorName'] ?? 'Member';

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
        'locatorName': locatorName,
        'locatorCode': locatorCode,
				'pairedAt': FieldValue.serverTimestamp(),
      },
    },

    'updatedAt':
        FieldValue.serverTimestamp(),

  }, SetOptions(merge: true));

  print(
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
			
	final requesterName =
    await IdentityService.getRequesterName();

	final requesterCode =
    await IdentityService.getRequesterCode();

  if (requesterId == null || groupId == null) {
    print(
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
				'requesterName': requesterName,
				'requesterCode': requesterCode,
			},
		},
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  print(
    "BEACON GROUP => "
    "paired requester added => $requesterId",
  );
}

static Future<void> ensureLocatorDefaultSettings({
  required String locatorId,
}) async {
  final groupId = await getLocalGroupId();

  if (groupId == null) {
    print("GROUP SERVICE => groupId missing");
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
    print("GROUP SERVICE => groupId/requesterId missing");
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
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}

static Future<void> removePairedLocator({
  required String locatorId,
}) async {
  final groupId = await getLocalGroupId();
  final requesterId = await IdentityService.getRequesterId();

  if (groupId == null ||
      requesterId == null) {
    print(
      "GROUP SERVICE => remove locator missing ids",
    );
    return;
  }

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(requesterId)
      .set({
    'pairedLocators': {
      locatorId: FieldValue.delete(),
    },
  }, SetOptions(merge: true));

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .set({
    'pairedRequesters': {
      requesterId: FieldValue.delete(),
    },
  }, SetOptions(merge: true));

  await FirebaseFirestore.instance
      .collection('groups')
      .doc(groupId)
      .collection('devices')
      .doc(locatorId)
      .collection('notifyRequesters')
      .doc(requesterId)
      .delete();
			
	await FirebaseFirestore.instance
			.collection('groups')
			.doc(groupId)
			.update({
		'activeLocatorCount':
				FieldValue.increment(-1),
	});

  print(
    "GROUP SERVICE => locator removed => $locatorId",
  );
}

static Future<void> clearLocalGroup() async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.remove(_groupIdKey);
  await prefs.remove('group_code');
  await prefs.remove('join_status');
  await prefs.remove(_isMasterKey);
}

}
