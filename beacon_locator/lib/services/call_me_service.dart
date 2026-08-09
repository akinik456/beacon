import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class CallMeService {
  CallMeService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> createCallMe({
    required String targetRequesterId,
  }) async {
    final locatorId = await IdentityService.getLocatorId();
    final locatorName = await IdentityService.getLocatorName();
    final locatorCode = await IdentityService.getLocatorCode();

    if (locatorId == null || targetRequesterId.isEmpty) {
      return;
    }

    final enabled = await _isCallMeEnabledForRequester(
      locatorId: locatorId,
      requesterId: targetRequesterId,
    );

    if (!enabled) {
      Log.d("BEACON CALLME => disabled by requester => $targetRequesterId");
      return;
    }

    await _createCallMeItem(
      locatorId: locatorId,
      locatorName: locatorName,
      locatorCode: locatorCode,
      targetRequesterId: targetRequesterId,
    );
  }

  static Future<bool> _isCallMeEnabledForRequester({
    required String locatorId,
    required String requesterId,
  }) async {
    final notifyDoc = await _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('notifyRequesters')
        .doc(requesterId)
        .get();

    final notifyData = notifyDoc.data() ?? {};

    return notifyData['callMe'] == true;
  }

  static Future<void> _createCallMeItem({
    required String locatorId,
    required String? locatorName,
    required String? locatorCode,
    required String targetRequesterId,
  }) async {
    final callMeId = const Uuid().v4();

    await _firestore
        .collection('call_me')
        .doc(targetRequesterId)
        .collection('items')
        .doc(callMeId)
        .set({
      'callMeId': callMeId,
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