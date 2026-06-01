import 'package:cloud_firestore/cloud_firestore.dart';

class RequestLocationService {
  RequestLocationService._();

  static Future<void> createRequestLocation({
    required String groupId,
    required String requesterId,
    required String locatorId,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(requesterId)
        .collection('request_location')
        .doc();

    await ref.set({
      'locatorId': locatorId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    print(
      'BEACON RL => created ${ref.id} for locator $locatorId',
    );
  }
}