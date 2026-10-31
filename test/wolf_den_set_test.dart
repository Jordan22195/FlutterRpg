import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/systems/dungeon_system.dart';

// The Wolf Den set is medium leather's stats plus speed: +1 on the minor
// slots and +2 on the major ones. Bosses drop the minors, the chest the majors.
void main() {
  final medium = {
    ArmorSlots.HEAD: ItemId.MEDIUM_LEATHER_COIF,
    ArmorSlots.BACK: ItemId.MEDIUM_LEATHER_COIF,
    ArmorSlots.HANDS: ItemId.MEDIUM_LEATHER_GLOVES,
    ArmorSlots.FEET: ItemId.MEDIUM_LEATHER_BOOTS,
    ArmorSlots.CHEST: ItemId.MEDIUM_LEATHER_CHEST,
    ArmorSlots.LEGS: ItemId.MEDIUM_LEATHER_PANTS,
  };
  final set = {
    ItemId.WOLF_DEN_HELM: 1,
    ItemId.WOLF_DEN_CLOAK: 1,
    ItemId.WOLF_DEN_GLOVES: 1,
    ItemId.WOLF_DEN_BOOTS: 1,
    ItemId.WOLF_DEN_CHESTGUARD: 2,
    ItemId.WOLF_DEN_LEGGUARDS: 2,
  };

  test('each piece is its medium counterpart plus speed at every rarity', () {
    for (final entry in set.entries) {
      final def = entry.key.definition as EquipmentItemDefinition;
      final base = medium[def.armorSlot]!.definition as EquipmentItemDefinition;
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
          if (r.entries != wolfDenMajorArmorDropTable) e,
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
}
