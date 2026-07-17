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

    final bestPlace = _selectBestPlacemark(places);

    final streetLineParts = [
      bestPlace.thoroughfare,
      bestPlace.subThoroughfare,
    ]
        .whereType<String>()
        .map((x) => x.trim())
        .where((x) => x.isNotEmpty)
        .toList();

    final areaParts = [
      bestPlace.subLocality,
      bestPlace.subAdministrativeArea,
      bestPlace.locality,
      bestPlace.administrativeArea,
    ];

    final parts = <String>[];

    final streetLine = streetLineParts.join(' ').trim();

    if (streetLine.isNotEmpty) {
      parts.add(streetLine);
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

static Placemark _selectBestPlacemark(
  List<Placemark> places,
) {
  if (places.length == 1) {
    return places.first;
  }

  final groupCounts = <String, int>{};

  for (final place in places) {
    final district = _cleanAddressValue(
      place.subAdministrativeArea,
    );

    final postalCode = _cleanAddressValue(
      place.postalCode,
    );

    if (district.isEmpty && postalCode.isEmpty) {
      continue;
    }

    final key = '${district.toLowerCase()}|'
        '${postalCode.toLowerCase()}';

    groupCounts[key] = (groupCounts[key] ?? 0) + 1;
  }

  String? majorityKey;
  var majorityCount = 0;

  for (final entry in groupCounts.entries) {
    if (entry.value > majorityCount) {
      majorityKey = entry.key;
      majorityCount = entry.value;
    }
  }

  var candidates = places;

  if (majorityKey != null) {
    final matchingPlaces = places.where((place) {
      final district = _cleanAddressValue(
        place.subAdministrativeArea,
      );

      final postalCode = _cleanAddressValue(
        place.postalCode,
      );

      final key = '${district.toLowerCase()}|'
          '${postalCode.toLowerCase()}';

      return key == majorityKey;
    }).toList();

    if (matchingPlaces.isNotEmpty) {
      candidates = matchingPlaces;
    }
  }

  Placemark bestPlace = candidates.first;
  var bestScore = _placemarkScore(bestPlace);

  for (final place in candidates.skip(1)) {
    final score = _placemarkScore(place);

    if (score > bestScore) {
      bestPlace = place;
      bestScore = score;
    }
  }

  return bestPlace;
}

static int _placemarkScore(
  Placemark place,
) {
  var score = 0;

  if (_cleanAddressValue(place.thoroughfare).isNotEmpty) {
    score += 5;
  }

  if (_cleanAddressValue(place.subThoroughfare).isNotEmpty) {
    score += 4;
  }

  if (_cleanAddressValue(place.subLocality).isNotEmpty) {
    score += 4;
  }

  if (_cleanAddressValue(
    place.subAdministrativeArea,
  ).isNotEmpty) {
    score += 4;
  }

  if (_cleanAddressValue(place.postalCode).isNotEmpty) {
    score += 3;
  }

  if (_cleanAddressValue(place.locality).isNotEmpty) {
    score += 2;
  }

  if (_cleanAddressValue(
    place.administrativeArea,
  ).isNotEmpty) {
    score += 2;
  }

  return score;
}

static String _cleanAddressValue(
  String? value,
) {
  return value?.trim() ?? '';
}

static Future<void> debugKnownAddresses() async {
  final testPoints = [
    (lat: 40.009416, lng: 32.876869),
    (lat: 40.009416, lng: 32.8769),
    (lat: 40.009416, lng: 32.877),
    (lat: 40.009416, lng: 32.878),
    (lat: 40.009416, lng: 32.879),
  ];

  for (var i = 0; i < testPoints.length; i++) {
    final point = testPoints[i];

    try {
      final places = await placemarkFromCoordinates(
        point.lat,
        point.lng,
      );

      Log.d(
        "BEACON ADDRESS TEST => "
        "POINT ${i + 1} "
        "lat=${point.lat} "
        "lng=${point.lng} "
        "resultCount=${places.length}",
      );

      for (var j = 0; j < places.length; j++) {
        final p = places[j];

        Log.d(
          "BEACON ADDRESS TEST => "
          "POINT ${i + 1} PLACE ${j + 1} | "
          "name=${p.name} | "
          "street=${p.street} | "
          "thoroughfare=${p.thoroughfare} | "
          "subThoroughfare=${p.subThoroughfare} | "
          "subLocality=${p.subLocality} | "
          "locality=${p.locality} | "
          "subAdministrativeArea=${p.subAdministrativeArea} | "
          "administrativeArea=${p.administrativeArea} | "
          "postalCode=${p.postalCode} | "
          "isoCountryCode=${p.isoCountryCode} | "
          "country=${p.country}",
        );
      }

      final generatedAddress = await getAddressFromLatLng(
        lat: point.lat,
        lng: point.lng,
      );

      Log.d(
        "BEACON ADDRESS TEST => "
        "POINT ${i + 1} FINAL ADDRESS => "
        "$generatedAddress",
      );
    } catch (e) {
      Log.e(
        "BEACON ADDRESS TEST => "
        "POINT ${i + 1} ERROR => $e",
      );
    }
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