import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

import 'smart_presence_scheduler.dart';


class MotionService {
  MotionService._();

  static StreamSubscription? _sub;

  static DateTime _lastMotion =
      DateTime.fromMillisecondsSinceEpoch(0);

  static void start() {

    _sub?.cancel();

    _sub = userAccelerometerEventStream().listen(
      (event) {

        final magnitude =
            sqrt(
              event.x * event.x +
              event.y * event.y +
              event.z * event.z,
            );

        if (magnitude < 1.5) {
          return;
        }

        final now = DateTime.now();

        if (now
                .difference(_lastMotion)
                .inSeconds <
            10) {
          return;
        }

        _lastMotion = now;

        print(
          "BEACON MOTION => "
          "detected "
          "mag=$magnitude",
        );
				SmartPresenceScheduler.boostAndUpdateNow(
					reason: 'motion',
				);
      },
    );
  }

  static void stop() {
    _sub?.cancel();
    _sub = null;
  }
}