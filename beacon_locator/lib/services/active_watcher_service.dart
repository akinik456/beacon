import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'identity_service.dart';
import 'notification_service.dart';
import 'smart_presence_scheduler.dart';
import '../utils/log.dart';

class ActiveWatcherService {
  ActiveWatcherService._();

  static StreamSubscription<DatabaseEvent>? _sub;
	
	static String _langCode = 'en';

	static void setLangCode(String langCode) {
		_langCode = langCode;
	}

  static final ValueNotifier<List<Map<String, dynamic>>>
      activeWatchers = ValueNotifier([]);

  static Future<void> start() async {
    await _startInternal(
      updateScheduler: true,
    );
  }

  static Future<void> startUiOnly() async {
    await _startInternal(
      updateScheduler: false,
    );
  }

  static Future<void> _startInternal({
    required bool updateScheduler,
  }) async {
    await stop();

    final groupId = await IdentityService.getGroupId();
    final locatorId = await IdentityService.getLocatorId();

    if (groupId == null || locatorId == null) {
      Log.d("BEACON WATCHER => missing group/locator");
      return;
    }

    final ref = FirebaseDatabase.instance.ref(
      "presence/groups/$groupId/active_watchers/$locatorId",
    );

    Log.d(
      "BEACON WATCHER => listening "
      "updateScheduler=$updateScheduler",
    );
		Log.d("groupid:$groupId");

    _sub = ref.onValue.listen((event) async {
      final watchers = _parseWatchers(event.snapshot.value);

      final hasWatcher = watchers.isNotEmpty;

      Log.d(
        "BEACON WATCHER => hasWatcher=$hasWatcher "
        "updateScheduler=$updateScheduler",
      );

      if (updateScheduler) {
        SmartPresenceScheduler.setActiveWatcher(
          hasWatcher,
        );
      }

      activeWatchers.value = watchers;

      await _updateNotificationFromWatchers(watchers);
    });
  }

  static Future<void> updateNotificationFromServer() async {
    final groupId = await IdentityService.getGroupId();
    final locatorId = await IdentityService.getLocatorId();

    if (groupId == null || locatorId == null) {
      Log.d(
        "BEACON WATCHER => notification skip missing group/locator",
      );

      await NotificationService.cancelActiveWatchers();
      return;
    }

    final ref = FirebaseDatabase.instance.ref(
      "presence/groups/$groupId/active_watchers/$locatorId",
    );

    final snapshot = await ref.get();

    final watchers = _parseWatchers(snapshot.value);

    activeWatchers.value = watchers;

    await _updateNotificationFromWatchers(watchers);
  }

  static List<Map<String, dynamic>> _parseWatchers(
    Object? value,
  ) {
    final watchers = <Map<String, dynamic>>[];

    if (value is Map) {
      for (final entry in value.entries) {
        final data = entry.value;

        if (data is Map) {
          watchers.add(
            Map<String, dynamic>.from(data),
          );
        }
      }
    }

    return watchers;
  }

  static Future<void> _updateNotificationFromWatchers(
    List<Map<String, dynamic>> watchers,
  ) async {
    if (watchers.isEmpty) {
      await NotificationService.cancelActiveWatchers();
      return;
    }

    final names = watchers
        .map(
          (watcher) =>
              (watcher['requesterName'] ?? 'Requester')
                  .toString()
                  .trim(),
        )
        .where((name) => name.isNotEmpty)
        .toList();

    if (names.isEmpty) {
      await NotificationService.cancelActiveWatchers();
      return;
    }

    await NotificationService.showActiveWatchers(
      names: names,
			langCode: _langCode,
    );
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    activeWatchers.value = [];

    await NotificationService.cancelActiveWatchers();
  }
}