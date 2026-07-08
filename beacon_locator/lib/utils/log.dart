import 'package:flutter/foundation.dart';

class Log {
  Log._();
	static const bool enabled = true;
	
  static void d(Object? message) {
    if(kDebugMode && enabled) {
      debugPrint(message?.toString());
    }
  }

  static void e(Object? message, [Object? error]) {
    if(kDebugMode && enabled) {
      debugPrint("❌ $message");
      if (error != null) {
        debugPrint(error.toString());
      }
    }
  }
}