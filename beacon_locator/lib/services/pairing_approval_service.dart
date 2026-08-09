import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class PairingApprovalService {
  PairingApprovalService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<String> approvePairingRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
  }) async {
    final locatorId = await IdentityService.getLocatorId();

    if (locatorId == null || locatorId.isEmpty) {
      Log.d(
        "BEACON APPROVE ERROR => locatorId not found",
      );
      return 'error_locator_not_found';
    }

    final requesterId = requestData['requesterId'];
    final requesterName = requestData['requesterName'];
    final requesterCode =
        requestData['requesterCode'] ?? '------';

    if (requesterId == null) {
      Log.d(
        "BEACON APPROVE ERROR => invalid request data",
      );
      return 'invalid_request_data';
    }

    final requestRef = _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('pairing_requests')
        .doc(requestId);

    final locatorRef = _firestore
        .collection('locators')
        .doc(locatorId);

    final result =
        await _firestore.runTransaction<String>((tx) async {
      final requestSnap = await tx.get(requestRef);

      if (!requestSnap.exists) {
        Log.d(
          "BEACON APPROVE ERROR => request not found",
        );
        return 'request_not_found';
      }

      final currentStatus =
          requestSnap.data()?['status'];

      if (currentStatus != 'pending') {
        Log.d(
          "BEACON APPROVE ERROR => "
          "request already processed status=$currentStatus",
        );
        return currentStatus?.toString() ??
            'invalid_request_status';
      }

      tx.set(
        locatorRef,
        {
          'pairedRequesters': {
            requesterId: {
              'requesterCode': requesterCode,
              'requesterName': requesterName,
              'pairedAt': FieldValue.serverTimestamp(),
            },
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      tx.update(
        requestRef,
        {
          'status': 'approved',
          'respondedAt': FieldValue.serverTimestamp(),
        },
      );

      return 'approved';
    });

    if (result == 'approved') {
      Log.d(
        "BEACON APPROVE => SUCCESS "
        "locator=$locatorId "
        "requester=$requesterId",
      );
    }

    return result;
  }

  static Future<void> rejectPairingRequest({
    required String requestId,
    required Map<String, dynamic> requestData,
  }) async {
    final locatorId =
        await IdentityService.getLocatorId();

    if (locatorId == null) return;

    await _firestore
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
