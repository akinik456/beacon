import 'package:cloud_firestore/cloud_firestore.dart';
import 'code_service.dart';
import 'identity_service.dart';
import 'group_service.dart';
import '../utils/log.dart';

class LocatorPairingService {
  LocatorPairingService._();

  static final _firestore = FirebaseFirestore.instance;

		static Future<Map<String, String>?> sendPairingRequest({
  required String locatorInput,
}) async {
  try {
    final requesterId =
        await IdentityService.getRequesterId();

    final requesterName =
        await IdentityService.getRequesterName();

    final requesterCode =
        await IdentityService.getRequesterCode();

    if (requesterId == null ||
        requesterName == null ||
        requesterCode == null) {
      Log.d(
        "BEACON PAIRING => MISSING REQUESTER DATA",
      );
      return null;
    }

    final normalized =
        CodeService.normalizeCode(locatorInput);

    String locatorId;

    if (CodeService.isValidCode(normalized)) {
      Log.d(
        "BEACON PAIRING CODE QUERY => $normalized",
      );

      final query = await _firestore
          .collection('locators')
          .where('locatorCode', isEqualTo: normalized)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        Log.d(
          "BEACON PAIRING => LOCATOR NOT FOUND",
        );
        return null;
      }

      locatorId = query.docs.first.id;
    } else {
      final locatorDoc = await _firestore
          .collection('locators')
          .doc(locatorInput.trim())
          .get();

      if (!locatorDoc.exists) {
        Log.d(
          "BEACON PAIRING => LOCATOR ID NOT FOUND",
        );
        return null;
      }

      locatorId = locatorInput.trim();
    }

    // REQUESTER ROOT DOC
    final requesterDoc = await _firestore
        .collection('requesters')
        .doc(requesterId)
        .get();

    if (!requesterDoc.exists) {
      Log.d(
        "BEACON PAIRING => REQUESTER DOC MISSING",
      );

      return {
        'error': 'missing_requester_device',
      };
    }

    final requesterData =
        requesterDoc.data() ?? {};

    final pairedLocators =
        Map<String, dynamic>.from(
      requesterData['pairedLocators'] ?? {},
    );

    // ZATEN EŞLEŞMİŞ
    if (pairedLocators.containsKey(locatorId)) {
      return {
        'error': 'member_already_paired',
      };
    }

    // SATIN ALMA / LOCATOR LİMİTİ
    final maxLocators =
        requesterData['maxLocators'] ?? 1;

    if (pairedLocators.length >= maxLocators) {
      return {
        'error': 'member_limit_reached',
      };
    }

    // AYNI REQUESTER AYNI LOCATOR'A
    // İKİNCİ PENDING İSTEK ATAMASIN
    final pendingRequestSnap = await _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('pairing_requests')
        .where(
          'requesterId',
          isEqualTo: requesterId,
        )
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .limit(1)
        .get();

    if (pendingRequestSnap.docs.isNotEmpty) {
      return {
        'error': 'pairing_request_pending',
      };
    }

    final requestRef = _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('pairing_requests')
        .doc();

    await requestRef.set({
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterCode': requesterCode,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Log.d(
      "BEACON PAIRING => REQUEST SENT "
      "=> locator:$locatorId "
      "request:${requestRef.id}",
    );

    return {
      'locatorId': locatorId,
      'requestId': requestRef.id,
    };
  } catch (e) {
    Log.e(
      "BEACON PAIRING ERROR => $e",
    );
    return null;
  }
}
}
