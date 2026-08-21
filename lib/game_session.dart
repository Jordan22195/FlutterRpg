import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/catalogs/enchantments/enchantments.dart';
import 'package:rpg/controllers/action_queue_controller.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/services/enchanting_service.dart';
import 'package:rpg/systems/enchanting_system.dart';
import 'package:rpg/systems/offline_progress_system.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/equipment_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/crafting_state.dart';
import 'package:rpg/data/dungeon_run.dart';
import 'package:rpg/data/encounter_data.dart';
import 'package:rpg/controllers/dungeon_controller.dart';
import 'package:rpg/systems/dungeon_system.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/offline_progress_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/offline_progress_service.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/combat_auto_eat_service.dart';
import 'package:rpg/services/entity_screen_router_service.dart';
import 'package:rpg/services/crafting_service.dart';
import 'package:rpg/services/dungeon_service.dart';
import 'package:rpg/services/encounter_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/shop_service.dart';
import 'package:rpg/controllers/shop_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/exploration_service.dart';
import 'package:rpg/systems/crafting_system.dart';
import 'package:rpg/systems/firemaking_system.dart';
import 'package:rpg/systems/encounter_system.dart';
import 'package:rpg/systems/exploration_system.dart';
import 'package:rpg/systems/equipment_system.dart';

import 'data/bound_action.dart';
import 'data/inventory_data.dart';
import 'data/ui_state.dart';

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
  final UiState uiState;
  final ActionTimingData actionTimingData;

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
    UiState? uiState,
    ActionTimingData? actionTimingData,
  }) : dungeonRun = dungeonRun ?? DungeonRun(),
       uiState = uiState ?? UiState(),
       actionTimingData = actionTimingData ?? ActionTimingData();

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
      'uiState': uiState.toJson(),
      'actionTimingData': actionTimingData.toJson(),
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
      // optional: saves from before screen restore have no ui state;
      // default to opening on the map tab
      uiState: json['uiState'] is Map<String, dynamic>
          ? UiState.fromJson(json['uiState'] as Map<String, dynamic>)
          : UiState(),
      // optional: saves from before the action loop was persisted have no
      // timing state; default to an idle loop
      actionTimingData: json['actionTimingData'] is Map<String, dynamic>
          ? ActionTimingData.fromJson(
              json['actionTimingData'] as Map<String, dynamic>,
            )
          : ActionTimingData(),
    );
  }
}

/// The content pack a save was created against.
///
/// Item, entity, zone and dungeon definitions now hang off their id enums, so
/// there is nothing to bundle for them. What remains are the two catalogs
/// still keyed by `String` id — recipes and enchantments, whose ids are
/// written into save data — plus the pack identity that `SaveGameData`
/// records.
class GameCatalogBundle {
  final String id;
  final int version;
  final RecipeCatalog recipeCatalog;
  final EnchantmentCatalog enchantmentCatalog;

  GameCatalogBundle({
    required this.id,
    required this.version,
    required this.recipeCatalog,
    required this.enchantmentCatalog,
  });
}

class GameSessionFactory {
  GameCatalogBundle catalog1() {
    return GameCatalogBundle(
      id: "1",
      version: 1,
      recipeCatalog: RecipeCatalog(),
      enchantmentCatalog: EnchantmentCatalog(),
    );
  }

