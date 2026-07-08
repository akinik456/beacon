// lib/services/subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

import 'group_service.dart';
import 'identity_service.dart';
import '../utils/log.dart';


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
    final requesterId =
    await IdentityService.getRequesterId();

		if (requesterId == null || requesterId.isEmpty) {
			return const SubscriptionInfo(
				isPremium: false,
				trialActive: false,
				trialDaysLeft: 0,
			);
		}

		final requesterDoc = await _firestore
				.collection('requesters')
				.doc(requesterId)
				.get();
		Log.d("SUB => requesterId=$requesterId");

		final groupId =
				requesterDoc.data()?['groupId'] as String?;
				
		Log.d("SUB => groupId=$groupId");

		if (groupId == null || groupId.isEmpty) {
			return const SubscriptionInfo(
				isPremium: false,
				trialActive: false,
				trialDaysLeft: 0,
			);
		}
 Log.d("SUB => loading subscription for group=$groupId");   
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
  final isMaster =
      await GroupService.getLocalIsMaster();

  if (!isMaster) {
	Log.d("markExpiredIfNeeded isMaster $isMaster");
    return;
  }
  final groupId = await GroupService.getLocalGroupId();

  final doc = await _firestore
      .collection('groups')
      .doc(groupId)
      .get();

  final data = doc.data();

  if (data == null) return;

  final purchaseStatus = data['purchaseStatus'];
  final planStatus = data['planStatus'];
  final trialEndsAt = data['trialEndsAt'];

  if (purchaseStatus == 'lifetime') {Log.d("markExpiredIfNeeded purchaseStatus $purchaseStatus"); return;}
  if (planStatus != 'trial') {Log.d("markExpiredIfNeeded planStatus $planStatus"); return;}
  if (trialEndsAt is! Timestamp) {Log.d("markExpiredIfNeeded trialEndsAt $trialEndsAt"); return;}

  final expired =
      DateTime.now().isAfter(trialEndsAt.toDate());
			
	Log.d("markExpiredIfNeeded expired $expired");

  if (!expired) return;

  await _firestore
      .collection('groups')
      .doc(groupId)
      .update({
    'planStatus': 'expired',
    'entitlementUpdatedAt': FieldValue.serverTimestamp(),
  });
Log.d("markExpiredIfNeeded expired signed");
}

static Future<void> addRequesterSlot() async {
  final groupId = await GroupService.getLocalGroupId();

  if (groupId == null || groupId.isEmpty) {
    return;
  }

  await _firestore.collection('groups').doc(groupId).update({
    'maxRequesters': FieldValue.increment(1),
    'entitlementUpdatedAt': FieldValue.serverTimestamp(),
  });
}

static Future<void> addMemberSlot() async {
  final groupId = await GroupService.getLocalGroupId();

  if (groupId == null || groupId.isEmpty) {
    return;
  }

  await _firestore.collection('groups').doc(groupId).update({
    'maxLocators': FieldValue.increment(1),
    'entitlementUpdatedAt': FieldValue.serverTimestamp(),
  });
}
static Future<void> processPurchase({
  required String productId,
  required String purchaseId,
}) async {
  final groupId = await GroupService.getLocalGroupId();

  if (groupId == null || groupId.isEmpty) {
    Log.d("BEACON IAP => groupId missing");
    return;
  }

  final requesterId = await IdentityService.getRequesterId();

  final groupRef =
      _firestore.collection('groups').doc(groupId);

  final purchaseRef = groupRef
      .collection('purchases')
      .doc(purchaseId);

  await _firestore.runTransaction((tx) async {
    final purchaseDoc = await tx.get(purchaseRef);

    if (purchaseDoc.exists) {
      Log.d(
        "BEACON IAP => purchase already processed $purchaseId",
      );
      return;
    }

    tx.set(purchaseRef, {
      'purchaseId': purchaseId,
      'productId': productId,
      'requesterId': requesterId,
      'processedAt': FieldValue.serverTimestamp(),
    });

    if (productId == 'lynrafamily_lifetime') {
      tx.update(groupRef, {
        'planStatus': 'active',
        'purchaseStatus': 'lifetime',
        'purchaseOwnerRequesterId': requesterId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'entitlementUpdatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (productId == 'extra_requester_1') {
      tx.update(groupRef, {
        'maxRequesters': FieldValue.increment(1),
        'entitlementUpdatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (productId == 'extra_member_1') {
      tx.update(groupRef, {
        'maxLocators': FieldValue.increment(1),
        'entitlementUpdatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
  });
}
}