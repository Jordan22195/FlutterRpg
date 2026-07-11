import 'dart:math';

import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../data/action_result.dart';
import '../data/dungeon_run.dart';
import '../data/inventory_data.dart';
import '../data/ObjectStack.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/combat_auto_eat_service.dart';
import '../services/encounter_service.dart';
import '../services/inventory_service.dart';
import '../services/player_data_service.dart';
import '../services/weighted_drop_table_service.dart';

/// The outcome of clearing a pack: where the run goes next, and whether a
/// floor was cleared / the dungeon finished / the run should pause for the
/// player's loop-or-continue choice. Pure, so advancement is unit-testable
/// against synthetic definitions.
class DungeonAdvance {
  final int floorIndex;
  final int packIndex;
  final bool clearedFloor;
  final bool awaitChoice;
  final bool complete;

  const DungeonAdvance({
    required this.floorIndex,
    required this.packIndex,
    this.clearedFloor = false,
    this.awaitChoice = false,
    this.complete = false,
  });
}

/// Coordinates a dungeon run: entry (key consumption + spawning), combat
/// ticks with per-kill drops, floor/pack advancement, enemy attacks, and
/// auto-eat. Deliberately does NOT touch world/zone state — dungeon
/// enemies are spawned from the definition and live only on the run.
class DungeonSystem {
  final DungeonCatalog _dungeonCatalog;
  final EntityCatalog _entityCatalog;
  final EncounterService _encounterService;
  final WeightedDropTableService _dropTableService;
  final InventoryService _inventoryService;
  final PlayerDataService _playerDataService;
  final CombatAutoEatService _autoEatService;

  DungeonSystem({
    required DungeonCatalog dungeonCatalog,
    required EntityCatalog entityCatalog,
    required EncounterService encounterService,
    required WeightedDropTableService dropTableService,
    required InventoryService inventoryService,
    required PlayerDataService playerDataService,
    required CombatAutoEatService autoEatService,
  }) : _dungeonCatalog = dungeonCatalog,
       _entityCatalog = entityCatalog,
       _encounterService = encounterService,
       _dropTableService = dropTableService,
       _inventoryService = inventoryService,
       _playerDataService = playerDataService,
       _autoEatService = autoEatService;

  DungeonDefinition? definitionFor(DungeonId id) =>
      _dungeonCatalog.getDefinitionFor(id);

  // ---- entry ----

