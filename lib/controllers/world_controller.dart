import 'package:flutter/widgets.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/data/entity_details.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/inventory_data.dart';
import '../services/inventory_service.dart';
import '../catalogs/zone_catalog.dart';
import '../services/player_data_service.dart';
import '../services/exploration_service.dart';
import '../catalogs/entity_catalog.dart';
import '../services/weighted_drop_table_service.dart';
import '../services/entity_screen_router_service.dart';
import '../systems/encounter_system.dart';
import '../systems/exploration_system.dart';
import '../data/zone_details.dart';

class WorldController extends ChangeNotifier {
  // controllers
  final ActionTimingController _actionTimingController;
  final EncounterController _encounterController;
  final CraftingController _craftingController;
  final EnchantingController _enchantingController;

  // data
  final PlayerData _playerState;
  final WorldData _worldState;
  final InventoryData _inventoryState;

  // catalogs
  final ZoneCatalog _zoneCatalog;
  final EntityCatalog _entityCatalog;

  // services
  final ExplorationService _explorationService;
  final EntityScreenRouterService _entityScreenRouterService;
  final PlayerDataService _playerDataService;

  // systems
  final EncounterSystem _encounterSystem;
  final ExplorationSystem _explorationSystem;

  WorldController({
    required WorldData worldState,
    required ExplorationService explorationService,
    required PlayerData playerState,
    required InventoryData inventoryState,
    required ZoneCatalog zoneCatalog,
    required EntityCatalog entityCatalog,
    required EntityScreenRouterService entityScreenRouterService,
    required PlayerDataService playerDataService,
    required EncounterSystem encounterSystem,
    required ExplorationSystem explorationSystem,
    required ActionTimingController actionTimingController,
    required EncounterController encounterController,
    required CraftingController craftingController,
    required EnchantingController enchantingController,
  }) : _playerDataService = playerDataService,
       _inventoryState = inventoryState,
       _explorationService = explorationService,
       _zoneCatalog = zoneCatalog,
       _worldState = worldState,
       _entityCatalog = entityCatalog,
       _playerState = playerState,
       _entityScreenRouterService = entityScreenRouterService,
       _encounterSystem = encounterSystem,
       _explorationSystem = explorationSystem,
       _actionTimingController = actionTimingController,
       _encounterController = encounterController,
       _craftingController = craftingController,
       _enchantingController = enchantingController;

  // world data (entity counts, removals) is mutated by other domains
  // (encounter kills/catches). those controllers are wired to call this
  // in GameSessionFactory
  void refresh() {
    notifyListeners();
  }

  List<Entity> getCurrentZoneEntities() {
    final list = _explorationService.getCurrentZoneEntities(
      _playerState,
      _worldState,
    );
    return list;
  }

  // ---- explore session finds ----

  // whether the explore finds on screen still belong to the player's
  // current activity. the action loop runs one action at a time, so any
  // other action running means the explore session is over
  bool _exploreSessionActive = false;

  bool _isExploreSessionActive() {
    if (_exploreSessionActive &&
        _actionTimingController.isRunning &&
        !_actionTimingController.isRunningAction(doExplore)) {
      _exploreSessionActive = false;
    }
    return _exploreSessionActive;
  }

  /// Items turned up by the current explore session in this zone. Mirrors
  /// the encounter screen's session drops: an ended session shows nothing.
  List<ObjectStack> getCurrentZoneItems() {
    if (!_isExploreSessionActive()) {
      return [];
    }
    return _explorationService.getCurrentZoneItems(_playerState, _worldState);
  }

  ZoneDefinition getCurrentZoneDefinition() {
    return _zoneCatalog.getDefinitionFor(_playerState.currentZoneId);
  }

  // ---- explore screen card data ----

  /// Estimated xp for fully consuming ONE count of [e].
  double xpPerUnit(EncounterEntity e) {
    return _encounterSystem.xpPerUnit(e);
  }

  /// Everything the entity details popup shows for [e]: its own stats, its
  /// drop table odds, and the combat rolls both ways against the player's
  /// current stats.
  EntityDetails entityDetails(EncounterEntity e) {
    return _encounterSystem.buildEntityDetails(
      playerState: _playerState,
      entity: e,
    );
  }

  /// dev/testing helper: force an entity's remaining count in this zone
  void devSetEntityCount(EntityId id, int count) {
    _explorationService.setEntityCount(id, count, _playerState, _worldState);
    notifyListeners();
  }

  /// Level required to interact with [id] (herb gates); 0 when ungated.
  int requiredLevelFor(EntityId id) {
    final def = _entityCatalog.getDefinitionFor(id);
    return def is HerbEntityDefinition ? def.requiredLevel : 0;
  }

  /// Whether the player's stats (with gear/buffs, matching the zone-gate
  /// convention) meet [id]'s level requirement. True for ungated entities.
  bool meetsEntityRequirement(EntityId id) {
    final def = _entityCatalog.getDefinitionFor(id);
    if (def is! HerbEntityDefinition) return true;
    final level =
        _playerDataService.getStatTotals(_playerState)[def.entityType] ?? 0;
    return level >= def.requiredLevel;
  }

  // ---- zone travel ----

  ZoneId get currentZoneId => _playerState.currentZoneId;

