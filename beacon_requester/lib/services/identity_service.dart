import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class IdentityService {
  IdentityService._();

  static const _requesterIdKey = 'requester_id';

  static Future<String> getOrCreateRequesterId() async {
    final prefs = await SharedPreferences.getInstance();

    final existingId = prefs.getString(_requesterIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      print("BEACON IDENTITY => existing requesterId => $existingId");
      return existingId;
    }

    const uuid = Uuid();

    final newId = uuid.v4();

    await prefs.setString(_requesterIdKey, newId);

    print("BEACON IDENTITY => new requesterId => $newId");

    return newId;
  }
}