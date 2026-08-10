import 'package:flutter/material.dart';
import 'skill_data.dart';

/// Groups skills into the sections shown on the skills screen. Order here is
/// the display order, both of the categories and of the skills within each.
enum SkillCategory { core, combat, gathering, crafting }

const Map<SkillCategory, List<SkillId>> kSkillsByCategory = {
  SkillCategory.core: [
    SkillId.STAMINA,
    SkillId.SPEED,
    SkillId.STRENGTH,
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

/// The colour of a skill's xp progress ring, drawn from the palette of the
/// icon that sits inside it — steel for the sword, ore-red for the pick,
/// water blue for the rod — so a ring is recognisable before the art is.
///
/// Every skill gets its own: the rings appear side by side in rows of up to
/// six and in the full skills grid, so no two are within about 15 deltaE of
/// each other. Where a family crowds (the wood and leather browns, the reds
/// of hitpoints and cooking) the members are spread across that family's
/// range rather than pulled out of it.
Color skillRingColor(SkillId id) {
  switch (id) {
    // core loop
    case SkillId.STAMINA:
      return const Color(0xFF2E9BFF); // sky
    case SkillId.SPEED:
      return const Color(0xFFE8D22B); // lightning yellow
    case SkillId.STRENGTH:
      return const Color(0xFFE39AA0); // flesh
    case SkillId.RECOVERY:
      return const Color(0xFF1FC47D); // mint
    case SkillId.EXPLORATION:
      return const Color(0xFFCBA55B); // map parchment

    // combat
    case SkillId.HITPOINTS:
      return const Color(0xFFE33B33); // heart red
    case SkillId.ATTACK:
      return const Color(0xFF9AA7B8); // sword steel
    case SkillId.RANGED:
      return const Color(0xFF4E8C7E); // bowstring teal
    case SkillId.MAGIC:
      return const Color(0xFF6A5CF0); // arcane indigo
    case SkillId.DEFENCE:
      return const Color(0xFFC4694E); // shield bronze

    // gathering
    case SkillId.WOODCUTTING:
      // the canopy rather than the cut timber, matching the green its
      // encounter hp bar is drawn in
      return const Color(0xFF3F8F4E);
    case SkillId.MINING:
      return const Color(0xFF8B4A52); // ore seam
    case SkillId.FISHING:
      return const Color(0xFF2FA5B8); // water
    case SkillId.HERBALISM:
      return const Color(0xFF5AA637); // leaf

    // crafting
    case SkillId.FIREMAKING:
      return const Color(0xFFF26B1E); // flame
    case SkillId.COOKING:
      return const Color(0xFFB83C22); // seared
    case SkillId.LEATHERWORKING:
      return const Color(0xFF8E4A33); // tanned hide
    case SkillId.BLACKSMITHING:
      return const Color(0xFF5E6B7A); // anvil slate
    case SkillId.TAILORING:
      return const Color(0xFFB4713C); // spun cloth
    case SkillId.ENCHANTING:
      return const Color(0xFFA749E8); // rune violet
    case SkillId.JEWELCRAFTING:
      return const Color(0xFF1E6FD8); // cut gem
    case SkillId.FLETCHING:
      return const Color(0xFFA98B5A); // shaft wood
    case SkillId.ALCHEMY:
      return const Color(0xFF8CC63F); // brew

    default:
      return const Color(0xFF8A8F98);
  }
}

/// Accent used for a category's section header.
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
