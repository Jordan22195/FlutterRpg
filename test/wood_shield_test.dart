import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';

void main() {
  test('a wood shield defends less than a copper one', () {
    final wood = ItemId.WOOD_SHIELD.build() as EquipmentItem;
    final copper = ItemId.COPPER_SHIELD.build() as EquipmentItem;
    expect(
      wood.effectiveSkillBonus[SkillId.DEFENCE]!,
      lessThan(copper.effectiveSkillBonus[SkillId.DEFENCE]!),
    );
  });

  test('the Rotwood Scarecrow drops it, rarer than its pitchfork', () {
    final drops =
        (EntityId.ROTWOOD_SCARECROW.definition as CombatEntityDefinition)
            .itemDrops;
    double weightOf(ItemId id) =>
        drops.firstWhere((d) => d.id == id).weight.toDouble();
    expect(weightOf(ItemId.WOOD_SHIELD), lessThan(weightOf(ItemId.PITCHFORK)));
  });
}
