import 'dart:async';

import 'presence_service.dart';
import 'alert_monitor_service.dart';
import '../utils/log.dart';

class SmartPresenceScheduler {
  SmartPresenceScheduler._();

  static Timer? _timer;

  static DateTime? _fastUntil;

  static bool _hasActiveWatcher = false;
  static bool _isUpdating = false;
	
	static const _vehiclePeriod =
    Duration(seconds: 15);

  static const _fastPeriod =
      Duration(seconds: 60);

  static const _slowPeriod =
      Duration(hours: 1);
			


  static const _fastWindow =
      Duration(minutes: 2);
			
	static double _speedKmh = 0;

	static void setSpeedKmh(double value) {
		_speedKmh = value;
	}		

  static void start() {
    Log.d("SMART PRESENCE => start");

    _scheduleNext(
      immediate: true,
      reason: 'start',
    );
  }

  static void stop() {
    Log.d("SMART PRESENCE => stop");

    _timer?.cancel();
    _timer = null;
  }

  static Future<void> boostAndUpdateNow({
    required String reason,
  }) async {
    Log.d(
      "SMART PRESENCE => boost => $reason",
    );

    _fastUntil =
        DateTime.now().add(_fastWindow);

    await _runUpdate(
      reason: reason,
    );

    _scheduleNext(
      immediate: false,
      reason: reason,
    );
  }

  static Future<void> _runUpdate({
    required String reason,
  }) async {
    if (_isUpdating) {
      Log.d(
        "SMART PRESENCE => skip update reason=$reason",
      );
      return;
    }

    _isUpdating = true;

    try {
      await PresenceService.updateOnline(
				reason: reason,
			);

      await AlertMonitorService.checkNow();
    } finally {
      _isUpdating = false;
    }
  }

  static void _scheduleNext({
		required bool immediate,
		required String reason,
	}) {
		_timer?.cancel();

		final now = DateTime.now();

		final isFast =
				_hasActiveWatcher ||
				(_fastUntil != null && now.isBefore(_fastUntil!));

		Duration period;

		if (isFast) {
			if (_hasActiveWatcher && _speedKmh >= 20) {
				period = _vehiclePeriod;
			} else {
				period = _fastPeriod;
			}
		} else {
			period = _slowPeriod;
		}

		Log.d(
			"SMART PRESENCE => schedule "
			"period=${period.inSeconds}s "
			"reason=$reason",
		);

		_timer = Timer(
			immediate ? Duration.zero : period,
			() async {
				await _runUpdate(
					reason: 'timer',
				);

				_scheduleNext(
					immediate: false,
					reason: 'timer',
				);
			},
		);
	}
  static void setActiveWatcher(bool value) {
		final wasActive = _hasActiveWatcher;

		_hasActiveWatcher = value;

		Log.d(
			"SMART PRESENCE => activeWatcher=$value",
		);

		if (!wasActive && value) {
			boostAndUpdateNow(
				reason: 'active_watcher_started',
			);
		} else if (wasActive && !value) {
			_scheduleNext(
				immediate: false,
				reason: 'active_watcher_off',
			);
		}
	}
}