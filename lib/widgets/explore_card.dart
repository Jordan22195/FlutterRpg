import '../data/skill_data.dart';

/// The tool a gathering skill is worked with, as a lock line says it
/// ("Needs an axe").
String toolNoun(SkillId skill) => switch (skill) {
  SkillId.WOODCUTTING => 'an axe',
  SkillId.MINING => 'a pickaxe',
  SkillId.FISHING => 'a fishing rod',
  _ => 'a tool',
};

/// The tool a gathering skill is worked with, as a tile names it when none is
/// equipped ("No Axe Equipped").
String toolName(SkillId skill) => switch (skill) {
  SkillId.WOODCUTTING => 'Axe',
  SkillId.MINING => 'Pickaxe',
  SkillId.FISHING => 'Fishing Rod',
  _ => 'Tool',
};

/// What a tile says under its name when the tool for [skill] isn't equipped.
String noToolEquipped(SkillId skill) => 'No ${toolName(skill)} Equipped';

/// Human label for a skill on explore cards ("Combat", "Woodcutting").
String skillDisplayName(Enum skill) {
  if (skill == SkillId.ATTACK) return "Combat";
  final raw = skill.name;
  if (raw.isEmpty) return raw;
  return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
}

/// Action verb for a skill's per-unit xp readout ("+16 / kill").
String skillActionVerb(Enum skill) {
  switch (skill) {
    case SkillId.ATTACK:
      return "kill";
    case SkillId.FISHING:
      return "catch";
    case SkillId.HERBALISM:
      return "pick";
    case SkillId.WOODCUTTING:
      return "chop";
    case SkillId.MINING:
      return "mine";
    default:
      return "action";
  }
}
