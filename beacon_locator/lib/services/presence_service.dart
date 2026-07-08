import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'identity_service.dart';
import 'geofence_service.dart';
import 'locator_settings_service.dart';
import 'movement_alert_service.dart';
import '../utils/log.dart';
import 'smart_presence_scheduler.dart';

class PresenceService {
  PresenceService._();

  static final _db = FirebaseDatabase.instance.ref();
	static StreamSubscription<DatabaseEvent>? _connectedSub;
	static String? _serviceGroupId;
	static String? _serviceLocatorId;

 static Future<void> updateOnline({
  String reason = 'unknown',
}) async {

Log.d(
  "BEACON PRESENCE => "
  "cachedGroup=$_serviceGroupId "
  "cachedLocator=$_serviceLocatorId",
);
  final groupId =
    _serviceGroupId ?? await IdentityService.getGroupId();

	final locatorId =
			_serviceLocatorId ?? await IdentityService.getLocatorId();
		Log.d("updateOnline called");

  if (groupId == null || locatorId == null) {
    Log.d("BEACON PRESENCE => missing group/locator");
		Log.d("BEACON LOCAL IDS => group=$groupId locator=$locatorId");
    return;
  }

  final path = "presence/groups/$groupId/locators/$locatorId";

  final batteryLevel = await Battery().batteryLevel;
  final gpsEnabled = await Geolocator.isLocationServiceEnabled();

  Position? position;

  if (gpsEnabled) {
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      Log.e("BEACON PRESENCE => getCurrentPosition failed => $e");
    }
		double speedKmh = 0;

			if (position != null) {
				final speedMps = position.speed;

				final speedKmh = speedMps >= 0
					? speedMps * 3.6
					: 0.0;

				SmartPresenceScheduler.setSpeedKmh(speedKmh);

				Log.d(
					"BEACON PRESENCE => "
					"speed=${speedKmh.toStringAsFixed(1)} km/h",
				);
				SmartPresenceScheduler.setSpeedKmh(speedKmh);
			}
		
  }

  double? movedMeters;

  if (position != null) {
    final snapshot = await _db.child(path).get();
    final data = snapshot.value;

    if (data is Map) {
      final oldLat = data['lat'];
      final oldLng = data['lng'];

      if (oldLat is num && oldLng is num) {
        movedMeters = Geolocator.distanceBetween(
          oldLat.toDouble(),
          oldLng.toDouble(),
          position.latitude,
          position.longitude,
        );

        Log.d(
          "BEACON PRESENCE => "
          "reason=$reason "
          "moved=${movedMeters.toStringAsFixed(1)}m",
        );
      }
    }
  }

  final shouldSkipSmallMove =
      (reason == 'timer' || reason == 'motion') &&
      movedMeters != null &&
      movedMeters < 25;

  if (shouldSkipSmallMove) {
    Log.d(
      "BEACON PRESENCE => "
      "skip reason=$reason moved=${movedMeters.toStringAsFixed(1)}m",
    );
    return;
  }

  final updateData = {
		'status': 'online',
		'lastSeen': ServerValue.timestamp,
		'battery': batteryLevel,
		'gpsEnabled': gpsEnabled,
		'lat': position?.latitude,
		'lng': position?.longitude,
		'accuracy': position?.accuracy,
		'movedSinceLastUpdateMeters': movedMeters?.round(),
		'updateCount': ServerValue.increment(1),
	};

	if (movedMeters == null || movedMeters >= 25) {
		updateData['stationarySince'] = ServerValue.timestamp;
	}

	await _db.child(path).update(updateData);
Log.d("RTDB updated");
  if (position != null) {
    await GeofenceService.checkPlaces(
      groupId: groupId,
      locatorId: locatorId,
      lat: position.latitude,
      lng: position.longitude,
    );
		
		 await MovementAlertService.checkNow(
			position: position,
			reason: reason,
		);
  }
	Log.d(
		"MovementAlertService.checkNow is called ? "
		"lat=${position?.latitude},lng=${position?.longitude}",
	);
  Log.d(
    "BEACON PRESENCE => "
    "online updated reason=$reason",
  );
}

static void setServiceIds({
  required String groupId,
  required String locatorId,
}) {
  _serviceGroupId = groupId;
  _serviceLocatorId = locatorId;

  Log.d(
    "BEACON PRESENCE => service ids set "
    "group=$groupId locator=$locatorId",
  );
}
static Future<void> startConnectionWatcher() async {
Log.d("BEACON PRESENCE => startConnectionWatcher called");
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();
	
	Log.d(
    "BEACON PRESENCE => watcher ids group=$groupId locator=$locatorId",
  );

  if (groupId == null || locatorId == null) {
    Log.d("BEACON PRESENCE => watcher missing group/locator");
    return;
  }

  final locatorRef = _db.child(
    "presence/groups/$groupId/locators/$locatorId",
  );

  final connectedRef =
      FirebaseDatabase.instance.ref(".info/connected");

  await _connectedSub?.cancel();

  _connectedSub = connectedRef.onValue.listen((event) async {
    final connected =
        event.snapshot.value as bool? ?? false;
	Log.d("BEACON PRESENCE => connected=$connected");

    if (!connected) return;

    await locatorRef.onDisconnect().update({
			'status': 'offline',
			'lastSeen': ServerValue.timestamp,
			'offlineSince': ServerValue.timestamp,
		});

    await locatorRef.update({
      'status': 'online',
      'lastSeen': ServerValue.timestamp,
			'offlineSince': null,
    });

    Log.d("BEACON PRESENCE => onDisconnect armed");
  });
}
}
