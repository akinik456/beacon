import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';

class PairingRequestService {
  PairingRequestService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Future<Stream<QuerySnapshot<Map<String, dynamic>>>>
      watchPendingPairingRequests() async {
    final locatorId =
        await IdentityService.getLocatorId();

    if (locatorId == null || locatorId.isEmpty) {
      throw Exception(
        'Locator id not found',
      );
    }

    return _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('pairing_requests')
        .where(
          'status',
          isEqualTo: 'pending',
        )
        .snapshots();
  }
}