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
    Log.d(
      "markExpiredIfNeeded isMaster $isMaster",
    );
    return;
  }

  final groupId =
      await GroupService.getLocalGroupId();

  if (groupId == null || groupId.isEmpty) {
    Log.d(
      "markExpiredIfNeeded groupId missing",
    );
    return;
  }

  final groupRef =
      _firestore.collection('groups').doc(groupId);

  final groupDoc = await groupRef.get();
  final data = groupDoc.data();

  if (data == null) {
    return;
  }

  final purchaseStatus =
      data['purchaseStatus'];

  final planStatus =
      data['planStatus'];

  final trialEndsAt =
      data['trialEndsAt'];

  if (purchaseStatus == 'lifetime') {
    Log.d(
      "markExpiredIfNeeded "
      "purchaseStatus $purchaseStatus",
    );
    return;
  }

  if (planStatus != 'trial') {
    Log.d(
      "markExpiredIfNeeded "
      "planStatus $planStatus",
    );
    return;
  }

  if (trialEndsAt is! Timestamp) {
    Log.d(
      "markExpiredIfNeeded "
      "trialEndsAt $trialEndsAt",
    );
    return;
  }

  final expired =
      DateTime.now().isAfter(
        trialEndsAt.toDate(),
      );

  Log.d(
    "markExpiredIfNeeded expired $expired",
  );

  if (!expired) {
    return;
  }

  final devicesSnapshot = await groupRef
      .collection('devices')
      .get();

  final batch = _firestore.batch();

  batch.update(groupRef, {
    'planStatus': 'expired',
    'entitlementUpdatedAt':
        FieldValue.serverTimestamp(),
  });

  for (final deviceDoc
      in devicesSnapshot.docs) {
    batch.update(
      deviceDoc.reference,
      {
        'isEntitled': false,
      },
    );
  }

  await batch.commit();

  Log.d(
    "markExpiredIfNeeded expired signed "
    "devicesDisabled=${devicesSnapshot.docs.length}",
  );
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
  final groupId =
      await GroupService.getLocalGroupId();

  if (groupId == null || groupId.isEmpty) {
    Log.d("BEACON IAP => groupId missing");
    return;
  }

  final requesterId =
      await IdentityService.getRequesterId();

  final groupRef =
      _firestore.collection('groups').doc(groupId);

  final purchaseRef = groupRef
      .collection('purchases')
      .doc(purchaseId);

  final devicesSnapshot = await groupRef
      .collection('devices')
      .get();

  final deviceRefs = devicesSnapshot.docs
      .map((doc) => doc.reference)
      .toList();

  await _firestore.runTransaction((tx) async {
    final purchaseDoc =
        await tx.get(purchaseRef);

    if (purchaseDoc.exists) {
      Log.d(
        "BEACON IAP => "
        "purchase already processed $purchaseId",
      );
      return;
    }

    /*
     * Transaction içinde güncel device durumlarını
     * yeniden okuyoruz.
     */
    final deviceDocs = <DocumentSnapshot<
        Map<String, dynamic>>>[];

    for (final deviceRef in deviceRefs) {
      deviceDocs.add(
        await tx.get(deviceRef),
      );
    }

    tx.set(purchaseRef, {
      'purchaseId': purchaseId,
      'productId': productId,
      'requesterId': requesterId,
      'processedAt':
          FieldValue.serverTimestamp(),
    });

    // =====================================================
    // LIFETIME
    // Temel paket: 1 requester (master) + 1 locator
    // =====================================================

    if (productId == 'lynrafamily_lifetime') {
      DocumentReference<Map<String, dynamic>>?
          firstLocatorRef;

      for (final deviceDoc in deviceDocs) {
        final data = deviceDoc.data();

        if (data == null) {
          continue;
        }

        tx.update(deviceDoc.reference, {
          'isEntitled': false,
        });

        if (firstLocatorRef == null &&
            data['role'] == 'locator') {
          firstLocatorRef =
              deviceDoc.reference;
        }
      }

      if (firstLocatorRef != null) {
        tx.update(firstLocatorRef, {
          'isEntitled': true,
        });
      }

      tx.update(groupRef, {
        'planStatus': 'active',
        'purchaseStatus': 'lifetime',

        'maxRequesters': 1,
        'maxLocators': 1,

        'purchaseOwnerRequesterId':
            requesterId,
        'purchasedAt':
            FieldValue.serverTimestamp(),
        'entitlementUpdatedAt':
            FieldValue.serverTimestamp(),
      });

      Log.d(
        "BEACON IAP => lifetime processed "
        "locatorEnabled=${firstLocatorRef != null}",
      );

      return;
    }

    // =====================================================
    // EXTRA REQUESTER
    // İlk pasif, master olmayan requester açılır.
    // Pasif requester yoksa slot sonraki katılım için kalır.
    // =====================================================

    if (productId == 'extra_requester_1') {
      DocumentReference<Map<String, dynamic>>?
          requesterToEnableRef;

      for (final deviceDoc in deviceDocs) {
        final data = deviceDoc.data();

        if (data == null) {
          continue;
        }

        final isRequester =
            data['role'] == 'requester';

        final isMaster =
            data['isMaster'] == true ||
            deviceDoc.id == requesterId;

        final isEntitled =
            data['isEntitled'] == true;

        if (isRequester &&
            !isMaster &&
            !isEntitled) {
          requesterToEnableRef =
              deviceDoc.reference;
          break;
        }
      }

      if (requesterToEnableRef != null) {
        tx.update(requesterToEnableRef, {
          'isEntitled': true,
        });
      }

      tx.update(groupRef, {
        'maxRequesters':
            FieldValue.increment(1),
        'entitlementUpdatedAt':
            FieldValue.serverTimestamp(),
      });

      Log.d(
        "BEACON IAP => extra requester processed "
        "deviceEnabled="
        "${requesterToEnableRef != null}",
      );

      return;
    }

    // =====================================================
    // EXTRA MEMBER
    // İlk pasif locator açılır.
    // Pasif locator yoksa slot sonraki katılım için kalır.
    // =====================================================

    if (productId == 'extra_member_1') {
      DocumentReference<Map<String, dynamic>>?
          locatorToEnableRef;

      for (final deviceDoc in deviceDocs) {
        final data = deviceDoc.data();

        if (data == null) {
          continue;
        }

        final isLocator =
            data['role'] == 'locator';

        final isEntitled =
            data['isEntitled'] == true;

        if (isLocator && !isEntitled) {
          locatorToEnableRef =
              deviceDoc.reference;
          break;
        }
      }

      if (locatorToEnableRef != null) {
        tx.update(locatorToEnableRef, {
          'isEntitled': true,
        });
      }

      tx.update(groupRef, {
        'maxLocators':
            FieldValue.increment(1),
        'entitlementUpdatedAt':
            FieldValue.serverTimestamp(),
      });

      Log.d(
        "BEACON IAP => extra member processed "
        "deviceEnabled="
        "${locatorToEnableRef != null}",
      );

      return;
    }

    throw StateError(
      'Unknown productId: $productId',
    );
  });
}
}