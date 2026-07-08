import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'identity_service.dart';
import '../utils/log.dart';

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
	static bool _movementAlertEnabled = false;
	
	static bool _hasGpsOffNotifyTarget = false;
	static bool _hasBatteryLowNotifyTarget = false;
	static bool _hasGeofenceNotifyTarget = false;
	static bool _hasMovementNotifyTarget = false;
	static bool _hasCallMeNotifyTarget = false;

	static bool get gpsOffAlertEnabled => _gpsOffAlertEnabled;
	static bool get batteryLowAlertEnabled => _batteryLowAlertEnabled;
	static int get batteryLowLevel => _batteryLowLevel;
	static bool get geofenceAlertEnabled => _geofenceAlertEnabled;
	static bool get movementAlertEnabled => _movementAlertEnabled;


	static bool get hasGpsOffNotifyTarget => _hasGpsOffNotifyTarget;
	static bool get hasBatteryLowNotifyTarget => _hasBatteryLowNotifyTarget;
	static bool get hasGeofenceNotifyTarget => _hasGeofenceNotifyTarget;
	static bool get hasMovementNotifyTarget => _hasMovementNotifyTarget;
	static bool get hasCallMeNotifyTarget => _hasCallMeNotifyTarget;
	
	static Future<void> startListeners() async {
		final locatorId = await IdentityService.getLocatorId();
		final groupId = await IdentityService.getGroupId();

		if (locatorId == null || groupId == null) {
			Log.d("LOCATOR SETTINGS => missing locatorId/groupId");
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
			_movementAlertEnabled = data['movementAlert'] ?? false;

			Log.d(
				"LOCATOR SETTINGS => "
				"gps=$_gpsOffAlertEnabled "
				"battery=$_batteryLowAlertEnabled "
				"level=$_batteryLowLevel "
				"geo=$_geofenceAlertEnabled"
				"move=$_movementAlertEnabled",
				
			);
		});

		_notifySub = locatorRef
				.collection('notifyRequesters')
				.snapshots()
				.listen((snapshot) {
			bool gps = false;
			bool battery = false;
			bool geo = false;
			bool move = false;
			bool callMe = false;

			for (final doc in snapshot.docs) {
				final data = doc.data();

				if (data['gpsOff'] == true) gps = true;
				if (data['batteryLow'] == true) battery = true;
				if (data['geofence'] == true) geo = true;
				if (data['movement'] == true) move = true;
				if (data['callMe'] == true) callMe = true;
			}

			_hasGpsOffNotifyTarget = gps;
			_hasBatteryLowNotifyTarget = battery;
			_hasGeofenceNotifyTarget = geo;
			_hasMovementNotifyTarget =move;
			_hasCallMeNotifyTarget = callMe;

			Log.d(
				"LOCATOR NOTIFY TARGETS => "
				"gps=$gps "
				"battery=$battery "
				"geo=$geo "
				"move=$move"
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
			'movementAlert': data['movementAlert'] ?? false,
    };
  }

  static Map<String, dynamic> _defaultSettings() {
    return {
      'gpsOffAlert': true,
      'batteryLowAlert': true,
      'batteryLowLevel': 20,
      'geofenceAlert': false,
			'movementAlert': false,
    };
  }
}