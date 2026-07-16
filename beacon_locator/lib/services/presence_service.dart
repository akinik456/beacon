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
import 'presence_cache_service.dart';
import 'motion_service.dart';
import 'gps_analysis_service.dart';



class PresenceService {
  PresenceService._();
			
  static final _db = FirebaseDatabase.instance.ref();
	static StreamSubscription<DatabaseEvent>? _connectedSub;
	static String? _serviceGroupId;
	static String? _serviceLocatorId;
	static double? _lastLat;
	static double? _lastLng;
	static int? _lastBatteryLevel;
	static bool? _lastGpsEnabled;
	
	static double? lastSpeedKmh;
	static DateTime? _lastAcceptedLocationTime;
		
		
	static Future<void> updateOnline({
		String reason = 'unknown',
	}) async {
  final groupId = _serviceGroupId ?? await IdentityService.getGroupId();
  final locatorId = _serviceLocatorId ?? await IdentityService.getLocatorId();
  if (groupId == null || locatorId == null) {
    Log.d(
      "BEACON PRESENCE => "
      "missing group/locator",
    );
    return;
  }

  final path = "presence/groups/$groupId/locators/$locatorId";
  final batteryLevel = await Battery().batteryLevel;
  final gpsEnabled = await Geolocator.isLocationServiceEnabled();			
	final batteryChanged = _lastBatteryLevel == null || (batteryLevel - _lastBatteryLevel!).abs() >= 5;
  final deviceStatusChanged = batteryChanged || _lastGpsEnabled != gpsEnabled;

  Position? position;

  if (gpsEnabled) {
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      Log.e(
        "BEACON PRESENCE => "
        "getCurrentPosition failed => $e",
      );
    }
  }

  // Hatalı GPS konumunu hareket/konum hesabında kullanma.
  // Ancak pil veya GPS durumu değiştiyse aşağıda yine yazılabilir.
  /* position.accuracy > 50 kontrol aktif olmalı mı?
	if (position != null && position.accuracy > 50) {
    Log.d(
      "BEACON PRESENCE => "
      "ignore inaccurate position "
      "accuracy=${position.accuracy.toStringAsFixed(1)}m",
    );
    position = null;
  }?*?*/

  double speedKmh = 0;

  if (position != null) { 
    final speedMps = position.speed;
    speedKmh = speedMps >= 0
        ? speedMps * 3.6
        : 0;
		if (speedKmh < 3) { 
      speedKmh = 0;
    }//?*?
  }

  double? movedMeters;

