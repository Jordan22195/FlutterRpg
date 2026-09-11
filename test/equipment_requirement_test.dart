import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/systems/equipment_system.dart';

/// Gear asks something of the player before it can be worn: the skill comes
/// from what the piece is, the level from what it is made of. This is the
/// enforcement of that — the point where a mithril helmet stops being
/// wearable by a level 1 character who happened to find one.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EquipmentItem item(ItemId id) => id.build() as EquipmentItem;

  group('what a piece asks for', () {
    final service = EquipmentService();

    test('a metal piece asks for its metal at the skill it is used with', () {
      expect(service.requirementFor(item(ItemId.MITHRIL_HELMET)), (
        skill: SkillId.DEFENCE,
        level: 60,
      ));
      expect(service.requirementFor(item(ItemId.MITHRIL_SWORD)), (
        skill: SkillId.ATTACK,
        level: 60,
      ));
      // same metal, same level, three different skills
      expect(service.requirementFor(item(ItemId.STEEL_PICKAXE)), (
        skill: SkillId.MINING,
        level: 40,
      ));
      expect(service.requirementFor(item(ItemId.STEEL_AXE)), (
        skill: SkillId.WOODCUTTING,
        level: 40,
      ));
      expect(service.requirementFor(item(ItemId.COPPER_HELMET)), (
        skill: SkillId.DEFENCE,
        level: 1,
      ));
    });

    test('a hide asks for defence at the tier it sits on', () {
      expect(service.requirementFor(item(ItemId.LIGHT_LEATHER_COIF)), (
        skill: SkillId.DEFENCE,
        level: 1,
      ));
      expect(service.requirementFor(item(ItemId.HEAVY_DEMONHIDE_CHEST)), (
        skill: SkillId.DEFENCE,
        level: 99,
      ));
    });

    test('a piece with no material behind it asks for nothing', () {
      // jewellery, cloth and the pieces off the metal ladder are ungated:
      // there is no tier to gate them by
      for (final id in [
        ItemId.TOPAZ_RING,
        ItemId.WOOL_CLOAK,
        ItemId.STONE_AXE,
        ItemId.SIMPLE_FISHING_ROD,
        ItemId.PITCHFORK,
      ]) {
        expect(
          service.requirementFor(item(id)),
          isNull,
          reason: '${id.name} should be wearable by anyone',
        );
      }
    });

    test('the level is a floor, not a threshold to clear', () {
      final helmet = item(ItemId.MITHRIL_HELMET);
      expect(service.meetsRequirement(helmet, {SkillId.DEFENCE: 59}), isFalse);
      expect(service.meetsRequirement(helmet, {SkillId.DEFENCE: 60}), isTrue);
      expect(service.meetsRequirement(helmet, {SkillId.DEFENCE: 99}), isTrue);
      // the wrong skill at any level does not help
      expect(service.meetsRequirement(helmet, {SkillId.ATTACK: 99}), isFalse);
      expect(service.meetsRequirement(helmet, const {}), isFalse);
    });
  });

  group('the manager refuses what the player cannot wear', () {
    late InventoryService inventoryService;
    late EquipmentSystem system;
    late EquipmentData equipment;
    late InventoryData inventory;

    setUp(() {
      inventoryService = InventoryService();
      system = EquipmentSystem(
        inventoryService: inventoryService,
        equipmentService: EquipmentService(),
      );
      equipment = EquipmentData();
      inventory = InventoryData(itemMap: {});
    });

    test('a refused equip leaves the bag exactly as it was', () {
      final helmet = item(ItemId.MITHRIL_HELMET);
      inventoryService.addEquipment(inventory, helmet);

      final equipped = system.equipItem(
        helmet,
        equipment,
        inventory,
        skillLevels: const {SkillId.DEFENCE: 59},
      );

      expect(equipped, isFalse);
      expect(equipment.armorEquipment[ArmorSlots.HEAD], isNull);
      // the piece must not be swallowed by the attempt
      expect(inventory.equipment.map((i) => i.instanceId), [helmet.instanceId]);
    });

    test('one more level and the same piece goes on', () {
      final helmet = item(ItemId.MITHRIL_HELMET);
      inventoryService.addEquipment(inventory, helmet);

      final equipped = system.equipItem(
        helmet,
        equipment,
        inventory,
        skillLevels: const {SkillId.DEFENCE: 60},
      );

      expect(equipped, isTrue);
      expect(
        equipment.armorEquipment[ArmorSlots.HEAD]?.id,
        ItemId.MITHRIL_HELMET,
      );
      expect(inventory.equipment, isEmpty);
    });

    test('a refused weapon does not displace the one already held', () {
      final copper = item(ItemId.COPPER_SWORD);
      final mithril = item(ItemId.MITHRIL_SWORD);
      inventoryService.addEquipment(inventory, copper);
      inventoryService.addEquipment(inventory, mithril);
      system.equipItem(
        copper,
        equipment,
        inventory,
        skillLevels: const {SkillId.ATTACK: 1},
      );

      final equipped = system.equipItem(
        mithril,
        equipment,
        inventory,
        skillLevels: const {SkillId.ATTACK: 1},
      );

      expect(equipped, isFalse);
      // the sword the player could wear is still in their hand
      expect(
        equipment.armorEquipment[ArmorSlots.WEAPON_1H]?.instanceId,
        copper.instanceId,
      );
      expect(inventory.equipment.map((i) => i.instanceId), [
        mithril.instanceId,
      ]);
    });

    test('a tool is gated by the skill it gathers with, not by combat', () {
      final pickaxe = item(ItemId.MITHRIL_PICKAXE);
      inventoryService.addEquipment(inventory, pickaxe);

      // a max-level fighter who has never mined cannot hold it
      expect(
        system.equipTool(
          SkillId.MINING,
          pickaxe,
          equipment,
          inventory,
          skillLevels: const {SkillId.ATTACK: 99, SkillId.MINING: 1},
        ),
        isFalse,
      );
      expect(equipment.equipedTools[SkillId.MINING], isNull);
      expect(inventory.equipment, isNotEmpty);

      expect(
        system.equipTool(
          SkillId.MINING,
          pickaxe,
          equipment,
          inventory,
          skillLevels: const {SkillId.MINING: 60},
        ),
        isTrue,
      );
      expect(
        equipment.equipedTools[SkillId.MINING]?.id,
        ItemId.MITHRIL_PICKAXE,
      );
    });
  });

  group('gear cannot pay its own way in', () {
    // the requirement is measured against levels earned from xp, never
    // against stat totals — otherwise a player one level short could wear a
    // cloak for the defence it grants and let that count toward the tier
    EquipmentController controllerFor(save, {required int defenceLevel}) {
      final skillService = SkillService();
      final defence = save.playerData.skillData[SkillId.DEFENCE]!;
      defence.xp = defence.xpTable[defenceLevel];
      expect(skillService.getLevel(defence), defenceLevel);

      return EquipmentController(
        playerState: save.playerData,
        inventoryState: save.inventoryData,
        equipmentService: EquipmentService(),
        playerDataService: PlayerDataService(
          buffService: BuffService(),
          equpmentService: EquipmentService(),
          skillService: SkillService(),
        ),
        skillService: skillService,
        equipmentSystem: EquipmentSystem(
          inventoryService: InventoryService(),
          equipmentService: EquipmentService(),
        ),
      );
    }

    test('a borrowed point of defence does not unlock the next tier', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      final controller = controllerFor(save, defenceLevel: 59);

      final cloak = item(ItemId.WOOL_CLOAK); // ungated, and grants defence
      final helmet = item(ItemId.MITHRIL_HELMET);
      save.inventoryData.equipment.addAll([cloak, helmet]);

      expect(controller.equipItem(cloak), isTrue);

      // the cloak has pushed the *total* to the requirement
      final totals = PlayerDataService(
        buffService: BuffService(),
        equpmentService: EquipmentService(),
        skillService: SkillService(),
      ).getStatTotals(save.playerData);
      expect(totals[SkillId.DEFENCE], greaterThanOrEqualTo(60));

      // ...and it still is not enough, because the level is what counts
      expect(controller.canEquip(helmet), isFalse);
      expect(controller.equipItem(helmet), isFalse);
      expect(controller.getItemInSlot(ArmorSlots.HEAD), isNull);
    });

    test('the level itself does unlock it', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      final controller = controllerFor(save, defenceLevel: 60);

      final helmet = item(ItemId.MITHRIL_HELMET);
      save.inventoryData.equipment.add(helmet);

      expect(controller.canEquip(helmet), isTrue);
      expect(controller.equipItem(helmet), isTrue);
      expect(
        controller.getItemInSlot(ArmorSlots.HEAD)?.id,
        ItemId.MITHRIL_HELMET,
      );
    });
  });
}
