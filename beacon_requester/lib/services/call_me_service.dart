import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class CallMeService {
  CallMeService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> createCallMe({
    required String groupId,
    required String targetLocatorId,
  }) async {
    final requesterId =
        await IdentityService.getRequesterId();

    final requesterName =
        await IdentityService.getRequesterName();
Log.d("createCallMe IdentityService.getRequesterName");
    final requesterCode =
        await IdentityService.getRequesterCode();

    if (requesterId == null ||
        requesterId.isEmpty ||
        targetLocatorId.isEmpty) {
      return;
    }

    final callMeId = const Uuid().v4();

    await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('call_me')
        .doc(targetLocatorId)
        .collection('items')
        .doc(callMeId)
        .set({
      'callMeId': callMeId,
      'groupId': groupId,
      'requesterId': requesterId,
      'requesterName': requesterName ?? 'Requester',
      'requesterCode': requesterCode ?? '------',
      'targetLocatorId': targetLocatorId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Log.d(
      "BEACON CALLME => requester created => $callMeId => $targetLocatorId",
    );
  }
}