  if (position != null && _lastLat != null && _lastLng != null) {
    movedMeters = Geolocator.distanceBetween(
      _lastLat!,
      _lastLng!,
      position.latitude,
      position.longitude,
    );
		
		double? elapsedSeconds;

		if (_lastAcceptedLocationTime != null) {
			elapsedSeconds = DateTime.now()
					.difference(_lastAcceptedLocationTime!)
					.inMilliseconds /
					1000.0;
		}	

		final motionRecent = MotionService.wasRecentlyMoving();
			
		final analysis = GpsAnalysisService.analyze(
			input: GpsAnalysisInput(
				accuracy: position.accuracy,
				movedMeters: movedMeters,
				elapsedSeconds: elapsedSeconds,
				reportedSpeedKmh: speedKmh,
				lastSpeedKmh: lastSpeedKmh,
				motionRecent: motionRecent,
			),
		);
		
		var finalAnalysis = analysis;
		
		if (analysis.decision == GpsDecision.verify ||
    analysis.decision == GpsDecision.suspicious) {		
			final firstPosition = position;
			final firstMovedMeters = movedMeters;
				
			final confirmation =
				await _getConfirmationPosition(
					firstTimestamp: firstPosition.timestamp,
				);
				if (confirmation == null) {
					Log.d(
						"BEACON_GPS_VERIFY => "
						"confirmation unavailable",
					);
				} else {
				final isNewFix =
								confirmation.timestamp.isAfter(firstPosition.timestamp);
				if (!isNewFix) {
					Log.d(
								"BEACON_GPS_VERIFY => "
								"cached confirmation ignored "
								"firstTime=${firstPosition.timestamp} "
								"secondTime=${confirmation.timestamp}",
							);
				} else {
							final double? secondElapsedSeconds =
									_lastAcceptedLocationTime != null
											? DateTime.now()
													.difference(_lastAcceptedLocationTime!)
													.inMilliseconds /
													1000.0
											: null;

							final double? confirmationMovedMeters =
									_lastLat != null && _lastLng != null
											? Geolocator.distanceBetween(
													_lastLat!,
													_lastLng!,
													confirmation.latitude,
													confirmation.longitude,
												)
											: null;

							final rawConfirmationSpeedKmh =
									confirmation.speed >= 0
											? confirmation.speed * 3.6
											: 0.0;

							final confirmationSpeedKmh =
									rawConfirmationSpeedKmh < 3
											? 0.0
											: rawConfirmationSpeedKmh;

							final secondAnalysis =
									GpsAnalysisService.analyze(
								input: GpsAnalysisInput(
									accuracy: confirmation.accuracy,
									movedMeters: confirmationMovedMeters,
									elapsedSeconds: secondElapsedSeconds,
									reportedSpeedKmh: confirmationSpeedKmh,
									lastSpeedKmh: lastSpeedKmh,
									motionRecent: motionRecent,
								),
							);

							final firstToSecondDistance =
									Geolocator.distanceBetween(
								firstPosition.latitude,
								firstPosition.longitude,
								confirmation.latitude,
								confirmation.longitude,
							);

							Log.d(
								"BEACON_GPS_VERIFY => "
								"firstTime=${firstPosition.timestamp} "
								"secondTime=${confirmation.timestamp} "
								"firstToSecond=${firstToSecondDistance.toStringAsFixed(1)}m",
							);

							Log.d(
								"BEACON_GPS_VERIFY => "
								"first=${analysis.decision.name}:${analysis.score} "
								"second=${secondAnalysis.decision.name}:${secondAnalysis.score}",
							);

							Log.d(
								"BEACON_GPS_VERIFY => "
								"firstMoved=${firstMovedMeters?.toStringAsFixed(1)}m "
								"secondMoved=${confirmationMovedMeters?.toStringAsFixed(1)}m",
							);

							if (secondAnalysis.decision == GpsDecision.safe) {
								position = confirmation;
								movedMeters = confirmationMovedMeters;
								speedKmh = confirmationSpeedKmh;
								finalAnalysis = secondAnalysis;
							}
						}
					}
				}
		if (analysis.decision == GpsDecision.suspicious &&
				finalAnalysis.decision != GpsDecision.safe) {
				
			try {
  final rejectedRef = _db
      .child('gps_diagnostics')
      .child(groupId)
      .child(locatorId)
      .child('rejected')
      .push();

  await rejectedRef.set({
    'createdAt': ServerValue.timestamp,
    'reason': reason,

    'score': analysis.score,
    'decision': analysis.decision.name,
    'reasons': analysis.reasons,

    'lat': position.latitude,
    'lng': position.longitude,
    'accuracy': position.accuracy,

    'movedMeters': movedMeters,
    'elapsedSeconds': elapsedSeconds,

    'reportedSpeedKmh': speedKmh,
    'calculatedSpeedKmh':
        analysis.calculatedSpeedKmh,
    'speedDifferenceKmh':
        analysis.speedDifferenceKmh,
    'speedJumpKmh':
        analysis.speedJumpKmh,

    'motionRecent': motionRecent,

    'positionTimestamp':
        position.timestamp.millisecondsSinceEpoch,
  });

  Log.d(
    "BEACON_GPS_REJECTED => "
    "diagnostic saved "
    "score=${analysis.score} "
    "moved=${movedMeters?.toStringAsFixed(1)}m",
  );
} catch (e) {
  Log.e(
    "BEACON_GPS_REJECTED => "
    "diagnostic save failed => $e",
  );
}

Log.d(
  "BEACON_GPS => suspicious fix rejected "
  "score=${analysis.score} "
  "reason=$reason",
);

return;	
				

		}
				
				
		SmartPresenceScheduler.setSpeedKmh(speedKmh,);
		
Log.d(
  "BEACON_GPS => "
  "reason=$reason "
  "accuracy=${position.accuracy.toStringAsFixed(1)}m "
  "moved=${movedMeters?.toStringAsFixed(1)}m "
  "elapsed=${elapsedSeconds?.toStringAsFixed(1)}s "
  "motionRecent=$motionRecent",
);

Log.d(
  "BEACON_GPS => "
  "lastSpeed=${lastSpeedKmh?.toStringAsFixed(1)}kmh "
  "reportedSpeed=${speedKmh.toStringAsFixed(1)}kmh "
  "calculatedSpeed=${finalAnalysis.calculatedSpeedKmh?.toStringAsFixed(1)}kmh "
  "speedDifference=${finalAnalysis.speedDifferenceKmh?.toStringAsFixed(1)}kmh "
  "speedJump=${finalAnalysis.speedJumpKmh?.toStringAsFixed(1)}kmh",
);
Log.d(
  "BEACON_GPS_SCORE => "
  "score=${finalAnalysis.score} "
  "decision=${finalAnalysis.decision.name} "
  "reasons=${finalAnalysis.reasons.isEmpty ? 'none' : finalAnalysis.reasons.join(',')}",
);    
		
		Log.d(
      "BEACON PRESENCE => "
      "reason=$reason "
      "moved=${movedMeters != null ? movedMeters.toStringAsFixed(1) : '-'}m",
    );
  }

  final shouldSkipSmallMove =
      (reason == 'timer' || reason == 'motion') &&
      movedMeters != null &&
      movedMeters < 2; // ?*?< 25;

	// Hareket yok, pil/GPS de değişmedi:
  // ne alert kontrolüne ne de RTDB write'a gerek var.
  if (shouldSkipSmallMove &&
      !deviceStatusChanged) {
    Log.d(
      "BEACON PRESENCE => "
      "skip small move "
      "reason=$reason "
      "moved=${movedMeters?.toStringAsFixed(1)}m",
    );
    return;
  }//?*?

