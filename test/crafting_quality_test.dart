import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/crafting_state.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/crafting_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/world_service.dart';
import 'package:rpg/systems/crafting_system.dart';

void main() {
  CraftingSystem buildSystem(SaveGameData save, GameCatalogBundle catalogs) {
    final buffService = BuffService();
    final equipmentService = EquipmentService();
    final skillService = SkillService();
    final playerDataService = PlayerDataService(
      buffService: buffService,
      equpmentService: equipmentService,
      skillService: skillService,
    );
    return CraftingSystem(
      playerState: save.playerData,
      inventoryData: save.inventoryData,
      craftingState: save.craftingState,
      worldState: save.worldData,
      recipeCatalog: catalogs.recipeCatalog,
      zoneCatalog: catalogs.zoneCatalog,
      playerDataService: playerDataService,
      craftingService: CraftingService(),
      inventoryService: InventoryService(),
      weightedDropTableService: WeightedDropTableService(),
      worldService: WorldService(),
      buffService: buffService,
      entityCatalog: catalogs.entityCatalog,
    );
  }

  test('rollQuality produces a spread of tiers above the requirement', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final system = buildSystem(save, catalogs);

    final counts = <ItemQuality, int>{};
    for (var i = 0; i < 2000; i++) {
      final q = system.rollQuality(16, 2);
      counts[q] = (counts[q] ?? 0) + 1;
    }

    // common should dominate but never be the only outcome
    expect(counts[ItemQuality.COMMON] ?? 0, greaterThan(1000));
    expect(counts.keys.length, greaterThan(2));
    expect((counts[ItemQuality.UNCOMMON] ?? 0), greaterThan(0));
  });

  test('crafting daggers at level 16 yields quality instances', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final system = buildSystem(save, catalogs);

    // blacksmithing level 16
    final smithing = save.playerData.skillData[SkillId.BLACKSMITHING]!;
    smithing.xp = smithing.xpTable[16];

    // enough bars for 100 daggers
    save.inventoryData.itemMap[ItemId.COPPER_BAR] = 100;

    final craftingState = CraftingState();
    craftingState.activeRecipeId = 'forge_copper_dagger';

    for (var i = 0; i < 100; i++) {
      system.craftActiveRecipeOnce(
        craftingState,
        save.playerData,
        save.inventoryData,
        save.playerData.buffData,
        save.worldData,
      );
    }

    // all 100 crafted, stacked by quality; bars consumed
    final totalCount = save.inventoryData.equipment.fold<int>(
      0,
      (sum, stack) => sum + stack.count,
    );
    expect(totalCount, 100);
    // identical items stack: at most one stack per quality tier
    expect(
      save.inventoryData.equipment.length,
      lessThanOrEqualTo(ItemQuality.values.length),
    );
    expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], isNull);

    // with ~30% non-common odds per craft, 100 crafts virtually
    // guarantee at least one non-common item
    final nonCommon = save.inventoryData.equipment
        .where((e) => e.quality != ItemQuality.COMMON)
        .fold<int>(0, (sum, stack) => sum + stack.count);
    expect(nonCommon, greaterThan(0));

    // quality and stack counts survive a save round trip
    final restored = InventoryData.fromJson(save.inventoryData.toJson());
    expect(
      restored.equipment.fold<int>(0, (sum, stack) => sum + stack.count),
      100,
    );
    expect(
      restored.equipment
          .where((e) => e.quality != ItemQuality.COMMON)
          .fold<int>(0, (sum, stack) => sum + stack.count),
      nonCommon,
    );
  });

  test('identical equipment stacks; equipping takes one off the stack', () {
    final factory = GameSessionFactory();
    final save = factory.newGame(factory.catalog1());
    final inventoryService = InventoryService();

    final a = ItemCatalog.buildItem(ItemId.COPPER_DAGGER) as EquipmentItem;
    final b = ItemCatalog.buildItem(ItemId.COPPER_DAGGER) as EquipmentItem;
    inventoryService.addEquipment(save.inventoryData, a);
    inventoryService.addEquipment(save.inventoryData, b);

    // same name, same quality -> one stack of 2
    expect(save.inventoryData.equipment.length, 1);
    expect(save.inventoryData.equipment.single.count, 2);

    // a different quality does not stack with commons
    final rare = ItemCatalog.buildItem(ItemId.COPPER_DAGGER) as EquipmentItem;
    rare.quality = ItemQuality.RARE;
    inventoryService.addEquipment(save.inventoryData, rare);
    expect(save.inventoryData.equipment.length, 2);

    // taking one off the stack leaves the rest
    final taken = inventoryService.takeOneEquipment(
      save.inventoryData,
      save.inventoryData.equipment.first.instanceId,
    );
    expect(taken, isNotNull);
    expect(taken!.count, 1);
    expect(save.inventoryData.equipment.first.count, 1);
  });
}
