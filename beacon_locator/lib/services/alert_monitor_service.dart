import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';

import 'alert_service.dart';
import 'locator_settings_service.dart';
import 'identity_service.dart';
import '../utils/log.dart';

class AlertMonitorService {
  AlertMonitorService._();

  static bool _lastGpsEnabled = true;
	static bool _lastBatteryLow = false;
	

  static Future<void> checkNow() async {

	final gpsOffAlertEnabled =
			LocatorSettingsService.gpsOffAlertEnabled &&
			LocatorSettingsService.hasGpsOffNotifyTarget;

	final batteryLowAlertEnabled =
			LocatorSettingsService.batteryLowAlertEnabled &&
			LocatorSettingsService.hasBatteryLowNotifyTarget;

	final batteryLowLevel =
			LocatorSettingsService.batteryLowLevel;
			
		final groupId = await IdentityService.getGroupId();
		final locatorId = await IdentityService.getLocatorId();	
		
		Log.d("groupid:$groupId,locatorId:$locatorId");
		
	Log.d(
		"BEACON ALERT MONITOR => "
		"gpsOffAlertEnabled=$gpsOffAlertEnabled "
		"batteryLowAlertEnabled=$batteryLowAlertEnabled "
		"batteryLowLevel=$batteryLowLevel",
	);		
    try {
			final gpsEnabled =
					await Geolocator.isLocationServiceEnabled();

			Log.d(
				"BEACON ALERT MONITOR => gpsEnabled=$gpsEnabled",
			);

			if (gpsOffAlertEnabled &&
					!gpsEnabled &&
					_lastGpsEnabled) {
				await AlertService.sendGpsOffAlert();
			}

			_lastGpsEnabled = gpsEnabled;
		} catch (e) {
			Log.e(
				"BEACON ALERT MONITOR ERROR => $e",
			);
		}
	
		final batteryLevel =
    await Battery().batteryLevel;

		Log.d(
			"BEACON ALERT MONITOR => battery=$batteryLevel",
		);

		final isBatteryLow =
				batteryLevel <= batteryLowLevel;

		if (batteryLowAlertEnabled &&
				isBatteryLow &&
				!_lastBatteryLow) {
			await AlertService.sendBatteryLowAlert(
				batteryLevel: batteryLevel,
			);
		}

		_lastBatteryLow = isBatteryLow;
		
  }
	
	
}