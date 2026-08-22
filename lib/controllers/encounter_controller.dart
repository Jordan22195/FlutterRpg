import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/services/exploration_service.dart';
import '../data/bound_action.dart';
import '../data/offline_progress_data.dart';
import '../services/offline_progress_service.dart';
import '../data/dungeon_run.dart';
import '../data/encounter_data.dart';
import '../services/dungeon_service.dart';
import '../services/encounter_service.dart';
import '../systems/encounter_system.dart';
import '../services/inventory_service.dart';
import '../data/ObjectStack.dart';

// controllers coordinate between ui and systems or services
// systems coordinate multiple services

class EncounterController extends ChangeNotifier {
  // nonserialized data
  final EncounterData _encounterState;

  // controllers
  final ActionTimingController _actionTimingController;

  // data
  final PlayerData _playerState;
  final WorldData _worldState;
  final InventoryData _inventoryState;
  final DungeonRun _dungeonRun;
  final OfflineProgressData _offlineProgressData;

  // services
  final EncounterService _encounterService;
  final OfflineProgressService _offlineProgressService;
  final ExplorationService _explorationService;
  final PlayerDataService _playerDataService;
  final InventoryService _inventoryService;
  final DungeonService _dungeonService;

  //systems
  final EncounterSystem _encounterSystem;

  EncounterActionResult latestActionResult = EncounterActionResult();

  // increments every time an encounter action fires; lets the ui replay
  // per-action feedback (damage numbers) even when the value repeats
  int actionSequence = 0;

  // last damage the combat entity dealt to the player, with its own
  // sequence so the ui can replay the hit feedback
  int latestEntityDamage = 0;
  int entityAttackSequence = 0;
  DateTime? _lastEntityAttackAt;

  // increments each time the player is killed in an encounter. the shell
  // watches this to drop back to the map screen and announce the death;
  // a sequence (rather than a flag) so repeat deaths always register
  int deathSequence = 0;

  // increments each time a dungeon card is fully cleared. the shell watches
  // this to drop back to the dungeon list (or run the next card); a
  // sequence, so clearing the same card twice always registers
  int slotClearedSequence = 0;

  /// The card index that [slotClearedSequence] last reported.
  int lastClearedSlot = -1;

  EncounterController({
    required PlayerData playerData,
    required EncounterData encounterState,
    required DungeonRun dungeonRun,
    required DungeonService dungeonService,

    required EncounterService encounterService,
    required WorldData worldState,
    required ExplorationService explorationService,
    required ActionTimingController actionTimingController,
    required WeightedDropTableService dropTableService,
    required PlayerDataService playerDataService,
    required InventoryData inventoryState,
    required InventoryService inventoryService,
    required EncounterSystem encounterSystem,
    required OfflineProgressData offlineProgressData,
    required OfflineProgressService offlineProgressService,
  }) : _playerState = playerData,
       _offlineProgressData = offlineProgressData,
       _offlineProgressService = offlineProgressService,
       _encounterState = encounterState,
       _dungeonRun = dungeonRun,
       _dungeonService = dungeonService,
       _encounterService = encounterService,
       _worldState = worldState,
       _explorationService = explorationService,
       _actionTimingController = actionTimingController,
       _playerDataService = playerDataService,
       _inventoryState = inventoryState,
       _encounterSystem = encounterSystem,
       _inventoryService = inventoryService;

