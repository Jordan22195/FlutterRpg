import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/recipe_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/catalogs/enchantment_catalog.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/services/enchanting_service.dart';
import 'package:rpg/systems/enchanting_system.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/crafting_state.dart';
import 'package:rpg/data/dungeon_run.dart';
import 'package:rpg/data/encounter_data.dart';
import 'package:rpg/catalogs/dungeon_catalog.dart';
import 'package:rpg/controllers/dungeon_controller.dart';
import 'package:rpg/systems/dungeon_system.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/combat_auto_eat_service.dart';
import 'package:rpg/services/entity_screen_router_service.dart';
import 'package:rpg/services/crafting_service.dart';
import 'package:rpg/services/encounter_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/shop_service.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/world_service.dart';
import 'package:rpg/systems/crafting_system.dart';
import 'package:rpg/systems/encounter_system.dart';
import 'package:rpg/systems/equipment_system.dart';

import 'data/inventory_data.dart';

class SaveGameData {
  final String slotId;
  final String contentPackId;
  final int saveVersion;
  final int contentPackVersion;
  final PlayerData playerData;
  final InventoryData inventoryData;
  final WorldData worldData;
  final CraftingState craftingState;
  final EncounterData encounterData;
  final DungeonRun dungeonRun;

  SaveGameData({
    required this.slotId,
    required this.contentPackId,
    required this.saveVersion,
    required this.contentPackVersion,
    required this.playerData,
    required this.inventoryData,
    required this.worldData,
    required this.craftingState,
    required this.encounterData,
    DungeonRun? dungeonRun,
  }) : dungeonRun = dungeonRun ?? DungeonRun();

  Map<String, dynamic> toJson() {
    return {
      'slotId': slotId,
      'contentPackId': contentPackId,
      'saveVersion': saveVersion,
      'contentPackVersion': contentPackVersion,
      'playerData': playerData.toJson(),
      'inventoryData': inventoryData.toJson(),
      'worldData': worldData.toJson(),
      'craftingState': craftingState.toJson(),
      'encounterData': encounterData.toJson(),
      'dungeonRun': dungeonRun.toJson(),
    };
  }

  factory SaveGameData.fromJson(Map<String, dynamic> json) {
    if (json['slotId'] is! String || (json['slotId'] as String).isEmpty) {
      throw FormatException('SaveGameData.slotId is missing or invalid.');
    }
    if (json['contentPackId'] is! String ||
        (json['contentPackId'] as String).isEmpty) {
      throw FormatException(
        'SaveGameData.contentPackId is missing or invalid.',
      );
    }
    if (json['saveVersion'] is! int) {
      throw FormatException('SaveGameData.saveVersion is missing or invalid.');
    }
    if (json['contentPackVersion'] is! int) {
      throw FormatException(
        'SaveGameData.contentPackVersion is missing or invalid.',
      );
    }
    if (json['playerData'] is! Map<String, dynamic>) {
      throw FormatException('SaveGameData.playerData is missing or invalid.');
    }
    if (json['inventoryData'] is! Map<String, dynamic>) {
      throw FormatException(
        'SaveGameData.inventoryData is missing or invalid.',
      );
    }
    if (json['worldData'] is! Map<String, dynamic>) {
      throw FormatException('SaveGameData.worldData is missing or invalid.');
    }
    if (json['craftingState'] is! Map<String, dynamic>) {
      throw FormatException(
        'SaveGameData.craftingState is missing or invalid.',
      );
    }
    if (json['encounterData'] is! Map<String, dynamic>) {
      throw FormatException(
        'SaveGameData.encounterData is missing or invalid.',
      );
    }

    return SaveGameData(
      slotId: json['slotId'] as String,
      contentPackId: json['contentPackId'] as String,
      saveVersion: json['saveVersion'] as int,
      contentPackVersion: json['contentPackVersion'] as int,
      playerData: PlayerData.fromJson(
        json['playerData'] as Map<String, dynamic>,
      ),
      inventoryData: InventoryData.fromJson(
        json['inventoryData'] as Map<String, dynamic>,
      ),
      worldData: WorldData.fromJson(json['worldData'] as Map<String, dynamic>),
      craftingState: CraftingState.fromJson(
        json['craftingState'] as Map<String, dynamic>,
      ),
      encounterData: EncounterData.fromJson(
        json['encounterData'] as Map<String, dynamic>,
      ),
      // optional: saves from before dungeons have no run; default to an
      // inactive one
      dungeonRun: json['dungeonRun'] is Map<String, dynamic>
          ? DungeonRun.fromJson(json['dungeonRun'] as Map<String, dynamic>)
          : DungeonRun(),
    );
  }
}

