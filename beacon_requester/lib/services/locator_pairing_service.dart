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
      final requesterId = await IdentityService.getRequesterId();

      final requesterName = await IdentityService.getRequesterName();
			Log.d("sendPairingRequest IdentityService.getRequesterName");

      final requesterCode = await IdentityService.getRequesterCode();

      final groupId = await GroupService.getLocalGroupId();

      if (requesterId == null ||
          requesterName == null ||
          requesterCode == null ||
          groupId == null) {
        Log.d("BEACON PAIRING => MISSING REQUESTER DATA");
        return null;
      }

      final normalized = CodeService.normalizeCode(locatorInput);

      String locatorId;

      if (CodeService.isValidCode(normalized)) {
			Log.d("BEACON PAIRING CODE QUERY => $normalized");
        final query = await _firestore
            .collection('locators')
            .where('locatorCode', isEqualTo: normalized)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          Log.d("BEACON PAIRING => LOCATOR NOT FOUND");
          return null;
        }

        locatorId = query.docs.first.id;
      } else {
        locatorId = locatorInput.trim();
      }
			
			if (groupId.isEmpty) {
				Log.d("BEACON PAIRING => GROUP ID MISSING");
				return null;
			}
			
			final requesterDoc = await _firestore
					.collection('groups')
					.doc(groupId)
					.collection('devices')
					.doc(requesterId)
					.get();
			if (!requesterDoc.exists) {
				Log.d("BEACON PAIRING => REQUESTER DEVICE DOC MISSING");
				return {
					'error': 'missing_requester_device',
				};
			}
			final requesterData = requesterDoc.data() ?? {};

			final pairedLocators = Map<String, dynamic>.from(
				requesterData['pairedLocators'] ?? {},
			);

			if (pairedLocators.containsKey(locatorId)) {
				return {
					'error': 'member_already_paired',
				};
			}

			final existingDeviceDoc = await _firestore
					.collection('groups')
					.doc(groupId)
					.collection('devices')
					.doc(locatorId)
					.get();
					
			final groupSnap = await _firestore
					.collection('groups')
					.doc(groupId)
					.get();

			final groupData = groupSnap.data() ?? {};

			final maxLocators =
					groupData['maxLocators'] ?? 1;

			final activeLocatorCount =
					groupData['activeLocatorCount'] ?? 0;

			final locatorAlreadyInGroup = existingDeviceDoc.exists;

			if (!locatorAlreadyInGroup &&
					activeLocatorCount >= maxLocators) {
				return {
					'error': 'member_limit_reached',
				};
			}
			
			final pendingRequestSnap = await _firestore
					.collection('locators')
					.doc(locatorId)
					.collection('pairing_requests')
					.where('status', isEqualTo: 'pending')
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
        'groupId': groupId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      Log.d(
        "BEACON PAIRING => REQUEST SENT "
        "=> locator:$locatorId "
        "request:${requestRef.id}",
      );

      return {'locatorId': locatorId, 'requestId': requestRef.id};
    } catch (e) {
      Log.e("BEACON PAIRING ERROR => $e");
      return null;
    }
  }
}
