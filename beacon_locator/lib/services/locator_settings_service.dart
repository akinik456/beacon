import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';

class LocatorSettingsService {
  LocatorSettingsService._();

  static final _firestore = FirebaseFirestore.instance;
	
	static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
    _settingsSub;

	static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
			_notifySub;

	static bool _gpsOffAlertEnabled = true;
	static bool _batteryLowAlertEnabled = true;
	static int _batteryLowLevel = 20;
	static bool _geofenceAlertEnabled = false;

	static bool _hasGpsOffNotifyTarget = false;
	static bool _hasBatteryLowNotifyTarget = false;
	static bool _hasGeofenceNotifyTarget = false;
	static bool _hasCallMeNotifyTarget = false;

	static bool get gpsOffAlertEnabled => _gpsOffAlertEnabled;
	static bool get batteryLowAlertEnabled => _batteryLowAlertEnabled;
	static int get batteryLowLevel => _batteryLowLevel;
	static bool get geofenceAlertEnabled => _geofenceAlertEnabled;

	static bool get hasGpsOffNotifyTarget => _hasGpsOffNotifyTarget;
	static bool get hasBatteryLowNotifyTarget => _hasBatteryLowNotifyTarget;
	static bool get hasGeofenceNotifyTarget => _hasGeofenceNotifyTarget;
	static bool get hasCallMeNotifyTarget => _hasCallMeNotifyTarget;
	
	static Future<void> startListeners() async {
		final locatorId = await IdentityService.getLocatorId();
		final groupId = await IdentityService.getGroupId();

		if (locatorId == null || groupId == null) {
			print("LOCATOR SETTINGS => missing locatorId/groupId");
			return;
		}

		await stopListeners();

		final locatorRef = _firestore
				.collection('groups')
				.doc(groupId)
				.collection('devices')
				.doc(locatorId);

		_settingsSub = locatorRef
				.collection('settings')
				.doc('config')
				.snapshots()
				.listen((doc) {
			final data = doc.data() ?? {};

			_gpsOffAlertEnabled = data['gpsOffAlert'] ?? true;
			_batteryLowAlertEnabled = data['batteryLowAlert'] ?? true;
			_batteryLowLevel = data['batteryLowLevel'] ?? 20;
			_geofenceAlertEnabled = data['geofenceAlert'] ?? false;

			print(
				"LOCATOR SETTINGS => "
				"gps=$_gpsOffAlertEnabled "
				"battery=$_batteryLowAlertEnabled "
				"level=$_batteryLowLevel "
				"geo=$_geofenceAlertEnabled",
			);
		});

		_notifySub = locatorRef
				.collection('notifyRequesters')
				.snapshots()
				.listen((snapshot) {
			bool gps = false;
			bool battery = false;
			bool geo = false;
			bool callMe = false;

			for (final doc in snapshot.docs) {
				final data = doc.data();

				if (data['gpsOff'] == true) gps = true;
				if (data['batteryLow'] == true) battery = true;
				if (data['geofence'] == true) geo = true;
				if (data['callMe'] == true) callMe = true;
			}

			_hasGpsOffNotifyTarget = gps;
			_hasBatteryLowNotifyTarget = battery;
			_hasGeofenceNotifyTarget = geo;
			_hasCallMeNotifyTarget = callMe;

			print(
				"LOCATOR NOTIFY TARGETS => "
				"gps=$gps "
				"battery=$battery "
				"geo=$geo "
				"callMe=$callMe",
			);
		});
	}

	static Future<void> stopListeners() async {
		await _settingsSub?.cancel();
		await _notifySub?.cancel();

		_settingsSub = null;
		_notifySub = null;
	}
	

  static Future<Map<String, dynamic>> loadSettings() async {
    final locatorId = await IdentityService.getLocatorId();
    final groupId = await IdentityService.getGroupId();

    if (locatorId == null || groupId == null) {
      return _defaultSettings();
    }

    final doc = await _firestore
        .collection('groups')
        .doc(groupId)
        .collection('devices')
        .doc(locatorId)
        .collection('settings')
        .doc('config')
        .get();

    if (!doc.exists) {
      return _defaultSettings();
    }

    final data = doc.data() ?? {};

    return {
      'gpsOffAlert': data['gpsOffAlert'] ?? true,
      'batteryLowAlert': data['batteryLowAlert'] ?? true,
      'batteryLowLevel': data['batteryLowLevel'] ?? 20,
      'geofenceAlert': data['geofenceAlert'] ?? false,
    };
  }

  static Map<String, dynamic> _defaultSettings() {
    return {
      'gpsOffAlert': true,
      'batteryLowAlert': true,
      'batteryLowLevel': 20,
      'geofenceAlert': false,
    };
  }
}