class GameCatalogBundle {
  final String id;
  final int version;
  final ItemCatalog itemCatalog;
  final EntityCatalog entityCatalog;
  final RecipeCatalog recipeCatalog;
  final ZoneCatalog zoneCatalog;
  final DungeonCatalog dungeonCatalog;

  GameCatalogBundle({
    required this.id,
    required this.version,
    required this.itemCatalog,
    required this.entityCatalog,
    required this.recipeCatalog,
    required this.zoneCatalog,
    required this.dungeonCatalog,
  });
}

class GameSessionFactory {
  GameCatalogBundle catalog1() {
    return GameCatalogBundle(
      id: "1",
      version: 1,
      itemCatalog: ItemCatalog(),
      entityCatalog: EntityCatalog(),
      recipeCatalog: RecipeCatalog(),
      zoneCatalog: ZoneCatalog(),
      dungeonCatalog: DungeonCatalog(),
    );
  }

  // builds a fresh save for first runs or when the stored save
  // cannot be parsed.
  SaveGameData newGame(GameCatalogBundle catalogs) {
    final zones = <ZoneId, Zone>{};
    for (final zoneId in ZoneId.values) {
      if (zoneId == ZoneId.NULL) continue;
      final def = catalogs.zoneCatalog.getDefinitionFor(zoneId);
      if (def.id == ZoneId.NULL) continue;
      zones[zoneId] = Zone(
        id: zoneId,
        name: def.name,
        permanentEntities: def.permanentEntities
            .map((id) => catalogs.entityCatalog.buildEntity(id))
            .toList(),
        discoveredEntities: [],
      );
    }

    // hitpoints starts at level 10; all other skills start at level 1
    final skillData = {
      for (final s in SkillId.values) s: SkillData(name: s.name, xp: 0),
    };
    final hpSkill = skillData[SkillId.HITPOINTS]!;
    hpSkill.xp = hpSkill.xpTable[10];

    return SaveGameData(
      slotId: "slot_1",
      contentPackId: catalogs.id,
      saveVersion: 1,
      contentPackVersion: catalogs.version,
      playerData: PlayerData(
        currentZoneId: ZoneId.TUTORIAL_FARM,
        currentEntityViewId: EntityId.NULL,
        buffData: BuffData(),
        skillData: skillData,
        equipmentData: EquipmentData(),
        hitpoints: 10,
        // matches max stamina at stamina level 1 (10 per level)
        stamina: 10,
      ),
      inventoryData: InventoryData(itemMap: {}),
      worldData: WorldData(zones: zones),
      craftingState: CraftingState(),
      encounterData: EncounterData(),
    );
  }

