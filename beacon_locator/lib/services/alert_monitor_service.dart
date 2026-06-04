import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

import 'alert_service.dart';
import 'locator_settings_service.dart';

class AlertMonitorService {
  AlertMonitorService._();

  static bool _lastGpsEnabled = true;
	
	

  static Future<void> checkNow() async {
	
	final gpsOffAlertEnabled =
			LocatorSettingsService.gpsOffAlertEnabled &&
			LocatorSettingsService.hasGpsOffNotifyTarget;

	final batteryLowAlertEnabled =
			LocatorSettingsService.batteryLowAlertEnabled &&
			LocatorSettingsService.hasBatteryLowNotifyTarget;

	final batteryLowLevel =
			LocatorSettingsService.batteryLowLevel;
		
    try {
			final gpsEnabled =
					await Geolocator.isLocationServiceEnabled();

			print(
				"BEACON ALERT MONITOR => gpsEnabled=$gpsEnabled",
			);

			if (gpsOffAlertEnabled &&
					!gpsEnabled &&
					_lastGpsEnabled) {
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

		if (batteryLowAlertEnabled &&
				batteryLevel <= batteryLowLevel) {
			await AlertService.sendBatteryLowAlert(batteryLevel: batteryLevel);
		}
		
  }
	
	
}