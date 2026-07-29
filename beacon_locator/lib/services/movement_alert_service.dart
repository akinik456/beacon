import 'package:geolocator/geolocator.dart';

import 'alert_service.dart';
import '../utils/log.dart';
import 'app_log_service.dart';

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

  static const double _movementStartMeters = 70;
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
    Log.d(
      "BEACON_MOVEMENT_ALERT => checkNow",
    );

    await AppLogService.log(
      type: AppLogType.gps,
      text: "BEACON_MOVEMENT_ALERT => checkNow",
    );

    final now = DateTime.now();

    if (position.accuracy > _maxAcceptableAccuracy) {
      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "skip bad accuracy, "
        "accuracy=${position.accuracy.toStringAsFixed(1)}",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
            "skip bad accuracy, "
            "accuracy=${position.accuracy.toStringAsFixed(1)}",
      );

      return;
    }

    // ============================================================
    // INITIAL STATE
    // ============================================================

    if (_state == _MovementState.unknown) {
      _state = _MovementState.stationary;
      _stationaryReference = position;
      _lastPosition = position;

      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "state=stationary initial reference set",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
            "state=stationary initial reference set",
      );

      return;
    }

    // ============================================================
    // STATIONARY STATE
    // ============================================================

    if (_state == _MovementState.stationary) {
      final reference = _stationaryReference;

      if (reference == null) {
        _stationaryReference = position;
        _lastPosition = position;

        Log.d(
          "BEACON_MOVEMENT_ALERT => "
          "stationary reference reset",
        );

        await AppLogService.log(
          type: AppLogType.gps,
          text:
              "BEACON_MOVEMENT_ALERT => "
              "stationary reference reset",
        );

        return;
      }

      final movedFromReference = Geolocator.distanceBetween(
        reference.latitude,
        reference.longitude,
        position.latitude,
        position.longitude,
      );

      final effectiveAccuracy = position.accuracy * 2;

      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "effectiveAccuracy=${effectiveAccuracy.toStringAsFixed(1)}m",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
            "effectiveAccuracy=${effectiveAccuracy.toStringAsFixed(1)}m",
      );

      final isReliableMove =
          movedFromReference >= _movementStartMeters &&
          movedFromReference > effectiveAccuracy;

      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "state=stationary "
        "reason=$reason "
        "movedFromRef=${movedFromReference.toStringAsFixed(1)}m",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
            "state=stationary "
            "reason=$reason "
            "movedFromRef=${movedFromReference.toStringAsFixed(1)}m",
      );

      if (movedFromReference < _movementStartMeters) {
        return;
      }

      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "isReliableMove=$isReliableMove",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
            "isReliableMove=$isReliableMove",
      );

      if (!isReliableMove) {
        return;
      }

      // Referans noktasından 50 metre veya daha fazla uzaklaşıldı
      // ve ölçüm accuracy değerine göre güvenilir.
      // Candidate doğrulaması beklenmeden alarm gönderilir.

      await AlertService.sendMovementAlert(
        movedMeters: movedFromReference,
        detectedWhileOffline: false,
      );

      _state = _MovementState.moving;
      _lastMeaningfulMoveAt = now;
      _lastPosition = position;

      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "state=moving reliable movement alert sent",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
            "state=moving reliable movement alert sent",
      );

      return;
    }

    // ============================================================
    // MOVING STATE
    // ============================================================

    if (_state == _MovementState.moving) {
      final lastPosition = _lastPosition;

      if (lastPosition == null) {
        _lastPosition = position;
        _lastMeaningfulMoveAt = now;

        Log.d(
          "BEACON_MOVEMENT_ALERT => "
          "moving last position reset",
        );

        await AppLogService.log(
          type: AppLogType.gps,
          text:
              "BEACON_MOVEMENT_ALERT => "
              "moving last position reset",
        );

        return;
      }

      final movedFromLast = Geolocator.distanceBetween(
        lastPosition.latitude,
        lastPosition.longitude,
        position.latitude,
        position.longitude,
      );

      Log.d(
        "BEACON_MOVEMENT_ALERT => "
        "state=moving "
        "reason=$reason "
        "movedFromLast=${movedFromLast.toStringAsFixed(1)}m",
      );

      await AppLogService.log(
        type: AppLogType.gps,
        text:
            "BEACON_MOVEMENT_ALERT => "
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

        Log.d(
          "BEACON_MOVEMENT_ALERT => "
          "state=stationary new reference set",
        );

        await AppLogService.log(
          type: AppLogType.gps,
          text:
              "BEACON_MOVEMENT_ALERT => "
              "state=stationary new reference set",
        );
      }
    }
  }
}