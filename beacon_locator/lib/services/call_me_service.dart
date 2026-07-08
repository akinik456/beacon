import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class CallMeService {
  CallMeService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> createCallMe({
    required String groupId,
    required String targetRequesterId,
  }) async {
    final locatorId = await IdentityService.getLocatorId();
    final locatorName = await IdentityService.getLocatorName();
    final locatorCode = await IdentityService.getLocatorCode();

    if (locatorId == null || targetRequesterId.isEmpty) {
      return;
    }

    final enabled = await _isCallMeEnabledForRequester(
      groupId: groupId,
      locatorId: locatorId,
      requesterId: targetRequesterId,
    );

    if (!enabled) {
      Log.d("BEACON CALLME => disabled by requester => $targetRequesterId");
      return;
    }

    await _createCallMeItem(
      groupId: groupId,
      locatorId: locatorId,
      locatorName: locatorName,
      locatorCode: locatorCode,
      targetRequesterId: targetRequesterId,
    );
  }

  static Future<void> createCallMeForAll({
    required String groupId,
    required List<String> requesterIds,
  }) async {
    final locatorId = await IdentityService.getLocatorId();
    final locatorName = await IdentityService.getLocatorName();
    final locatorCode = await IdentityService.getLocatorCode();

    if (locatorId == null || requesterIds.isEmpty) {
      return;
    }

    for (final requesterId in requesterIds) {
      if (requesterId.isEmpty) continue;

      final enabled = await _isCallMeEnabledForRequester(
        groupId: groupId,
        locatorId: locatorId,
        requesterId: requesterId,
      );

      if (!enabled) {
        Log.d("BEACON CALLME => skipped disabled requester => $requesterId");
        continue;
      }

      await _createCallMeItem(
        groupId: groupId,
        locatorId: locatorId,
        locatorName: locatorName,
        locatorCode: locatorCode,
        targetRequesterId: requesterId,
      );
    }
  }

  static Future<bool> _isCallMeEnabledForRequester({
    required String groupId,
    required String locatorId,
    required String requesterId,
  }) async {
    final notifyDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(locatorId)
        .collection('notifyRequesters')
        .doc(requesterId)
        .get();

    final notifyData = notifyDoc.data() ?? {};

    return notifyData['callMe'] == true;
  }

  static Future<void> _createCallMeItem({
    required String groupId,
    required String locatorId,
    required String? locatorName,
    required String? locatorCode,
    required String targetRequesterId,
  }) async {
    final callMeId = const Uuid().v4();

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
      'locatorName': locatorName ?? 'Locator',
      'locatorCode': locatorCode ?? '------',
      'targetRequesterId': targetRequesterId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Log.d("BEACON CALLME => created => $callMeId => $targetRequesterId");
  }
}