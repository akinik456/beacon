import 'package:cloud_firestore/cloud_firestore.dart';

class JoinRequestService {
  JoinRequestService._();

  static final _firestore = FirebaseFirestore.instance;

  static Stream<QuerySnapshot<Map<String, dynamic>>>
      watchPendingJoinRequests({
    required String groupId,
  }) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('join_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }
}