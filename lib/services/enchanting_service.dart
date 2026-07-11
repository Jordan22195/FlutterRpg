import 'dart:math';

import '../catalogs/item_catalog.dart';
import '../data/skill_data.dart';

class EnchantingService {
  /// Skills a random enchant can roll points into.
  static const List<SkillId> statPool = [
    SkillId.ATTACK,
    SkillId.DEFENCE,
    SkillId.HITPOINTS,
    SkillId.STAMINA,
    SkillId.SPEED,
    SkillId.RECOVERY,
    SkillId.WOODCUTTING,
    SkillId.MINING,
    SkillId.FISHING,
    SkillId.HERBALISM,
  ];

  /// The material an item of [quality] disenchants into.
  ItemId materialForQuality(ItemQuality quality) {
    switch (quality) {
      case ItemQuality.COMMON:
        return ItemId.ENCHANTING_DUST;
      case ItemQuality.UNCOMMON:
        return ItemId.ENCHANTING_ESSENCE;
      case ItemQuality.RARE:
        return ItemId.ENCHANTING_RUNE;
      case ItemQuality.EPIC:
        return ItemId.ENCHANTING_PRISM;
      case ItemQuality.LEGENDARY:
        return ItemId.SOUL_SHARD;
    }
  }

  /// How many materials disenchanting yields: scales with the item's
  /// stat total and the player's enchanting level.
  int disenchantYield(int statTotal, int enchantingLevel) {
    final base = statTotal / 2.0;
    final levelMultiplier = 1 + 0.05 * enchantingLevel;
    final amount = (base * levelMultiplier).floor();
    return amount < 1 ? 1 : amount;
  }

  /// Applies a random enchant: [statTotal] points are spread across 1-3
  /// randomly chosen skills (each gets at least 1), and the item takes
  /// [name] as its suffix. Re-enchanting replaces the previous enchant.
  void applyRandomEnchant(
    EquipmentItem item,
    String name,
    int statTotal, {
    Random? rng,
  }) {
    final random = rng ?? Random();

    final maxSkills = min(3, statTotal);
    final skillCount = 1 + random.nextInt(maxSkills);

    final pool = List<SkillId>.of(statPool)..shuffle(random);
    final skills = pool.take(skillCount).toList();

    // every chosen skill gets 1 point; remaining points land randomly
    final bonus = <SkillId, int>{for (final s in skills) s: 1};
    for (var i = skills.length; i < statTotal; i++) {
      final s = skills[random.nextInt(skills.length)];
      bonus[s] = bonus[s]! + 1;
    }

    item.enchantName = name;
    item.enchantBonus = bonus;
  }
}
