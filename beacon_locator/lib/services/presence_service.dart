import 'package:firebase_database/firebase_database.dart';

import 'identity_service.dart';

class PresenceService {
  PresenceService._();

  static final _db =
      FirebaseDatabase.instance.ref();

  static Future<void> updateOnline() async {

    final groupId = await IdentityService.getGroupId();

    final locatorId =
        await IdentityService.getLocatorId();

    if (groupId == null ||
        locatorId == null) {

      print(
        "BEACON PRESENCE => "
        "missing group/locator",
      );

      return;
    }

    await _db
        .child(
          "presence/groups/$groupId/locators/$locatorId",
        )
        .set({
      'status': 'online',
      'lastSeen':
          ServerValue.timestamp,
    });

    print(
      "BEACON PRESENCE => "
      "online updated",
    );
  }
}