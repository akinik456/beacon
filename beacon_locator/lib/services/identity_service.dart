import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'code_service.dart';
import '../utils/log.dart';


class IdentityService {
  IdentityService._();

  static const _locatorIdKey = 'locator_id';

  static Future<String?> getLocatorId() async {
    final prefs = await SharedPreferences.getInstance();

    final locatorId = prefs.getString(_locatorIdKey);

    if (locatorId != null && locatorId.isNotEmpty) {
      /*Log.d(
        "BEACON IDENTITY => locatorId found => $locatorId",
      );*/

      return locatorId;
    }

    Log.d("BEACON IDENTITY => locatorId not found");

    return null;
  }

  static Future<String> createLocatorId() async {
    final prefs = await SharedPreferences.getInstance();

    final existingId = prefs.getString(_locatorIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      Log.d(
        "BEACON IDENTITY => existing locatorId => "
        "$existingId",
      );

      return existingId;
    }

    const uuid = Uuid();

    final newId = uuid.v4();

    await prefs.setString(_locatorIdKey, newId);

    Log.d(
      "BEACON IDENTITY => new locatorId => $newId",
    );

    final locatorCode =
        CodeService.shortCodeFromId(newId);

    await prefs.setString(_locatorIdKey, newId);
    await prefs.setString('locator_code', locatorCode);

    Log.d(
      "BEACON IDENTITY => locatorCode => "
      "$locatorCode",
    );

    return newId;
  }

  static Future<String?> getLocatorCode() async {
    final prefs = await SharedPreferences.getInstance();

    final locatorCode =
        prefs.getString('locator_code');

    if (locatorCode != null &&
        locatorCode.isNotEmpty) {

      Log.d(
        "BEACON IDENTITY => locatorCode found => "
        "$locatorCode",
      );

      return locatorCode;
    }

    Log.d("BEACON IDENTITY => locatorCode not found");

    return null;
  }
	
	static const _locatorNameKey =
			'locator_name';

	static Future<void> setLocatorName(
		String name,
	) async {
		final prefs =
				await SharedPreferences.getInstance();

		await prefs.setString(
			_locatorNameKey,
			name.trim(),
		);

		Log.d(
			"BEACON IDENTITY => locatorName "
			"saved => $name",
		);
	}

	static Future<String?> getLocatorName() async {
		final prefs =
				await SharedPreferences.getInstance();

		final locatorName =
				prefs.getString(_locatorNameKey);

		if (locatorName != null &&
				locatorName.isNotEmpty) {

			Log.d(
				"BEACON IDENTITY => locatorName "
				"found => $locatorName",
			);

			return locatorName;
		}

		Log.d(
			"BEACON IDENTITY => locatorName "
			"not found",
		);

		return null;
	}		

}