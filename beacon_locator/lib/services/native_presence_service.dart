import 'package:flutter/services.dart';

class NativePresenceService {
  NativePresenceService._();

  static const _channel =
      MethodChannel('lynra/presence_service');

  static Future<void> start({
		required String groupId,
		required String locatorId,
	}) async {
		try {
			await _channel.invokeMethod(
				'startPresenceService',
				{
					'groupId': groupId,
					'locatorId': locatorId,
				},
			);

			print(
				"NATIVE PRESENCE => service start requested "
				"group=$groupId locator=$locatorId",
			);
		} catch (e) {
			print(
				"NATIVE PRESENCE => start failed => $e",
			);
		}
	}
	
	static Future<Map<String, String>?> getPresenceIds() async {
		try {
			final result = await _channel.invokeMethod<Map>(
				'getPresenceIds',
			);

			final groupId = result?['groupId'] as String?;
			final locatorId = result?['locatorId'] as String?;

			if (groupId == null || locatorId == null) {
				return null;
			}

			return {
				'groupId': groupId,
				'locatorId': locatorId,
			};
		} catch (e) {
			print("NATIVE PRESENCE => get ids failed => $e");
			return null;
		}
	}
}