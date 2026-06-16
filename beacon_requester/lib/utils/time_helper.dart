import '../l10n/app_localizations.dart';

class TimeHelper {
  TimeHelper._();

  static String formatLastSeen(
    int? timestampMs,
    AppLocalizations l10n,
  ) {
    if (timestampMs == null || timestampMs <= 0) {
      return l10n.unknown;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMs = now - timestampMs;
    final seconds = diffMs ~/ 1000;

    if (seconds < 10) {
      return l10n.justNow;
    }

    if (seconds < 60) {
      return l10n.secondsAgo(seconds);
    }

    final minutes = seconds ~/ 60;

    if (minutes < 60) {
      return l10n.minutesAgo(minutes);
    }

    final hours = minutes ~/ 60;

    if (hours < 24) {
      return l10n.hoursAgo(hours);
    }

    final days = hours ~/ 24;

    if (days == 1) {
      return l10n.yesterday;
    }

    return l10n.daysAgo(days);
  }
}