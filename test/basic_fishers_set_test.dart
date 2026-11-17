
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';

// The basic fisher's set: six pieces of +2 fishing each. The set comes only
// out of sunken caches (sunken_cache_test).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const slots = {
    ItemId.BASIC_FISHERS_BOOTS: ArmorSlots.FEET,
    ItemId.BASIC_FISHERS_HAT: ArmorSlots.HEAD,
    ItemId.BASIC_FISHERS_TUNIC: ArmorSlots.CHEST,
    ItemId.BASIC_FISHERS_PANTS: ArmorSlots.LEGS,
    ItemId.BASIC_FISHERS_GLOVES: ArmorSlots.HANDS,
    ItemId.BASIC_FISHERS_CLOAK: ArmorSlots.BACK,
  };

  test('every piece is +2 fishing and nothing else, each in its own slot', () {
    for (final entry in slots.entries) {
      final def = entry.key.definition as EquipmentItemDefinition;
      expect(def.armorSlot, entry.value, reason: entry.key.name);
      expect(def.statsAt(Rarity.COMMON), {
        SkillId.FISHING: 2,
      }, reason: entry.key.name);
    }
  });

}
