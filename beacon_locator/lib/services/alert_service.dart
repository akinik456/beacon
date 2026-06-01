import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import 'identity_service.dart';

class AlertService {
  AlertService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<void> sendGpsOffAlert() async {
    final groupId = await IdentityService.getGroupId();
    final locatorId = await IdentityService.getLocatorId();
    final locatorName = await IdentityService.getLocatorName();
    final locatorCode = await IdentityService.getLocatorCode();

    if (groupId == null || locatorId == null) {
      print("BEACON ALERT => missing group/locator");
      return;
    }

    final locatorDeviceDoc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(locatorId)
        .get();

    final data = locatorDeviceDoc.data();

    if (data == null) {
      print("BEACON ALERT => locator device doc not found");
      return;
    }

    final pairedRequesters = Map<String, dynamic>.from(
      data['pairedRequesters'] ?? {},
    );

    if (pairedRequesters.isEmpty) {
      print("BEACON ALERT => no paired requesters");
      return;
    }

    for (final requesterId in pairedRequesters.keys) {
      final alertId = const Uuid().v4();

      await _firestore
          .collection('groups')
          .doc(groupId)
          .collection('alerts')
          .doc(requesterId)
          .collection('items')
          .doc(alertId)
          .set({
        'alertId': alertId,
        'groupId': groupId,
        'type': 'gps_off',
        'locatorId': locatorId,
        'locatorName': locatorName ?? 'Locator',
        'locatorCode': locatorCode ?? '------',
        'targetRequesterId': requesterId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    print("BEACON ALERT => gps_off sent");
  }
}