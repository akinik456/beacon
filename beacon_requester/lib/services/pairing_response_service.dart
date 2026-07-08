import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/log.dart';

class PairingResponseService {
  PairingResponseService._();

  static final _firestore =
      FirebaseFirestore.instance;

  static Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchPairingResponse({
    required String locatorId,
    required String requestId,
  }) {

    return _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('pairing_requests')
        .doc(requestId)
        .snapshots();
  }

  static Future<void> deletePairingRequest({
    required String locatorId,
    required String requestId,
  }) async {

    await _firestore
        .collection('locators')
        .doc(locatorId)
        .collection('pairing_requests')
        .doc(requestId)
        .delete();

    Log.d(
      "BEACON PAIRING RESPONSE => "
      "REQUEST DELETED => $requestId",
    );
  }
}