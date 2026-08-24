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

  /// A count written to at most three significant digits with a magnitude
  /// suffix: 123 -> "123", 1453 -> "1.45k", 115599 -> "115k",
  /// 1234567 -> "1.23m".
  ///
  /// For badges and other places a few characters wide, where the magnitude
  /// is what the reader is after and the exact figure would only be noise.
  ///
  /// Truncates rather than rounds: with 115,599 of something you have 115k
  /// of it, not 116k, and a number that rounds *up* past what you hold reads
  /// as a lie however small the error. Truncating also means the result can
  /// never spill into the next magnitude, so there is no "1000k".
  static String formatShortCount(int value) {
    if (value.abs() < 1000) return '$value';

    const suffixes = ['k', 'm', 'b', 't'];
    final magnitude = value.abs();

    var unit = 1000;
    var tier = 0;
    while (tier < suffixes.length - 1 && magnitude >= unit * 1000) {
      unit *= 1000;
      tier++;
    }

    // integer maths throughout: a double divide would round where we want
    // to truncate, and lose precision on large counts besides
    final whole = magnitude ~/ unit;
    final remainder = magnitude % unit;

    String text;
    if (whole >= 100) {
      text = '$whole';
    } else if (whole >= 10) {
      final tenths = (remainder * 10) ~/ unit;
      text = tenths == 0 ? '$whole' : '$whole.$tenths';
    } else {
      final hundredths = (remainder * 100) ~/ unit;
      text = hundredths == 0
          ? '$whole'
          : '$whole.${hundredths.toString().padLeft(2, '0')}';
    }

    // a trailing zero costs a character and says nothing: 1.50k is 1.5k
    if (text.contains('.') && text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }

    return '${value < 0 ? '-' : ''}$text${suffixes[tier]}';
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
