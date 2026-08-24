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
import '../data/bound_action.dart';
import '../data/offline_progress_data.dart';
import '../services/offline_progress_service.dart';
import '../catalogs/zones/zones.dart';
import '../services/player_data_service.dart';
import '../services/exploration_service.dart';
import '../catalogs/entities/entities.dart';
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
  final OfflineProgressData _offlineProgressData;

  // the world map as a graph; travel cost is a computation, not a lookup
  final ZoneTravelGraph _travelGraph = ZoneTravelGraph();

  // services
  final ExplorationService _explorationService;
  final OfflineProgressService _offlineProgressService;
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
    required EntityScreenRouterService entityScreenRouterService,
    required PlayerDataService playerDataService,
    required EncounterSystem encounterSystem,
    required ExplorationSystem explorationSystem,
    required ActionTimingController actionTimingController,
    required EncounterController encounterController,
    required CraftingController craftingController,
    required EnchantingController enchantingController,
    required OfflineProgressData offlineProgressData,
    required OfflineProgressService offlineProgressService,
  }) : _playerDataService = playerDataService,
       _offlineProgressData = offlineProgressData,
       _offlineProgressService = offlineProgressService,
       _inventoryState = inventoryState,
       _explorationService = explorationService,
       _worldState = worldState,
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

  /// The zone the running explore belongs to. A zone is a place, not a kind
  /// of place: an explore started in one zone is not this zone's explore,
  /// and must not fill this zone's timer or claim its finds.
  ZoneId? _exploreZoneId;

  bool _isExploreSessionActive() {
    if (_exploreSessionActive &&
        _actionTimingController.isRunning &&
        !_actionTimingController.isRunningAction(doExplore)) {
      _exploreSessionActive = false;
    }
    return _exploreSessionActive &&
        _exploreZoneId == _playerState.currentZoneId;
  }

  /// True when the explore loop is running, and running on this zone.
  bool _isExploringHere() {
    return _actionTimingController.isRunningAction(doExplore) &&
        _exploreZoneId == _playerState.currentZoneId;
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
    return _playerState.currentZoneId.definition;
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
    final def = id.definition;
    return def is HerbEntityDefinition ? def.requiredLevel : 0;
  }

  /// Whether the player's stats (with gear/buffs, matching the zone-gate
  /// convention) meet [id]'s level requirement. True for ungated entities.
  bool meetsEntityRequirement(EntityId id) {
    final def = id.definition;
    if (def is! HerbEntityDefinition) return true;
    final level =
        _playerDataService.getStatTotals(_playerState)[def.entityType] ?? 0;
    return level >= def.requiredLevel;
  }

  // ---- zone travel ----

  ZoneId get currentZoneId => _playerState.currentZoneId;

  ZoneDefinition zoneDefinition(ZoneId zoneId) {
    return zoneId.definition;
  }

  /// The zone graph's edges, for drawing the travel paths on the map.
  List<(ZoneId, ZoneId, double)> travelEdges() {
    return ZoneTravelGraph.travelEdges();
  }

  /// Stamina cost to travel from the player's zone to [target], summed
  /// along the path through the zone tree.
  double travelCostTo(ZoneId target) {
    return _travelGraph.travelCost(_playerState.currentZoneId, target);
  }

  bool canAffordTravelTo(ZoneId target) {
    return _playerState.stamina >= travelCostTo(target);
  }

  /// Hops along the cheapest route from the player's zone to [target]; 0 when
  /// they are already there, -1 when unreachable.
  int travelHopsTo(ZoneId target) {
    return ZoneTravelGraph.travelHops(_playerState.currentZoneId, target);
  }

  /// Whether the player's stamina covers walking [from] -> [to] in one hop.
  /// This is about right now, not about the road: it flips back as stamina
  /// recovers, which is what makes an unaffordable edge worth marking.
  bool canAffordHop(ZoneId from, ZoneId to) {
    return _playerState.stamina >= ZoneTravelGraph.edgeCost(from, to);
  }

  /// The player's Exploration level, for stating an unmet zone gate.
  int get playerExplorationLevel {
    return _explorationSystem.explorationLevel(_playerState);
  }

  /// The player's level in [skill], gear and buffs included — the same total
  /// the zone gates are checked against.
  int skillLevelFor(SkillId skill) {
    return _playerDataService.getStatTotals(_playerState)[skill] ?? 0;
  }

  /// Exploration level [target] demands to enter; 0 when ungated.
  int requiredExplorationLevel(ZoneId target) {
    return target.definition.explorationLevel;
  }

  /// Whether the player's exploration reaches [target]'s base difficulty.
  bool meetsZoneExplorationRequirement(ZoneId target) {
    final def = target.definition;
    if (def.explorationLevel <= 0) return true;
    return _explorationSystem.explorationLevel(_playerState) >=
        def.explorationLevel;
  }

  /// Whether the player meets [target]'s extra skill gate (the mine's
  /// mining requirement, say), independent of its exploration level.
  bool meetsZoneSkillRequirement(ZoneId target) {
    final def = target.definition;
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

  /// What's standing in [zoneId]: permanent structures plus the entities
  /// exploring there has turned up. Any zone, not just the one the player
  /// is in, so the map can preview a place before you walk to it.
  List<Entity> zoneEntities(ZoneId zoneId) {
    return _explorationService.getZoneEntities(zoneId, _worldState);
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

    // an explore runs on whatever zone the player is standing in, so it
    // follows them: walking into a new zone carries the session over rather
    // than ending it, and the loop keeps turning without a second tap.
    final wasExploring = _isExploringHere();
    _playerDataService.setCurrentZone(target, _playerState);

    if (wasExploring) {
      // the session is the new zone's now, so the timer belongs to it
      _exploreZoneId = target;
      // finds still belong to the zone they were made in: the new zone
      // starts on a clean sheet rather than showing what an older visit
      // turned up there
      _explorationService.clearCurrentZoneItems(_playerState, _worldState);
    } else {
      // not exploring: any earlier session is over and its finds go with it
      _exploreSessionActive = false;
      _exploreZoneId = null;
    }
    notifyListeners();
    return true;
  }

  // fires a single time when the explore button is pressed
  // binds doExplore to the periodic loop
  void startExplore() {
    // if already exploring this zone, continue the current explore action.
    // an explore belonging to a different zone is not this one's, so it
    // falls through and starts a fresh session here
    if (_isExploringHere()) {
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
    _exploreZoneId = _playerState.currentZoneId;

    // exploring offers no stance, so nothing on this screen could put one
    // back: a strong or defensive stance carried in from a fight would
    // otherwise keep boosting that skill for the whole explore session
    _playerDataService.resetStanceToFast(_playerState);

    // bind explore action to action timing controller
    _actionTimingController.bindOnFireFunction(
      doExplore,
      activityIconId: SkillId.EXPLORATION,
      // nothing is equipped to explore with, so this runs at the default
      actionSkill: SkillId.EXPLORATION,
      boundAction: BoundAction.explore(zoneId: _playerState.currentZoneId),
    );

    // start action timing
    _actionTimingController.start();
  }

  /// How far the player is through the current explore action, 0..1. Zero
  /// unless exploring is the action running — working an entity leaves the
  /// explore screen's timer empty rather than mirroring that entity's.
  double exploreProgress() {
    if (!_isExploringHere()) return 0.0;
    return _actionTimingController.actionProgress;
  }

  /// The interval the explore timer fills over: live while exploring here,
  /// and what starting an explore in this zone would cost otherwise.
  Duration exploreInterval() {
    if (_isExploringHere()) {
      return _actionTimingController.getCurrentActionDuration();
    }
    return _actionTimingController.idleActionDurationFor(SkillId.EXPLORATION);
  }

  // function bound to action button in startExplore.
  // This executes periodically. [count] is how many explores the tick is
  // settling at once - one during normal play, and however many the player
  // was away for when the loop is catching up on offline progress.
  void doExplore(
    int count, {
    bool offline = false,
    DateTime? at,
    Duration? span,
  }) {
    final result = _explorationSystem.explore(
      playerState: _playerState,
      worldState: _worldState,
      playerInventory: _inventoryState,
      numTimesToExplore: count,
      offline: offline,
      at: at,
    );
    // a no-op unless the timing system is settling time away
    _offlineProgressService.recordExplore(_offlineProgressData, result);
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
