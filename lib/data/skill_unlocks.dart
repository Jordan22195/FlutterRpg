import '../catalogs/enchantment_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../game_session.dart';
import 'skill_data.dart';

class SkillUnlock {
  final String name;
  final int levelRequirement;
  final String category;

  const SkillUnlock({
    required this.name,
    required this.levelRequirement,
    required this.category,
  });
}

/// Merges every catalog's skill-level gate into one sorted list for the
/// skill detail screen's unlocks card.
List<SkillUnlock> unlocksForSkill(SkillId skill, GameCatalogBundle catalogs) {
  final unlocks = <SkillUnlock>[];

  for (final recipe in catalogs.recipeCatalog.recipesForSkill(skill)) {
    unlocks.add(
      SkillUnlock(
        name: recipe.name,
        levelRequirement: recipe.levelRequirement,
        category: 'Recipe',
      ),
    );
  }

  for (final dungeon in catalogs.dungeonCatalog.all) {
    if (dungeon.requiredSkill != skill) continue;
    unlocks.add(
      SkillUnlock(
        name: dungeon.name,
        levelRequirement: dungeon.requiredLevel,
        category: 'Dungeon',
      ),
    );
  }

  for (final zone in catalogs.zoneCatalog.all) {
    if (zone.requiredSkill != skill) continue;
    unlocks.add(
      SkillUnlock(
        name: zone.name,
        levelRequirement: zone.requiredLevel,
        category: 'Zone',
      ),
    );
  }

  for (final def in catalogs.entityCatalog.all) {
    if (def is! HerbEntityDefinition || def.entityType != skill) continue;
    unlocks.add(
      SkillUnlock(
        name: def.name,
        levelRequirement: def.requiredLevel,
        category: 'Gathering',
      ),
    );
  }

  if (skill == SkillId.ENCHANTING) {
    for (final recipe in EnchantmentCatalog().recipes) {
      unlocks.add(
        SkillUnlock(
          name: recipe.name,
          levelRequirement: recipe.levelRequirement,
          category: 'Enchantment',
        ),
      );
    }
  }

  unlocks.sort((a, b) => a.levelRequirement.compareTo(b.levelRequirement));
  return unlocks;
}
