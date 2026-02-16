class Util {
  static String formatRemainingTime(DateTime expirationTime) {
    final remaining = expirationTime.difference(DateTime.now());

    if (remaining.isNegative) {
      return "0s";
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else if (minutes > 0) {
      return "${minutes}m ${seconds}s";
    } else {
      return "${seconds}s";
    }
  }
}
