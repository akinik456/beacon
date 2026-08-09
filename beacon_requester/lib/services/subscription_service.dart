// lib/services/subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

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

  static final _firestore = FirebaseFirestore.instance;

  static Future<SubscriptionInfo> load() async {
    final requesterId = await IdentityService.getRequesterId();

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

    final data = requesterDoc.data();

    if (data == null) {
      return const SubscriptionInfo(
        isPremium: false,
        trialActive: false,
        trialDaysLeft: 0,
      );
    }

    final purchaseStatus = data['purchaseStatus'] as String?;
    final planStatus = data['planStatus'] as String?;
    final trialEndsAt = data['trialEndsAt'];

    final isPremium = purchaseStatus == 'lifetime';

    bool trialActive = false;
    int trialDaysLeft = 0;

    if (planStatus == 'trial' && trialEndsAt is Timestamp) {
      final now = DateTime.now();
      final end = trialEndsAt.toDate();

      trialActive = now.isBefore(end);

      if (trialActive) {
        trialDaysLeft = end.difference(now).inDays + 1;
      }
    }

    Log.d(
      "SUB => requester=$requesterId "
      "plan=$planStatus "
      "purchase=$purchaseStatus",
    );

    return SubscriptionInfo(
      isPremium: isPremium,
      trialActive: trialActive,
      trialDaysLeft: trialDaysLeft,
    );
  }

  static Future<void> activateLifetime() async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null || requesterId.isEmpty) {
      return;
    }

    await _firestore
        .collection('requesters')
        .doc(requesterId)
        .set({
      'planStatus': 'active',
      'purchaseStatus': 'lifetime',
      'purchaseOwnerRequesterId': requesterId,
      'purchasedAt': FieldValue.serverTimestamp(),
      'entitlementUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> markExpiredIfNeeded() async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null || requesterId.isEmpty) {
      return;
    }

    final requesterRef =
        _firestore.collection('requesters').doc(requesterId);

    final requesterDoc = await requesterRef.get();
    final data = requesterDoc.data();

    if (data == null) {
      return;
    }

    final purchaseStatus = data['purchaseStatus'];
    final planStatus = data['planStatus'];
    final trialEndsAt = data['trialEndsAt'];

    if (purchaseStatus == 'lifetime') {
      return;
    }

    if (planStatus != 'trial') {
      return;
    }

    if (trialEndsAt is! Timestamp) {
      return;
    }

    final expired = DateTime.now().isAfter(
      trialEndsAt.toDate(),
    );

    Log.d(
      "SUB => markExpiredIfNeeded expired=$expired",
    );

    if (!expired) {
      return;
    }

    await requesterRef.set({
      'planStatus': 'expired',
      'entitlementUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Log.d(
      "SUB => trial marked expired requester=$requesterId",
    );
  }

  static Future<void> addRequesterSlot() async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null || requesterId.isEmpty) {
      return;
    }

    await _firestore
        .collection('requesters')
        .doc(requesterId)
        .set({
      'maxRequesters': FieldValue.increment(1),
      'entitlementUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> addMemberSlot() async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null || requesterId.isEmpty) {
      return;
    }

    await _firestore
        .collection('requesters')
        .doc(requesterId)
        .set({
      'maxLocators': FieldValue.increment(1),
      'entitlementUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> processPurchase({
    required String productId,
    required String purchaseId,
  }) async {
    final requesterId = await IdentityService.getRequesterId();

    if (requesterId == null || requesterId.isEmpty) {
      Log.d("BEACON IAP => requesterId missing");
      return;
    }

    final requesterRef =
        _firestore.collection('requesters').doc(requesterId);

    final purchaseRef = requesterRef
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
        tx.set(
          requesterRef,
          {
            'planStatus': 'active',
            'purchaseStatus': 'lifetime',
            'maxRequesters': 1,
            'maxLocators': 1,
            'purchaseOwnerRequesterId': requesterId,
            'purchasedAt': FieldValue.serverTimestamp(),
            'entitlementUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        Log.d("BEACON IAP => lifetime processed");
        return;
      }

      if (productId == 'extra_requester_1') {
        tx.set(
          requesterRef,
          {
            'maxRequesters': FieldValue.increment(1),
            'entitlementUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        Log.d("BEACON IAP => extra requester processed");
        return;
      }

      if (productId == 'extra_member_1') {
        tx.set(
          requesterRef,
          {
            'maxLocators': FieldValue.increment(1),
            'entitlementUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        Log.d("BEACON IAP => extra member processed");
        return;
      }

      throw StateError(
        'Unknown productId: $productId',
      );
    });
  }
}
