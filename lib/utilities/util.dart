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

  static Map<dynamic, int> addMap(Map<dynamic, int> a, Map<dynamic, int> b) {
    final totals = <dynamic, int>{};

    final keys = <dynamic>{...a.keys, ...b.keys};

    for (final key in keys) {
      final aVal = a[key] ?? 0;
      final bVal = b[key] ?? 0;
      totals[key] = aVal + bVal;
    }

    return totals;
  }
}