  ZoneDefinition zoneDefinition(ZoneId zoneId) {
    return _zoneCatalog.getDefinitionFor(zoneId);
  }

  /// The zone graph's edges, for drawing the travel paths on the map.
  List<(ZoneId, ZoneId, double)> travelEdges() {
    return ZoneCatalog.travelEdges();
  }

  /// Stamina cost to travel from the player's zone to [target], summed
  /// along the path through the zone tree.
  double travelCostTo(ZoneId target) {
    return _zoneCatalog.travelCost(_playerState.currentZoneId, target);
  }

  bool canAffordTravelTo(ZoneId target) {
    return _playerState.stamina >= travelCostTo(target);
  }

  /// Exploration level [target] demands to enter; 0 when ungated.
  int requiredExplorationLevel(ZoneId target) {
    return _zoneCatalog.getDefinitionFor(target).explorationLevel;
  }

  /// Whether the player's exploration reaches [target]'s base difficulty.
  bool meetsZoneExplorationRequirement(ZoneId target) {
    final def = _zoneCatalog.getDefinitionFor(target);
    if (def.explorationLevel <= 0) return true;
    return _explorationSystem.explorationLevel(_playerState) >=
        def.explorationLevel;
  }

  /// Whether the player meets [target]'s extra skill gate (the mine's
  /// mining requirement, say), independent of its exploration level.
  bool meetsZoneSkillRequirement(ZoneId target) {
    final def = _zoneCatalog.getDefinitionFor(target);
    if (def.requiredSkill == SkillId.NULL || def.requiredLevel <= 0) {
      return true;
    }
    final level =
        _playerDataService.getStatTotals(_playerState)[def.requiredSkill] ?? 0;
    return level >= def.requiredLevel;
  }

  /// A zone opens only when both of its gates are met: its exploration
  /// difficulty and any additional skill requirement.
  bool meetsZoneRequirement(ZoneId target) {
    return meetsZoneExplorationRequirement(target) &&
        meetsZoneSkillRequirement(target);
  }

  /// Everything the zone detail screen shows for [zoneId].
  ZoneDetails zoneDetails(ZoneId zoneId) {
    return _explorationSystem.buildZoneDetails(_playerState, zoneId);
  }

  /// Moves the player to [target], paying the path's stamina cost.
  /// Returns false when the level requirement isn't met or stamina can't
  /// cover the cost. Re-entering the current zone is free.
  bool travelToZone(ZoneId target) {
    if (target == _playerState.currentZoneId) return true;
    if (!meetsZoneRequirement(target)) return false;

    final cost = travelCostTo(target);
    if (cost.isInfinite || _playerState.stamina < cost) return false;

    _playerDataService.changeStamina(-cost, _playerState);
    _playerDataService.setCurrentZone(target, _playerState);
    // finds belong to the zone they were made in; leaving ends the session
    _exploreSessionActive = false;
    notifyListeners();
    return true;
  }

  // fires a single time when the explore button is pressed
  // binds doExplore to the periodic loop
  void startExplore() {
    // if already exploring, continue the current explore action
    if (_actionTimingController.isRunningAction(doExplore)) {
      return;
    }

    // stop action timing
    _actionTimingController.stop();

    // exploring after doing something else is a new session, so the
    // previous session's finds are cleared. resuming an explore the
    // player only paused keeps them
    if (!_isExploreSessionActive()) {
      _explorationService.clearCurrentZoneItems(_playerState, _worldState);
    }
    _exploreSessionActive = true;

    // bind explore action to action timing controller
    _actionTimingController.bindOnFireFunction(
      doExplore,
      activityIconId: SkillId.EXPLORATION,
    );

    // start action timing
    _actionTimingController.start();
  }

  // function bound to action button in startExplore.
  // This executes periodically.
  void doExplore() {
    _explorationSystem.explore(
      playerState: _playerState,
      worldState: _worldState,
      playerInventory: _inventoryState,
    );
    notifyListeners();
  }

  void stopExplore() {
    // stop action timing
    _actionTimingController.stop();
    notifyListeners();
  }

  /// Re-pushes the entity screen for the saved [PlayerData.currentEntityViewId]
  /// when rebuilding navigation after an app relaunch. Unlike
  /// [navigateToEntity] this doesn't reset session drop logs — from the
  /// player's perspective they never left the screen. Returns false
  /// (pushing nothing) when the entity is no longer in the current zone,
  /// so the caller can stop at the nearest restorable ancestor.
  bool restoreEntityView(BuildContext context) {
    final entityId = _playerState.currentEntityViewId;
    final present = _explorationService
        .getCurrentZoneEntities(_playerState, _worldState)
        .any((e) => e.id == entityId);
    if (!present) return false;

    _entityScreenRouterService.navigateToEntity(entityId, context);
    return true;
  }

  void navigateToEntity(EntityId entityId, BuildContext context) {
    _entityScreenRouterService.navigateToEntity(entityId, context);

    // todo: move this. break paradigm of only mutating data in services.
    _playerState.currentEntityViewId = entityId;

    // finished encounter/crafting/enchanting sessions clear their
    // drops on navigation
    _encounterController.onEntityViewChanged();
    _craftingController.onEntityViewChanged();
    _enchantingController.onEntityViewChanged();
  }
}
