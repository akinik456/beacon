class TimeHelper {
  TimeHelper._();

  static String formatLastSeen(int? timestampMs) {
    if (timestampMs == null || timestampMs <= 0) {
      return 'Unknown';
    }

    final now = DateTime.now().millisecondsSinceEpoch;

    final diffMs = now - timestampMs;

    final seconds = diffMs ~/ 1000;

    if (seconds < 60) {
      return '$seconds sec ago';
    }

    final minutes = seconds ~/ 60;

    if (minutes < 60) {
      return '$minutes min ago';
    }

    final hours = minutes ~/ 60;

    if (hours < 24) {
      return '$hours hour ago';
    }

    final days = hours ~/ 24;

    if (days == 1) {
      return 'Yesterday';
    }

    return '$days days ago';
  }
}