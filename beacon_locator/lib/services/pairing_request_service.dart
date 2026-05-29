import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';

class PairingRequestService {
  PairingRequestService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      watchPendingPairingRequests({
    required String locatorId,
  }) {
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