  void doFishingEncounterAction(
    int count, {
    bool offline = false,
    DateTime? at,
    Duration? span,
  }) {
    latestActionResult = _encounterSystem.executeFishingAction(
      playerState: _playerState,
      encounter: _encounterState,
      world: _worldState,
      playerInventory: _inventoryState,
      actionCount: count,
      offline: offline,
      at: at,
    );
    actionSequence++;
    _recordOfflineResult();

    // fishing spots never deplete, so they are barred from dungeon cards
    // and there is no queue to advance here

    // check action conditions are met before the action fires again
    if (!_encounterService.fishingConditionsMet(
      _playerState,
      _encounterState,
    )) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  void doHerbalismEncounterAction(
    int count, {
    bool offline = false,
    DateTime? at,
    Duration? span,
  }) {
    latestActionResult = _encounterSystem.executeHerbalismAction(
      playerState: _playerState,
      encounter: _encounterState,
      worldState: _worldState,
      playerInventory: _inventoryState,
      actionCount: count,
      offline: offline,
      at: at,
    );
    actionSequence++;
    _recordOfflineResult();
    _recordDungeonDrops();

    if (_advanceDungeonQueue()) {
      notifyListeners();
      return;
    }

    // check action conditions are met before the action fires again
    if (!_herbalismConditionsMet()) {
      _actionTimingController.stop();
    }
    notifyListeners();
  }

  // basic gather conditions plus the herb's herbalism level gate
  bool _herbalismConditionsMet() {
    if (!_encounterService.herbalismConditionsMet(
      _playerState,
      _encounterState,
    )) {
      return false;
    }
    return _encounterSystem.meetsHerbRequirement(
      _playerState,
      _encounterState.entity!.id,
    );
  }

  // function bound to action button in startEncounterAction.
  // This executes periodically.
  //
  void doEncounterAction(
    int count, {
    bool offline = false,
    DateTime? at,
    Duration? span,
  }) {
    latestActionResult = _encounterSystem.executePlayerAction(
      playerState: _playerState,
      encounter: _encounterState,
      worldState: _worldState,
      playerInventory: _inventoryState,
      instantRespawn: _dungeonService.runningEntity(_dungeonRun) != null,
      actionCount: count,
      offline: offline,
      at: at,
      span: span,
    );
    actionSequence++;
    _recordOfflineResult();
    _recordDungeonDrops();

    // the fight killed the player while they were away. this sits above the
    // queue advance for the same reason the shell checks death first: a
    // death inside a dungeon card ends the run, it does not hand off to the
    // next card. from here it is the live death path - the loop stops, they
    // come back on 1 hp, and the shell unwinds the map and leaves the run.
    if (latestActionResult.playerDied) {
      _offlineProgressService.recordDeath(
        _offlineProgressData,
        killedBy: _encounterState.entity?.id,
      );
      _actionTimingController.stop();
      _playerDataService.heal(1, _playerState);
      deathSequence++;
      notifyListeners();
      return;
    }

    // a dungeon card is a queue: a spent member hands off to the next one
    // before the conditions below get a chance to stop the loop
    if (_advanceDungeonQueue()) {
      notifyListeners();
      return;
    }

    // check action conditions are met before the action fires again
    if (!_encounterService.encounterConditionsMet(
      _playerState,
      _encounterState,
    )) {
      // stop action timing
      _actionTimingController.stop();
      // todo reset encouter state
    }
    notifyListeners();
  }

  // ---- dungeon cards ----

  /// Starts dungeon card [index] — the encounter behind a card tap. Only
  /// one card runs at a time, so this drops whatever was running.
  ///
  /// The encounter panel's drop log is a card's own haul, so a new card
  /// starts it fresh; the run's cumulative haul lives on the run.
  bool startDungeonSlot(int index) {
    final entity = _dungeonService.slotAt(_dungeonRun, index)?.current;
    if (entity == null) return false;

    _actionTimingController.stop();
    // set before delegating: startEncounterActionFor reads the running card
    // to decide whether this start is leaving the dungeon
    _dungeonRun.runningSlot = index;
    _playerState.currentEntityViewId = entity.id;

    return startEncounterActionFor(entity);
  }

  /// Adds this tick's result to the offline progress report. A no-op unless
  /// the timing system is settling time away, so normal play costs a call
  /// and a flag check.
  void _recordOfflineResult() {
    _offlineProgressService.record(_offlineProgressData, latestActionResult);
  }

  /// Copies this tick's drops into the run's cumulative haul. The encounter
  /// panel's own log resets with each card, so the run total has to be kept
  /// separately — the dungeon list's loot tab reads it.
  void _recordDungeonDrops() {
    if (_dungeonService.runningEntity(_dungeonRun) == null) return;
    _inventoryService.addItems(_dungeonRun.loot, latestActionResult.items);
  }

  /// Hands the running card off to its next member, keeping the loop
  /// running. Returns true when it did — the caller then skips its own
  /// conditions check, which would otherwise see the spent member and stop.
  ///
  /// Clearing the last member marks the card and stops the loop, reporting
  /// through [slotClearedSequence].
  bool _advanceDungeonQueue() {
    final slot = _dungeonService.runningSlot(_dungeonRun);
    final current = slot?.current;
    if (current == null) return false;

    // only the member the loop is actually firing on can advance the queue
    if (!identical(_encounterState.entity, current)) return false;
    if (current.count > 0) return false;

    final next = _dungeonService.advanceRunning(_dungeonRun);
    if (next != null) {
      _startDungeonMember(next);
      return true;
    }

    _dungeonService.markCleared(_dungeonRun, _dungeonRun.runningSlot);
    _actionTimingController.stop();
    lastClearedSlot = _dungeonRun.runningSlot;
    slotClearedSequence++;
    return false;
  }

  /// Swaps the live encounter onto [entity] without restarting the loop.
  ///
  /// The bound icon and action skill are captured by value when the action
  /// is bound, so they have to be re-bound to follow the new member — but
  /// in place: stop() would wipe the boost and momentum the player has
  /// built up mid-card, and start() is a no-op while already running.
  void _startDungeonMember(EncounterEntity entity) {
    _encounterService.setEncounterEntity(_encounterState, entity);
    _playerState.currentEntityViewId = entity.id;
    // the next member may not offer the stance the last one did
    _playerDataService.coerceStanceFor(entity, _playerState);

    _actionTimingController.bindOnFireFunction(
      _actionFor(entity),
      activityIconId: entity.id,
      activityCount: () => _encounterState.entity?.count ?? 0,
      actionSkill: entity.entityType,
      // the card, not the entity: a dungeon member is rebuilt from the run's
      // queue, which a zone lookup would never find
      boundAction: BoundAction.dungeonSlot(
        dungeonSlot: _dungeonRun.runningSlot,
      ),
    );

    // a fresh enemy starts a fresh swing timer
    _lastEntityAttackAt = null;
  }

  /// Releases the dungeon card context, so the encounter screen stops
  /// resolving through the run.
  void _releaseDungeonSlot() => _dungeonService.clearRunningSlot(_dungeonRun);

  /// The members still queued behind the one on screen, in queue order.
  /// Empty for an ordinary world encounter.
  List<EncounterEntity> queueRemaining() =>
      _dungeonService.runningSlot(_dungeonRun)?.remaining ?? const [];

  // todo move this logic to the enoucnter system
  // fires a single time when action button is pressed
  // binds the entity's encounter action to the periodic loop
  void startEncounterAction() {
    // inside a dungeon card the button re-starts THAT card's member. the
    // zone lookup below can't see it — and with the same EntityId sitting
    // in the zone it would happily start the wrong fight
    final inCard = _dungeonService.runningEntity(_dungeonRun);
    if (inCard != null) {
      startEncounterActionFor(inCard);
      return;
    }

    // get the player view entity
    final entity = _explorationService.getSelectedEntity(
      _playerState,
      _worldState,
    );
    if (entity is! EncounterEntity) {
      return;
    }
    startEncounterActionFor(entity);
  }

  // the tick an entity's encounter runs on. fishing spots don't deplete or
  // fight back, and herbs are picked in one action with a level gate, so
  // each runs its own action with its own start conditions
  FutureOr<void> Function(int, {bool offline, DateTime? at, Duration? span})
  _actionFor(EncounterEntity entity) {
    switch (entity.entityType) {
      case SkillId.FISHING:
        return doFishingEncounterAction;
      case SkillId.HERBALISM:
        return doHerbalismEncounterAction;
      default:
        return doEncounterAction;
    }
  }

  // starts the encounter action on [entity] directly (used by the action
  // button via startEncounterAction and by the action queue). returns
  // true when the action is running when this returns
  bool startEncounterActionFor(EncounterEntity entity) {
    // starting anything that isn't the running card's own member leaves the
    // dungeon behind. this is the one place that decides it, because every
    // way of starting an encounter — the action button, the action queue,
    // a card tap — comes through here
    if (!identical(entity, _dungeonService.runningEntity(_dungeonRun))) {
      _releaseDungeonSlot();
    }

    final isFishing = entity.entityType == SkillId.FISHING;
    final isHerbalism = entity.entityType == SkillId.HERBALISM;
    final action = _actionFor(entity);

    final isNew = _encounterService.isNewEntity(_encounterState, entity);

    // same entity with its action already running: let it continue.
    // (a stopped action on the same entity falls through and restarts)
    if (!isNew && _actionTimingController.isRunningAction(action)) {
      return true;
    }

    // stop action timing
    _actionTimingController.stop();

    // a new entity starts a new encounter session: drops shown in the
    // encounter screen belong to the previous session and are cleared
    if (isNew) {
      _inventoryService.clearItems(_encounterState.itemDrops);
    }

    // set as active entity in encounter state.
    _encounterService.setEncounterEntity(_encounterState, entity);

    // entities that don't offer the current stance start fast
    _playerDataService.coerceStanceFor(entity, _playerState);

    // check action conditions are met
    final conditionsMet = isFishing
        ? _encounterService.fishingConditionsMet(_playerState, _encounterState)
        : isHerbalism
        ? _herbalismConditionsMet()
        : _encounterService.encounterConditionsMet(
            _playerState,
            _encounterState,
          );
    if (!conditionsMet) {
      return false;
    }

    // bind the encounter action to the action timing controller.
    // same icon + count the entity's card shows on the explore screen.
    _actionTimingController.bindOnFireFunction(
      action,
      activityIconId: entity.id,
      activityCount: () => _encounterState.entity?.count ?? 0,
      // the weapon in combat, the skill's tool when gathering, sets how
      // long each action takes
      actionSkill: entity.entityType,
      // the slot release above has already zeroed runningSlot for anything
      // that is not the running card's own member, so this still standing
      // means the fight belongs to the dungeon rather than the zone
      boundAction: _dungeonRun.runningSlot >= 0
          ? BoundAction.dungeonSlot(dungeonSlot: _dungeonRun.runningSlot)
          : BoundAction.encounter(
              zoneId: _playerState.currentZoneId,
              entityId: entity.id,
            ),
    );

    // fresh combat starts a fresh enemy swing timer
    _lastEntityAttackAt = null;

    // start action timing
    _actionTimingController.start();
    return true;
  }

  // called every frame of the action timing loop (wired in
  // GameSessionFactory). drives combat entity attacks on their own
  // attack interval while the player's combat action is running
  void onActionTimingFrame() {
    if (!_actionTimingController.isRunningAction(doEncounterAction)) {
      _lastEntityAttackAt = null;
      return;
    }
    final entity = _encounterState.entity;
    if (entity is! CombatEntity || _encounterState.respawning) {
      return;
    }

    final now = DateTime.now();
    // first frame of combat starts the swing timer
    _lastEntityAttackAt ??= now;

    final interval = Duration(
      milliseconds: (entity.attackInterval * 1000).round(),
    );
    if (now.difference(_lastEntityAttackAt!) < interval) {
      return;
    }
    _lastEntityAttackAt = now;

    latestEntityDamage = _encounterSystem.executeEntityAttack(
      playerState: _playerState,
      encounter: _encounterState,
    );
    entityAttackSequence++;

    // a swing that takes the player to zero kills, before any food can be
    // reached for. checking this ahead of the eat is what makes a big max
    // hit dangerous: food tops the player up between hits, it does not pull
    // them back from a hit they could not survive.
    //
    // when the player dies the encounter ends and their hp is reset to 1.
    if (_playerState.hitpoints <= 0) {
      _actionTimingController.stop();
      _playerDataService.heal(1, _playerState);
      deathSequence++;
      notifyListeners();
      return;
    }

    // heal between hits when hp runs low and food is equipped; this is why
    // queued/automated combat can sustain itself
    _encounterSystem.autoEat(
      playerState: _playerState,
      playerInventory: _inventoryState,
    );

    notifyListeners();
  }

  // how far the combat entity is through its attack windup, 0..1. sampled
  // by the ui every frame rather than pushed on notify, since the swing
  // timer runs on wall clock between the attacks that do notify
  double entityAttackProgress() {
    if (!isViewingActiveEncounter()) return 0.0;
    if (!_actionTimingController.isRunningAction(doEncounterAction)) return 0.0;

    final entity = _encounterState.entity;
    final lastAttack = _lastEntityAttackAt;
    if (entity is! CombatEntity ||
        lastAttack == null ||
        entity.attackInterval <= 0 ||
        _encounterState.respawning) {
      return 0.0;
    }

    final elapsed = DateTime.now().difference(lastAttack).inMicroseconds / 1e6;
    return (elapsed / entity.attackInterval).clamp(0.0, 1.0);
  }

  /// True while the loop is running any of the encounter actions. Fishing
  /// and herbalism bind their own, so a check against [doEncounterAction]
  /// alone reads "not running" on exactly those two screens.
  bool _isRunningAnyEncounterAction() {
    return _actionTimingController.isRunningAction(doEncounterAction) ||
        _actionTimingController.isRunningAction(doFishingEncounterAction) ||
        _actionTimingController.isRunningAction(doHerbalismEncounterAction);
  }

  /// True when the encounter actions are firing on the entity currently on
  /// screen — the one predicate behind every piece of per-action feedback
  /// this screen draws. Viewing a different entity while an action runs
  /// elsewhere is not acting here.
  bool _isActingOnViewedEntity() {
    return isViewingActiveEncounter() && _isRunningAnyEncounterAction();
  }

  /// How far the player is through the action being performed on the entity
  /// in view, 0..1. Zero unless the action is firing on *this* entity, so a
  /// run against one target never draws progress on another's screen.
  double playerActionProgress() {
    if (!_isActingOnViewedEntity()) return 0.0;
    return _actionTimingController.actionProgress;
  }

  /// The interval the timer on this screen is filling over: the running
  /// action's live interval while this is the entity being worked, and what
  /// starting on it would cost otherwise.
  Duration playerActionInterval() {
    if (_isActingOnViewedEntity()) {
      return _actionTimingController.getCurrentActionDuration();
    }
    return _actionTimingController.idleActionDurationFor(
      _resolveViewedEntity()?.entityType,
    );
  }

  // function bound to eat button
  void eatSingleEquipedFood() {
    final ate = _encounterSystem.eatEquipedFood(
      playerState: _playerState,
      playerInventory: _inventoryState,
    );
    if (ate) {
      notifyListeners();
    }
  }

  /// Resolves the entity the player is viewing, as the object the zone
  /// actually holds.
  ///
  /// An EntityId is a *kind*, not an instance: the same Oak Tree id sits in
  /// several zones, each with its own count and hitpoints. So the zone's own
  /// instance is the answer, and the live encounter entity is only fallen
  /// back to when the zone no longer has one — a depleted node is removed
  /// from the zone, and its screen still has to show the encounter that just
  /// finished rather than going blank.
  EncounterEntity? _resolveViewedEntity() {
    // a dungeon card owns the entity being worked. the same EntityId can
    // sit in several cards of the same dungeon, so it resolves through the
    // running card rather than through currentEntityViewId
    final inCard = _dungeonService.runningEntity(_dungeonRun);
    if (inCard != null) return inCard;

    // keyed on zone as well as id, so a tree in one zone never resolves to
    // the identical-looking tree being worked in another
    final selected = _explorationService.getSelectedEntity(
      _playerState,
      _worldState,
    );
    if (selected is EncounterEntity) return selected;

    final active = _encounterState.entity;
    if (active != null && active.id == _playerState.currentEntityViewId) {
      return active;
    }
    return null;
  }

  // populates encounter hp bar percentage - needs to move to entity view controller
  double getHealthPercent() {
    final e = _resolveViewedEntity();
    if (e == null || e.maxHitPoints <= 0) return 0.0;
    return (e.hitpoints / e.maxHitPoints).clamp(0.0, 1.0);
  }

  // todo make this not return the mutable entity state. instead return
  // a snapshot or copy of the entity
  EncounterEntity getActiveEntity() {
    return _resolveViewedEntity() ??
        EncounterEntity(
          id: EntityId.NULL,
          name: "null",
          count: 0,
          entityType: SkillId.NULL,
          defence: 0,
          hitpoints: 0,
        );
  }

  // true only when the entity being viewed is the one respawning; the
  // respawn flag itself is global to the running encounter
  bool respawning() {
    return _encounterState.respawning && isViewingActiveEncounter();
  }

  // true when the screen is showing the entity the encounter actions are
  // firing on, so per-action feedback belongs on this screen
  bool isViewingActiveEncounter() {
    final active = _encounterState.entity;
    if (active == null) return false;

    final inCard = _dungeonService.runningEntity(_dungeonRun);
    if (inCard != null) return identical(active, inCard);

    // identity, not id: two zones can each hold an Oak Tree, and working
    // one must not light up the other's progress bar and damage numbers
    return _encounterState.isActive &&
        identical(active, _resolveViewedEntity());
  }

  bool isCombatEntity() {
    return (_resolveViewedEntity() is CombatEntity);
  }

  // drops collected during the current encounter session. entities that
  // are not the session's entity show an empty list
  List<ObjectStack> itemDrops() {
    if (!isViewingActiveEncounter()) {
      return [];
    }
    return _inventoryService.getObjectStackList(_encounterState.itemDrops);
  }

  // called when the player navigates to view an entity. if no encounter
  // action is running the previous session is over, so its drops are
  // cleared; a still-running session keeps its drops
  void onEntityViewChanged() {
    // navigating to a zone entity leaves the dungeon card behind. dungeon
    // cards don't route through here, so this only ever fires on the way out
    _releaseDungeonSlot();

    if (!_isRunningAnyEncounterAction()) {
      _inventoryService.clearItems(_encounterState.itemDrops);
      notifyListeners();
    }
  }

  // herbalism level required to pick the viewed entity; 0 for non-herbs
  int viewedHerbRequiredLevel() {
    final e = _resolveViewedEntity();
    return e == null ? 0 : _encounterSystem.herbRequiredLevel(e.id);
  }

  // true when the viewed entity is an herb the player can't pick yet
  bool viewedHerbLocked() {
    final e = _resolveViewedEntity();
    if (e == null) return false;
    return !_encounterSystem.meetsHerbRequirement(_playerState, e.id);
  }

  ItemId getEquipedFoodItemId() {
    return _playerState.equipmentData.equipedFood;
  }

  int getEquipedFoodItemCount() {
    final id = _playerState.equipmentData.equipedFood;
    return _inventoryService.getItemCount(_inventoryState, id);
  }

  Map<SkillId, int> getPlayerStats() {
    return _playerDataService.getStatTotals(_playerState);
  }

  int getPlayerHp() {
    return _playerState.hitpoints;
  }
}