  // builds a fresh save for first runs or when the stored save
  // cannot be parsed.
  SaveGameData newGame(GameCatalogBundle catalogs) {
    final zones = <ZoneId, Zone>{};
    for (final zoneId in ZoneId.values) {
      if (zoneId == ZoneId.NULL) continue;
      final def = zoneId.definition;
      zones[zoneId] = Zone(
        id: zoneId,
        name: def.name,
        permanentEntities: def.permanentEntities
            .map((id) => id.build())
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
    // migration: saves created before a skill was added have no entry for
    // it. PlayerDataService.applyXp silently drops xp for a missing skill,
    // so backfill before anything can award any
    for (final skillId in SkillId.values) {
      save.playerData.skillData.putIfAbsent(
        skillId,
        () => SkillData(name: skillId.name, xp: 0),
      );
    }

    // migration: saves created before a zone was added have no entry for
    // it in world data; build the missing zones from their definitions
    for (final zoneId in ZoneId.values) {
      if (zoneId == ZoneId.NULL) continue;
      if (save.worldData.zones.containsKey(zoneId)) continue;
      final def = zoneId.definition;
      save.worldData.zones[zoneId] = Zone(
        id: zoneId,
        name: def.name,
        permanentEntities: def.permanentEntities
            .map((id) => id.build())
            .toList(),
        discoveredEntities: [],
      );
    }

    // migration: fires used to be a second entity standing next to the
    // firepit. they are zone buffs owned by the firepit now, so any campfire
    // entity left in a save is dropped. Zone.fromJson already skips the ones
    // whose entity id no longer parses; this catches any that do.
    const retiredFireEntityNames = {'BASIC_CAMPIRE', 'OAK_CAMPFIRE'};
    for (final zone in save.worldData.zones.values) {
      zone.discoveredEntities.removeWhere(
        (e) => retiredFireEntityNames.contains(e.id.name),
      );
    }

    // migration: recipe selections were one per station before a station
    // could offer more than one skill. file each under the skill its recipe
    // trains, which needs the catalog the data layer has no reference to.
    for (final entry in save.craftingState.legacySelections.entries) {
      final skill = catalogs.recipeCatalog.recipeById(entry.value).skill;
      if (skill == SkillId.NULL) continue;
      (save.craftingState.selectedRecipeByEntity[entry.key] ??= {})[skill] =
          entry.value;
    }
    save.craftingState.legacySelections.clear();

    // migration: permanent entities added to a zone definition after the
    // save serialized that zone are synced in on load
    for (final zone in save.worldData.zones.values) {
      final def = zone.id.definition;
      for (final entityId in def.permanentEntities) {
        if (zone.permanentEntities.any((e) => e.id == entityId)) continue;
        zone.permanentEntities.add(entityId.build());
      }
    }

    // migration: fishing spots used to serialize as plain encounter
    // entities. rebuild them from the catalog so they load as the
    // FishingEntity the explore screen groups with the structures - a
    // spot never depletes, so it carries no runtime state worth keeping
    for (final zone in save.worldData.zones.values) {
      for (final list in [zone.permanentEntities, zone.discoveredEntities]) {
        for (var i = 0; i < list.length; i++) {
          final entity = list[i];
          if (entity is FishingEntity) continue;
          final def = entity.id.definition;
          if (def is! FishingEntityDefinition) continue;
          list[i] = def.toEntity(entity.id);
        }
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
        .where((id) => id.definition is EquipmentItemDefinition)
        .toList();
    for (final id in legacyEquipmentIds) {
      final count = save.inventoryData.itemMap.remove(id) ?? 0;
      if (count <= 0) continue;
      final item = id.build();
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

    // session-scoped data: offline progress is recalculated on resume, so
    // the report it collects never has to survive a save
    final offlineProgressData = OfflineProgressData();

    // services
    final buffService = BuffService();
    final craftingService = CraftingService();
    final encounterService = EncounterService();
    final equipmentService = EquipmentService();
    final inventoryService = InventoryService();
    final skillService = SkillService();
    final weightedDropTableService = WeightedDropTableService();
    final explorationService = ExplorationService(
      inventoryService: inventoryService,
    );
    ActionTimingService actionTimingService = ActionTimingService();
    final playerDataService = PlayerDataService(
      buffService: buffService,
      equpmentService: equipmentService,
      skillService: skillService,
    );
    final entityScreenRouterService = EntityScreenRouterService();
    final enchantingService = EnchantingService();
    final enchantmentCatalog = EnchantmentCatalog();
    final shopService = ShopService(inventoryService: inventoryService);
    final offlineProgressService = OfflineProgressService(inventoryService);
    final combatAutoEatService = CombatAutoEatService(
      inventoryService: inventoryService,
      playerDataService: playerDataService,
    );

    // systems
    final firemakingSystem = FiremakingSystem(buffService: buffService);
    final craftingSystem = CraftingSystem(
      playerState: save.playerData,
      inventoryData: save.inventoryData,
      craftingState: save.craftingState,
      worldState: save.worldData,
      recipeCatalog: catalogs.recipeCatalog,
      playerDataService: playerDataService,
      craftingService: craftingService,
      inventoryService: inventoryService,
      weightedDropTableService: weightedDropTableService,
      firemakingSystem: firemakingSystem,
    );
    final encounterSystem = EncounterSystem(
      encounterService: encounterService,
      explorationService: explorationService,
      playerDataService: playerDataService,
      dropTableService: weightedDropTableService,
      inventoryService: inventoryService,
      autoEatService: combatAutoEatService,
    );
    final explorationSystem = ExplorationSystem(
      explorationService: explorationService,
      playerDataService: playerDataService,
      dropTableService: weightedDropTableService,
      inventoryService: inventoryService,
    );
    final equipmentSystem = EquipmentSystem(
      inventoryService: inventoryService,
      equipmentService: equipmentService,
    );
    final enchantingSystem = EnchantingSystem(
      enchantingService: enchantingService,
      inventoryService: inventoryService,
      playerDataService: playerDataService,
      equipmentService: equipmentService,
      enchantmentCatalog: enchantmentCatalog,
    );
    final dungeonSystem = DungeonSystem(
      explorationService: explorationService,
      inventoryService: inventoryService,
      playerDataService: playerDataService,
    );
    final dungeonService = DungeonService();
    ActionTimingSystem actionSpeedSystem = ActionTimingSystem(
      actionTimingService: actionTimingService,
      playerDataService: playerDataService,
      equipmentService: equipmentService,
    );
    final offlineProgressSystem = OfflineProgressSystem(
      actionTimingService: actionTimingService,
      actionTimingSystem: actionSpeedSystem,
      playerDataService: playerDataService,
      skillService: skillService,
      buffService: buffService,
      offlineProgressService: offlineProgressService,
      offlineProgressData: offlineProgressData,
    );

    //controllers
    ActionTimingController actionTimingController = ActionTimingController(
      vsync: vsync,
      actionTimingService: actionTimingService,
      playerState: save.playerData,
      actionSpeedSystem: actionSpeedSystem,
      offlineProgressSystem: offlineProgressSystem,
      actionTimingState: save.actionTimingData,
      offlineProgressData: offlineProgressData,
      offlineProgressService: offlineProgressService,
    );
    final playerDataController = PlayerDataController(
      playerData: save.playerData,
      playerDataService: playerDataService,
      actionTimingController: actionTimingController,
    );
    final inventoryController = InventoryController(
      inventoryData: save.inventoryData,
      inventoryService: inventoryService,
    );
    final encounterController = EncounterController(
      playerData: save.playerData,
      encounterState: save.encounterData,
      dungeonRun: save.dungeonRun,
      dungeonService: dungeonService,
      encounterService: encounterService,
      worldState: save.worldData,
      explorationService: explorationService,
      actionTimingController: actionTimingController,
      dropTableService: weightedDropTableService,
      playerDataService: playerDataService,
      inventoryState: save.inventoryData,
      inventoryService: inventoryService,
      encounterSystem: encounterSystem,
      offlineProgressData: offlineProgressData,
      offlineProgressService: offlineProgressService,
    );
    final buffController = BuffController(
      playerState: save.playerData,
      buffService: buffService,
      actionTimingState: save.actionTimingData,
      offlineProgressSystem: offlineProgressSystem,
    );
    final craftingController = CraftingController(
      actionTimingController: actionTimingController,
      inventoryData: save.inventoryData,
      inventoryService: inventoryService,
      craftingSystem: craftingSystem,
      firemakingSystem: firemakingSystem,
      worldState: save.worldData,
      buffState: save.playerData.buffData,
      craftingService: craftingService,
      craftingState: save.craftingState,
      playerState: save.playerData,
      reciepeCatalog: catalogs.recipeCatalog,
      playerDataService: playerDataService,
      offlineProgressData: offlineProgressData,
      offlineProgressService: offlineProgressService,
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
      playerDataService: playerDataService,
      offlineProgressData: offlineProgressData,
      offlineProgressService: offlineProgressService,
    );
    final worldController = WorldController(
      worldState: save.worldData,
      explorationService: explorationService,
      playerState: save.playerData,
      inventoryState: save.inventoryData,
      entityScreenRouterService: entityScreenRouterService,
      playerDataService: playerDataService,
      encounterSystem: encounterSystem,
      explorationSystem: explorationSystem,
      actionTimingController: actionTimingController,
      encounterController: encounterController,
      craftingController: craftingController,
      enchantingController: enchantingController,
      offlineProgressData: offlineProgressData,
      offlineProgressService: offlineProgressService,
    );
    final dungeonController = DungeonController(
      dungeonRun: save.dungeonRun,
      uiState: save.uiState,
      actionTimingController: actionTimingController,
      encounterController: encounterController,
      playerState: save.playerData,
      inventoryState: save.inventoryData,
      worldState: save.worldData,
      dungeonSystem: dungeonSystem,
      dungeonService: dungeonService,
      inventoryService: inventoryService,
    );
    final shopController = ShopController(
      playerState: save.playerData,
      worldState: save.worldData,
      inventoryState: save.inventoryData,
      explorationService: explorationService,
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
      explorationService: explorationService,
      recipeCatalog: catalogs.recipeCatalog,
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
    // explore finds land in the player inventory as well as the zone list
    worldController.addListener(inventoryController.refresh);

    // encounter actions mutate world data (entity counts, removals);
    // forward so world listeners (explore screen) rebuild
    encounterController.addListener(worldController.refresh);

    // those same actions award skill xp on player data, and equipping
    // changes stat totals; forward so skill readouts (skills grid, skill
    // detail screen, status bars) rebuild as the xp lands
    encounterController.addListener(playerDataController.refresh);
    craftingController.addListener(playerDataController.refresh);
    // firemaking changes the buff list as it crafts, so the buff row must
    // not wait for the next expiry tick to show it
    craftingController.addListener(buffController.refresh);
    enchantingController.addListener(playerDataController.refresh);
    dungeonController.addListener(playerDataController.refresh);
    equipmentController.addListener(playerDataController.refresh);

    // the action timing loop notifies every frame while running; the
    // encounter controller uses it to drive enemy attacks. dungeon cards
    // run through that same encounter loop, so there is nothing extra here
    actionTimingController.addListener(encounterController.onActionTimingFrame);

    return GameSession(
      saveGameData: save,
      offlineProgressData: offlineProgressData,
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
      explorationService: explorationService,
      shopService: shopService,
      craftingSystem: craftingSystem,
      firemakingSystem: firemakingSystem,
      encounterSystem: encounterSystem,
      explorationSystem: explorationSystem,
      equipmentSystem: equipmentSystem,
      dungeonSystem: dungeonSystem,
      actionTimingSystem: actionSpeedSystem,
      offlineProgressSystem: offlineProgressSystem,
    );
  }
}

class GameSession {
  // game state data
  SaveGameData saveGameData;

  /// The buffer offline settles report into. Session-scoped, so it is not
  /// part of [saveGameData].
  OfflineProgressData offlineProgressData;

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
  ExplorationService explorationService;
  ShopService shopService;

  // systems
  CraftingSystem craftingSystem;
  FiremakingSystem firemakingSystem;
  EncounterSystem encounterSystem;
  ExplorationSystem explorationSystem;
  EquipmentSystem equipmentSystem;
  DungeonSystem dungeonSystem;
  ActionTimingSystem actionTimingSystem;
  OfflineProgressSystem offlineProgressSystem;

  GameSession({
    // data
    required this.saveGameData,
    required this.offlineProgressData,

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
    required this.explorationService,
    required this.shopService,

    // systems
    required this.craftingSystem,
    required this.firemakingSystem,
    required this.encounterSystem,
    required this.explorationSystem,
    required this.equipmentSystem,
    required this.dungeonSystem,
    required this.actionTimingSystem,
    required this.offlineProgressSystem,
  });

  /// Rebinds and restarts whatever action the save was running.
  ///
  /// The loop fires a closure, which no save can hold, so the timing state
  /// comes back with [ActionTimingData.running] set and nothing bound to
  /// fire. This re-runs the controller's own start path for the recorded
  /// [BoundAction], which is what actually rebinds it.
  ///
  /// Call after the screens have been restored: a dungeon card restores by
  /// starting its own slot, and this must not start a second action over it.
  void resumeBoundAction() {
    final timing = saveGameData.actionTimingData;
    final bound = timing.boundAction;
    if (!timing.running || bound == null) return;

    // something is already firing - the dungeon card the screen restore
    // started. it is the same action this would resume, so leave it alone
    if (actionTimingController.isTicking) return;

    // every start path below stops the loop first, which resets progress and
    // boost, and stamps lastActionTime to now so a deliberate pause never
    // pays out offline progress. a resume is the opposite case on both
    // counts: the momentum was real and the gap is exactly what is owed. so
    // they are taken now and put back once the action is running again.
    final progress = timing.actionProgressPercentComplete;
    final boost = timing.percentOfMaxBoost;
    final locked = timing.boostLocked;
    final offlineSince = saveGameData.playerData.lastActionTime;

    switch (bound.kind) {
      case BoundActionKind.EXPLORE:
        worldController.startExplore();
      case BoundActionKind.ENCOUNTER:
        final entity = explorationService.getEntity(
          bound.entityId,
          bound.zoneId,
          saveGameData.worldData,
        );
        if (entity is! EncounterEntity) return;
        encounterController.startEncounterActionFor(entity);
      case BoundActionKind.CRAFT:
        craftingController.startCraftingActionFor(
          bound.recipeId,
          bound.entityId,
        );
      case BoundActionKind.ENCHANT:
        enchantingController.startEnchantingActionFor(
          bound.recipeId,
          bound.targetInstanceId,
        );
      case BoundActionKind.DUNGEON_SLOT:
        dungeonController.startSlot(bound.dungeonSlot);
    }

    // the action could not be restarted - the entity is gone, the materials
    // ran out, the card is locked. the player comes back idle
    if (!actionTimingController.isTicking) return;

    timing.actionProgressPercentComplete = progress;
    timing.percentOfMaxBoost = boost;
    timing.boostLocked = locked;
    saveGameData.playerData.lastActionTime = offlineSince;
  }

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
