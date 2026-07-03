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

  static Map<K, int> addMap<K>(Map<K, int> a, Map<K, int> b) {
    final totals = <K, int>{};

    final keys = <K>{...a.keys, ...b.keys};

    for (final key in keys) {
      final aVal = a[key] ?? 0;
      final bVal = b[key] ?? 0;
      totals[key] = aVal + bVal;
    }

    return totals;
  }
}
