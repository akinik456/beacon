import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import 'alert_service.dart';
import '../utils/log.dart';

class GeofenceService {
  GeofenceService._();

  static const double _radiusMeters = 100;
	static final Map<String, bool> _lastInsideState = {};
	
  static Future<void> checkPlaces({
    required String groupId,
    required String locatorId,
    required double lat,
    required double lng,
  }) async {
    try {
      final placesSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('devices')
          .doc(locatorId)
          .collection('places')
          .where('isActive', isEqualTo: true)
          .get();

      for (final doc in placesSnapshot.docs) {
        final data = doc.data();

        final placeLat = data['lat']?.toDouble();
        final placeLng = data['lng']?.toDouble();

        if (placeLat == null || placeLng == null) {
          continue;
        }

        final distance = Geolocator.distanceBetween(
          lat,
          lng,
          placeLat,
          placeLng,
        );

        final isInside = distance <= _radiusMeters;

        Log.d(
          "BEACON GEO => ${data['name']} "
          "distance=${distance.round()}m "
          "inside=$isInside",
        );
				
				
				final placeId = doc.id;

				final previousInside =
						_lastInsideState[placeId];

				_lastInsideState[placeId] = isInside;

				if (previousInside == null) {
					continue;
				}

				if (!previousInside && isInside) {
					await AlertService.sendPlaceAlert(
						type: 'place_enter',
						placeName: data['name'] ?? 'Place',
					);
					Log.d(
						"BEACON GEO => ENTER => ${data['name']}",
					);
				}

				if (previousInside && !isInside) {
					await AlertService.sendPlaceAlert(
						type: 'place_exit',
						placeName: data['name'] ?? 'Place',
					);
					Log.d(
						"BEACON GEO => EXIT => ${data['name']}",
					);
				}
				
      }	
    } catch (e) {
      Log.e("BEACON GEO ERROR => $e");
    }
  }
}