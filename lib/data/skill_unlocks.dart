import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/catalogs/dungeons/dungeon_id.dart';
import '../catalogs/enchantments/enchantments.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../catalogs/recipes/crafting_recipe.dart';
import '../game_session.dart';
import 'skill_data.dart';

class SkillUnlock {
  final String name;
  final int levelRequirement;
  final String category;

  /// What to draw beside the name: an [ItemId] or [EntityId] each, so a gear
  /// set shows every piece it unlocks. Empty for rows that are only text.
  final List<Enum> icons;

  /// A short line under the name, e.g. what a cooked food heals. Null for
  /// most rows.
  final String? detail;

  const SkillUnlock({
    required this.name,
    required this.levelRequirement,
    required this.category,
    this.icons = const [],
    this.detail,
  });
}

/// Merges every catalog's skill-level gate into one sorted list for the
/// skill detail screen's unlocks card.
List<SkillUnlock> unlocksForSkill(SkillId skill, GameCatalogBundle catalogs) {
  final unlocks = <SkillUnlock>[];

  for (final recipe in catalogs.recipeCatalog.recipesForSkill(skill)) {
    // the firepit's reagent mix is a way to run the reagent recipes, not a
    // recipe of its own to unlock
    if (recipe.isReagentMix) continue;
    unlocks.add(
      SkillUnlock(
        name: recipe.name,
        levelRequirement: recipe.levelRequirement,
        category: 'Recipe',
        icons: _recipeIcons(recipe),
        detail: _recipeDetail(recipe),
      ),
    );
  }

  for (final dungeonId in DungeonId.values) {
    if (dungeonId == DungeonId.NULL) continue;
    final dungeon = dungeonId.definition;
    if (dungeon.requiredSkill != skill) continue;
    unlocks.add(
      SkillUnlock(
        name: dungeon.name,
        levelRequirement: dungeon.requiredLevel,
        category: 'Dungeon',
      ),
    );
  }

  for (final zoneId in ZoneId.values) {
    if (zoneId == ZoneId.NULL) continue;
    final zone = zoneId.definition;
    if (zone.requiredSkill == skill) {
      unlocks.add(
        SkillUnlock(
          name: zone.name,
          levelRequirement: zone.requiredLevel,
          category: 'Zone',
        ),
      );
    }

    // a zone's exploration difficulty is a separate gate from its skill
    // requirement, so the mine can appear under both Mining and Exploration
    if (skill == SkillId.EXPLORATION && zone.explorationLevel > 0) {
      unlocks.add(
        SkillUnlock(
          name: zone.name,
          levelRequirement: zone.explorationLevel,
          category: 'Zone',
        ),
      );
    }
  }

  // the gathering nodes: fishing lists its fish rather than its spots, and
  // the fighting skills list none, since a monster is not an unlock
  if (_nodeSkills.contains(skill) && skill != SkillId.FISHING) {
    for (final entityId in EntityId.values) {
      final def = entityId.definition;
      if (def is! EncounterEntityDefinition || def.entityType != skill) {
        continue;
      }
      unlocks.add(
        SkillUnlock(
          name: def.name,
          levelRequirement: def.requiredLevel <= 0 ? 1 : def.requiredLevel,
          category: 'Gathering',
          icons: [entityId],
        ),
      );
    }
  }

  if (skill == SkillId.FISHING) {
    // every fish at the level it first bites, wherever it is caught
    final fishLevels = <ItemId, int>{};
    for (final entityId in EntityId.values) {
      final def = entityId.definition;
      if (def is! FishingEntityDefinition) continue;
      for (final fish in def.itemDrops) {
        final level = fish.unlockLevel < 1 ? 1 : fish.unlockLevel;
        final known = fishLevels[fish.id];
        if (known == null || level < known) fishLevels[fish.id] = level;
      }
    }
    for (final fish in fishLevels.entries) {
      unlocks.add(
        SkillUnlock(
          name: fish.key.definition.name,
          levelRequirement: fish.value,
          category: 'Fish',
          icons: [fish.key],
        ),
      );
    }
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

  unlocks.addAll(_gearUnlocks(skill));

  // stable: rows at the same level keep the order they were found in
  final indexed = unlocks.asMap().entries.toList()
    ..sort((a, b) {
      final byLevel = a.value.levelRequirement.compareTo(
        b.value.levelRequirement,
      );
      return byLevel != 0 ? byLevel : a.key.compareTo(b.key);
    });
  return [for (final e in indexed) e.value];
}

/// The skills whose nodes are worked by hand and listed on their own screen.
const _nodeSkills = {
  SkillId.WOODCUTTING,
  SkillId.MINING,
  SkillId.FISHING,
  SkillId.HERBALISM,
};

/// What a recipe makes, to draw beside it: its first output, which is the
/// good one (a cook's second is the burnt food).
List<Enum> _recipeIcons(CraftingRecipe recipe) {
  if (recipe.output.isEmpty) return const [];
  final id = recipe.output.first.id;
  return id == ItemId.NULL ? const [] : [id];
}

/// A cooked food shows what it heals.
String? _recipeDetail(CraftingRecipe recipe) {
  if (recipe.output.isEmpty) return null;
  final def = recipe.output.first.id.definition;
  if (def is! FoodItemDefinition) return null;
  final what = def.restoreSkill == SkillId.HITPOINTS
      ? 'health'
      : def.restoreSkill.name.toLowerCase();
  return 'Heals ${def.restoreAmount} $what';
}

/// Every set of gear that [skill] gates, one row a set: a skilling tier
/// (Novice, Apprentice…) or a material (Iron, Heavy Leather…). A tool is
/// gated by its metal, so a set that is only one piece, like a pickaxe,
/// reads as that piece's own name.
List<SkillUnlock> _gearUnlocks(SkillId skill) {
  final sets = <String, List<EquipmentItemDefinition>>{};
  final setIds = <String, List<ItemId>>{};
  final setNames = <String, String>{};
  final setLevels = <String, int>{};

  for (final id in ItemId.values) {
    if (id == ItemId.NULL) continue;
    final def = id.definition;
    if (def is! EquipmentItemDefinition || def.skillRequirement != skill) {
      continue;
    }

    final String key;
    final String name;
    if (def is SkillingGearDefinition) {
      key = 'tier:${def.tier.name}';
      name = _title(def.tier.name);
    } else if (def.materialId != EquipmentMaterialId.NULL) {
      key = 'material:${def.materialId.name}';
      name = _title(def.materialId.name);
    } else {
      // dev items and anything else made of nothing
      continue;
    }

    final level = def.skillLevelRequirement < 1 ? 1 : def.skillLevelRequirement;
    final setKey = '$key@$level';
    (sets[setKey] ??= []).add(def);
    (setIds[setKey] ??= []).add(id);
    setNames[setKey] = name;
    setLevels[setKey] = level;
  }

  return [
    for (final key in sets.keys)
      () {
        // worn pieces in slot order, so every set reads the same way
        final pieces = [
          for (var i = 0; i < sets[key]!.length; i++)
            (sets[key]![i], setIds[key]![i]),
        ]..sort((a, b) => a.$1.armorSlot.index.compareTo(b.$1.armorSlot.index));
        return SkillUnlock(
          name: pieces.length == 1
              ? pieces.single.$1.name
              : '${setNames[key]} set',
          levelRequirement: setLevels[key]!,
          category: 'Gear',
          icons: [for (final p in pieces) p.$2],
        );
      }(),
  ];
}

String _title(String enumName) => enumName
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
    .join(' ');
