import 'package:geolocator/geolocator.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_service.dart';
import 'locator_settings_service.dart';
import 'identity_service.dart';
import '../utils/log.dart';

class AlertMonitorService {
  AlertMonitorService._();
	
	static const String _gpsOffSentKey =
    'alert_gps_off_sent';

	static const String _batteryLowSentKey =
    'alert_battery_low_sent';

  static Future<void> checkNow() async {
	
	final prefs = await SharedPreferences.getInstance();

	final gpsOffSent =
			prefs.getBool(_gpsOffSentKey) ?? false;

	final batteryLowSent =
			prefs.getBool(_batteryLowSentKey) ?? false;

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

			if (gpsOffAlertEnabled && !gpsEnabled) {
				if (!gpsOffSent) {
					await AlertService.sendGpsOffAlert();
					await prefs.setBool(_gpsOffSentKey, true);
				}
				else
				{				
					Log.d(
						"BEACON ALERT MONITOR => "
						"gps_off skipped , sent already",
					);
				}
			} else if (gpsEnabled && gpsOffSent) {
				await prefs.setBool(_gpsOffSentKey, false);

				Log.d(
					"BEACON ALERT MONITOR => "
					"gps_off sent flag reset",
				);
			}
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

		if (batteryLowAlertEnabled && isBatteryLow) {
			if (!batteryLowSent) {
				await AlertService.sendBatteryLowAlert(
					batteryLevel: batteryLevel,
				);

				await prefs.setBool(
					_batteryLowSentKey,
					true,
				);
			}
			else
			{				
				Log.d(
					"BEACON ALERT MONITOR => "
					"battery_low skipped , sent already",
				);
			}
		} else if (!isBatteryLow && batteryLowSent) {
			await prefs.setBool(
				_batteryLowSentKey,
				false,
			);

			Log.d(
				"BEACON ALERT MONITOR => "
				"battery_low sent flag reset",
			);
		}		
  }	
}