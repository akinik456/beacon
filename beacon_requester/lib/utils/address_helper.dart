import 'package:geocoding/geocoding.dart';
import 'log.dart';

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

    final streetLineParts = [
      p.thoroughfare,     // 1144. Sokak
      p.subThoroughfare,  // 4
    ].where((x) => x != null && x.trim().isNotEmpty).toList();

    final areaParts = [
      p.subLocality,          // Bademlik
			p.subAdministrativeArea, // İlçe
      p.locality,             // varsa ilçe/şehir
      p.administrativeArea,   // Ankara
    ];

    final parts = <String>[];

    final streetLine = streetLineParts.join(' ');
    if (streetLine.trim().isNotEmpty) {
      parts.add(streetLine.trim());
    }

    for (final part in areaParts) {
      if (part == null) continue;

      final value = part.trim();
      if (value.isEmpty) continue;

      final exists = parts.any(
        (x) => x.toLowerCase() == value.toLowerCase(),
      );

      if (!exists) {
        parts.add(value);
      }
    }

    if (parts.isEmpty) return '';

    return parts.take(4).join(', ');
  } catch (e) {
    Log.e("BEACON ADDRESS ERROR => $e");
    return '';
  }
}
}
class AddressData {
  final String name;
  final String street;
  final String thoroughfare;
  final String subThoroughfare;
  final String subLocality;
  final String locality;
  final String administrativeArea;
  final String postalCode;

  const AddressData({
    required this.name,
    required this.street,
    required this.thoroughfare,
    required this.subThoroughfare,
    required this.subLocality,
    required this.locality,
    required this.administrativeArea,
    required this.postalCode,
  });

  String get displayLine {
    final parts = [
      if (thoroughfare.isNotEmpty) thoroughfare,
      if (subThoroughfare.isNotEmpty) 'No: $subThoroughfare',
      if (subLocality.isNotEmpty) subLocality,
      if (administrativeArea.isNotEmpty) administrativeArea,
    ];

    return parts.join(', ');
  }
}