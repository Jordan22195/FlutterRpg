import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/systems/equipment_system.dart';

// rings are the one item with two homes: they are defined for FINGER and
// can be worn on either finger, so equipping has to choose a slot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EquipmentItem ring(ItemId id) => id.build() as EquipmentItem;

  test('a fresh EquipmentData has two empty ring slots', () {
    final equipment = EquipmentData();

    expect(equipment.armorEquipment.containsKey(ArmorSlots.FINGER), isTrue);
    expect(equipment.armorEquipment.containsKey(ArmorSlots.FINGER_2), isTrue);
    expect(equipment.armorEquipment[ArmorSlots.FINGER], isNull);
    expect(equipment.armorEquipment[ArmorSlots.FINGER_2], isNull);
  });

  test('rings fill the first finger, then the second', () {
    final service = EquipmentService();
    final equipment = EquipmentData();

    service.equipItem(ring(ItemId.TOPAZ_RING), equipment);
    final displaced = service.equipItem(ring(ItemId.RUBY_RING), equipment);

    expect(displaced, isEmpty);
    expect(equipment.armorEquipment[ArmorSlots.FINGER]?.id, ItemId.TOPAZ_RING);
    expect(equipment.armorEquipment[ArmorSlots.FINGER_2]?.id, ItemId.RUBY_RING);
  });

  test('both rings count toward the stat totals', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    final first = ring(ItemId.TOPAZ_RING);
    final second = ring(ItemId.RUBY_RING);

    final oneRing = EquipmentData();
    service.equipItem(first, oneRing);
    final soloTotals = service.getStatTotals(oneRing);

    service.equipItem(ring(ItemId.TOPAZ_RING), equipment);
    service.equipItem(second, equipment);
    final totals = service.getStatTotals(equipment);

    for (final skill in second.effectiveSkillBonus.keys) {
      expect(
        totals[skill],
        (soloTotals[skill] ?? 0) + second.effectiveSkillBonus[skill]!,
        reason: 'the second ring should add its own $skill bonus',
      );
    }
  });

  test('a chosen slot wins over the first empty one', () {
    final service = EquipmentService();
    final equipment = EquipmentData();

    service.equipItem(
      ring(ItemId.RUBY_RING),
      equipment,
      toSlot: ArmorSlots.FINGER_2,
    );

    expect(equipment.armorEquipment[ArmorSlots.FINGER], isNull);
    expect(equipment.armorEquipment[ArmorSlots.FINGER_2]?.id, ItemId.RUBY_RING);
  });

  test('with both fingers full, a new ring displaces the chosen one', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    service.equipItem(ring(ItemId.TOPAZ_RING), equipment);
    final worn = ring(ItemId.RUBY_RING);
    service.equipItem(worn, equipment);

    final displaced = service.equipItem(
      ring(ItemId.ONYX_RING),
      equipment,
      toSlot: ArmorSlots.FINGER_2,
    );

    expect(displaced?.map((item) => item.instanceId), [worn.instanceId]);
    expect(equipment.armorEquipment[ArmorSlots.FINGER]?.id, ItemId.TOPAZ_RING);
    expect(equipment.armorEquipment[ArmorSlots.FINGER_2]?.id, ItemId.ONYX_RING);
  });

  test('the second finger offers the rings the first one does', () {
    final inventory = InventoryData(itemMap: {});
    final service = InventoryService();
    service.addEquipment(inventory, ring(ItemId.TOPAZ_RING));
    service.addEquipment(inventory, ring(ItemId.ONYX_RING));

    final offered = service.getEquipmentForSlot(ArmorSlots.FINGER_2, inventory);

    expect(offered.map((item) => item.id), [
      ItemId.TOPAZ_RING,
      ItemId.ONYX_RING,
    ]);
  });

  test('equipping to a finger takes the ring out of the inventory', () {
    final inventoryService = InventoryService();
    final system = EquipmentSystem(
      inventoryService: inventoryService,
      equipmentService: EquipmentService(),
    );
    final equipment = EquipmentData();
    final inventory = InventoryData(itemMap: {});
    final worn = ring(ItemId.TOPAZ_RING);
    final swappedIn = ring(ItemId.ONYX_RING);
    inventoryService.addEquipment(inventory, worn);
    inventoryService.addEquipment(inventory, swappedIn);

    system.equipItem(worn, equipment, inventory, toSlot: ArmorSlots.FINGER_2);
    expect(inventory.equipment.map((item) => item.instanceId), [
      swappedIn.instanceId,
    ]);

    system.equipItem(
      swappedIn,
      equipment,
      inventory,
      toSlot: ArmorSlots.FINGER_2,
    );

    expect(equipment.armorEquipment[ArmorSlots.FINGER_2]?.id, ItemId.ONYX_RING);
    // the displaced ring goes back where it came from
    expect(inventory.equipment.map((item) => item.instanceId), [
      worn.instanceId,
    ]);
  });

  test('both rings survive a JSON round trip', () {
    final service = EquipmentService();
    final equipment = EquipmentData();
    service.equipItem(ring(ItemId.TOPAZ_RING), equipment);
    service.equipItem(ring(ItemId.RUBY_RING), equipment);

    final restored = EquipmentData.fromJson(
      jsonDecode(jsonEncode(equipment.toJson())) as Map<String, dynamic>,
    );

    expect(restored.armorEquipment[ArmorSlots.FINGER]?.id, ItemId.TOPAZ_RING);
    expect(restored.armorEquipment[ArmorSlots.FINGER_2]?.id, ItemId.RUBY_RING);
  });
}
