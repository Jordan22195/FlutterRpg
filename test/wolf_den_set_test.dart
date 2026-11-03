import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/systems/dungeon_system.dart';

// The Wolf Den set is heavy leather's stats plus speed: +1 on the minor
// slots and +2 on the major ones. Bosses drop the minors, the chest the majors.
void main() {
  final heavy = {
    ArmorSlots.HEAD: ItemId.HEAVY_LEATHER_COIF,
    ArmorSlots.BACK: ItemId.HEAVY_LEATHER_COIF,
    ArmorSlots.HANDS: ItemId.HEAVY_LEATHER_GLOVES,
    ArmorSlots.FEET: ItemId.HEAVY_LEATHER_BOOTS,
    ArmorSlots.CHEST: ItemId.HEAVY_LEATHER_CHEST,
    ArmorSlots.LEGS: ItemId.HEAVY_LEATHER_PANTS,
  };
  final set = {
    ItemId.WOLF_DEN_HELM: 1,
    ItemId.WOLF_DEN_CLOAK: 1,
    ItemId.WOLF_DEN_GLOVES: 1,
    ItemId.WOLF_DEN_BOOTS: 1,
    ItemId.WOLF_DEN_CHESTGUARD: 2,
    ItemId.WOLF_DEN_LEGGUARDS: 2,
  };

  test('each piece is its heavy counterpart plus speed at every rarity', () {
    for (final entry in set.entries) {
      final def = entry.key.definition as EquipmentItemDefinition;
      final base = heavy[def.armorSlot]!.definition as EquipmentItemDefinition;
      for (final rarity in Rarity.values) {
        final stats = def.statsAt(rarity);
        final expected = base.statsAt(rarity);
        expect(stats[SkillId.SPEED], entry.value, reason: entry.key.name);
        expect(
          {...stats}..remove(SkillId.SPEED),
          expected,
          reason: '${entry.key.name} at ${rarity.name}',
        );
      }
    }
  });

  test('the dungeon bosses drop the minors, rarely', () {
    for (final boss in [
      EntityId.CAVE_BEAR,
      EntityId.DEN_ALPHA_WOLF,
      EntityId.GROTTO_FUNGAL_MONSTER,
    ]) {
      final def = boss.definition as CombatEntityDefinition;
      final roll = def.bonusDrops.singleWhere(
        (r) => r.entries == wolfDenMinorArmorDropTable,
      );
      expect(roll.chance, lessThan(0.1), reason: boss.name);
    }
    expect(wolfDenMinorArmorDropTable.map((e) => e.id), {
      ItemId.WOLF_DEN_HELM,
      ItemId.WOLF_DEN_CLOAK,
      ItemId.WOLF_DEN_GLOVES,
      ItemId.WOLF_DEN_BOOTS,
    });
  });

  test('the chest holds the majors and bulk resources', () {
    final rolls = DungeonId.WOLF_DEN.definition.chestRolls;
    expect(
      rolls.where((r) => r.entries == wolfDenMajorArmorDropTable).single.chance,
      lessThan(0.5),
    );
    final bulk = [
      for (final r in rolls)
        for (final e in r.entries)
          if (r.entries != wolfDenMajorArmorDropTable &&
              r.entries != wolfDenRareSetDropTable)
            e,
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

  test(
    'the boss minors drop uncommon and the end chest holds the set at rare',
    () {
      expect(wolfDenMinorArmorDropTable.map((e) => e.rarity).toSet(), {
        Rarity.UNCOMMON,
      });
      expect(wolfDenRareSetDropTable.map((e) => e.rarity).toSet(), {
        Rarity.RARE,
      });
      expect(wolfDenRareSetDropTable.map((e) => e.id).toSet(), {
        ...wolfDenMinorArmorDropTable.map((e) => e.id),
        ...wolfDenMajorArmorDropTable.map((e) => e.id),
      });
      expect(
        DungeonId.WOLF_DEN.definition.chestRolls.any(
          (r) => r.entries == wolfDenRareSetDropTable,
        ),
        isTrue,
      );
    },
  );

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
    final ring = ItemId.REDCAP_RING.definition as EquipmentItemDefinition;
    expect(ring.fibLevel, 2);
    expect(ring.statWeights.keys, [SkillId.RECOVERY]);
    expect(
      boss.bonusDrops.expand((r) => r.entries).map((e) => e.id),
      contains(ItemId.REDCAP_RING),
    );
  });
}
