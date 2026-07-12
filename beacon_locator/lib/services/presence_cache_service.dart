import 'package:shared_preferences/shared_preferences.dart';

import '../utils/log.dart';

class PresenceCacheService {
  PresenceCacheService._();

  static const String _latKey =
      'presence_lat';

  static const String _lngKey =
      'presence_lng';

  static const String _statusKey =
      'presence_status';

  static const String _gpsEnabledKey =
      'presence_gps_enabled';

  static const String _geoInsideKey =
      'presence_geo_inside';

  static const String _geoPlaceNameKey =
      'presence_geo_place_name';

  static const String _geoPlaceDistanceKey =
      'presence_geo_place_distance';

  static const String _stationarySinceKey =
      'presence_stationary_since';

  static const String _offlineSinceKey =
      'presence_offline_since';

  static Future<void> save(
    Map<String, dynamic> data,
  ) async {
    final prefs =
        await SharedPreferences.getInstance();

    final lat = data['lat'];

    if (lat is num) {
      await prefs.setDouble(
        _latKey,
        lat.toDouble(),
      );
    }

    final lng = data['lng'];

    if (lng is num) {
      await prefs.setDouble(
        _lngKey,
        lng.toDouble(),
      );
    }

    final status = data['status'];

    if (status != null) {
      await prefs.setString(
        _statusKey,
        status.toString(),
      );
    }

    final gpsEnabled =
        data['gpsEnabled'];

    if (gpsEnabled is bool) {
      await prefs.setBool(
        _gpsEnabledKey,
        gpsEnabled,
      );
    }

    final geoInside =
        data['geoInside'];

    if (geoInside is bool) {
      await prefs.setBool(
        _geoInsideKey,
        geoInside,
      );
    }

    final geoPlaceName =
        data['geoPlaceName'];

    if (geoPlaceName != null) {
      await prefs.setString(
        _geoPlaceNameKey,
        geoPlaceName.toString(),
      );
    }

    final geoPlaceDistance =
        data['geoPlaceDistanceMeters'];

    if (geoPlaceDistance is num) {
      await prefs.setInt(
        _geoPlaceDistanceKey,
        geoPlaceDistance.round(),
      );
    } else if (data.containsKey(
      'geoPlaceDistanceMeters',
    )) {
      await prefs.remove(
        _geoPlaceDistanceKey,
      );
    }

    final stationarySince =
        data['stationarySince'];

    if (stationarySince is int) {
      await prefs.setInt(
        _stationarySinceKey,
        stationarySince,
      );
    } else if (data.containsKey(
      'stationarySince',
    )) {
      await prefs.remove(
        _stationarySinceKey,
      );
    }

    final offlineSince =
        data['offlineSince'];

    if (offlineSince is int) {
      await prefs.setInt(
        _offlineSinceKey,
        offlineSince,
      );
    } else if (data.containsKey(
      'offlineSince',
    )) {
      await prefs.remove(
        _offlineSinceKey,
      );
    }

    Log.d(
      "BEACON PRESENCE CACHE => saved",
    );
  }

  static Future<Map<String, dynamic>> load() async {
    final prefs =
        await SharedPreferences.getInstance();
		await prefs.reload();

    final data = <String, dynamic>{
      'lat': prefs.getDouble(_latKey),
      'lng': prefs.getDouble(_lngKey),
      'status':
          prefs.getString(_statusKey) ??
              'offline',
      'gpsEnabled':
          prefs.getBool(_gpsEnabledKey) ??
              false,
      'geoInside':
          prefs.getBool(_geoInsideKey) ??
              false,
      'geoPlaceName':
          prefs.getString(
            _geoPlaceNameKey,
          ) ??
              '',
      'geoPlaceDistanceMeters':
          prefs.getInt(
            _geoPlaceDistanceKey,
          ),
      'stationarySince':
          prefs.getInt(
            _stationarySinceKey,
          ),
      'offlineSince':
          prefs.getInt(
            _offlineSinceKey,
          ),
    };

    Log.d(
      "BEACON PRESENCE CACHE => loaded",
    );

    return data;
  }

  static Future<void> clear() async {
    final prefs =
        await SharedPreferences.getInstance();

    await prefs.remove(_latKey);
    await prefs.remove(_lngKey);
    await prefs.remove(_statusKey);
    await prefs.remove(_gpsEnabledKey);
    await prefs.remove(_geoInsideKey);
    await prefs.remove(_geoPlaceNameKey);
    await prefs.remove(
      _geoPlaceDistanceKey,
    );
    await prefs.remove(
      _stationarySinceKey,
    );
    await prefs.remove(
      _offlineSinceKey,
    );

    Log.d(
      "BEACON PRESENCE CACHE => cleared",
    );
  }
}