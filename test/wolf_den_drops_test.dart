import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeon_id.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';

// the Wolf Den bosses' armour, and the spider den's speed trim
void main() {
  Set<ItemId> bonusItems(EntityId id) {
    final def = id.definition as CombatEntityDefinition;
    return {
      for (final roll in def.bonusDrops)
        for (final e in roll.entries)
          if (e is ItemDropType) e.id,
    };
  }

  EquipmentItemDefinition gear(ItemId id) =>
      id.definition as EquipmentItemDefinition;

  test('the Cave Bear drops bear hide bracers and no boots', () {
    final drops = bonusItems(EntityId.CAVE_BEAR);
    expect(drops, contains(ItemId.BEAR_HIDE_BRACERS));
    expect(drops, isNot(contains(ItemId.WOLF_DEN_BOOTS)));
    expect(drops, contains(ItemId.WOLF_DEN_GLOVES));
  });

  test('the Den Alpha Wolf drops wolf hide bracers and no gloves', () {
    final drops = bonusItems(EntityId.DEN_ALPHA_WOLF);
    expect(drops, contains(ItemId.WOLF_HIDE_BRACERS));
    expect(drops, isNot(contains(ItemId.WOLF_DEN_GLOVES)));
    expect(drops, contains(ItemId.WOLF_DEN_BOOTS));
  });

  test('the den chest can roll the wolf hide belt', () {
    final items = {
      for (final roll in DungeonId.WOLF_DEN.definition.chestRolls)
        for (final e in roll.entries)
          if (e is ItemDropType) e.id,
    };
    expect(items, contains(ItemId.WOLF_HIDE_BELT));
  });

  test('the new pieces carry their stat on the right slot', () {
    expect(gear(ItemId.BEAR_HIDE_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(gear(ItemId.BEAR_HIDE_BRACERS).bonusStats, {SkillId.STRENGTH: 1});
    expect(gear(ItemId.WOLF_HIDE_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(gear(ItemId.WOLF_HIDE_BRACERS).bonusStats, {SkillId.SPEED: 1});
    expect(gear(ItemId.WOLF_HIDE_BELT).armorSlot, ArmorSlots.WAIST);
    expect(gear(ItemId.WOLF_HIDE_BELT).bonusStats, {SkillId.SPEED: 1});
  });

  test('the spider den bosses drop a speed bracer and a speed shoulder', () {
    expect(
      bonusItems(EntityId.THICKET_WEAVER),
      contains(ItemId.WEBBED_BRACERS),
    );
    expect(
      bonusItems(EntityId.SPIDER_BROODMOTHER),
      contains(ItemId.BROODMOTHERS_MANTLE),
    );
    expect(gear(ItemId.WEBBED_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(
      gear(ItemId.WEBBED_BRACERS).bonusStats?[SkillId.SPEED],
      greaterThan(0),
    );
    expect(gear(ItemId.BROODMOTHERS_MANTLE).armorSlot, ArmorSlots.SHOULDER);
    expect(
      gear(ItemId.BROODMOTHERS_MANTLE).bonusStats?[SkillId.SPEED],
      greaterThan(0),
    );
  });
}
