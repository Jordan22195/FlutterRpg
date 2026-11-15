import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';

// the Wolf Den bosses' own pieces, and the spider den's speed trim
void main() {
  Set<ItemId> bonusItems(EntityId id) {
    final def = id.definition as CombatEntityDefinition;
    return {
      for (final roll in def.bonusDrops)
        for (final e in roll.entries.flattened)
          if (e.id.definition is EquipmentItemDefinition) e.id,
    };
  }

  EquipmentItemDefinition gear(ItemId id) =>
      id.definition as EquipmentItemDefinition;

  test('the Cave Bear drops bear hide bracers and the helm, nothing else', () {
    expect(bonusItems(EntityId.CAVE_BEAR), {
      ItemId.BEAR_HIDE_BRACERS,
      ItemId.WOLF_DEN_HELM,
    });
  });

  test('the Den Alpha Wolf drops wolf hide bracers and the boots', () {
    expect(bonusItems(EntityId.DEN_ALPHA_WOLF), {
      ItemId.WOLF_HIDE_BRACERS,
      ItemId.WOLF_DEN_BOOTS,
    });
  });

  test('the bracers sit on the wrist and split toward their stat', () {
    expect(gear(ItemId.BEAR_HIDE_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(gear(ItemId.BEAR_HIDE_BRACERS).statWeights, {
      SkillId.STRENGTH: 2,
      SkillId.RECOVERY: 1,
    });
    expect(gear(ItemId.WOLF_HIDE_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(gear(ItemId.WOLF_HIDE_BRACERS).statWeights, {
      SkillId.ATTACK: 2,
      SkillId.SPEED: 1,
    });
    expect(gear(ItemId.WOLF_HIDE_BELT).armorSlot, ArmorSlots.WAIST);
    expect(gear(ItemId.WOLF_HIDE_BELT).statWeights, {
      SkillId.ATTACK: 2,
      SkillId.SPEED: 1,
    });
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
    // the combat stat leads on both; speed rides second
    expect(gear(ItemId.WEBBED_BRACERS).statWeights, {
      SkillId.DEFENCE: 2,
      SkillId.SPEED: 1,
    });
    expect(gear(ItemId.BROODMOTHERS_MANTLE).armorSlot, ArmorSlots.SHOULDER);
    expect(gear(ItemId.BROODMOTHERS_MANTLE).statWeights, {
      SkillId.DEFENCE: 2,
      SkillId.SPEED: 1,
    });
  });
}
