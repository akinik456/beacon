import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'code_service.dart';

class IdentityService {
  IdentityService._();

  static const _locatorIdKey = 'locator_id';

  static Future<String?> getLocatorId() async {
    final prefs = await SharedPreferences.getInstance();

    final locatorId = prefs.getString(_locatorIdKey);

    if (locatorId != null && locatorId.isNotEmpty) {
      print(
        "BEACON IDENTITY => locatorId found => $locatorId",
      );

      return locatorId;
    }

    print("BEACON IDENTITY => locatorId not found");

    return null;
  }

  static Future<String> createLocatorId() async {
    final prefs = await SharedPreferences.getInstance();

    final existingId = prefs.getString(_locatorIdKey);

    if (existingId != null && existingId.isNotEmpty) {
      print(
        "BEACON IDENTITY => existing locatorId => "
        "$existingId",
      );

      return existingId;
    }

    const uuid = Uuid();

    final newId = uuid.v4();

    await prefs.setString(_locatorIdKey, newId);

    print(
      "BEACON IDENTITY => new locatorId => $newId",
    );

    final locatorCode =
        CodeService.shortCodeFromId(newId);

    await prefs.setString(_locatorIdKey, newId);
    await prefs.setString('locator_code', locatorCode);

    print(
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

      print(
        "BEACON IDENTITY => locatorCode found => "
        "$locatorCode",
      );

      return locatorCode;
    }

    print("BEACON IDENTITY => locatorCode not found");

    return null;
  }
	
	static const _locatorNameKey =
			'requester_name';

	static Future<void> setLocatorName(
		String name,
	) async {
		final prefs =
				await SharedPreferences.getInstance();

		await prefs.setString(
			_locatorNameKey,
			name.trim(),
		);

		print(
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

			print(
				"BEACON IDENTITY => locatorName "
				"found => $locatorName",
			);

			return locatorName;
		}

		print(
			"BEACON IDENTITY => locatorName "
			"not found",
		);

		return null;
	}		
	
	static const _groupIdKey = 'group_id';

	static Future<void> setGroupId(String groupId) async {
  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(_groupIdKey, groupId);

  final saved = prefs.getString(_groupIdKey);

  print(
    "BEACON IDENTITY => setGroupId "
    "key=$_groupIdKey value=$groupId saved=$saved",
  );
}

static Future<String?> getGroupId() async {
  final prefs = await SharedPreferences.getInstance();

  final value = prefs.getString(_groupIdKey);

  print(
    "BEACON IDENTITY => getGroupId "
    "key=$_groupIdKey value=$value",
  );

  return value;
}

static Future<void> clearGroupId() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_groupIdKey);
}
	
}