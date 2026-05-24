import 'package:firebase_database/firebase_database.dart';

import 'identity_service.dart';

class ActiveWatcherService {
  ActiveWatcherService._();

  static final _rtdb = FirebaseDatabase.instance;

  static Future<void> addWatcher({
    required String groupId,
    required String locatorId,
  }) async {
    try {
      final requesterId =
          await IdentityService.getOrCreateRequesterId();

      await _rtdb
          .ref(
            'presence/groups/$groupId/active_watchers/$locatorId/$requesterId',
          )
          .set({
        'active': true,
        'lastSeen': ServerValue.timestamp,
      });

      print(
        "BEACON ACTIVE WATCHER => ADD SUCCESS => "
        "$locatorId / $requesterId",
      );
    } catch (e) {
      print("BEACON ACTIVE WATCHER ADD ERROR => $e");
    }
  }

  static Future<void> removeWatcher({
    required String groupId,
    required String locatorId,
  }) async {
    try {
      final requesterId =
          await IdentityService.getOrCreateRequesterId();

      await _rtdb
          .ref(
            'presence/groups/$groupId/active_watchers/$locatorId/$requesterId',
          )
          .remove();

      print(
        "BEACON ACTIVE WATCHER => REMOVE SUCCESS => "
        "$locatorId / $requesterId",
      );
    } catch (e) {
      print("BEACON ACTIVE WATCHER REMOVE ERROR => $e");
    }
  }
}