  GameSession create({
    required SaveGameData save,
    required GameCatalogBundle catalogs,
    required TickerProvider vsync,
  }) {
    // migration: saves created before a zone was added have no entry for
    // it in world data; build the missing zones from their definitions
    for (final zoneId in ZoneId.values) {
      if (zoneId == ZoneId.NULL) continue;
      if (save.worldData.zones.containsKey(zoneId)) continue;
      final def = catalogs.zoneCatalog.getDefinitionFor(zoneId);
      if (def.id == ZoneId.NULL) continue;
      save.worldData.zones[zoneId] = Zone(
        id: zoneId,
        name: def.name,
        permanentEntities: def.permanentEntities
            .map((id) => catalogs.entityCatalog.buildEntity(id))
            .toList(),
        discoveredEntities: [],
      );
    }

    // migration: permanent entities added to a zone definition after the
    // save serialized that zone are synced in on load
    for (final zone in save.worldData.zones.values) {
      final def = catalogs.zoneCatalog.getDefinitionFor(zone.id);
      for (final entityId in def.permanentEntities) {
        if (zone.permanentEntities.any((e) => e.id == entityId)) continue;
        zone.permanentEntities.add(catalogs.entityCatalog.buildEntity(entityId));
      }
    }

    // save repair: an entity must not be both permanent and discovered.
    // (entities discovered before they were promoted to permanent are
    // duplicated in older saves.) the permanent entry wins; the
    // discovered duplicate - the one carrying a discovery count - is
    // dropped. also collapses accidental duplicates within each list
    for (final zone in save.worldData.zones.values) {
      final permanentIds = <EntityId>{};
      zone.permanentEntities.retainWhere((e) => permanentIds.add(e.id));

      final discoveredIds = <EntityId>{};
      zone.discoveredEntities.retainWhere(
        (e) => !permanentIds.contains(e.id) && discoveredIds.add(e.id),
      );
    }

    // migration: equipment used to be stored as stackable counts in the
    // item map; convert those counts into unique equipment instances
    final legacyEquipmentIds = save.inventoryData.itemMap.keys
        .where(
          (id) =>
              catalogs.itemCatalog.definitionFor(id) is EquipmentItemDefition,
        )
        .toList();
    for (final id in legacyEquipmentIds) {
      final count = save.inventoryData.itemMap.remove(id) ?? 0;
      if (count <= 0) continue;
      final item = ItemCatalog.buildItem(id);
      if (item is EquipmentItem) {
        item.count = count;
        save.inventoryData.equipment.add(item);
      }
    }

    // migration: merge identical equipment into stacks (saves from before
    // stacking stored each piece as its own entry)
    final loadedEquipment = save.inventoryData.equipment.toList();
    save.inventoryData.equipment.clear();
    for (final item in loadedEquipment) {
      var merged = false;
      for (final stack in save.inventoryData.equipment) {
        if (stack.canStackWith(item)) {
          stack.count += item.count;
          merged = true;
          break;
        }
      }
      if (!merged) {
        save.inventoryData.equipment.add(item);
      }
    }

    // a save written during the 200ms respawn window restores the flag
    // with no respawn pending; clear it so the ui isn't stuck spinning
    save.encounterData.respawning = false;

    // migration: hitpoints has a level-10 floor; saves created before the
    // floor existed get bumped up (and healed to the new minimum max hp)
    final hpSkill = save.playerData.skillData[SkillId.HITPOINTS];
    if (hpSkill != null && hpSkill.xp < hpSkill.xpTable[10]) {
      hpSkill.xp = hpSkill.xpTable[10];
      if (save.playerData.hitpoints < 10) {
        save.playerData.hitpoints = 10;
      }
    }

    // services
    final buffService = BuffService();
    final craftingService = CraftingService();
    final encounterService = EncounterService();
    final equipmentService = EquipmentService();
    final inventoryService = InventoryService();
    final skillService = SkillService();
    final weightedDropTableService = WeightedDropTableService();
    final worldService = WorldService();
    ActionTimingService actionTimingService = ActionTimingService();
    final playerDataService = PlayerDataService(
      buffService: buffService,
      equpmentService: equipmentService,
      skillService: skillService,
    );
    final entityScreenRouterService = EntityScreenRouterService(
      entityCatalog: catalogs.entityCatalog,
    );
    final enchantingService = EnchantingService();
    final enchantmentCatalog = EnchantmentCatalog();
    final shopService = ShopService(inventoryService: inventoryService);
    final combatAutoEatService = CombatAutoEatService(
      itemCatalog: catalogs.itemCatalog,
      inventoryService: inventoryService,
      playerDataService: playerDataService,
    );

    // systems
    final craftingSystem = CraftingSystem(
      playerState: save.playerData,
      inventoryData: save.inventoryData,
      craftingState: save.craftingState,
      worldState: save.worldData,
      recipeCatalog: catalogs.recipeCatalog,
      zoneCatalog: catalogs.zoneCatalog,
      playerDataService: playerDataService,
      craftingService: craftingService,
      inventoryService: inventoryService,
      weightedDropTableService: weightedDropTableService,
      worldService: worldService,
      buffService: buffService,
      entityCatalog: catalogs.entityCatalog,
    );
    final encounterSystem = EncounterSystem(
      encounterService: encounterService,
      worldService: worldService,
      playerDataService: playerDataService,
      dropTableService: weightedDropTableService,
      inventoryService: inventoryService,
      entityCatalog: catalogs.entityCatalog,
      itemCatalog: catalogs.itemCatalog,
      autoEatService: combatAutoEatService,
    );
    final equipmentSystem = EquipmentSystem(
      inventoryService: inventoryService,
      equipmentService: equipmentService,
    );
    final enchantingSystem = EnchantingSystem(
      enchantingService: enchantingService,
      inventoryService: inventoryService,
      playerDataService: playerDataService,
      enchantmentCatalog: enchantmentCatalog,
    );
    final dungeonSystem = DungeonSystem(
      dungeonCatalog: catalogs.dungeonCatalog,
      entityCatalog: catalogs.entityCatalog,
      encounterService: encounterService,
      dropTableService: weightedDropTableService,
      inventoryService: inventoryService,
      playerDataService: playerDataService,
      autoEatService: combatAutoEatService,
    );
    final zoneBuffSystem = ZoneBuffSystem(
      worldService: worldService,
      buffService: buffService,
    );
    ActionSpeedSystem actionSpeedSystem = ActionSpeedSystem(
      actionTimingService: actionTimingService,
      playerDataService: playerDataService,
    );

    //controllers
    ActionTimingController actionTimingController = ActionTimingController(
      vsync: vsync,
      actionTimingService: actionTimingService,
      playerState: save.playerData,
      actionSpeedSystem: actionSpeedSystem,
    );
    final playerDataController = PlayerDataController(
      playerData: save.playerData,
      playerDataService: playerDataService,
      actionTimingController: actionTimingController,
    );
    final inventoryController = InventoryController(
      inventoryData: save.inventoryData,
      inventoryService: inventoryService,
      itemCatalog: catalogs.itemCatalog,
    );
    final encounterController = EncounterController(
      playerData: save.playerData,
      encounterState: save.encounterData,
      encounterService: encounterService,
      worldState: save.worldData,
      worldService: worldService,
      actionTimingController: actionTimingController,
      entityCatalog: catalogs.entityCatalog,
      dropTableService: weightedDropTableService,
      playerDataService: playerDataService,
      inventoryState: save.inventoryData,
      inventoryService: inventoryService,
      itemCatalog: catalogs.itemCatalog,
      encounterSystem: encounterSystem,
    );
    final buffController = BuffController(
      playerState: save.playerData,
      buffService: buffService,
      zoneBuffSystem: zoneBuffSystem,
      worldState: save.worldData,
    );
    final craftingController = CraftingController(
      actionTimingController: actionTimingController,
      inventoryData: save.inventoryData,
      inventoryService: inventoryService,
      craftingSystem: craftingSystem,
      worldState: save.worldData,
      buffState: save.playerData.buffData,
      craftingService: craftingService,
      craftingState: save.craftingState,
      playerState: save.playerData,
      reciepeCatalog: catalogs.recipeCatalog,
      entityCatalog: catalogs.entityCatalog,
    );
    final equipmentController = EquipmentController(
      playerState: save.playerData,
      inventoryState: save.inventoryData,
      equipmentService: equipmentService,
      equipmentSystem: equipmentSystem,
    );
    final enchantingController = EnchantingController(
      actionTimingController: actionTimingController,
      playerState: save.playerData,
      inventoryState: save.inventoryData,
      enchantmentCatalog: enchantmentCatalog,
      inventoryService: inventoryService,
      enchantingSystem: enchantingSystem,
    );
    final worldController = WorldController(
      worldState: save.worldData,
      worldService: worldService,
      playerState: save.playerData,
      zoneCatalog: catalogs.zoneCatalog,
      dropTableService: weightedDropTableService,
      entityCatalog: catalogs.entityCatalog,
      entityScreenRouterService: entityScreenRouterService,
      playerDataService: playerDataService,
      actionTimingController: actionTimingController,
      encounterController: encounterController,
      craftingController: craftingController,
      enchantingController: enchantingController,
    );
    final dungeonController = DungeonController(
      dungeonRun: save.dungeonRun,
      actionTimingController: actionTimingController,
      playerState: save.playerData,
      inventoryState: save.inventoryData,
      entityCatalog: catalogs.entityCatalog,
      dungeonSystem: dungeonSystem,
      playerDataService: playerDataService,
      inventoryService: inventoryService,
    );
    final shopController = ShopController(
      playerState: save.playerData,
      worldState: save.worldData,
      inventoryState: save.inventoryData,
      entityCatalog: catalogs.entityCatalog,
      itemCatalog: catalogs.itemCatalog,
      worldService: worldService,
      inventoryService: inventoryService,
      shopService: shopService,
    );
    final actionQueueController = ActionQueueController(
      actionTimingController: actionTimingController,
      encounterController: encounterController,
      craftingController: craftingController,
      worldController: worldController,
      playerState: save.playerData,
      worldState: save.worldData,
      worldService: worldService,
      entityCatalog: catalogs.entityCatalog,
      recipeCatalog: catalogs.recipeCatalog,
      zoneCatalog: catalogs.zoneCatalog,
    );

    // encounter, crafting, and equipment actions mutate inventory data;
    // forward their change notifications so inventory listeners rebuild
    encounterController.addListener(inventoryController.refresh);
    craftingController.addListener(inventoryController.refresh);
    equipmentController.addListener(inventoryController.refresh);
    enchantingController.addListener(inventoryController.refresh);
    shopController.addListener(inventoryController.refresh);
    // dungeon combat mutates inventory (drops, key consumption, food)
    dungeonController.addListener(inventoryController.refresh);

    // encounter actions mutate world data (entity counts, removals);
    // forward so world listeners (explore screen) rebuild
    encounterController.addListener(worldController.refresh);

    // the action timing loop notifies every frame while running; the
    // encounter and dungeon controllers use it to drive enemy attacks
    actionTimingController.addListener(encounterController.onActionTimingFrame);
    actionTimingController.addListener(dungeonController.onActionTimingFrame);

    // a run restored from a save (app closed mid-dungeon) resumes its loop
    dungeonController.resumeIfRunning();

    return GameSession(
      saveGameData: save,
      catalogBundle: catalogs,
      playerDataController: playerDataController,
      actionTimingController: actionTimingController,
      inventoryController: inventoryController,
      encounterController: encounterController,
      buffController: buffController,
      craftingController: craftingController,
      equipmentController: equipmentController,
      enchantingController: enchantingController,
      worldController: worldController,
      actionQueueController: actionQueueController,
      shopController: shopController,
      dungeonController: dungeonController,
      buffService: buffService,
      craftingService: craftingService,
      encounterService: encounterService,
      equipmentService: equipmentService,
      inventoryService: inventoryService,
      playerDataService: playerDataService,
      skillService: skillService,
      weightedDropTableService: weightedDropTableService,
      worldService: worldService,
      shopService: shopService,
      craftingSystem: craftingSystem,
      encounterSystem: encounterSystem,
      equipmentSystem: equipmentSystem,
      dungeonSystem: dungeonSystem,
    );
  }
}

