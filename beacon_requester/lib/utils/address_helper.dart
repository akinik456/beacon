import 'package:geocoding/geocoding.dart';

class AddressHelper {
  AddressHelper._();

  static Future<String> getAddressFromLatLng({
    required double lat,
    required double lng,
  }) async {
    try {
      final places = await placemarkFromCoordinates(lat, lng);

      if (places.isEmpty) return '';

      final p = places.first;

      final parts = [
        p.street,
        p.subLocality,
        p.locality,
      ].where((x) => x != null && x.trim().isNotEmpty).toList();

      if (parts.isEmpty) return '';

      return parts.join(', ');
    } catch (e) {
      print("BEACON ADDRESS ERROR => $e");
      return '';
    }
  }
}