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
	static Position? _movementCandidate;

  static DateTime? _lastMeaningfulMoveAt;

  static Future<void> checkNow({
    required Position position,
    required String reason,
  }) async {
	Log.d("MovementAlertService.checkNow");
	
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
			
			final effectiveAccuracy = position.accuracy * 2;

			final isReliableMove =
					movedFromReference != null &&
					movedFromReference >= 50 &&
					movedFromReference > effectiveAccuracy;

      Log.d(
        "BEACON MOVEMENT ALERT => "
        "state=stationary "
        "reason=$reason "
        "movedFromRef=${movedFromReference.toStringAsFixed(1)}m",
      );

      if (movedFromReference < _movementStartMeters) {
				_movementCandidate = null;
				return;
			}

			if (!isReliableMove) {
				_movementCandidate = null;
				return;
			}

			final candidate = _movementCandidate;

			if (candidate == null) {
				_movementCandidate = position;

				Log.d(
					"BEACON MOVEMENT ALERT => "
					"movement candidate set "
					"movedFromRef=${movedFromReference.toStringAsFixed(1)}m",
				);

				return;
			}

			final distanceFromCandidate = Geolocator.distanceBetween(
				candidate.latitude,
				candidate.longitude,
				position.latitude,
				position.longitude,
			);

			final candidateConfirmed =
					distanceFromCandidate <= 25 &&
					movedFromReference >= _movementStartMeters;

			if (!candidateConfirmed) {
				_movementCandidate = position;

				Log.d(
					"BEACON MOVEMENT ALERT => "
					"movement candidate replaced "
					"distanceFromCandidate=${distanceFromCandidate.toStringAsFixed(1)}m",
				);

				return;
			}

			await AlertService.sendMovementAlert(
				movedMeters: movedFromReference,
				detectedWhileOffline: false,
			);

			_movementCandidate = null;
			_state = _MovementState.moving;
			_lastMeaningfulMoveAt = now;
			_lastPosition = position;

			Log.d(
				"BEACON MOVEMENT ALERT => "
				"state=moving confirmed alert sent",
			);

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