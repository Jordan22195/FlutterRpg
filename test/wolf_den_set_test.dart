import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';

// The Wolf Den set is heavy leather turned to speed: the same rung and the
// same budget as the hide it is cut from, split speed-first rather than
// attack and defence evenly. Each den boss owns two pieces; the chest owns
// the body pieces. See design/DUNGEON_LOOT_GUIDE.md.
void main() {
  final heavy = {
    ArmorSlots.HEAD: ItemId.HEAVY_LEATHER_COIF,
    ArmorSlots.BACK: ItemId.HEAVY_LEATHER_COIF,
    ArmorSlots.HANDS: ItemId.HEAVY_LEATHER_GLOVES,
    ArmorSlots.FEET: ItemId.HEAVY_LEATHER_BOOTS,
    ArmorSlots.CHEST: ItemId.HEAVY_LEATHER_CHEST,
    ArmorSlots.LEGS: ItemId.HEAVY_LEATHER_PANTS,
  };
  const set = [
    ItemId.WOLF_DEN_HELM,
    ItemId.WOLF_DEN_CLOAK,
    ItemId.WOLF_DEN_GLOVES,
    ItemId.WOLF_DEN_BOOTS,
    ItemId.WOLF_DEN_CHESTGUARD,
    ItemId.WOLF_DEN_LEGGUARDS,
  ];

  EquipmentItemDefinition gear(ItemId id) =>
      id.definition as EquipmentItemDefinition;
  int total(Map<SkillId, int> stats) => stats.values.fold(0, (a, b) => a + b);

  Map<ItemId, Set<Rarity>> bonusGear(EntityId id) {
    final out = <ItemId, Set<Rarity>>{};
    for (final roll in (id.definition as CombatEntityDefinition).bonusDrops) {
      for (final e in roll.entries.flattened) {
        if (e.id.definition is EquipmentItemDefinition) {
          (out[e.id] ??= {}).add(e.rarity);
        }
      }
    }
    return out;
  }

  test('each piece is worth its heavy counterpart, split toward speed', () {
    for (final id in set) {
      final def = gear(id);
      final base = gear(heavy[def.armorSlot]!);
      expect(def.materialId, EquipmentMaterialId.HEAVY_LEATHER);
      expect(def.bonusStats, isNull, reason: id.name);
      for (final rarity in Rarity.values) {
        expect(
          total(def.statsAt(rarity)),
          total(base.statsAt(rarity)),
          reason: '${id.name} at ${rarity.name}',
        );
      }
      expect(def.statWeights.keys, contains(SkillId.SPEED), reason: id.name);
    }
    // every piece leads with its combat stat and keeps speed second
    for (final id in set) {
      final w = gear(id).statWeights;
      expect(
        w[SkillId.SPEED],
        lessThan(w.values.reduce((a, b) => a > b ? a : b)),
        reason: id.name,
      );
    }
    expect(gear(ItemId.WOLF_DEN_CHESTGUARD).statWeights, {
      SkillId.DEFENCE: 2,
      SkillId.SPEED: 1,
    });
  });

  test('each den boss owns two pieces, at uncommon and rare', () {
    const owned = {
      EntityId.CAVE_BEAR: {ItemId.BEAR_HIDE_BRACERS, ItemId.WOLF_DEN_HELM},
      EntityId.DEN_ALPHA_WOLF: {
        ItemId.WOLF_HIDE_BRACERS,
        ItemId.WOLF_DEN_BOOTS,
      },
      EntityId.GROTTO_FUNGAL_MONSTER: {
        ItemId.REDCAP_RING,
        ItemId.WOLF_DEN_GLOVES,
      },
    };
    for (final MapEntry(key: boss, value: items) in owned.entries) {
      final drops = bonusGear(boss);
      expect(drops.keys.toSet(), items, reason: boss.name);
      for (final rarities in drops.values) {
        expect(rarities, {Rarity.UNCOMMON, Rarity.RARE}, reason: boss.name);
      }
    }
  });

  test(
    'the chest owns the body pieces, and gives some boss pieces at rare',
    () {
      final rolls = DungeonId.WOLF_DEN.definition.chestRolls;
      final gearLines = [
        for (final r in rolls)
          for (final e in r.entries.flattened)
            if (e.id.definition is EquipmentItemDefinition) e,
      ];
      final ids = gearLines.map((e) => e.id).toSet();
      expect(
        ids,
        containsAll([ItemId.WOLF_DEN_CHESTGUARD, ItemId.WOLF_DEN_LEGGUARDS]),
      );
      for (final boss in [
        EntityId.CAVE_BEAR,
        EntityId.DEN_ALPHA_WOLF,
        EntityId.GROTTO_FUNGAL_MONSTER,
      ]) {
        final drops = bonusGear(boss).keys;
        expect(drops, isNot(contains(ItemId.WOLF_DEN_CHESTGUARD)));
        expect(drops, isNot(contains(ItemId.WOLF_DEN_LEGGUARDS)));
      }
      // the boss pieces it gives are at the bosses' top rarity, never above
      for (final e in gearLines) {
        if (e.id == ItemId.WOLF_DEN_CHESTGUARD ||
            e.id == ItemId.WOLF_DEN_LEGGUARDS) {
          continue;
        }
        expect(e.rarity, Rarity.RARE, reason: e.id.name);
      }
    },
  );

  test('the chest still hauls the forest in bulk', () {
    final bulk = [
      for (final r in DungeonId.WOLF_DEN.definition.chestRolls)
        for (final e in r.entries.flattened)
          if (e.id.definition is! EquipmentItemDefinition) e,
    ];
    expect(
      bulk.map((e) => e.id),
      containsAll([
        ItemId.LOGS,
        ItemId.OAK_LOGS,
        ItemId.IRON_ORE,
        ItemId.IRON_BAR,
        ItemId.GUAM_LEAF,
        ItemId.BEAR_CLAW,
        ItemId.WOLF_CLAW,
      ]),
    );
    for (final e in bulk) {
      expect(e.lowCount, 20, reason: e.id.name);
      expect(e.highCount, 80, reason: e.id.name);
    }
  });

  test('the pieces no boss owns fall to the den\'s own wolves and bears', () {
    expect(
      bonusGear(EntityId.FOREST_WOLF_UNCOMMON).keys,
      contains(ItemId.WOLF_DEN_CLOAK),
    );
    expect(
      bonusGear(EntityId.BEAR_UNCOMMON).keys,
      contains(ItemId.WOLF_HIDE_BELT),
    );
  });

  test('the grotto boss hauls bulk herbs, mushrooms and logs, and a ring', () {
    final boss =
        EntityId.GROTTO_FUNGAL_MONSTER.definition as CombatEntityDefinition;
    expect(boss.itemDrops.map((e) => e.id), {
      ItemId.GUAM_LEAF,
      ItemId.HARRALANDER,
      ItemId.RED_CAP_MUSHROOM,
      ItemId.OAK_LOGS,
      ItemId.MAPLE_LOGS,
    });
    for (final e in boss.itemDrops) {
      expect(e.lowCount, 50, reason: e.id.name);
      expect(e.highCount, 150, reason: e.id.name);
    }
    final ring = gear(ItemId.REDCAP_RING);
    // a rung under the boss's loot ceiling (rung 6 - 5)
    expect(ring.fibLevel, 1);
    // recovery rides on a strength piece rather than standing alone
    expect(ring.statWeights, {SkillId.STRENGTH: 2, SkillId.RECOVERY: 1});
  });
}
