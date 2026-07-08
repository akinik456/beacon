import 'package:url_launcher/url_launcher.dart';
import 'log.dart';

class MapHelper {
  MapHelper._();

  static Future<void> openInMaps({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      Log.d("BEACON MAP ERROR => could not open maps");
    }
  }
}