import 'package:firebase_database/firebase_database.dart';

import 'identity_service.dart';
import '../utils/log.dart';

class ActiveWatcherService {
  ActiveWatcherService._();

  static final _rtdb = FirebaseDatabase.instance;

  static Future<void> addWatcher({
		required String requesterName,
		required String requesterCode,
    required String groupId,
    required String locatorId,
  }) async {
	Log.d("addWatcher called");
    try {
      final requesterId =
          await IdentityService.getRequesterId();

      await _rtdb
          .ref(
            'presence/groups/$groupId/active_watchers/$locatorId/$requesterId',
          )
          .set({
				'requesterName':requesterName,	
				'requesterCode':requesterCode,
        'active': true,
        'lastSeen': ServerValue.timestamp,
      });

      Log.d(
        "BEACON ACTIVE WATCHER => ADD SUCCESS => "
        "$locatorId / $requesterId",
      );
    } catch (e) {
      Log.e("BEACON ACTIVE WATCHER ADD ERROR => $e");
    }
  }

  static Future<void> removeWatcher({
    required String groupId,
    required String locatorId,
  }) async {
    try {
      final requesterId =
          await IdentityService.getRequesterId();

      await _rtdb
          .ref(
            'presence/groups/$groupId/active_watchers/$locatorId/$requesterId',
          )
          .remove();

      Log.d(
        "BEACON ACTIVE WATCHER => REMOVE SUCCESS => "
        "$locatorId / $requesterId",
      );
    } catch (e) {
      Log.e("BEACON ACTIVE WATCHER REMOVE ERROR => $e");
    }
  }
}