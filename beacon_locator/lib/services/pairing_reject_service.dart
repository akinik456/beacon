import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class PairingRejectService {
  PairingRejectService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Future<void> rejectPairingRequest({
    required String requestId,
  }) async {
    try {
      final locatorId =
          await IdentityService.getLocatorId();

      if (locatorId == null || locatorId.isEmpty) {
        Log.d(
          "BEACON REJECT ERROR => locatorId not found",
        );
        return;
      }

      await _firestore
          .collection('locators')
          .doc(locatorId)
          .collection('pairing_requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      Log.d(
        "BEACON REJECT => SUCCESS => $requestId",
      );
    } catch (e) {
      Log.e(
        "BEACON REJECT ERROR => $e",
      );
    }
  }
}