import 'package:shared_preferences/shared_preferences.dart';

class NotificationTextService {
  NotificationTextService._();

  static Future<String> _langCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('languageCode') ?? 'en';
  }

  static String beingWatched(String langCode) {
		switch (langCode) {
			case 'tr':
				return 'İzleniyorsun';
			case 'es':
				return 'Te están observando';
			default:
				return 'Being watched';
		}
	}

  static Future<String> watchingLocation({
    required List<String> names,
  }) async {
    if (names.isEmpty) return '';

    final langCode = await _langCode();

    if (names.length == 1) {
      switch (langCode) {
        case 'tr':
          return '${names[0]} konumunu izliyor.';
        case 'es':
          return '${names[0]} está viendo tu ubicación.';
        default:
          return '${names[0]} is watching your location.';
      }
    }

    if (names.length == 2) {
      switch (langCode) {
        case 'tr':
          return '${names[0]} ve ${names[1]} konumunu izliyor.';
        case 'es':
          return '${names[0]} y ${names[1]} están viendo tu ubicación.';
        default:
          return '${names[0]} and ${names[1]} are watching your location.';
      }
    }

    switch (langCode) {
      case 'tr':
        return '${names[0]} ve ${names.length - 1} kişi daha konumunu izliyor.';
      case 'es':
        return '${names[0]} y ${names.length - 1} personas más están viendo tu ubicación.';
      default:
        return '${names[0]} and ${names.length - 1} others are watching your location.';
    }
  }
}