import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'code_service.dart';

class IdentityService {
  IdentityService._();

  static const _requesterIdKey = 'requester_id';

	static Future<String?> getRequesterId() async {
		final prefs = await SharedPreferences.getInstance();

		final requesterId = prefs.getString(_requesterIdKey);

		if (requesterId != null && requesterId.isNotEmpty) {
			print(
				"BEACON IDENTITY => requesterId found => $requesterId",
			);

			return requesterId;
		}

		print("BEACON IDENTITY => requesterId not found");

		return null;
	}

	static Future<String> createRequesterId() async {
		final prefs = await SharedPreferences.getInstance();

		final existingId = prefs.getString(_requesterIdKey);

		if (existingId != null && existingId.isNotEmpty) {
			print(
				"BEACON IDENTITY => existing requesterId => "
				"$existingId",
			);

			return existingId;
		}

		const uuid = Uuid();

		final newId = uuid.v4();

		await prefs.setString(_requesterIdKey, newId);

		print(
			"BEACON IDENTITY => new requesterId => $newId",
		);
		
		final requesterCode = CodeService.shortCodeFromId(newId);

		await prefs.setString(_requesterIdKey, newId);
		await prefs.setString('requester_code', requesterCode);

		print("BEACON IDENTITY => requesterCode => $requesterCode");

		return newId;
	}
	
	static Future<String?> getRequesterCode() async {
		final prefs = await SharedPreferences.getInstance();

		final requesterCode =
				prefs.getString('requester_code');

		if (requesterCode != null &&
				requesterCode.isNotEmpty) {

			print(
				"BEACON IDENTITY => requesterCode found => "
				"$requesterCode",
			);

			return requesterCode;
		}

		print("BEACON IDENTITY => requesterCode not found");

		return null;
	}

	static const _requesterNameKey =
			'requester_name';

	static Future<void> setRequesterName(
		String name,
	) async {
		final prefs =
				await SharedPreferences.getInstance();

		await prefs.setString(
			_requesterNameKey,
			name.trim(),
		);

		print(
			"BEACON IDENTITY => requesterName "
			"saved => $name",
		);
	}

	static Future<String?> getRequesterName() async {
		final prefs =
				await SharedPreferences.getInstance();

		final requesterName =
				prefs.getString(_requesterNameKey);

		if (requesterName != null &&
				requesterName.isNotEmpty) {

			print(
				"BEACON IDENTITY => requesterName "
				"found => $requesterName",
			);

			return requesterName;
		}

		print(
			"BEACON IDENTITY => requesterName "
			"not found",
		);

		return null;
	}	
	
}