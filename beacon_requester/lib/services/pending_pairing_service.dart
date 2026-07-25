import 'package:shared_preferences/shared_preferences.dart';

class PendingPairingService {
  PendingPairingService._();

  static const _locatorIdKey =
      'pending_pairing_locator_id';

  static const _requestIdKey =
      'pending_pairing_request_id';

  static Future<void> save({
    required String locatorId,
    required String requestId,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      _locatorIdKey,
      locatorId,
    );

    await prefs.setString(
      _requestIdKey,
      requestId,
    );
  }

  static Future<Map<String, String>?> load() async {
    final prefs = await SharedPreferences.getInstance();

    final locatorId =
        prefs.getString(_locatorIdKey);

    final requestId =
        prefs.getString(_requestIdKey);

    if (locatorId == null ||
        locatorId.isEmpty ||
        requestId == null ||
        requestId.isEmpty) {
      return null;
    }

    return {
      'locatorId': locatorId,
      'requestId': requestId,
    };
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_locatorIdKey);
    await prefs.remove(_requestIdKey);
  }
}