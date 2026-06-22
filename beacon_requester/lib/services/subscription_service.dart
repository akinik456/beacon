// lib/services/subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_service.dart';
import 'identity_service.dart';

class SubscriptionInfo {
  final bool isPremium;
  final bool trialActive;
  final int trialDaysLeft;

  const SubscriptionInfo({
    required this.isPremium,
    required this.trialActive,
    required this.trialDaysLeft,
  });

  bool get hasFullAccess => isPremium || trialActive;
}

class SubscriptionService {
  SubscriptionService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Future<SubscriptionInfo> load() async {
    final groupId =
        await GroupService.getLocalGroupId();

    if (groupId == null || groupId.isEmpty) {
      return const SubscriptionInfo(
        isPremium: false,
        trialActive: false,
        trialDaysLeft: 0,
      );
    }

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .get();

    final data = doc.data();

    if (data == null) {
      return const SubscriptionInfo(
        isPremium: false,
        trialActive: false,
        trialDaysLeft: 0,
      );
    }

    final purchaseStatus =
        data['purchaseStatus'] as String?;

    final planStatus =
        data['planStatus'] as String?;

    final trialEndsAt =
        data['trialEndsAt'];

    final isPremium =
        purchaseStatus == 'lifetime';

    bool trialActive = false;
    int trialDaysLeft = 0;

    if (planStatus == 'trial' &&
        trialEndsAt is Timestamp) {
      final now = DateTime.now();
      final end = trialEndsAt.toDate();

      trialActive = now.isBefore(end);

      if (trialActive) {
        trialDaysLeft =
            end.difference(now).inDays + 1;
      }
    }

    return SubscriptionInfo(
      isPremium: isPremium,
      trialActive: trialActive,
      trialDaysLeft: trialDaysLeft,
    );
  }
static Future<void> activateLifetime() async {
  final groupId = await GroupService.getLocalGroupId();

  if (groupId == null || groupId.isEmpty) {
    return;
  }

  final requesterId =
      await IdentityService.getRequesterId();

  await _firestore
      .collection('groups')
      .doc(groupId)
      .update({
    'planStatus': 'active',
    'purchaseStatus': 'lifetime',
    'purchaseOwnerRequesterId': requesterId,
    'purchasedAt': FieldValue.serverTimestamp(),
    'entitlementUpdatedAt':
        FieldValue.serverTimestamp(),
  });
}	
static Future<void> markExpiredIfNeeded() async {
print("markExpiredIfNeeded called");
  final groupId = await GroupService.getLocalGroupId();

  final doc = await _firestore
      .collection('groups')
      .doc(groupId)
      .get();

  final data = doc.data();

  if (data == null) return;
print("markExpiredIfNeeded data is not null");

  final purchaseStatus = data['purchaseStatus'];
  final planStatus = data['planStatus'];
  final trialEndsAt = data['trialEndsAt'];

  if (purchaseStatus == 'lifetime') {print("markExpiredIfNeeded purchaseStatus $purchaseStatus"); return;}
  if (planStatus != 'trial') {print("markExpiredIfNeeded planStatus $planStatus"); return;}
  if (trialEndsAt is! Timestamp) {print("markExpiredIfNeeded trialEndsAt $trialEndsAt"); return;}

  final expired =
      DateTime.now().isAfter(trialEndsAt.toDate());
			
	print("markExpiredIfNeeded expired $expired");

  if (!expired) return;

  await _firestore
      .collection('groups')
      .doc(groupId)
      .update({
    'planStatus': 'expired',
    'entitlementUpdatedAt': FieldValue.serverTimestamp(),
  });
print("markExpiredIfNeeded expired signed");
}
}