  // Hareket yok ama pil veya GPS durumu değişti:
  // yalnızca status alanlarını güncelle.
  if (shouldSkipSmallMove &&
      deviceStatusChanged) {
    await _db.child(path).update({
      'status': 'online',
      'lastSeen': ServerValue.timestamp,
      'battery': batteryLevel,
      'gpsEnabled': gpsEnabled,
      'updateCount': ServerValue.increment(1),
    });
		
		await PresenceCacheService.save({
			'status': 'online',
			'battery': batteryLevel,
			'gpsEnabled': gpsEnabled,
		});		

    _lastBatteryLevel = batteryLevel;
    _lastGpsEnabled = gpsEnabled;

    Log.d(
      "BEACON PRESENCE => "
      "device status updated without location",
    );

    return;
  }

  // Geçerli konum yoksa yalnızca değişen cihaz durumu yazılabilir.
  if (position == null) {
    if (!deviceStatusChanged) {
      Log.d(
        "BEACON PRESENCE => "
        "no valid position and no status change",
      );
      return;
    }

    await _db.child(path).update({
      'status': 'online',
      'lastSeen': ServerValue.timestamp,
      'battery': batteryLevel,
      'gpsEnabled': gpsEnabled,
      'updateCount': ServerValue.increment(1),
    });
		
		await PresenceCacheService.save({
			'status': 'online',
			'battery': batteryLevel,
			'gpsEnabled': gpsEnabled,
		});

    _lastBatteryLevel = batteryLevel;
    _lastGpsEnabled = gpsEnabled;

    Log.d(
      "BEACON PRESENCE => "
      "device status updated without valid position",
    );

    return;
  }

  // Buraya geldiysek geçerli ve anlamlı bir konum hareketi var.
  final placeData =
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

  // Motion alert ve geofence kontrolleri çalıştı.
  // Aktif izleyen yoksa sırf motion nedeniyle presence konumu yazma.
  if (reason == 'motion' &&
      !SmartPresenceScheduler.hasActiveWatcher) {
    if (deviceStatusChanged) {
      await _db.child(path).update({
        'status': 'online',
        'lastSeen': ServerValue.timestamp,
        'battery': batteryLevel,
        'gpsEnabled': gpsEnabled,
        'updateCount': ServerValue.increment(1),
      });
			
			await PresenceCacheService.save({
				'status': 'online',
				'battery': batteryLevel,
				'gpsEnabled': gpsEnabled,
			});

      _lastBatteryLevel = batteryLevel;
      _lastGpsEnabled = gpsEnabled;
    }

    Log.d(
      "BEACON PRESENCE => "
      "skip location write, "
      "motion without active watcher",
    );

    return;
  }

  final Map<String, dynamic> updateData = {
    'status': 'online',
    'lastSeen': ServerValue.timestamp,
    'battery': batteryLevel,
    'gpsEnabled': gpsEnabled,
    'lat': position.latitude,
    'lng': position.longitude,
    'accuracy': position.accuracy,
    'movedSinceLastUpdateMeters':
        movedMeters?.round(),
    'updateCount': ServerValue.increment(1),
    ...placeData,
  };
	
	final Map<String, dynamic> cacheData = {
		'status': 'online',
		'battery': batteryLevel,
		'gpsEnabled': gpsEnabled,
		'lat': position.latitude,
		'lng': position.longitude,
		...placeData,
		'stationarySince': updateData['stationarySince'],
		'offlineSince': null,
	};

  if (movedMeters == null ||
      movedMeters >= 25) {
    updateData['stationarySince'] =
        ServerValue.timestamp;
  }

  await _db.child(path).update(updateData,);
	await PresenceCacheService.save(cacheData);

  _lastBatteryLevel = batteryLevel;
  _lastGpsEnabled = gpsEnabled;
  _lastLat = position.latitude;
  _lastLng = position.longitude;
	lastSpeedKmh = speedKmh;
	_lastAcceptedLocationTime = position.timestamp;

  Log.d(
    "BEACON PRESENCE => "
    "online updated reason=$reason",
  );
}

static Future<Position?> _getConfirmationPosition({
  required DateTime firstTimestamp,
}) async {
  try {
    final stream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 0,
      ),
    );

    return await stream
    .firstWhere((newPosition) {
      final isFresh =
          newPosition.timestamp.isAfter(firstTimestamp);

      Log.d(
        "BEACON_GPS_STREAM => "
        "first=$firstTimestamp "
        "candidate=${newPosition.timestamp} "
        "isFresh=$isFresh",
      );

      return isFresh;
    })
    .timeout(
      const Duration(seconds: 20),
    );
  } on TimeoutException {
    Log.d(
      "BEACON_GPS_VERIFY => "
      "fresh confirmation timeout",
    );

    return null;
  } catch (e) {
    Log.e(
      "BEACON_GPS_VERIFY => "
      "confirmation stream failed => $e",
    );

    return null;
  }
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
