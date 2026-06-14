import 'package:firebase_database/firebase_database.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'identity_service.dart';
import 'geofence_service.dart';
import 'locator_settings_service.dart';

class PresenceService {
  PresenceService._();

  static final _db = FirebaseDatabase.instance.ref();

 static Future<void> updateOnline() async {
	print("LynraFamiy Member updateOnline called");
  final groupId = await IdentityService.getGroupId();
  final locatorId = await IdentityService.getLocatorId();

  if (groupId == null || locatorId == null) {
    print(
      "BEACON PRESENCE => "
      "missing group/locator",
    );
    return;
  }

  final batteryLevel = await Battery().batteryLevel;
  final gpsEnabled = await Geolocator.isLocationServiceEnabled();

  Position? position;

  if (gpsEnabled) {
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print(
        "BEACON PRESENCE => "
        "getCurrentPosition failed => $e",
      );
    }
  }

  print(
    "BEACON PRESENCE => "
    "battery=$batteryLevel "
    "gps=$gpsEnabled",
  );

  await _db.child("presence/groups/$groupId/locators/$locatorId").set({
    'status': 'online',
    'lastSeen': ServerValue.timestamp,
    'battery': batteryLevel,
    'gpsEnabled': gpsEnabled,
    'lat': position?.latitude,
    'lng': position?.longitude,
    'accuracy': position?.accuracy,
  });

  print(
    "BEACON PRESENCE => "
    "online updated",
  );
}
}
