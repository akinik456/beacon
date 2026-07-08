import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import '../utils/log.dart';

class FirebaseTestService {
  FirebaseTestService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _rtdb = FirebaseDatabase.instance;

  static Future<void> runTest() async {
    try {
      // ================= FIRESTORE TEST =================
      await _firestore.collection('test').doc('requester').set({
        'status': 'ok',
        'timestamp': FieldValue.serverTimestamp(),
      });

      Log.d("BEACON FIRESTORE TEST => SUCCESS");

      // ================= RTDB TEST =================
      await _rtdb.ref('test/requester').set({
        'status': 'ok',
        'timestamp': ServerValue.timestamp,
      });

      Log.d("BEACON RTDB TEST => SUCCESS");
    } catch (e) {
      Log.e("BEACON FIREBASE TEST ERROR => $e");
    }
  }
}