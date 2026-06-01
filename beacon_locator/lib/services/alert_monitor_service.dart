import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

import 'alert_service.dart';

class AlertMonitorService {
  AlertMonitorService._();

  static Timer? _timer;

  static bool _lastGpsEnabled = true;

  static void start() {
    stop();

    print("BEACON ALERT MONITOR => start");

    _checkNow();

    _timer = Timer.periodic(
      const Duration(seconds: 60),
      (_) {
        _checkNow();
      },
    );
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }

  static Future<void> _checkNow() async {
    try {
      final gpsEnabled =
          await Geolocator.isLocationServiceEnabled();

      print(
        "BEACON ALERT MONITOR => gpsEnabled=$gpsEnabled",
      );

      if (!gpsEnabled && _lastGpsEnabled) {
        await AlertService.sendGpsOffAlert();
      }

      _lastGpsEnabled = gpsEnabled;
    } catch (e) {
      print(
        "BEACON ALERT MONITOR ERROR => $e",
      );
    }
	
		final batteryLevel =
				await Battery().batteryLevel;

		print(
			"BEACON ALERT MONITOR => battery=$batteryLevel",
		);

		if (batteryLevel <= 20) {
			await AlertService.sendBatteryLowAlert(
				batteryLevel: batteryLevel,
			);
		}	
		
  }
	
	
}