class GameSession {
  // game state data
  SaveGameData saveGameData;

  // catalogs
  GameCatalogBundle catalogBundle;

  // controllers
  PlayerDataController playerDataController;
  ActionTimingController actionTimingController;
  InventoryController inventoryController;
  EncounterController encounterController;
  BuffController buffController;
  CraftingController craftingController;
  EquipmentController equipmentController;
  EnchantingController enchantingController;
  WorldController worldController;
  ActionQueueController actionQueueController;
  ShopController shopController;
  DungeonController dungeonController;

  // services
  BuffService buffService;
  CraftingService craftingService;
  EncounterService encounterService;
  EquipmentService equipmentService;
  InventoryService inventoryService;
  PlayerDataService playerDataService;
  SkillService skillService;
  WeightedDropTableService weightedDropTableService;
  WorldService worldService;
  ShopService shopService;

  // systems
  CraftingSystem craftingSystem;
  EncounterSystem encounterSystem;
  EquipmentSystem equipmentSystem;
  DungeonSystem dungeonSystem;

  GameSession({
    // data
    required this.saveGameData,

    // catalogs
    required this.catalogBundle,

    // controllers
    required this.playerDataController,
    required this.actionTimingController,
    required this.inventoryController,
    required this.encounterController,
    required this.buffController,
    required this.craftingController,
    required this.equipmentController,
    required this.enchantingController,
    required this.worldController,
    required this.actionQueueController,
    required this.shopController,
    required this.dungeonController,

    // services
    required this.buffService,
    required this.craftingService,
    required this.encounterService,
    required this.equipmentService,
    required this.inventoryService,
    required this.playerDataService,
    required this.skillService,
    required this.weightedDropTableService,
    required this.worldService,
    required this.shopService,

    // systems
    required this.craftingSystem,
    required this.encounterSystem,
    required this.equipmentSystem,
    required this.dungeonSystem,
  });

  void dispose() {
    // the queue listens to the action timing controller; drop the
    // listener before the timing controller goes away
    actionQueueController.dispose();
    playerDataController.dispose();
    actionTimingController.dispose();
    inventoryController.dispose();
    encounterController.dispose();
    buffController.dispose();
    craftingController.dispose();
    equipmentController.dispose();
    worldController.dispose();
    shopController.dispose();
    dungeonController.dispose();
  }
}
