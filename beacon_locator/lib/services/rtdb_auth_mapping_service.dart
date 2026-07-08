import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class RtdbAuthMappingService {
  RtdbAuthMappingService._();

  static final _db = FirebaseDatabase.instance.ref();

  static Future<void> syncLocatorAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    final locatorId = await IdentityService.getLocatorId();
		final groupId = await IdentityService.getGroupId();
		
    if (user == null || locatorId == null) {
      Log.d("BEACON RTDB AUTH => locator mapping skipped");
      return;
    }

    await _db.child("presence/auth/locators/$locatorId").update({
			'authUid': user.uid,
			'groupId': groupId,
			'role': 'locator',
			'updatedAt': ServerValue.timestamp,
		});
		
		await _db.child("presence/auth/uids/${user.uid}").update({
			'deviceId': locatorId,
			'groupId': groupId,
			'role': 'locator',
			'updatedAt': ServerValue.timestamp,
		});

    Log.d("BEACON RTDB AUTH => locator mapped");
  }
}