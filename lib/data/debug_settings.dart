/// Developer-only knobs, set from the settings screen's debug section.
///
/// Carried over when a new game is started, so a cap set up for testing
/// still applies to the fresh save.
class DebugSettings {
  /// The highest level any single skill reads at, or null for no cap.
  ///
  /// Only the level is capped: xp keeps accruing underneath, so lifting the
  /// cap puts every skill straight back at its earned level. Gear, buffs and
  /// stances still add on top of the capped level.
  int? maxSkillLevel;

  DebugSettings({this.maxSkillLevel});

  Map<String, dynamic> toJson() {
    return {if (maxSkillLevel != null) 'maxSkillLevel': maxSkillLevel};
  }

  // debug settings are disposable: anything malformed falls back to off
  // rather than failing the whole save load
  factory DebugSettings.fromJson(Map<String, dynamic> json) {
    final rawCap = json['maxSkillLevel'];
    return DebugSettings(
      maxSkillLevel: rawCap is int && rawCap >= 1 ? rawCap : null,
    );
  }
}
