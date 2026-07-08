import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

import 'smart_presence_scheduler.dart';
import '../utils/log.dart';

class MotionService {
  MotionService._();

  static StreamSubscription? _sub;

  static DateTime _lastMotion =
      DateTime.fromMillisecondsSinceEpoch(0);

  static double? _lastMagnitude;

  static void start() {
    Log.d("MOTION => started");

    _sub?.cancel();
    _sub = null;
    _lastMagnitude = null;

    _startUserAccelerometer();
  }

  static void _startUserAccelerometer() {
    try {
      _sub = userAccelerometerEventStream().listen(
        (event) {
          _processMotion(
            x: event.x,
            y: event.y,
            z: event.z,
            source: 'user_accelerometer',
          );
        },
        onError: (e) {
          Log.d(
            "BEACON MOTION => "
            "user accelerometer error => $e",
          );

          _startAccelerometerFallback();
        },
        cancelOnError: true,
      );
    } catch (e) {
      Log.e(
        "BEACON MOTION => "
        "user accelerometer unavailable => $e",
      );

      _startAccelerometerFallback();
    }
  }

  static void _startAccelerometerFallback() {
    Log.d(
      "BEACON MOTION => "
      "starting accelerometer fallback",
    );

    _sub?.cancel();
    _sub = null;
    _lastMagnitude = null;

    try {
      _sub = accelerometerEventStream().listen(
        (event) {
          _processMotion(
            x: event.x,
            y: event.y,
            z: event.z,
            source: 'accelerometer',
          );
        },
        onError: (e) {
          Log.d(
            "BEACON MOTION => "
            "accelerometer error => $e",
          );
        },
        cancelOnError: false,
      );
    } catch (e) {
      Log.e(
        "BEACON MOTION => "
        "no motion sensor available => $e",
      );
    }
  }

  static void _processMotion({
    required double x,
    required double y,
    required double z,
    required String source,
  }) {
    final magnitude = sqrt(
      x * x + y * y + z * z,
    );

    final last = _lastMagnitude;
    _lastMagnitude = magnitude;

    if (last == null) {
      return;
    }

    final delta = (magnitude - last).abs();

    if (delta < 2.0) {
      return;
    }

    Log.d(
      "MOTION => source=$source "
      "magnitude=$magnitude "
      "delta=$delta",
    );

    final now = DateTime.now();

    if (now.difference(_lastMotion).inSeconds < 10) {
      return;
    }

    _lastMotion = now;

    Log.d(
      "BEACON MOTION => "
      "detected "
      "source=$source "
      "mag=$magnitude",
    );

    SmartPresenceScheduler.boostAndUpdateNow(
      reason: 'motion',
    );
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }
}