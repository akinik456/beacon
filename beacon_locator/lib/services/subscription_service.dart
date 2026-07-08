import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class SubscriptionService {
  SubscriptionService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<bool> hasFullAccess() async {
    final groupId = await IdentityService.getGroupId();

    if (groupId == null || groupId.isEmpty) {
      return false;
    }

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .get();

    final data = doc.data();

    if (data == null) {
      return false;
    }

    final purchaseStatus = data['purchaseStatus'];
    final planStatus = data['planStatus'];
    final trialEndsAt = data['trialEndsAt'];
		
		Log.d("hasFullAccess planStatus$planStatus");

    if (purchaseStatus == 'lifetime') {
      return true;
    }

    if (planStatus == 'trial' &&
        trialEndsAt is Timestamp) {
      return DateTime.now().isBefore(
        trialEndsAt.toDate(),
      );
    }

    return false;
  }
}