import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/equipment_service.dart';

// The BACK slot's two catalog pieces, covering the slot plumbing. Their
// stats come off their definitions, so this reads them rather than
// declaring them: retuning a cloak must not fail these tests.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EquipmentItem cloak(ItemId id) => id.build() as EquipmentItem;

  int defenceOf(ItemId id) =>
      (id.definition as EquipmentItemDefinition).skillBonus[SkillId.DEFENCE]!;

  final woolDefence = defenceOf(ItemId.WOOL_CLOAK);
  final linenDefence = defenceOf(ItemId.LINEN_CAPE);

  test('a fresh EquipmentData has an empty BACK slot', () {
    final equipment = EquipmentData();

    expect(equipment.armorEquipment.containsKey(ArmorSlots.BACK), isTrue);
    expect(equipment.armorEquipment[ArmorSlots.BACK], isNull);
  });

  test('equipping a back item fills the slot and adds its stats', () {
    final service = EquipmentService();
    final equipment = EquipmentData();

    final displaced = service.equipItem(cloak(ItemId.WOOL_CLOAK), equipment);

    expect(displaced, isEmpty);
    expect(equipment.armorEquipment[ArmorSlots.BACK]?.name, 'Wool Cloak');
    expect(service.getStatTotals(equipment)[SkillId.DEFENCE], woolDefence);
  });

  test('a second back item displaces the first', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    final worn = cloak(ItemId.WOOL_CLOAK);

    service.equipItem(worn, equipment);
    final displaced = service.equipItem(cloak(ItemId.LINEN_CAPE), equipment);

    expect(displaced?.map((item) => item.instanceId), [worn.instanceId]);
    expect(equipment.armorEquipment[ArmorSlots.BACK]?.name, 'Linen Cape');
    expect(service.getStatTotals(equipment)[SkillId.DEFENCE], linenDefence);
  });

  test('unequipping the back slot returns the item and clears the slot', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    service.equipItem(cloak(ItemId.WOOL_CLOAK), equipment);

    final removed = service.unequipSlot(ArmorSlots.BACK, equipment);

    expect(removed?.name, 'Wool Cloak');
    expect(equipment.armorEquipment[ArmorSlots.BACK], isNull);
    expect(service.getStatTotals(equipment)[SkillId.DEFENCE], isNull);
  });

  test('an equipped back item survives a JSON round trip', () {
    final equipment = EquipmentData();
    EquipmentService().equipItem(cloak(ItemId.WOOL_CLOAK), equipment);

    final restored = EquipmentData.fromJson(
      jsonDecode(jsonEncode(equipment.toJson())) as Map<String, dynamic>,
    );

    final back = restored.armorEquipment[ArmorSlots.BACK];
    expect(back?.name, 'Wool Cloak');
    expect(back?.armorSlot, ArmorSlots.BACK);
    expect(back?.skillBonus[SkillId.DEFENCE], woolDefence);
  });
}
