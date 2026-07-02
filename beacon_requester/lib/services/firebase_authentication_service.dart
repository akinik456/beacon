import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
	static String? get uid => _auth.currentUser?.uid;
	
  static Future<String?> ensureSignedIn() async {
    final currentUser = _auth.currentUser;

    if (currentUser != null) {
      print("BEACON AUTH => existing uid=${currentUser.uid}");
      return currentUser.uid;
    }

    final credential = await _auth.signInAnonymously();
    final user = credential.user;

    print("BEACON AUTH => anonymous uid=${user?.uid}");

    return user?.uid;
  }

}