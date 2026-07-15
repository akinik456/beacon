import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_service.dart';
import '../utils/log.dart';

class GeofenceService {
  GeofenceService._();

  static const double _radiusMeters = 100;


  static Future<Map<String, dynamic>> checkPlaces({
    required String groupId,
    required String locatorId,
    required double lat,
    required double lng,
  }) async {
		final prefs = await SharedPreferences.getInstance();
    bool geoInside = false;
    String? currentPlaceId;
    String? currentPlaceName;
		double? currentPlaceDistanceMeters;
		
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

        final placeId = doc.id;
        final placeName =
            (data['name'] ?? 'Place').toString();

        final distance = Geolocator.distanceBetween(
          lat,
          lng,
          placeLat,
          placeLng,
        );

        final isInside =
            distance <= _radiusMeters;

        Log.d(
          "BEACON GEO => $placeName "
          "distance=${distance.round()}m "
          "inside=$isInside",
        );

        if (isInside && !geoInside) {
          geoInside = true;
          currentPlaceId = placeId;
          currentPlaceName = placeName;
					currentPlaceDistanceMeters = distance;
        }

        final stateKey =
						'geofence_inside_${groupId}_${locatorId}_$placeId';

				final previousInside =
						prefs.getBool(stateKey);

				await prefs.setBool(
					stateKey,
					isInside,
				);

        if (previousInside == null) {
          continue;
        }

        if (!previousInside && isInside) {
          await AlertService.sendPlaceAlert(
            type: 'place_enter',
            placeName: placeName,
          );

          Log.d(
            "BEACON GEO => ENTER => $placeName",
          );
        }

        if (previousInside && !isInside) {
          await AlertService.sendPlaceAlert(
            type: 'place_exit',
            placeName: placeName,
          );

          Log.d(
            "BEACON GEO => EXIT => $placeName",
          );
        }
      }

      return {
        'geoInside': geoInside,
        'geoPlaceId': currentPlaceId,
        'geoPlaceName': currentPlaceName,
				'geoPlaceDistanceMeters': currentPlaceDistanceMeters?.round(),
      };
    } catch (e) {
      Log.e(
        "BEACON GEO ERROR => $e",
      );

      return {
        'geoInside': false,
        'geoPlaceId': null,
        'geoPlaceName': null,
      };
    }
  }
}