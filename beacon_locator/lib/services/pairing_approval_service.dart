import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../services/active_watcher_service.dart';
import '../utils/log.dart';

class PairingApprovalService {
  PairingApprovalService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<String> approvePairingRequest({
  required String requestId,
  required Map<String, dynamic> requestData,
}) async {
  final locatorId = await IdentityService.getLocatorId();
	final locatorName = await IdentityService.getLocatorName();
	final locatorCode = await IdentityService.getLocatorCode();

  if (locatorId == null || locatorId.isEmpty) {
    Log.d("BEACON APPROVE ERROR => locatorId not found");
    return 'error_locator_not_found';
  }

  final groupId = requestData['groupId'];
  final requesterId = requestData['requesterId'];

  if (groupId == null || requesterId == null) {
    Log.d("BEACON APPROVE ERROR => invalid request data");
    return 'invalid_request_data';
  }

  final requestRef = _firestore
      .collection('locators')
      .doc(locatorId)
      .collection('pairing_requests')
      .doc(requestId);

  final groupRef = _firestore.collection('groups').doc(groupId);

  final deviceRef = groupRef
      .collection('devices')
      .doc(locatorId);

  final locatorRef = _firestore
      .collection('locators')
      .doc(locatorId);

  final result =
      await _firestore.runTransaction<String>((tx) async {
    final groupSnap = await tx.get(groupRef);

    if (!groupSnap.exists) {
      tx.update(requestRef, {
        'status': 'rejected_group_not_found',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      return 'rejected_group_not_found';
    }

    final deviceSnap = await tx.get(deviceRef);

    final locatorAlreadyInGroup = deviceSnap.exists;

    final groupData = groupSnap.data() ?? {};

    if (!locatorAlreadyInGroup) {
      final maxLocators = groupData['maxLocators'] ?? 1;
      final currentLocators =
          groupData['activeLocatorCount'] ?? 0;

      if (currentLocators >= maxLocators) {
        tx.update(requestRef, {
          'status': 'rejected_capacity',
          'respondedAt': FieldValue.serverTimestamp(),
        });

        return 'rejected_capacity';
      }

      tx.set(deviceRef, {
        'active': true,
				'role': 'locator',
				'locatorCode': locatorCode,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      tx.update(groupRef, {
        'activeLocatorCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    tx.set(deviceRef, {
      'pairedRequesters': {
        requesterId: {
          'requesterCode':
              requestData['requesterCode'] ?? '------',
          'pairedAt': FieldValue.serverTimestamp(),
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    tx.set(locatorRef, {
      'groupId': groupId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    tx.update(requestRef, {
      'status': 'approved',
      'respondedAt': FieldValue.serverTimestamp(),
    });
    return 'approved';
		
		
  });

  if (result == 'approved') {
		await IdentityService.setGroupId(groupId);

		final savedGroupId = await IdentityService.getGroupId();

		Log.d(
			"BEACON APPROVE => SUCCESS "
			"locator=$locatorId "
			"group=$groupId "
			"savedGroup=$savedGroupId",
		);
	}

  return result;
}
	
	static Future<void> rejectPairingRequest({
		required String requestId,
		required Map<String, dynamic> requestData,
	}) async {
		final locatorId = await IdentityService.getLocatorId();

		if (locatorId == null) return;

		await FirebaseFirestore.instance
				.collection('locators')
				.doc(locatorId)
				.collection('pairing_requests')
				.doc(requestId)
				.update({
			'status': 'rejected',
			'respondedAt': FieldValue.serverTimestamp(),
		});
	}	
}