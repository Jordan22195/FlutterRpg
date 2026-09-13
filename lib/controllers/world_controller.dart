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

  /// What's standing in the zone on screen. The viewed zone, not the current
  /// one: the map can walk you into a place to look at before you decide to
  /// make the trip, and the list has to show that place's things.
  List<Entity> viewedZoneEntities() {
    return _explorationService.getZoneEntities(viewedZoneId, _worldState);
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
    return _exploreSessionActive && _exploreZoneId == viewedZoneId;
  }

  /// True when the explore loop is running, and running on the zone the
  /// player is standing in. This is the action's own truth — what starting,
  /// continuing and carrying an explore across a trip all turn on.
  bool _isExploringHere() {
    return _actionTimingController.isRunningAction(doExplore) &&
        _exploreZoneId == _playerState.currentZoneId;
  }

  /// True when the running explore belongs to the zone on screen. The same
  /// question [_isExploringHere] asks, from the reader's side rather than
  /// the player's: a zone you are only looking at fills no timer of its own.
  bool _isExploringViewed() {
    return _actionTimingController.isRunningAction(doExplore) &&
        _exploreZoneId == viewedZoneId;
  }

  /// Items turned up by the current explore session in the zone on screen.
  /// Mirrors the encounter screen's session drops: an ended session shows
  /// nothing, and neither does a zone you are only looking at.
  List<ObjectStack> viewedZoneItems() {
    if (!_isExploreSessionActive()) {
      return [];
    }
    return _explorationService.getZoneItems(viewedZoneId, _worldState);
  }

  ZoneDefinition viewedZoneDefinition() {
    return viewedZoneId.definition;
  }

  // ---- explore screen card data ----

  /// Estimated xp for fully consuming ONE count of [e].
  double xpPerUnit(EncounterEntity e) {
    return _encounterSystem.xpPerUnit(e);
  }

  /// The number an entity card shows beside its skill icon: a combat
  /// entity's level, or a gathering node's defence — the difficulty the
  /// player's skill is rolled against when working it.
  int entityLevel(EncounterEntity e) {
    return e is CombatEntity ? e.level : e.defence;
  }

  /// Everything the entity details popup shows for [e]: its own stats, its
  /// drop table odds, and the combat rolls both ways against the player's
  /// current stats.
  EntityDetails entityDetails(EncounterEntity e) {
    return _encounterSystem.buildEntityDetails(
      playerState: _playerState,
      entity: e,
      // what working this entity costs per action from here, boost and all:
      // the info tab is read mid-fight, so the rate it quotes has to be the
      // one the button being held is actually producing. Not the interval
      // the action running on some other screen is using.
      actionInterval: _actionTimingController.boostedActionDurationFor(
        e.entityType,
      ),
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

  // ---- the zone on screen ----

  ZoneId get currentZoneId => _playerState.currentZoneId;

  /// The zone the screens are showing — see [PlayerData.currentZoneViewId].
  ZoneId get viewedZoneId => _playerState.currentZoneViewId;

  /// Whether the place on screen is the place the player is standing in.
  /// False is what turns the action button into a travel button.
  bool get isViewingCurrentZone => viewedZoneId == currentZoneId;

  /// Points the screens at [zone] without moving the player. Deliberately
  /// does not touch the running action: looking somewhere is free.
  void setViewedZone(ZoneId zone) {
    if (_playerState.currentZoneViewId == zone) return;
    _playerDataService.setViewedZone(zone, _playerState);
    notifyListeners();
  }

  // ---- zone travel ----

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

  /// How long the trip to [target] takes before the speed stat and any boost
  /// cut it. Its own number, not a function of what the trip costs.
  Duration travelTimeTo(ZoneId target) {
    return _travelGraph.travelTime(_playerState.currentZoneId, target);
  }

  /// Whether the player could set off for [target] right now: the gates are
  /// met, a road exists, and the stamina covers it.
  bool canTravelTo(ZoneId target) {
    if (target == _playerState.currentZoneId) return false;
    if (!meetsZoneRequirement(target)) return false;
    final cost = travelCostTo(target);
    return !cost.isInfinite && _playerState.stamina >= cost;
  }

  /// Moves the player to [target], paying the path's stamina cost.
  /// Returns false when the level requirement isn't met or stamina can't
  /// cover the cost. Re-entering the current zone is free.
  ///
  /// The instant trip. The one the player takes with the travel button runs
  /// on the action loop instead — see [startTravelTo] — and both end in
  /// [_arriveAt]. This one is what the action queue walks with, since a
  /// queue running unattended has nobody to hold the button down.
  bool travelToZone(ZoneId target) {
    if (target == _playerState.currentZoneId) return true;
    if (!canTravelTo(target)) return false;

    _playerDataService.changeStamina(-travelCostTo(target), _playerState);
    _arriveAt(target);
    return true;
  }

  /// Puts the player in [target] and settles what the move means for
  /// anything that was running. Everything after the fare is paid, so the
  /// instant trip and the walked one arrive the same way.
  void _arriveAt(ZoneId target) {
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
  }

  // ---- travelling as an action ----

  /// Where the running walk is headed. Lives only as long as the trip: the
  /// loop holds the action itself, and this is what the action needs to know
  /// when it fires.
  ZoneId? _travelTarget;

  /// True while the loop is walking the player somewhere.
  bool get isTravelling =>
      _actionTimingController.isRunningAction(doTravelArrive);

  /// Where the running walk is headed; null when nothing is walking.
  ZoneId? get travelTarget => isTravelling ? _travelTarget : null;

  /// Pays for the trip to [target] up front and starts walking it.
  ///
  /// Getting there is the whole of it. Arriving does not start whatever the
  /// screen was showing, held button or not: a trip is a decision, and what
  /// to do at the other end is the next one. Coming out of a walk already
  /// swinging would also mean the walk could never be used to simply go
  /// somewhere and look.
  ///
  /// Pressing the button again mid-trip is a boost, not a second departure:
  /// a walk already headed for [target] is left alone and reports success.
  bool startTravelTo(ZoneId target) {
    if (isTravelling && _travelTarget == target) {
      // the finger came back down on the trip already under way
      return true;
    }

    // changing your mind about where you were going. the trip in progress is
    // given up and its fare handed back before the new one is priced, so
    // turning around is not charged twice — and so the new trip is priced
    // against the stamina the old one was holding.
    if (isTravelling) cancelTravel();

    if (!canTravelTo(target)) return false;

    _actionTimingController.stop();

    _playerDataService.changeStamina(-travelCostTo(target), _playerState);
    _travelTarget = target;

    // walking offers no stance, and the road has no picker to put one back,
    // so a strong stance carried out of a fight would otherwise keep
    // boosting strength the whole way there. travel always boosts on speed.
    _playerDataService.resetStanceToFast(_playerState);

    _actionTimingController.bindOnFireFunction(
      doTravelArrive,
      activityIconId: SkillId.EXPLORATION,
      // no item paces a road: the graph does
      actionSkill: null,
      intervalOverride: travelTimeTo(target),
      boundAction: BoundAction.travel(zoneId: target),
    );

    _actionTimingController.start();
    notifyListeners();
    return true;
  }

  /// Gives up on a trip and hands the fare back. The player never left, so
  /// the refund is the same cost the departure charged.
  ///
  /// This is what a relaunch mid-walk does: a walk the player wasn't there
  /// for is not replayed, and is not worth their stamina either. [target] is
  /// for exactly that case — a fresh session has no trip in memory, only the
  /// destination the save recorded, so the caller supplies it.
  void cancelTravel({ZoneId? target}) {
    final destination = target ?? _travelTarget;
    _travelTarget = null;
    if (destination != null) {
      _playerDataService.changeStamina(travelCostTo(destination), _playerState);
    }
    _actionTimingController.stop();
    notifyListeners();
  }

  /// The end of the walk: you are there, and that is all that happens.
  ///
  /// The loop repeats whatever is bound to it, so arriving stops it outright
  /// rather than leaving the road bound to be walked a second time. Nothing
  /// is started in its place — not the screen the trip was launched from,
  /// and not even with the button still held. [ActionTimingService.stop]
  /// empties the boost on its way through, so a finger that never came off
  /// the button is holding nothing by the time the player is standing here.
  ///
  /// [count] is ignored for the same reason the loop is stopped: a batch
  /// settled after time away is still one arrival.
  void doTravelArrive(
    int count, {
    bool offline = false,
    DateTime? at,
    Duration? span,
  }) {
    final target = _travelTarget;
    _travelTarget = null;

    if (target != null) _arriveAt(target);
    _actionTimingController.stop();
  }

  /// Watches for a trip being displaced by something else taking the loop —
  /// the stop button, or an action started from another screen. The fare was
  /// paid at the door for a walk that is not going to happen, so it goes
  /// back. Nothing here fires for an arrival: [doTravelArrive] lets go of
  /// the trip before it stops the loop.
  ///
  /// Wired to the timing loop in [GameSessionFactory], the way the encounter
  /// controller's frame hook is — this is the only signal that reaches every
  /// path that can stop an action.
  void onActionTimingFrame() {
    if (_travelTarget == null) return;
    if (isTravelling) return;
    cancelTravel();
  }

  /// How far along the road the player is, 0..1. Zero unless walking, so a
  /// screen's travel bar is empty whenever nothing is travelling.
  double travelProgress() {
    if (!isTravelling) return 0.0;
    return _actionTimingController.actionProgress;
  }

  /// How long the running walk takes, boost and all. Idle, it quotes what
  /// the trip to the zone on screen would take from a standing start, so the
  /// bar under the travel button reads as the trip that button is offering
  /// rather than as nothing at all.
  Duration travelInterval() {
    if (isTravelling) {
      return _actionTimingController.getCurrentActionDuration();
    }
    return _actionTimingController.idleActionDurationFor(
      null,
      intervalOverride: travelTimeTo(viewedZoneId),
    );
  }

  /// Whether the progress bars belong to travel rather than to the screen's
  /// own action.
  ///
  /// True whenever the button is offering a trip — the place on screen is
  /// not the place the player is standing in, so there is nothing here to
  /// work yet and an action bar under that button would sit at zero forever
  /// without saying why. The bar shows the road instead, empty, quoting what
  /// the trip will take.
  ///
  /// And true while a trip is actually running, wherever the player has
  /// navigated to since: the loop is walking, so no screen's own action is
  /// filling anything.
  bool get isShowingTravel => isTravelling || !isViewingCurrentZone;

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
    if (!_isExploringViewed()) return 0.0;
    return _actionTimingController.actionProgress;
  }

  /// The interval the explore timer fills over: live while exploring here,
  /// and what starting an explore in this zone would cost otherwise.
  Duration exploreInterval() {
    if (_isExploringViewed()) {
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
