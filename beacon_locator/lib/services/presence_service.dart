import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'identity_service.dart';
import 'geofence_service.dart';
import 'locator_settings_service.dart';

class PresenceService {
  PresenceService._();

  static final _db = FirebaseDatabase.instance.ref();
	static StreamSubscription<DatabaseEvent>? _connectedSub;

 static Future<void> updateOnline({
  String reason = 'unknown',
}) async {
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();

  if (groupId == null || locatorId == null) {
    print("BEACON PRESENCE => missing group/locator");
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
      print("BEACON PRESENCE => getCurrentPosition failed => $e");
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

        print(
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
    print(
      "BEACON PRESENCE => "
      "skip reason=$reason moved=${movedMeters.toStringAsFixed(1)}m",
    );
    return;
  }

  await _db.child(path).update({
    'status': 'online',
    'lastSeen': ServerValue.timestamp,
    'battery': batteryLevel,
    'gpsEnabled': gpsEnabled,
    'lat': position?.latitude,
    'lng': position?.longitude,
    'accuracy': position?.accuracy,
    'movedSinceLastUpdateMeters': movedMeters?.round(),
    'updateCount': ServerValue.increment(1),
  });

  if (position != null) {
    await GeofenceService.checkPlaces(
      groupId: groupId,
      locatorId: locatorId,
      lat: position.latitude,
      lng: position.longitude,
    );
  }

  print(
    "BEACON PRESENCE => "
    "online updated reason=$reason",
  );
}


static Future<void> startConnectionWatcher() async {
print("BEACON PRESENCE => startConnectionWatcher called");
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();
	
	print(
    "BEACON PRESENCE => watcher ids group=$groupId locator=$locatorId",
  );

  if (groupId == null || locatorId == null) {
    print("BEACON PRESENCE => watcher missing group/locator");
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
	print("BEACON PRESENCE => connected=$connected");

    if (!connected) return;

    await locatorRef.onDisconnect().update({
      'status': 'offline',
      'lastSeen': ServerValue.timestamp,
    });

    await locatorRef.update({
      'status': 'online',
      'lastSeen': ServerValue.timestamp,
    });

    print("BEACON PRESENCE => onDisconnect armed");
  });
}
}
