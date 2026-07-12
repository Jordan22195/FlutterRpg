import 'package:flutter/material.dart';
import 'skill_data.dart';

/// Groups skills into the sections shown on the skills screen. Order here is
/// the display order, both of the categories and of the skills within each.
enum SkillCategory { core, combat, gathering, crafting }

const Map<SkillCategory, List<SkillId>> kSkillsByCategory = {
  SkillCategory.core: [
    SkillId.STAMINA,
    SkillId.SPEED,
    SkillId.RECOVERY,
  ],
  SkillCategory.combat: [
    SkillId.HITPOINTS,
    SkillId.ATTACK,
    SkillId.DEFENCE,
    SkillId.RANGED,
    SkillId.MAGIC,
    SkillId.EXPLORATION,
  ],
  SkillCategory.gathering: [
    SkillId.WOODCUTTING,
    SkillId.MINING,
    SkillId.FISHING,
    SkillId.HERBALISM,
  ],
  SkillCategory.crafting: [
    SkillId.FIREMAKING,
    SkillId.COOKING,
    SkillId.LEATHERWORKING,
    SkillId.BLACKSMITHING,
    SkillId.TAILORING,
    SkillId.FLETCHING,
    SkillId.ENCHANTING,
    SkillId.JEWELCRAFTING,
    SkillId.ALCHEMY,
  ],
};

String skillCategoryLabel(SkillCategory category) {
  switch (category) {
    case SkillCategory.core:
      return 'Core';
    case SkillCategory.combat:
      return 'Combat';
    case SkillCategory.gathering:
      return 'Gathering';
    case SkillCategory.crafting:
      return 'Crafting';
  }
}

/// Accent used for the section header and each skill's progress ring.
Color skillCategoryColor(SkillCategory category) {
  switch (category) {
    case SkillCategory.core:
      return const Color(0xFF4EC8A0);
    case SkillCategory.combat:
      return const Color(0xFFE05A58);
    case SkillCategory.gathering:
      return const Color(0xFF8CBF52);
    case SkillCategory.crafting:
      return const Color(0xFFE0A132);
  }
}

/// Title-cased skill name for captions ("STAMINA" -> "Stamina").
String skillLabel(SkillId id) {
  final raw = id.name;
  if (raw.isEmpty) return raw;
  return raw[0] + raw.substring(1).toLowerCase();
}
