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

  test('the bracers sit on the wrist and lean toward their stat', () {
    SkillId lead(ItemId id) => gear(id).catalogSecondaries!.first;
    expect(gear(ItemId.BEAR_HIDE_BRACERS).armorSlot, ArmorSlots.WRIST);
    // the bear's are a defender's, leaning strength
    expect(gear(ItemId.BEAR_HIDE_BRACERS).statWeights, {
      SkillId.DEFENCE: 2,
      SkillId.ATTACK: 1,
    });
    expect(lead(ItemId.BEAR_HIDE_BRACERS), SkillId.STRENGTH);
    expect(gear(ItemId.WOLF_HIDE_BRACERS).armorSlot, ArmorSlots.WRIST);
    expect(gear(ItemId.WOLF_HIDE_BRACERS).statWeights, {
      SkillId.ATTACK: 3,
      SkillId.DEFENCE: 1,
    });
    expect(lead(ItemId.WOLF_HIDE_BRACERS), SkillId.SPEED);
    expect(gear(ItemId.WOLF_HIDE_BELT).armorSlot, ArmorSlots.WAIST);
    expect(gear(ItemId.WOLF_HIDE_BELT).statWeights, {
      SkillId.ATTACK: 1,
      SkillId.DEFENCE: 1,
    });
    expect(lead(ItemId.WOLF_HIDE_BELT), SkillId.SPEED);
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
    // defence is the primary on both; speed is the first secondary
    expect(gear(ItemId.WEBBED_BRACERS).statWeights, {SkillId.DEFENCE: 1});
    expect(
      gear(ItemId.WEBBED_BRACERS).catalogSecondaries!.first,
      SkillId.SPEED,
    );
    expect(gear(ItemId.BROODMOTHERS_MANTLE).armorSlot, ArmorSlots.SHOULDER);
    expect(gear(ItemId.BROODMOTHERS_MANTLE).statWeights, {
      SkillId.DEFENCE: 3,
      SkillId.ATTACK: 1,
    });
    expect(
      gear(ItemId.BROODMOTHERS_MANTLE).catalogSecondaries!.first,
      SkillId.SPEED,
    );
  });
}
