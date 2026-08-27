import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/enchantments/enchantments.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/enchanting_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/systems/enchanting_system.dart';

void main() {
  EnchantingSystem buildSystem() {
    return EnchantingSystem(
      enchantingService: EnchantingService(),
      inventoryService: InventoryService(),
      playerDataService: PlayerDataService(
        buffService: BuffService(),
        equpmentService: EquipmentService(),
        skillService: SkillService(),
      ),
      equipmentService: EquipmentService(),
      enchantmentCatalog: EnchantmentCatalog(),
    );
  }

  test('disenchanting destroys the item and yields tier materials', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    helmet.quality = Rarity.RARE;
    save.inventoryData.equipment.add(helmet);

    final result = system.disenchant(
      helmet.instanceId,
      save.playerData,
      save.inventoryData,
    );

    final gained = result.items.single;
    expect(gained.id, ItemId.ENCHANTING_RUNE); // rare -> runes
    expect(gained.count, greaterThan(0));
    expect(save.inventoryData.equipment, isEmpty);
    expect(save.inventoryData.itemMap[ItemId.ENCHANTING_RUNE], gained.count);
    // enchanting xp was awarded, and reported: an offline settle builds its
    // report out of results, and this is the one action whose xp it cannot
    // work out for itself
    expect(result.xp[SkillId.ENCHANTING], greaterThan(0));
    expect(result.actionsPerformed, 1);
    expect(
      save.playerData.skillData[SkillId.ENCHANTING]!.xp,
      result.xp[SkillId.ENCHANTING],
    );
  });

  test('disenchant yield grows with stat total and level', () {
    final service = EnchantingService();
    expect(
      service.disenchantYield(10, 20),
      greaterThan(service.disenchantYield(10, 1)),
    );
    expect(
      service.disenchantYield(20, 5),
      greaterThan(service.disenchantYield(4, 5)),
    );
    expect(service.disenchantYield(1, 1), greaterThanOrEqualTo(1));
  });

  test('enchanting consumes materials and applies the exact stat total', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final dagger = ItemId.COPPER_DAGGER.build() as EquipmentItem;
    save.inventoryData.equipment.add(dagger);
    save.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 25;

    final enchanted = system.enchant(
      'minor_enchant',
      dagger.instanceId,
      save.playerData,
      save.inventoryData,
    );

    expect(enchanted.equipment, hasLength(1));
    expect(enchanted.actionsPerformed, 1);
    expect(save.inventoryData.itemMap[ItemId.ENCHANTING_DUST], 15);
    expect(dagger.enchantName, isNotEmpty);
    expect(dagger.displayName, contains('of the'));

    // stat total change is exactly the recipe's statTotal (+2 for minor)
    final enchantTotal = dagger.enchantBonus.values.fold(0, (a, b) => a + b);
    expect(enchantTotal, 2);
  });

  test('enchanting fails without level or materials', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final dagger = ItemId.COPPER_DAGGER.build() as EquipmentItem;
    save.inventoryData.equipment.add(dagger);

    // no materials
    expect(
      system
          .enchant(
            'minor_enchant',
            dagger.instanceId,
            save.playerData,
            save.inventoryData,
          )
          .equipment,
      isEmpty,
    );

    // materials but level too low for a higher tier
    save.inventoryData.itemMap[ItemId.ENCHANTING_ESSENCE] = 100;
    save.inventoryData.itemMap[ItemId.ENCHANTING_RUNE] = 100;
    expect(
      system
          .enchant(
            'greater_enchant',
            dagger.instanceId,
            save.playerData,
            save.inventoryData,
          )
          .equipment,
      isEmpty,
    );
    expect(dagger.enchantName, isEmpty);
  });

  test('enchant survives a save round trip', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    helmet.quality = Rarity.EPIC;
    save.inventoryData.equipment.add(helmet);
    save.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 10;

    system.enchant(
      'minor_enchant',
      helmet.instanceId,
      save.playerData,
      save.inventoryData,
    );

    final restored = SaveGameData.fromJson(save.toJson());
    final restoredHelmet = restored.inventoryData.equipment.single;
    expect(restoredHelmet.quality, Rarity.EPIC);
    expect(restoredHelmet.enchantName, helmet.enchantName);
    expect(restoredHelmet.enchantBonus, helmet.enchantBonus);
    expect(restoredHelmet.displayName, helmet.displayName);
  });

  test('worn gear is enchanted in place and stays equipped', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    save.playerData.equipmentData.armorEquipment[helmet.armorSlot] = helmet;
    save.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 10;

    // the bench lists what is worn ahead of the inventory's stacks
    final spare = ItemId.COPPER_HELMET.build() as EquipmentItem;
    save.inventoryData.equipment.add(spare);
    final targets = system.benchTargets(save.playerData, save.inventoryData);
    expect(targets.first.instanceId, helmet.instanceId);
    expect(system.isEquipped(save.playerData, helmet.instanceId), isTrue);
    expect(system.isEquipped(save.playerData, spare.instanceId), isFalse);

    final enchanted = system.enchant(
      'minor_enchant',
      helmet.instanceId,
      save.playerData,
      save.inventoryData,
    );

    // enchanted in place: still on the player, and never passed through
    // the inventory on the way
    expect(enchanted.equipment.single.enchantName, isNotEmpty);
    expect(
      save
          .playerData
          .equipmentData
          .armorEquipment[helmet.armorSlot]
          ?.instanceId,
      helmet.instanceId,
    );
    expect(helmet.enchantName, isNotEmpty);
    expect(save.inventoryData.equipment.single.instanceId, spare.instanceId);
  });

  test('disenchanting worn gear consumes it and empties the slot', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    helmet.quality = Rarity.RARE;
    save.playerData.equipmentData.armorEquipment[helmet.armorSlot] = helmet;

    final gained = system.disenchant(
      helmet.instanceId,
      save.playerData,
      save.inventoryData,
    );

    expect(gained.items, hasLength(1));
    expect(
      save.playerData.equipmentData.armorEquipment[helmet.armorSlot],
      isNull,
    );
    // consumed outright, not dropped back into the inventory
    expect(save.inventoryData.equipment, isEmpty);
  });
}
