import 'dart:async';

import 'presence_service.dart';
import 'alert_monitor_service.dart';

class SmartPresenceScheduler {
  SmartPresenceScheduler._();

  static Timer? _timer;

  static DateTime? _fastUntil;
	
	static bool _hasActiveWatcher = false;

  static const _fastPeriod =
      Duration(seconds: 30);

  static const _slowPeriod =
      Duration(hours: 1);

  static const _fastWindow =
      Duration(minutes: 2);

  static void start() {
    print("SMART PRESENCE => start");

    _scheduleNext(
      immediate: true,
      reason: 'start',
    );
  }

  static void stop() {
    print("SMART PRESENCE => stop");

    _timer?.cancel();
    _timer = null;
  }

  static Future<void> boostAndUpdateNow({
    required String reason,
  }) async {
    print(
      "SMART PRESENCE => boost => $reason",
    );

    _fastUntil =
        DateTime.now().add(_fastWindow);

    await PresenceService.updateOnline();
		
		await AlertMonitorService.checkNow();

    _scheduleNext(
      immediate: false,
      reason: reason,
    );
  }

  static void _scheduleNext({
    required bool immediate,
    required String reason,
  }) {
    _timer?.cancel();

    final now = DateTime.now();

    final isFast =
    _hasActiveWatcher ||
    (_fastUntil != null &&
     now.isBefore(_fastUntil!));

    final period =
        isFast ? _fastPeriod : _slowPeriod;

    print(
      "SMART PRESENCE => schedule "
      "period=${period.inSeconds}s "
      "reason=$reason",
    );

    _timer = Timer(
      immediate ? Duration.zero : period,
      () async {
        await PresenceService.updateOnline();
				
				await AlertMonitorService.checkNow();

        _scheduleNext(
          immediate: false,
          reason: 'timer',
        );
      },
    );
  }

	static void setActiveWatcher(bool value) {
		_hasActiveWatcher = value;

		print(
			"SMART PRESENCE => activeWatcher=$value",
		);

		if (value) {
			boostAndUpdateNow(
				reason: 'active_watcher',
			);
		} else {
			_scheduleNext(
				immediate: false,
				reason: 'active_watcher_off',
			);
		}
	}
	
}