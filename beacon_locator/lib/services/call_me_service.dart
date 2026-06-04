import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';

class CallMeService {
  CallMeService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Future<void> createCallMe({
    required String groupId,
    required String targetRequesterId,
  }) async {

    final locatorId =
        await IdentityService.getLocatorId();

    final locatorName =
        await IdentityService.getLocatorName();

    final locatorCode =
        await IdentityService.getLocatorCode();

    if (locatorId == null) {
      return;
    }
		
		final notifyDoc = await _firestore
				.collection('groups')
				.doc(groupId)
				.collection('devices')
				.doc(locatorId)
				.collection('notifyRequesters')
				.doc(targetRequesterId)
				.get();

		final notifyData =
				notifyDoc.data() ?? {};

		if (notifyData['callMe'] != true) {
			print(
				"BEACON CALLME => disabled by requester",
			);
			return;
		}

    final callMeId =
        const Uuid().v4();

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('call_me')
        .doc(targetRequesterId)
        .collection('items')
        .doc(callMeId)
        .set({
      'callMeId': callMeId,
      'groupId': groupId,
      'locatorId': locatorId,
      'locatorName': locatorName,
      'locatorCode': locatorCode,
      'targetRequesterId':
          targetRequesterId,
      'status': 'pending',
      'createdAt':
          FieldValue.serverTimestamp(),
    });

    print(
      "BEACON CALLME => "
      "created => $callMeId",
    );
  }
}