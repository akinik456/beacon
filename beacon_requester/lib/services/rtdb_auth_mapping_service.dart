import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'identity_service.dart';
import 'group_service.dart';
import '../utils/log.dart';

class RtdbAuthMappingService {
  RtdbAuthMappingService._();

  static final _db = FirebaseDatabase.instance.ref();

  static Future<void> syncRequesterAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    final requesterId = await IdentityService.getRequesterId();

    if (user == null || requesterId == null) {
      Log.d("BEACON RTDB AUTH => requester mapping skipped");
      return;
    }

    await _db.child("presence/auth/requesters/$requesterId").update({
      'authUid': user.uid,
      'role': 'requester',
      'updatedAt': ServerValue.timestamp,
    });
		
		await _db.child("presence/auth/uids/${user.uid}").update({
			'deviceId': requesterId,
			'role': 'requester',
			'updatedAt': ServerValue.timestamp,
		});

    Log.d("BEACON RTDB AUTH => requester mapped");
  }
}