import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// An offline batch is a shortcut, not a different game: it stands in for the
/// actions the loop would have run one at a time, so it has to pay what they
/// would have paid.
///
/// Every test here is the same shape - run n actions live, run one batch of n
/// offline, and hold the two up against each other. What the batch settles off
/// a mean rather than a roll (drops, kills, find counts) is compared inside a
/// band; what it has no excuse to differ on (the action count, xp that is a
/// flat rate, materials consumed) is compared exactly.
///
/// The one that has teeth is combat: the batch used to divide a hitpoint pool
/// by average damage and hand back the quotient, which paid several kills for
/// a single action whenever the player out-damaged the pool. A kill costs
/// whole landing hits and a swing can only take one thing down, and that is
/// what the live side is here to keep the batch honest about.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  int itemTotal(List<dynamic> stacks) =>
      stacks.fold<int>(0, (sum, s) => sum + (s.count as int));

  /// Holds every skill at the level it started the run on.
  ///
  /// A batch resolves at the level it was fired from - the stats are read
  /// once, not re-read per action - and the settle loop is what makes that
  /// honest, by cutting a new segment the moment it predicts a level-up
  /// (see [OfflineProgressSystem]). A live loop levels up mid-run instead,
  /// so left alone the two diverge on progression rather than on batching,
  /// and progression is not what these tests are about. Pinning the xp back
  /// after every live action is what leaves the batching as the only
  /// difference between the two sides.
  void Function() freezeLevels(GameSession session) {
    final snapshot = {
      for (final entry in session.saveGameData.playerData.skillData.entries)
        entry.key: entry.value.xp,
    };
    return () {
      for (final entry in snapshot.entries) {
        session.saveGameData.playerData.skillData[entry.key]!.xp = entry.value;
      }
    };
  }

  // ---- combat / gathering nodes ----

  // the entity both sides fight. a plain node has no attack, so nothing
  // swings back and the whole stretch belongs to the player - which is what
  // isolates the half of the fight the batch approximates.
  EncounterEntity standUp(
    GameSession session, {
    required int hitpoints,
    int count = 100000,
  }) {
    final node = EncounterEntity(
      id: EntityId.TREE,
      name: 'Test Node',
      count: count,
      entityType: SkillId.WOODCUTTING,
      defence: 5,
      hitpoints: hitpoints,
    );
    session.encounterService.setEncounterEntity(
      session.saveGameData.encounterData,
      node,
    );
    return node;
  }

  // what n actions came to, however they were run. the offline batch reports
  // one of these; the live loop's are summed into one.
  ({int actions, int kills, int drops, double xp}) tally(
    List<EncounterActionResult> results,
  ) {
    var actions = 0, kills = 0, drops = 0;
    var xp = 0.0;
    for (final r in results) {
      actions += r.actionsPerformed;
      kills += itemTotal(r.entitiesDefeated);
      drops += itemTotal(r.items);
      xp += r.xp.values.fold(0.0, (sum, v) => sum + v);
    }
    return (actions: actions, kills: kills, drops: drops, xp: xp);
  }

  ({int actions, int kills, int drops, double xp}) fightLive(
    GameSession session, {
    required int count,
    required int seed,
    bool freeze = true,
  }) {
    final save = session.saveGameData;
    final rng = Random(seed);
    final holdLevels = freezeLevels(session);
    final results = <EncounterActionResult>[];
    for (var i = 0; i < count; i++) {
      results.add(
        session.encounterSystem.executePlayerAction(
          playerState: save.playerData,
          encounter: save.encounterData,
          worldState: save.worldData,
          playerInventory: save.inventoryData,
          // respawn without the 200ms flash, so the loop stays synchronous
          instantRespawn: true,
          rng: rng,
        ),
      );
      if (freeze) holdLevels();
    }
    return tally(results);
  }

  ({int actions, int kills, int drops, double xp}) fightBatched(
    GameSession session, {
    required int count,
    required Duration interval,
  }) {
    final save = session.saveGameData;
    return tally([
      session.encounterSystem.executePlayerAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
        actionCount: count,
        offline: true,
        at: save.playerData.lastActionTime,
        span: interval * count,
      ),
    ]);
  }

  group('combat: a batch against the loop it stands in for', () {
    const actions = 4000;
    const interval = Duration(seconds: 3);

    // the shapes worth separating: a kill inside one hit, a kill over a
    // handful, and a kill over dozens. the first is where the old batch
    // broke, the last is where rounding a kill up to whole hits costs most.
    for (final scenario in [
      (name: 'one hit a kill', level: 30, hitpoints: 2),
      (name: 'a few hits a kill', level: 20, hitpoints: 40),
      (name: 'dozens of hits a kill', level: 8, hitpoints: 200),
    ]) {
      test('${scenario.name} pays what the loop pays', () {
        final live = buildSession();
        setLevel(live, SkillId.WOODCUTTING, scenario.level);
        standUp(live, hitpoints: scenario.hitpoints);
        final looped = fightLive(live, count: actions, seed: 20260824);
        live.dispose();

        final batch = buildSession();
        setLevel(batch, SkillId.WOODCUTTING, scenario.level);
        standUp(batch, hitpoints: scenario.hitpoints);
        final batched = fightBatched(batch, count: actions, interval: interval);
        batch.dispose();

        // both fought the whole stretch
        expect(looped.actions, actions);
        expect(batched.actions, actions);

        // a swing takes down one thing at most, whichever way it was run
        expect(looped.kills, lessThanOrEqualTo(looped.actions));
        expect(batched.kills, lessThanOrEqualTo(batched.actions));

        // and the batch settled the same fight the loop fought
        expect(looped.kills, greaterThan(0));
        expect(batched.kills, closeTo(looped.kills, looped.kills * 0.15));
        expect(batched.drops, closeTo(looped.drops, looped.drops * 0.15));
        expect(batched.xp, closeTo(looped.xp, looped.xp * 0.15));
      });
    }

    test('a group is cleared by the same number of actions either way', () {
      // only 50 to fell, and far more actions than that needs: both sides
      // stop at the group rather than running the stretch out
      final live = buildSession();
      setLevel(live, SkillId.WOODCUTTING, 20);
      standUp(live, hitpoints: 40, count: 50);
      final looped = fightLive(live, count: actions, seed: 7);
      live.dispose();

      final batch = buildSession();
      setLevel(batch, SkillId.WOODCUTTING, 20);
      standUp(batch, hitpoints: 40, count: 50);
      final batched = fightBatched(batch, count: actions, interval: interval);
      batch.dispose();

      expect(looped.kills, 50);
      expect(batched.kills, 50);
    });
  });

  // ---- crafting ----

  ({int bars, double xp, int ore}) smelt(
    GameSession session, {
    required int count,
    required bool offline,
  }) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = EntityId.ANVIL;
    save.craftingState.craftingZoneId = save.playerData.currentZoneId;
    save.craftingState.activeRecipeId = 'smelt_copper_bar';
    save.inventoryData.itemMap[ItemId.COPPER_ORE] = 4000;

    var xp = 0.0;
    for (var i = 0; i < (offline ? 1 : count); i++) {
      final result = session.craftingSystem.craftActiveRecipe(
        save.craftingState,
        save.playerData,
        save.inventoryData,
        save.playerData.buffData,
        save.worldData,
        craftCount: offline ? count : 1,
        offline: offline,
      );
      xp += result.xp.values.fold(0.0, (sum, v) => sum + v);
    }
    return (
      bars: save.inventoryData.itemMap[ItemId.COPPER_BAR] ?? 0,
      xp: xp,
      ore: save.inventoryData.itemMap[ItemId.COPPER_ORE] ?? 0,
    );
  }

  group('crafting: a batch against the loop it stands in for', () {
    test('settles the same crafts, inputs and xp', () {
      const crafts = 500;

      final live = buildSession();
      final looped = smelt(live, count: crafts, offline: false);
      live.dispose();

      final batch = buildSession();
      final batched = smelt(batch, count: crafts, offline: true);
      batch.dispose();

      // a craft is a craft: nothing here is settled off a mean, so all three
      // match to the item
      expect(looped.bars, crafts);
      expect(batched.bars, crafts);
      expect(batched.ore, looped.ore);
      expect(batched.xp, closeTo(looped.xp, 1e-6));
    });

    test('both stop at the materials on hand', () {
      // 4000 ore against 5000 crafts asked for: neither side crafts on credit
      const crafts = 5000;

      final live = buildSession();
      final looped = smelt(live, count: crafts, offline: false);
      live.dispose();

      final batch = buildSession();
      final batched = smelt(batch, count: crafts, offline: true);
      batch.dispose();

      expect(looped.bars, 4000);
      expect(batched.bars, 4000);
      expect(batched.ore, 0);
      expect(looped.ore, 0);
    });
  });

  // ---- exploration ----

  ({int actions, double xp, int finds, int items, int entities}) exploreRun(
    GameSession session, {
    required int count,
    required bool offline,
  }) {
    final save = session.saveGameData;
    save.playerData.currentZoneId = ZoneId.DEV_FOREST;

    final holdLevels = freezeLevels(session);
    var actions = 0, finds = 0, items = 0, entities = 0;
    var xp = 0.0;
    for (var i = 0; i < (offline ? 1 : count); i++) {
      final result = session.explorationSystem.explore(
        playerState: save.playerData,
        worldState: save.worldData,
        playerInventory: save.inventoryData,
        numTimesToExplore: offline ? count : 1,
        offline: offline,
      );
      actions += result.actionsPerformed;
      finds += result.findCount;
      items += itemTotal(result.items);
      entities += itemTotal(result.entities);
      xp += result.xp;
      holdLevels();
    }
    return (
      actions: actions,
      xp: xp,
      finds: finds,
      items: items,
      entities: entities,
    );
  }

  group('exploration: a batch against the loop it stands in for', () {
    const explores = 2000;

    test('at the zone level, pays the same explores, xp and finds', () {
      final live = buildSession();
      final looped = exploreRun(live, count: explores, offline: false);
      live.dispose();

      final batch = buildSession();
      final batched = exploreRun(batch, count: explores, offline: true);
      batch.dispose();

      // an explore is an action and its xp is a flat rate, so both are exact
      expect(looped.actions, explores);
      expect(batched.actions, explores);
      expect(batched.xp, closeTo(looped.xp, 1e-6));

      // the finds are a mean rather than a roll each
      expect(looped.finds, greaterThan(0));
      expect(batched.finds, closeTo(looped.finds, looped.finds * 0.15));
      expect(batched.items, closeTo(looped.items, looped.items * 0.15));
      expect(
        batched.entities,
        closeTo(looped.entities, looped.entities * 0.15),
      );
    });

    test('outlevelling the zone multiplies both sides alike', () {
      final live = buildSession();
      setLevel(live, SkillId.EXPLORATION, 30);
      final looped = exploreRun(live, count: explores, offline: false);
      live.dispose();

      final batch = buildSession();
      setLevel(batch, SkillId.EXPLORATION, 30);
      final batched = exploreRun(batch, count: explores, offline: true);
      batch.dispose();

      // more finds per explore, and the same xp: outlevelling a zone
      // multiplies its loot without touching its xp rate
      expect(looped.finds, greaterThan(explores));
      expect(batched.xp, closeTo(looped.xp, 1e-6));
      expect(batched.finds, closeTo(looped.finds, looped.finds * 0.15));
      expect(batched.items, closeTo(looped.items, looped.items * 0.15));
    });
  });

  // ---- the whole settle path ----

  // The tests above fire one batch directly, which holds the player's stats
  // still for its whole length. A real window is not settled that way:
  // [OfflineProgressSystem.settle] replays it segment by segment, cutting a
  // new one every time it predicts a level-up and re-reading the stats
  // there. That is the part that has to keep up with a player who is
  // levelling as they fight, so this is the one comparison that lets both
  // sides level.
  group('a whole window settled against the loop it stands in for', () {
    int levelOf(GameSession session, SkillId id) => session.skillService
        .getLevel(session.saveGameData.playerData.skillData[id]!);

    test('keeps up with the levels the fight earns', () {
      final batch = buildSession();
      final save = batch.saveGameData;
      final tree = EntityId.TREE.build() as EncounterEntity;
      tree.count = 100000;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(tree);
      expect(batch.encounterController.startEncounterActionFor(tree), isTrue);

      final now = DateTime.now();
      save.playerData.lastActionTime = now.subtract(const Duration(hours: 1));
      batch.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );
      final report = batch.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      final settledLevel = levelOf(batch, SkillId.WOODCUTTING);
      batch.actionTimingController.stop();
      batch.dispose();

      // the same number of actions, run one at a time, levelling as they go
      final live = buildSession();
      final liveTree = EntityId.TREE.build() as EncounterEntity;
      liveTree.count = 100000;
      live.encounterService.setEncounterEntity(
        live.saveGameData.encounterData,
        liveTree,
      );
      final looped = fightLive(
        live,
        count: report!.actionCount,
        seed: 20260824,
        freeze: false,
      );
      final loopedLevel = levelOf(live, SkillId.WOODCUTTING);
      live.dispose();

      // an hour of felling a level-1 tree is worth dozens of levels, and a
      // settle that resolved the window at the level it started from would
      // come back at a fraction of both numbers. The threshold only has to be
      // high enough that the parity check below is measuring something — the
      // xp rates behind it are tuning numbers and have already come down once.
      expect(loopedLevel, greaterThan(20));
      expect(settledLevel, closeTo(loopedLevel, 3));
      expect(
        report.enemiesDefeated,
        closeTo(looped.kills, looped.kills * 0.15),
      );

      // and the invariant still holds across the whole window
      expect(report.enemiesDefeated, lessThanOrEqualTo(report.actionCount));
    });
  });
}
