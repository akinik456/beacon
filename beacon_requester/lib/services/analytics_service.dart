import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics =
      FirebaseAnalytics.instance;

  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );

      print("BEACON ANALYTICS => $name");
    } catch (e) {
      print("BEACON ANALYTICS ERROR => $e");
    }
  }
}