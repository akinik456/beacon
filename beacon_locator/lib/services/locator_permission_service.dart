import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocatorPermissionService {
  LocatorPermissionService._();

  static Future<bool> hasAllRequiredPermissions() async {
    final locationAlways = await Permission.locationAlways.status;
    final activity = await Permission.activityRecognition.status;
    final notification = await Permission.notification.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;
		final autoStart = await isAutoStartMarkedOk();

		final memoryLock = await isMemoryLockMarkedOk();
    return locationAlways.isGranted &&
        activity.isGranted &&
        notification.isGranted &&
        battery.isGranted&&
			autoStart &&
			memoryLock;
		}
	
	static Future<bool> isLocationAlwaysGranted() async {
		final status = await Permission.locationAlways.status;
		return status.isGranted;
	}

  static Future<void> requestLocationAlways() async {
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
  }
	
	static Future<bool> isActivityRecognitionGranted() async {
		final status = await Permission.activityRecognition.status;
		return status.isGranted;
	}

  static Future<void> requestActivityRecognition() async {
    await Permission.activityRecognition.request();
  }
	
	static Future<bool> isNotificationGranted() async {
		final status = await Permission.notification.status;
		return status.isGranted;
	}	

  static Future<void> requestNotification() async {
    await Permission.notification.request();
  }
	
	static Future<bool> isBatteryOptimizationDisabled() async {
		final status =
				await Permission.ignoreBatteryOptimizations.status;

		return status.isGranted;
	}

  static Future<void> requestIgnoreBatteryOptimization() async {
    await Permission.ignoreBatteryOptimizations.request();
  }

  static Future<void> openAppSettingsPage() async {
    await openAppSettings();
  }
	
	static Future<void> openAutoStartSettings() async {
		if (!Platform.isAndroid) return;

		final deviceInfo = await DeviceInfoPlugin().androidInfo;
		final manufacturer =
				deviceInfo.manufacturer.toLowerCase();

		if (manufacturer.contains('xiaomi') ||
				manufacturer.contains('redmi') ||
				manufacturer.contains('poco')) {
			try {
				await const AndroidIntent(
					action: 'miui.intent.action.OP_AUTO_START',
					package: 'com.miui.securitycenter',
				).launch();
			} catch (e) {
				await openAppSettings();
			}
			return;
		}

		if (manufacturer.contains('samsung')) {
			await openAppSettings();
			return;
		}

		await openAppSettings();
	}
	
	static Future<bool> isAutoStartMarkedOk() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getBool('autostart_ok') ?? false;
	}

	static Future<void> setAutoStartMarkedOk(bool value) async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool('autostart_ok', value);
	}

	static Future<bool> isMemoryLockMarkedOk() async {
		final prefs = await SharedPreferences.getInstance();
		return prefs.getBool('memory_lock_ok') ?? false;
	}

	static Future<void> setMemoryLockMarkedOk(bool value) async {
		final prefs = await SharedPreferences.getInstance();
		await prefs.setBool('memory_lock_ok', value);
	}
	
}