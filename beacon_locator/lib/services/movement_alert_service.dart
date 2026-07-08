import 'package:geolocator/geolocator.dart';

import 'alert_service.dart';
import '../utils/log.dart';

// DEBUG ONLY
import 'identity_service.dart';
import 'package:firebase_database/firebase_database.dart';

enum _MovementState {
  unknown,
  stationary,
  moving,
}

class MovementAlertService {
  MovementAlertService._();

  static const double _movementStartMeters = 50;
  static const double _maxAcceptableAccuracy = 80;
  static const Duration _stationaryAfter = Duration(minutes: 10);

  static _MovementState _state = _MovementState.unknown;

  static Position? _stationaryReference;
  static Position? _lastPosition;

  static DateTime? _lastMeaningfulMoveAt;

  static Future<void> checkNow({
    required Position position,
    required String reason,
  }) async {
	Log.d("MovementAlertService.checkNow");
	
/*	// DEBUG ONLY
final groupId = await IdentityService.getGroupId();
final locatorId = await IdentityService.getLocatorId();

if (groupId != null && locatorId != null) {
  final snap = await FirebaseDatabase.instance
      .ref("presence/groups/$groupId/locators/$locatorId")
      .get();

  final data = snap.value;

  if (data is Map) {
    final lat = data["debugLat"];
    final lng = data["debugLng"];

    if (lat is num && lng is num) {
	Log.d("latitude:$lat");
	Log.d("longitude:$lng");
      position = Position(
        latitude: lat.toDouble(),
        longitude: lng.toDouble(),
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        altitudeAccuracy: position.altitudeAccuracy,
        headingAccuracy: position.headingAccuracy,
      );

      Log.d("BEACON MOVEMENT ALERT => DEBUG POSITION");
    }
  }
}*/
	
    final now = DateTime.now();

    if (position.accuracy > _maxAcceptableAccuracy) {
      Log.d(
        "BEACON MOVEMENT ALERT => skip bad accuracy "
        "accuracy=${position.accuracy.toStringAsFixed(1)}",
      );
      return;
    }

    if (_state == _MovementState.unknown) {
      _state = _MovementState.stationary;
      _stationaryReference = position;
      _lastPosition = position;

      Log.d("BEACON MOVEMENT ALERT => state=stationary initial reference set");
      return;
    }

    if (_state == _MovementState.stationary) {
      final reference = _stationaryReference;

      if (reference == null) {
        _stationaryReference = position;
        _lastPosition = position;
        Log.d("BEACON MOVEMENT ALERT => stationary reference reset");
        return;
      }

      final movedFromReference = Geolocator.distanceBetween(
        reference.latitude,
        reference.longitude,
        position.latitude,
        position.longitude,
      );

      Log.d(
        "BEACON MOVEMENT ALERT => "
        "state=stationary "
        "reason=$reason "
        "movedFromRef=${movedFromReference.toStringAsFixed(1)}m",
      );

      if (movedFromReference < _movementStartMeters) {
        return;
      }

      await AlertService.sendMovementAlert(
        movedMeters: movedFromReference,
        detectedWhileOffline: false,
      );

      _state = _MovementState.moving;
      _lastMeaningfulMoveAt = now;
      _lastPosition = position;

      Log.d("BEACON MOVEMENT ALERT => state=moving alert sent");
      return;
    }

    if (_state == _MovementState.moving) {
      final lastPosition = _lastPosition;

      if (lastPosition == null) {
        _lastPosition = position;
        _lastMeaningfulMoveAt = now;
        Log.d("BEACON MOVEMENT ALERT => moving last position reset");
        return;
      }

      final movedFromLast = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );

      Log.d(
        "BEACON MOVEMENT ALERT => "
        "state=moving "
        "reason=$reason "
        "movedFromLast=${movedFromLast.toStringAsFixed(1)}m",
      );

      if (movedFromLast >= _movementStartMeters) {
        _lastMeaningfulMoveAt = now;
        _lastPosition = position;
        return;
      }

      final lastMoveAt = _lastMeaningfulMoveAt;

      if (lastMoveAt != null &&
          now.difference(lastMoveAt) >= _stationaryAfter) {
        _state = _MovementState.stationary;
        _stationaryReference = position;
        _lastPosition = position;

        Log.d("BEACON MOVEMENT ALERT => state=stationary new reference set");
      }
    }
  }
}