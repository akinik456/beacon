import 'package:cloud_firestore/cloud_firestore.dart';
import 'code_service.dart';
import 'identity_service.dart';
import 'group_service.dart';

class LocatorPairingService {
  LocatorPairingService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, String>?> sendPairingRequest({
    required String locatorInput,
  }) async {
    try {
      final requesterId = await IdentityService.getRequesterId();

      final requesterName = await IdentityService.getRequesterName();
			print("sendPairingRequest IdentityService.getRequesterName");

      final requesterCode = await IdentityService.getRequesterCode();

      final groupId = await GroupService.getLocalGroupId();

      if (requesterId == null ||
          requesterName == null ||
          requesterCode == null ||
          groupId == null) {
        print("BEACON PAIRING => MISSING REQUESTER DATA");
        return null;
      }

      final normalized = CodeService.normalizeCode(locatorInput);

      String locatorId;

      if (CodeService.isValidCode(normalized)) {
        final query = await _firestore
            .collection('locators')
            .where('locatorCode', isEqualTo: normalized)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          print("BEACON PAIRING => LOCATOR NOT FOUND");
          return null;
        }

        locatorId = query.docs.first.id;
      } else {
        locatorId = locatorInput.trim();
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
        'groupId': groupId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      print(
        "BEACON PAIRING => REQUEST SENT "
        "=> locator:$locatorId "
        "request:${requestRef.id}",
      );

      return {'locatorId': locatorId, 'requestId': requestRef.id};
    } catch (e) {
      print("BEACON PAIRING ERROR => $e");
      return null;
    }
  }
}
