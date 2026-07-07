import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/enchantment_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
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
      enchantmentCatalog: EnchantmentCatalog(),
    );
  }

  test('disenchanting destroys the item and yields tier materials', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final helmet = ItemCatalog.buildItem(ItemId.COPPER_HELMET) as EquipmentItem;
    helmet.quality = ItemQuality.RARE;
    save.inventoryData.equipment.add(helmet);

    final gained = system.disenchant(
      helmet.instanceId,
      save.playerData,
      save.inventoryData,
    );

    expect(gained, isNotNull);
    expect(gained!.id, ItemId.ENCHANTING_RUNE); // rare -> runes
    expect(gained.count, greaterThan(0));
    expect(save.inventoryData.equipment, isEmpty);
    expect(
      save.inventoryData.itemMap[ItemId.ENCHANTING_RUNE],
      gained.count,
    );
    // enchanting xp was awarded
    expect(
      save.playerData.skillData[SkillId.ENCHANTING]!.xp,
      greaterThan(0),
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

    final dagger = ItemCatalog.buildItem(ItemId.COPPER_DAGGER) as EquipmentItem;
    save.inventoryData.equipment.add(dagger);
    save.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 25;

    final enchanted = system.enchant(
      'minor_enchant',
      dagger.instanceId,
      save.playerData,
      save.inventoryData,
    );

    expect(enchanted, isNotNull);
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

    final dagger = ItemCatalog.buildItem(ItemId.COPPER_DAGGER) as EquipmentItem;
    save.inventoryData.equipment.add(dagger);

    // no materials
    expect(
      system.enchant(
        'minor_enchant',
        dagger.instanceId,
        save.playerData,
        save.inventoryData,
      ),
      isNull,
    );

    // materials but level too low for a higher tier
    save.inventoryData.itemMap[ItemId.ENCHANTING_ESSENCE] = 100;
    save.inventoryData.itemMap[ItemId.ENCHANTING_RUNE] = 100;
    expect(
      system.enchant(
        'greater_enchant',
        dagger.instanceId,
        save.playerData,
        save.inventoryData,
      ),
      isNull,
    );
    expect(dagger.enchantName, isEmpty);
  });

  test('enchant survives a save round trip', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final system = buildSystem();

    final helmet = ItemCatalog.buildItem(ItemId.COPPER_HELMET) as EquipmentItem;
    helmet.quality = ItemQuality.EPIC;
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
    expect(restoredHelmet.quality, ItemQuality.EPIC);
    expect(restoredHelmet.enchantName, helmet.enchantName);
    expect(restoredHelmet.enchantBonus, helmet.enchantBonus);
    expect(restoredHelmet.displayName, helmet.displayName);
  });
}
