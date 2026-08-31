import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/equipment_service.dart';

// the BACK slot has no catalog items yet (SHOULDER and WRIST don't either),
// so these build cloak instances directly to cover the slot plumbing.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EquipmentItem cloak(String name, int defence) {
    return EquipmentItem(
      id: ItemId.NULL,
      name: name,
      value: 10,
      armorSlot: ArmorSlots.BACK,
      skillBonus: {SkillId.DEFENCE: defence},
    );
  }

  test('a fresh EquipmentData has an empty BACK slot', () {
    final equipment = EquipmentData();

    expect(equipment.armorEquipment.containsKey(ArmorSlots.BACK), isTrue);
    expect(equipment.armorEquipment[ArmorSlots.BACK], isNull);
  });

  test('equipping a back item fills the slot and adds its stats', () {
    final service = EquipmentService();
    final equipment = EquipmentData();

    final displaced = service.equipItem(cloak('Wool Cloak', 2), equipment);

    expect(displaced, isEmpty);
    expect(equipment.armorEquipment[ArmorSlots.BACK]?.name, 'Wool Cloak');
    expect(service.getStatTotals(equipment)[SkillId.DEFENCE], 2);
  });

  test('a second back item displaces the first', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    final worn = cloak('Wool Cloak', 2);

    service.equipItem(worn, equipment);
    final displaced = service.equipItem(cloak('Linen Cape', 3), equipment);

    expect(displaced?.map((item) => item.instanceId), [worn.instanceId]);
    expect(equipment.armorEquipment[ArmorSlots.BACK]?.name, 'Linen Cape');
    expect(service.getStatTotals(equipment)[SkillId.DEFENCE], 3);
  });

  test('unequipping the back slot returns the item and clears the slot', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    service.equipItem(cloak('Wool Cloak', 2), equipment);

    final removed = service.unequipSlot(ArmorSlots.BACK, equipment);

    expect(removed?.name, 'Wool Cloak');
    expect(equipment.armorEquipment[ArmorSlots.BACK], isNull);
    expect(service.getStatTotals(equipment)[SkillId.DEFENCE], isNull);
  });

  test('an equipped back item survives a JSON round trip', () {
    final equipment = EquipmentData();
    EquipmentService().equipItem(cloak('Wool Cloak', 2), equipment);

    final restored = EquipmentData.fromJson(
      jsonDecode(jsonEncode(equipment.toJson())) as Map<String, dynamic>,
    );

    final back = restored.armorEquipment[ArmorSlots.BACK];
    expect(back?.name, 'Wool Cloak');
    expect(back?.armorSlot, ArmorSlots.BACK);
    expect(back?.skillBonus[SkillId.DEFENCE], 2);
  });
}
