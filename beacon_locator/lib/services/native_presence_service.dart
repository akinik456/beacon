import 'package:flutter/services.dart';
import '../utils/log.dart';

class NativePresenceService {
  NativePresenceService._();

  static const _channel =
      MethodChannel('lynra/presence_service');

  static Future<void> start({
		required String locatorId,
	}) async {
		try {
			await _channel.invokeMethod(
				'startPresenceService',
				{
					'locatorId': locatorId,
				},
			);

			Log.d(
				"NATIVE PRESENCE => service start requested "
				"locator=$locatorId",
			);
		} catch (e) {
			Log.e(
				"NATIVE PRESENCE => start failed => $e",
			);
		}
	}
	
	static Future<Map<String, String>?> getPresenceIds() async {
		try {
			final result = await _channel.invokeMethod<Map>(
				'getPresenceIds',
			);

			final locatorId = result?['locatorId'] as String?;

			if (locatorId == null) {
				return null;
			}

			return {
				'locatorId': locatorId,
			};
		} catch (e) {
			Log.e("NATIVE PRESENCE => get ids failed => $e");
			return null;
		}
	}
}