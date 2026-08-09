import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class SubscriptionService {
  SubscriptionService._();

  static final _firestore = FirebaseFirestore.instance;

  static Future<bool> hasFullAccess() async {
    final locatorId =
        await IdentityService.getLocatorId();

    if (locatorId == null || locatorId.isEmpty) {
      Log.d(
        "BEACON SUBSCRIPTION => locatorId missing",
      );
      return false;
    }

    final locatorDoc = await _firestore
        .collection('locators')
        .doc(locatorId)
        .get();

    final locatorData = locatorDoc.data();

    if (locatorData == null) {
      Log.d(
        "BEACON SUBSCRIPTION => locator doc missing",
      );
      return false;
    }

    final pairedRequesters =
        Map<String, dynamic>.from(
      locatorData['pairedRequesters'] ?? {},
    );

    // Henüz kimseyle eşleşmemiş locator serbest çalışsın.
    if (pairedRequesters.isEmpty) {
      Log.d(
        "BEACON SUBSCRIPTION => no paired requester, access allowed",
      );
      return true;
    }

    for (final requesterId in pairedRequesters.keys) {
      final requesterDoc = await _firestore
          .collection('requesters')
          .doc(requesterId)
          .get();

      final requesterData = requesterDoc.data();

      if (requesterData == null) {
        continue;
      }

      final purchaseStatus =
          requesterData['purchaseStatus'];

      final planStatus =
          requesterData['planStatus'];

      final trialEndsAt =
          requesterData['trialEndsAt'];

      Log.d(
        "BEACON SUBSCRIPTION => "
        "requester=$requesterId "
        "plan=$planStatus "
        "purchase=$purchaseStatus",
      );

      // Lifetime
      if (purchaseStatus == 'lifetime') {
        return true;
      }

      // Aktif trial
      if (planStatus == 'trial' &&
          trialEndsAt is Timestamp &&
          DateTime.now().isBefore(
            trialEndsAt.toDate(),
          )) {
        return true;
      }
    }

    // Buraya geldiysek paired requester var
    // ama hiçbirinde lifetime veya aktif trial yok.
    Log.d(
      "BEACON SUBSCRIPTION => all paired requesters expired",
    );

    return false;
  }
}