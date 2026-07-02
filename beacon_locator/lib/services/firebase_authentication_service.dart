import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
	static StreamSubscription<User?>? _authSub;
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
	
	static void startAuthListener() {
    _authSub ??= _auth.authStateChanges().listen((user) {
      if (user == null) {
        print("BEACON AUTH => signed out");
      } else {
        print("BEACON AUTH => uid=${user.uid}");
      }
    });
  }

  static Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
  }

}