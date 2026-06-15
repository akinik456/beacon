import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

import 'identity_service.dart';
import 'smart_presence_scheduler.dart';

class ActiveWatcherService {
  ActiveWatcherService._();

  static StreamSubscription<DatabaseEvent>? _sub;

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
      print("BEACON WATCHER => missing group/locator");
      return;
    }

    final ref = FirebaseDatabase.instance.ref(
      "presence/groups/$groupId/active_watchers/$locatorId",
    );

    print(
      "BEACON WATCHER => listening "
      "updateScheduler=$updateScheduler",
    );

    _sub = ref.onValue.listen((event) {
      final value = event.snapshot.value;

      final hasWatcher =
          value is Map && value.isNotEmpty;

      print(
        "BEACON WATCHER => hasWatcher=$hasWatcher "
        "updateScheduler=$updateScheduler",
      );

      if (updateScheduler) {
        SmartPresenceScheduler.setActiveWatcher(
          hasWatcher,
        );
      }

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

      activeWatchers.value = watchers;
    });
  }

  static Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    activeWatchers.value = [];
  }
}