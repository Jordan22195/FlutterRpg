/// When automated combat reaches for food.
///
/// A rule rather than a constant because it decides how survivable a fight
/// is: a swing that takes the player to zero kills them outright, so the
/// only thing standing between a big max hit and a death is eating early
/// enough. It lives on [PlayerData] so the live eat and an offline settle
/// read the same one and cannot drift apart.
class AutoEatRule {
  /// Eat when hp is at or below this fraction of max hp.
  final double threshold;

  const AutoEatRule({this.threshold = 0.75});

  /// What every player starts with, and what the game used to hard-code.
  static const AutoEatRule standard = AutoEatRule();

  Map<String, dynamic> toJson() => {'threshold': threshold};

  /// Tolerant by design, like the rest of the save: a missing or malformed
  /// threshold falls back to the standard rule rather than failing a load.
  factory AutoEatRule.fromJson(Map<String, dynamic> json) {
    final raw = json['threshold'];
    if (raw is! num) return standard;
    return AutoEatRule(threshold: raw.toDouble().clamp(0.0, 1.0));
  }
}
