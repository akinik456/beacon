import 'package:geolocator/geolocator.dart';
import 'log.dart';


class LocationHelper {
  LocationHelper._();

static Future<Position?> getCurrentPosition() async {
  try {
    final serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      Log.d("BEACON LOCATION => service disabled");
      return null;
    }

    var permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      Log.d("BEACON LOCATION => permission denied");
      return null;
    }

    if (permission == LocationPermission.deniedForever) {
      Log.d("BEACON LOCATION => permission denied forever");
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  } catch (e) {
    Log.e("BEACON LOCATION ERROR => $e");
    return null;
  }
}
static double? distanceMeters({
  required double? fromLat,
  required double? fromLng,
  required double? toLat,
  required double? toLng,
}) {
  if (fromLat == null ||
      fromLng == null ||
      toLat == null ||
      toLng == null) {
    return null;
  }

  return Geolocator.distanceBetween(
    fromLat,
    fromLng,
    toLat,
    toLng,
  );
}

}