  /// Whether [dungeonId] can be entered right now: no run in progress, the
  /// level gate met, and the key owned (if keyed). Read-only.
  bool canEnter({
    required DungeonRun run,
    required DungeonId dungeonId,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    final def = _dungeonCatalog.getDefinitionFor(dungeonId);
    if (def == null || run.active) return false;
    if (!_meetsLevel(def, playerState)) return false;
    if (def.isKeyed &&
        _inventoryService.getItemCount(playerInventory, def.keyItemId) <= 0) {
      return false;
    }
    return true;
  }

  /// Starts a run: consumes the key (if keyed), resets run state to floor
  /// 0, and spawns the first pack. Returns false when entry isn't allowed.
  bool enterDungeon({
    required DungeonRun run,
    required DungeonId dungeonId,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    if (!canEnter(
      run: run,
      dungeonId: dungeonId,
      playerState: playerState,
      playerInventory: playerInventory,
    )) {
      return false;
    }
    final def = _dungeonCatalog.getDefinitionFor(dungeonId)!;

    if (def.isKeyed) {
      _inventoryService.removeItems(playerInventory, def.keyItemId, 1);
    }

    run.active = true;
    run.dungeonId = dungeonId;
    run.floorIndex = 0;
    run.packIndex = 0;
    run.maxClearedFloor = -1;
    run.awaitingFloorChoice = false;
    _inventoryService.clearItems(run.loot);
    _spawnPack(run, def);
    return true;
  }

  /// Ends the run (leave/abandon). For a keyed dungeon the key is already
  /// spent, so re-entry needs another key; a free (zone) dungeon can be
  /// re-entered, which is the "reset to floor 1" behavior.
  void leaveDungeon(DungeonRun run) {
    run.active = false;
    run.awaitingFloorChoice = false;
    run.fight.isActive = false;
    run.fight.entity = null;
  }

  // ---- the combat tick ----

  /// One dungeon combat tick: the player damages the current enemy; each
  /// kill drops loot and decrements the pack; a cleared pack advances the
  /// run (to the next pack/floor, a pause for the loop choice, or
  /// completion). Returns the action feedback for this tick.
  ActionResult executeDungeonAction({
    required DungeonRun run,
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    final result = ActionResult();
    if (!runConditionsMet(run, playerState)) return result;

    final def = _dungeonCatalog.getDefinitionFor(run.dungeonId)!;
    final entity = run.fight.entity!;

    final stats = _playerDataService.getStatTotals(playerState);
    final r = _encounterService.resolvePlayerDamage(stats, playerState, run.fight);
    result.damageDone = r.damageDone;
    result.enemyDied = r.enemyDied;

    if (result.damageDone <= 0) return result; // miss

    // xp accrues on every damaging hit, mirroring world combat
    result.xp[entity.entityType] = (5 * result.damageDone).toDouble();
    result.xp[SkillId.HITPOINTS] = (5 * result.damageDone) / 3.0;

    if (result.enemyDied) {
      _awardKillDrops(run, entity, playerInventory, result);

      entity.count--;
      if (entity.count > 0) {
        // next identical enemy in the pack
        entity.hitpoints = entity.maxHitPoints;
      } else {
        _advanceAfterPackCleared(run, def);
      }
    }

    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }

  /// Rolls the enemy's attack against the player and applies the damage.
  /// Returns the damage dealt. Enemies only attack while a fight is live.
  int executeEnemyAttack({
    required DungeonRun run,
    required PlayerData playerState,
  }) {
    if (!runConditionsMet(run, playerState)) return 0;
    final stats = _playerDataService.getStatTotals(playerState);
    final res = _encounterService.entityAttack(run.fight, stats);
    _playerDataService.applyDamage(res.damageDone, playerState);
    if (res.xp.isNotEmpty) {
      _playerDataService.applyXp(playerState, res.xp);
    }
    return res.damageDone;
  }

  /// Eats one equipped food when hp is low (shared auto-eat rule). Returns
  /// true when it ate. Used to survive the automated fights.
  bool autoEat({
    required PlayerData playerState,
    required InventoryData playerInventory,
  }) {
    return _autoEatService.autoEat(
      playerState: playerState,
      playerInventory: playerInventory,
    );
  }

  // ---- floor loop / continue (repeatable dungeons) ----

  /// Re-runs the just-cleared floor from its first pack.
  void loopFloor(DungeonRun run) {
    final def = _dungeonCatalog.getDefinitionFor(run.dungeonId);
    if (def == null || !run.awaitingFloorChoice) return;
    run.awaitingFloorChoice = false;
    run.packIndex = 0;
    _spawnPack(run, def);
  }

  /// Descends to the next floor, or completes the run when the boss floor
  /// was the one just cleared.
  void continueFloor(DungeonRun run) {
    final def = _dungeonCatalog.getDefinitionFor(run.dungeonId);
    if (def == null || !run.awaitingFloorChoice) return;
    run.awaitingFloorChoice = false;
    if (run.floorIndex + 1 < def.floors.length) {
      run.floorIndex++;
      run.packIndex = 0;
      _spawnPack(run, def);
    } else {
      _completeRun(run);
    }
  }

  // ---- conditions / advancement ----

  /// True while the run can take a combat tick: active, not paused for a
  /// floor choice, a live enemy with count remaining, and the player up.
  bool runConditionsMet(DungeonRun run, PlayerData playerState) {
    if (!run.active || run.awaitingFloorChoice) return false;
    if (_dungeonCatalog.getDefinitionFor(run.dungeonId) == null) return false;
    final entity = run.fight.entity;
    if (entity == null || !run.fight.isActive || entity.count <= 0) {
      return false;
    }
    if (playerState.hitpoints <= 0) return false;
    return true;
  }

  /// Pure advancement: given the cleared position, where does the run go?
  DungeonAdvance computeAdvance(
    DungeonDefinition def,
    int floorIndex,
    int packIndex,
  ) {
    final floor = def.floors[floorIndex];
    if (packIndex + 1 < floor.packs.length) {
      return DungeonAdvance(floorIndex: floorIndex, packIndex: packIndex + 1);
    }

    // the floor is cleared
    final isLastFloor = floorIndex + 1 >= def.floors.length;

    if (def.repeatable) {
      // pause for the loop/continue choice
      return DungeonAdvance(
        floorIndex: floorIndex,
        packIndex: packIndex,
        clearedFloor: true,
        awaitChoice: true,
      );
    }
    if (isLastFloor) {
      return DungeonAdvance(
        floorIndex: floorIndex,
        packIndex: packIndex,
        clearedFloor: true,
        complete: true,
      );
    }
    // auto-continue to the next floor
    return DungeonAdvance(
      floorIndex: floorIndex + 1,
      packIndex: 0,
      clearedFloor: true,
    );
  }

  // ---- internals ----

  bool _meetsLevel(DungeonDefinition def, PlayerData playerState) {
    if (def.requiredSkill == SkillId.NULL || def.requiredLevel <= 0) {
      return true;
    }
    final level =
        _playerDataService.getStatTotals(playerState)[def.requiredSkill] ?? 0;
    return level >= def.requiredLevel;
  }

  void _awardKillDrops(
    DungeonRun run,
    EncounterEntity entity,
    InventoryData playerInventory,
    ActionResult result,
  ) {
    final edef =
        _entityCatalog.getDefinitionFor(entity.id) as EncounterEntityDefinition;
    final drops = <ObjectStack<ItemId>>[
      _dropTableService.roll(edef.itemDrops),
      ..._dropTableService.rollBonus(edef.bonusDrops),
    ];
    result.items.addAll(drops);
    _inventoryService.addItems(playerInventory, drops);
    _inventoryService.addItems(run.loot, drops);
  }

  void _advanceAfterPackCleared(DungeonRun run, DungeonDefinition def) {
    final adv = computeAdvance(def, run.floorIndex, run.packIndex);
    if (adv.clearedFloor) {
      run.maxClearedFloor = max(run.maxClearedFloor, run.floorIndex);
    }
    if (adv.complete) {
      _completeRun(run);
    } else if (adv.awaitChoice) {
      run.awaitingFloorChoice = true;
      run.fight.isActive = false;
    } else {
      run.floorIndex = adv.floorIndex;
      run.packIndex = adv.packIndex;
      _spawnPack(run, def);
    }
  }

  void _completeRun(DungeonRun run) {
    run.active = false;
    run.awaitingFloorChoice = false;
    run.fight.isActive = false;
  }

  void _spawnPack(DungeonRun run, DungeonDefinition def) {
    final pack = def.floors[run.floorIndex].packs[run.packIndex];
    final entity = _entityCatalog.buildEntity(pack.entityId);
    if (entity is EncounterEntity) {
      entity.count = pack.count;
      run.fight.entity = entity;
      run.fight.isActive = true;
      run.fight.respawning = false;
    }
  }
}
