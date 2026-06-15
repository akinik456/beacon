import 'package:flutter/services.dart';

class NativePresenceService {
  NativePresenceService._();

  static const _channel =
      MethodChannel('lynra/presence_service');

  static Future<void> start() async {
    try {
      await _channel.invokeMethod(
        'startPresenceService',
      );

      print(
        "NATIVE PRESENCE => service start requested",
      );
    } catch (e) {
      print(
        "NATIVE PRESENCE => start failed => $e",
      );
    }
  }
}