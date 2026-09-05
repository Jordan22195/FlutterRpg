import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/offline_progress_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// What an offline settle owes the player, across every activity the loop
/// can be bound to and every condition that cuts a segment short.
///
/// These run against a real [GameSession] rather than a synthetic onFire, so
/// the bound action, the report and the player's own totals all have to agree
/// — an action count that only the report believes is a bug these catch.
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

  double xpOf(GameSession session, SkillId skill) =>
      session.saveGameData.playerData.skillData[skill]!.xp;

  /// The unboosted interval the loop will run at, in seconds — read through
  /// getCurrentActionDuration so it rounds exactly the way the loop does.
  double interval(GameSession session, {EntityId? entity}) {
    final player = session.saveGameData.playerData;
    final scratch = ActionTimingData()
      ..actionSkill = session.saveGameData.actionTimingData.actionSkill
      ..maxInterval = session.actionTimingSystem.intervalFor(
        session.saveGameData.actionTimingData.actionSkill,
        player,
      );
    return ActionTimingService()
            .getCurrentActionDuration(scratch)
            .inMicroseconds /
        1e6;
  }

  /// How many whole actions a gap of [seconds] buys at the current interval.
  int actionsIn(GameSession session, double seconds) =>
      (seconds / interval(session)).floor();

  /// Puts [seconds] of wall clock behind the player without waiting.
  DateTime goOffline(GameSession session, double seconds) {
    final now = DateTime.now();
    session.saveGameData.playerData.lastActionTime = now.subtract(
      Duration(microseconds: (seconds * 1e6).round()),
    );
    return now;
  }

  OfflineProgressReport settle(GameSession session, double seconds) {
    final save = session.saveGameData;
    final now = goOffline(session, seconds);
    session.offlineProgressSystem.settle(
      save.playerData,
      save.actionTimingData,
      now: now,
    );
    return session.actionTimingController.pendingOfflineReport!;
  }

  /// Stands [entity] up in the player's zone and binds the loop to it.
  EncounterEntity fight(
    GameSession session,
    EntityId id, {
    int count = 100000,
  }) {
    final save = session.saveGameData;
    final entity = id.build() as EncounterEntity;
    entity.count = count;
    save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
      entity,
    );
    expect(session.encounterController.startEncounterActionFor(entity), isTrue);
    return entity;
  }

  void tearDownSession(GameSession session) {
    session.actionTimingController.stop();
    session.dispose();
  }

  // ---------------------------------------------------------------- activity

  group('every activity type settles a gap', () {
    test('gathering pays the actions, the xp and the logs', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      final expected = actionsIn(session, 300);
      final xpBefore = xpOf(session, SkillId.WOODCUTTING);
      final report = settle(session, 300);

      expect(report.actionCount, expected);
      expect(report.timeAway, const Duration(seconds: 300));

      // the xp the report claims is the xp the player actually banked
      expect(
        xpOf(session, SkillId.WOODCUTTING) - xpBefore,
        closeTo(report.xp[SkillId.WOODCUTTING]!, 1e-6),
      );

      // and the loot it claims is the loot in the bag
      expect(report.items.itemMap[ItemId.LOGS], greaterThan(0));
      expect(
        save.inventoryData.itemMap[ItemId.LOGS],
        report.items.itemMap[ItemId.LOGS],
      );
      expect(report.entitiesDefeated[EntityId.TREE], greaterThan(0));

      tearDownSession(session);
    });

    test('combat pays the actions, the xp and the kills', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.ATTACK, 20);
      setLevel(session, SkillId.HITPOINTS, 40);
      save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 500;
      save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
      fight(session, EntityId.CHICKEN);

      final expected = actionsIn(session, 300);
      final xpBefore = xpOf(session, SkillId.ATTACK);
      final report = settle(session, 300);

      expect(report.actionCount, expected);
      expect(report.timeAway, const Duration(seconds: 300));
      expect(
        xpOf(session, SkillId.ATTACK) - xpBefore,
        closeTo(report.xp[SkillId.ATTACK]!, 1e-6),
      );
      expect(report.entitiesDefeated[EntityId.CHICKEN], greaterThan(0));
      // combat trains hitpoints alongside the attack skill
      expect(report.xp[SkillId.HITPOINTS], greaterThan(0));

      tearDownSession(session);
    });

    test('crafting pays the crafts, the inputs and the output', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 5000;
      expect(
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      final expected = actionsIn(session, 300);
      final report = settle(session, 300);
      final xpPerCraft = RecipeCatalog().recipeById('smelt_copper_bar').xp;

      expect(report.actionCount, expected);
      expect(report.timeAway, const Duration(seconds: 300));
      expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], expected);
      expect(save.inventoryData.itemMap[ItemId.COPPER_ORE], 5000 - expected);
      expect(report.items.itemMap[ItemId.COPPER_BAR], expected);
      expect(
        report.xp[SkillId.BLACKSMITHING],
        closeTo(xpPerCraft * expected, 1e-6),
      );

      tearDownSession(session);
    });

    test('exploration pays the explores, the xp and the finds', () {
      final session = buildSession();
      session.worldController.startExplore();

      final expected = actionsIn(session, 300);
      final xpBefore = xpOf(session, SkillId.EXPLORATION);
      final report = settle(session, 300);

      expect(report.actionCount, expected);
      expect(report.timeAway, const Duration(seconds: 300));
      expect(report.xp[SkillId.EXPLORATION], greaterThan(0));
      expect(
        xpOf(session, SkillId.EXPLORATION) - xpBefore,
        closeTo(report.xp[SkillId.EXPLORATION]!, 1e-6),
      );
      // an explore turns up entities rather than kills
      expect(report.entities, isNotEmpty);

      tearDownSession(session);
    });
  });

  // -------------------------------------------------------------- arithmetic

  group('actions performed against actions owed', () {
    test('a whole number of intervals fires exactly that many', () {
      final session = buildSession();
      fight(session, EntityId.TREE);

      final step = interval(session);
      final report = settle(session, step * 10);

      expect(report.actionCount, 10);
      tearDownSession(session);
    });

    test('a remainder under one interval buys no extra action', () {
      final session = buildSession();
      fight(session, EntityId.TREE);

      final step = interval(session);
      final report = settle(session, step * 10 + step * 0.9);

      expect(report.actionCount, 10);
      tearDownSession(session);
    });

    test('a gap too short for one action settles nothing', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      final now = goOffline(session, interval(session) * 0.5);
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      expect(session.actionTimingController.pendingOfflineReport, isNull);
      tearDownSession(session);
    });
  });

  // ----------------------------------------------------------------- stances

  group('each stance settles on its own terms', () {
    int actionsUnder(Stance stance) {
      final session = buildSession();
      setLevel(session, SkillId.SPEED, 50);
      setLevel(session, SkillId.STRENGTH, 50);
      fight(session, EntityId.TREE);
      session.playerDataService.setStance(
        stance,
        session.saveGameData.playerData,
      );

      final report = settle(session, 300);
      tearDownSession(session);
      return report.actionCount;
    }

    test('only the fast stance shortens the interval', () {
      final fast = actionsUnder(Stance.fast);
      final strong = actionsUnder(Stance.strong);
      final offensive = actionsUnder(Stance.offensive);
      final defensive = actionsUnder(Stance.defensive);

      // the three strength stances all leave the interval alone, so a gap
      // is worth the same number of actions under any of them
      expect(strong, offensive);
      expect(strong, defensive);
      expect(fast, greaterThan(strong));
    });

    test('the settle reads the stance rather than the last live frame', () {
      for (final stance in Stance.values) {
        final session = buildSession();
        final save = session.saveGameData;
        setLevel(session, SkillId.SPEED, 30);
        setLevel(session, SkillId.STRENGTH, 30);
        fight(session, EntityId.TREE);
        // a frame from another stance left this behind; the settle must
        // overwrite it rather than inherit it
        save.actionTimingData.boostingSpeed = stance != Stance.fast;
        session.playerDataService.setStance(stance, save.playerData);

        settle(session, 60);

        expect(
          save.actionTimingData.boostingSpeed,
          stance == Stance.fast,
          reason: '${stance.name} read the wrong boost skill',
        );
        tearDownSession(session);
      }
    });
  });

  group('a stance the activity does not offer', () {
    test('is coerced at bind time, and the settle honours the coerced one', () {
      // a tree offers strong and fast; an offensive stance is not on the
      // menu, so binding drops it back to fast - and the settle has to run
      // the stance the player is actually in, not the one they asked for
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.SPEED, 50);
      session.playerDataService.setStance(Stance.offensive, save.playerData);
      fight(session, EntityId.TREE);

      expect(session.playerDataService.getStance(save.playerData), Stance.fast);

      final report = settle(session, 300);

      // fast, so the interval was shortened by the speed stat
      expect(save.actionTimingData.boostingSpeed, isTrue);
      expect(report.actionCount, actionsIn(session, 300));
      tearDownSession(session);
    });
  });

  // ------------------------------------------------------------ boost endings

  group('a segment that ends on a boost running out', () {
    /// A session with a full stamina pool and the loop locked at full boost.
    GameSession boosted(Stance stance, {int stamina = 20}) {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.SPEED, 20);
      setLevel(session, SkillId.STRENGTH, 20);
      setLevel(session, SkillId.STAMINA, stamina);
      session.playerDataService.setStance(stance, save.playerData);
      save.playerData.stamina = session.playerDataService.getMaxStamina(
        save.playerData,
      );
      fight(session, EntityId.TREE);
      save.actionTimingData.boostLocked = true;
      save.actionTimingData.percentOfMaxBoost = 1.0;
      // the ceiling the settle will refresh to, set up front so a test can
      // measure the drain it is about to be charged
      final stats = session.playerDataService.getStatTotals(save.playerData);
      save.actionTimingData.boostingSpeed = stance == Stance.fast;
      save.actionTimingData.maxBoostMultiplier = stance == Stance.fast
          ? ActionTimingService().maxSpeedBoostForStat(
              stats[SkillId.SPEED] ?? 1,
            )
          : ActionTimingService().maxStrengthBoostForStat(
              stats[SkillId.STRENGTH] ?? 1,
            );
      return session;
    }

    test('a boosted speed run drains, breaks, then runs on unboosted', () {
      final session = boosted(Stance.fast);
      final save = session.saveGameData;

      final report = settle(session, 3600);

      // the pool cannot fund an hour, so the lock broke partway
      expect(save.actionTimingData.boostLocked, isFalse);
      // and the rest of the hour was spent recovering back to full
      expect(
        save.playerData.stamina,
        session.playerDataService.getMaxStamina(save.playerData),
      );
      // the boosted stretch bought more actions than an hour of idle would
      expect(report.actionCount, greaterThan(actionsIn(session, 3600)));
      tearDownSession(session);
    });

    test('a boosted strength run drains per action, not per second', () {
      final session = boosted(Stance.strong);
      final save = session.saveGameData;
      final timing = ActionTimingService();

      final perAction = timing.boostDrain(
        timing.getCurrentSpeedMultiplier(save.actionTimingData),
        speedStance: false,
      );
      final pool = save.playerData.stamina;
      // what the pool can fund, in whole actions
      final affordable = (pool / perAction).floor();

      final report = settle(session, 3600);

      expect(save.actionTimingData.boostLocked, isFalse);
      // a strength boost leaves the interval alone, so an hour is worth the
      // same actions boosted or not - the boost bought damage, not speed
      expect(report.actionCount, actionsIn(session, 3600));
      expect(affordable, greaterThan(0));
      tearDownSession(session);
    });

    test('a strength pool that cannot fund a whole action still settles', () {
      final session = boosted(Stance.strong);
      final save = session.saveGameData;
      final timing = ActionTimingService();

      // a pool with a fraction of an action left over in it. the settle cuts
      // its segment at the stamina, so the fraction is a stretch too short to
      // fire in - and a segment that fires nothing used to spend nothing,
      // which left the same fraction to cut the next segment, and the next,
      // burning the whole gap at zero actions.
      final perAction = timing.boostDrain(
        timing.getCurrentSpeedMultiplier(save.actionTimingData),
        speedStance: false,
      );
      save.playerData.stamina = perAction * 3.5;

      final report = settle(session, 3600);

      // the gap is worth what it was always worth: a strength boost buys
      // damage, not speed, so the hour holds the same actions either way
      expect(report.actionCount, actionsIn(session, 3600));
      expect(save.actionTimingData.boostLocked, isFalse);
      tearDownSession(session);
    });

    test('a boost the gap cannot exhaust stays locked and keeps draining', () {
      final session = boosted(Stance.fast, stamina: 99);
      final save = session.saveGameData;
      final timing = ActionTimingService();

      final before = save.playerData.stamina;
      final perSecond = timing.boostDrain(
        timing.getCurrentSpeedMultiplier(save.actionTimingData),
        speedStance: true,
      );

      settle(session, 10);

      expect(save.actionTimingData.boostLocked, isTrue);
      // exactly ten seconds of drain, not the whole pool
      expect(save.playerData.stamina, closeTo(before - 10 * perSecond, 1e-6));
      tearDownSession(session);
    });

    test('an already-empty locked boost settles the whole gap unboosted', () {
      final session = boosted(Stance.fast);
      final save = session.saveGameData;
      save.playerData.stamina = 0;

      final report = settle(session, 300);

      expect(save.actionTimingData.boostLocked, isFalse);
      expect(report.actionCount, actionsIn(session, 300));
      tearDownSession(session);
    });
  });

  // ----------------------------------------------------------------- potions

  group('a potion segment', () {
    /// Drinks [id] and pins its expiry [seconds] after the player's last
    /// action, so the settle meets it partway through the gap.
    void drink(GameSession session, ItemId id, double seconds) {
      final save = session.saveGameData;
      final potion = id.build() as BuffItem;
      potion.expirationTime = save.playerData.lastActionTime.add(
        Duration(microseconds: (seconds * 1e6).round()),
      );
      session.buffService.addBuff(potion, save.playerData.buffData);
    }

    test('a potion that runs out mid-gap splits the window', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      final now = goOffline(session, 300);
      drink(session, ItemId.MINOR_SPEED_POTION, 120);
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      // the potion was swept at the instant it went out, not left standing
      expect(
        session.buffService.getGlobalBuff(
          save.playerData.buffData,
          ItemId.MINOR_SPEED_POTION,
          at: now,
        ),
        isNull,
      );
      tearDownSession(session);
    });

    test('a speed potion is worth actions for the stretch it was up', () {
      // at the bottom of the speed curve a single point moves the interval
      // enough to be worth whole actions over ten minutes; at 40 speed the
      // same potion is worth less than one, and proves nothing
      int run({required double covering}) {
        final session = buildSession();
        final save = session.saveGameData;
        session.playerDataService.setStance(Stance.fast, save.playerData);
        fight(session, EntityId.TREE);

        final now = goOffline(session, 600);
        if (covering > 0) {
          drink(session, ItemId.MINOR_SPEED_POTION, covering);
        }
        session.offlineProgressSystem.settle(
          save.playerData,
          save.actionTimingData,
          now: now,
        );
        final count =
            session.actionTimingController.pendingOfflineReport!.actionCount;
        tearDownSession(session);
        return count;
      }

      final none = run(covering: 0);
      final half = run(covering: 300);
      final whole = run(covering: 600);

      // the potion lends its speed only to the stretch it was actually up
      // for: half a gap of it is worth strictly less than all of it, and
      // strictly more than none
      expect(whole, greaterThan(none));
      expect(half, greaterThan(none));
      expect(half, lessThan(whole));
    });

    test('a potion covering the whole gap never cuts it short', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      final now = goOffline(session, 60);
      drink(session, ItemId.MINOR_STRENGTH_POTION, 600);
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      // still up at the end of the gap
      expect(
        session.buffService.getGlobalBuff(
          save.playerData.buffData,
          ItemId.MINOR_STRENGTH_POTION,
          at: now,
        ),
        isNotNull,
      );
      tearDownSession(session);
    });

    test('a recovery potion pays its rate only while it was up', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.STAMINA, 60);
      save.playerData.stamina = 0;
      fight(session, EntityId.TREE);

      final now = goOffline(session, 120);
      drink(session, ItemId.MINOR_RECOVERY_POTION, 60);

      final buffed = session.playerDataService.staminaRecoveryPerSecond(
        save.playerData,
        at: save.playerData.lastActionTime,
      );
      final base = session.playerDataService.staminaRecoveryPerSecond(
        save.playerData,
        at: now,
      );
      expect(buffed, greaterThan(base));

      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      // 60s at the buffed rate then 60s at the player's own, not 120 of
      // either - reading the wall clock would have paid the whole gap at
      // the base rate, since the potion is long gone by settle time
      expect(save.playerData.stamina, closeTo(60 * buffed + 60 * base, 1e-6));
      tearDownSession(session);
    });
  });

  // -------------------------------------------------------------- level - ups

  group('a level-up segment', () {
    test('pays every action the gap was worth across the split', () {
      final session = buildSession();
      fight(session, EntityId.TREE);

      final expected = actionsIn(session, 300);
      final report = settle(session, 300);

      // the gap levels woodcutting partway through, which cuts the window.
      // the cut must not cost the player an action.
      expect(
        session.skillService.getLevel(
          session.saveGameData.playerData.skillData[SkillId.WOODCUTTING]!,
        ),
        greaterThan(1),
        reason: 'the gap was supposed to level the skill',
      );
      expect(report.actionCount, expected);
      tearDownSession(session);
    });

    test('the xp reported is the xp banked', () {
      final session = buildSession();
      fight(session, EntityId.TREE);
      final before = xpOf(session, SkillId.WOODCUTTING);

      final report = settle(session, 600);

      expect(
        xpOf(session, SkillId.WOODCUTTING) - before,
        closeTo(report.xp[SkillId.WOODCUTTING]!, 1e-6),
      );
      tearDownSession(session);
    });
  });

  // ------------------------------------------------- time away, and stopping

  group('the time the report says it covered', () {
    test('is the whole gap even when the loop stopped partway', () {
      final session = buildSession();
      final save = session.saveGameData;
      // only enough ore for a handful of crafts, so the loop stops early
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 5;
      expect(
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      final report = settle(session, 600);

      expect(report.timeAway, const Duration(seconds: 600));
      expect(report.actionCount, 5);
      expect(save.actionTimingData.running, isFalse);
      tearDownSession(session);
    });

    test(
      'the rest of a stopped gap recovers stamina rather than vanishing',
      () {
        final session = buildSession();
        final save = session.saveGameData;
        setLevel(session, SkillId.STAMINA, 40);
        save.playerData.stamina = 0;
        save.inventoryData.itemMap[ItemId.COPPER_ORE] = 3;
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        );

        settle(session, 600);

        // the loop died in the first few seconds; the remaining ~10 minutes
        // were idle, and idle recovers
        expect(save.playerData.stamina, greaterThan(0));
        tearDownSession(session);
      },
    );
  });

  // -------------------------------------------------------------------- loot

  group('what the gap paid out', () {
    test('gathering loot in the report is the loot in the bag', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.COPPER);

      final report = settle(session, 600);

      // every stack the report claims has to be in the inventory too, at
      // the same count - the report is a summary of what happened, not a
      // second, parallel payout
      expect(report.items.itemMap, isNotEmpty);
      for (final entry in report.items.itemMap.entries) {
        expect(
          save.inventoryData.itemMap[entry.key],
          entry.value,
          reason: '${entry.key.name} disagrees with the bag',
        );
      }
      tearDownSession(session);
    });

    test('equipment drops arrive as instances, not as a count', () {
      final session = buildSession();
      final save = session.saveGameData;
      for (final skill in [
        SkillId.ATTACK,
        SkillId.STRENGTH,
        SkillId.DEFENCE,
        SkillId.HITPOINTS,
      ]) {
        setLevel(session, skill, 99);
      }
      // half its kills pay a pitchfork, so an hour is certain to turn some up
      fight(session, EntityId.ROTWOOD_SCARECROW_1);

      final report = settle(session, 3600);

      final forks = report.items.equipment
          .where((e) => e.id == ItemId.PITCHFORK)
          .toList();
      expect(forks, isNotEmpty, reason: 'the run turned up no equipment');
      // an instance carrying its rolled quality, never a stackable count
      expect(report.items.itemMap[ItemId.PITCHFORK], isNull);
      expect(forks.map((f) => f.quality), everyElement(Rarity.RARE));
      // and the report's copy must not be the player's own instance
      final playerIds = save.inventoryData.equipment
          .map((e) => identityHashCode(e))
          .toSet();
      for (final f in forks) {
        expect(playerIds.contains(identityHashCode(f)), isFalse);
      }
      tearDownSession(session);
    });

    test('kills are counted by kind', () {
      final session = buildSession();
      setLevel(session, SkillId.WOODCUTTING, 40);
      fight(session, EntityId.TREE, count: 100000);

      final report = settle(session, 600);

      expect(report.entitiesDefeated.keys, [EntityId.TREE]);
      expect(report.enemiesDefeated, report.entitiesDefeated[EntityId.TREE]);
      tearDownSession(session);
    });
  });

  // ------------------------------------------------------------- exploration

  group('exploration offline', () {
    test('credits its finds to the zone as well as the report', () {
      final session = buildSession();
      final save = session.saveGameData;
      session.worldController.startExplore();

      final report = settle(session, 900);

      expect(report.entities, isNotEmpty);
      final zone = save.worldData.zones[save.playerData.currentZoneId]!;
      for (final id in report.entities.keys) {
        expect(
          zone.discoveredEntities.any((e) => e.id == id),
          isTrue,
          reason: '${id.name} was reported but never stood up in the zone',
        );
      }
      tearDownSession(session);
    });

    test('explore xp is flat per action, so the total is exact', () {
      final session = buildSession();
      final save = session.saveGameData;
      session.worldController.startExplore();

      final perExplore = save.playerData.currentZoneId.definition.xpPerExplore;
      final report = settle(session, 300);

      expect(
        report.xp[SkillId.EXPLORATION],
        closeTo(perExplore * report.actionCount, 1e-6),
      );
      tearDownSession(session);
    });
  });

  // ------------------------------------------------------------------ deaths

  group('dying while away', () {
    test('reports the killer and how far into the gap it happened', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.IMP_LEGENDARY);

      final report = settle(session, 3600);

      expect(report.died, isTrue);
      expect(report.killedBy, EntityId.IMP_LEGENDARY);
      expect(report.diedAfter, isNotNull);
      // it happened early in the hour, not at the end of it
      expect(report.diedAfter!, lessThan(const Duration(minutes: 10)));
      // and the whole gap is still what the report says it covered
      expect(report.timeAway, const Duration(seconds: 3600));
      // the loop is stopped and the player is back on 1hp
      expect(save.actionTimingData.running, isFalse);
      expect(save.playerData.hitpoints, 1);
      tearDownSession(session);
    });
  });

  // ------------------------------------------------------- combined segments

  group('several thresholds in one gap', () {
    test('a potion, a level-up and a boost all cut the same window', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.SPEED, 20);
      setLevel(session, SkillId.STAMINA, 20);
      session.playerDataService.setStance(Stance.fast, save.playerData);
      save.playerData.stamina = session.playerDataService.getMaxStamina(
        save.playerData,
      );
      fight(session, EntityId.TREE);

      final now = goOffline(session, 1800);
      final potion = ItemId.MINOR_SPEED_POTION.build() as BuffItem;
      potion.expirationTime = save.playerData.lastActionTime.add(
        const Duration(seconds: 400),
      );
      session.buffService.addBuff(potion, save.playerData.buffData);

      save.actionTimingData.boostLocked = true;
      save.actionTimingData.percentOfMaxBoost = 1.0;

      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );
      final report = session.actionTimingController.pendingOfflineReport!;

      // every threshold resolved: the potion burnt out, the boost drained,
      // the skill levelled, and the whole half hour is accounted for
      expect(
        session.buffService.getGlobalBuff(
          save.playerData.buffData,
          ItemId.MINOR_SPEED_POTION,
          at: now,
        ),
        isNull,
      );
      expect(save.actionTimingData.boostLocked, isFalse);
      expect(
        session.skillService.getLevel(
          save.playerData.skillData[SkillId.WOODCUTTING]!,
        ),
        greaterThan(1),
      );
      expect(report.timeAway, const Duration(seconds: 1800));
      expect(save.playerData.lastActionTime, now);
      expect(report.actionCount, greaterThan(0));
      tearDownSession(session);
    });

    test('a settled gap is never worth more time than it held', () {
      // the ceiling on any settle: the actions it paid, at the fastest
      // interval it could possibly have run them at, still fit in the gap.
      // Over-paying here is how a rounding fix turns into free progress.
      for (final stance in Stance.values) {
        final session = buildSession();
        final save = session.saveGameData;
        setLevel(session, SkillId.SPEED, 30);
        setLevel(session, SkillId.STRENGTH, 30);
        setLevel(session, SkillId.STAMINA, 30);
        save.playerData.stamina = session.playerDataService.getMaxStamina(
          save.playerData,
        );
        fight(session, EntityId.TREE);
        // after binding: an encounter coerces the stance it offers, so one
        // set before the bind would not survive it
        session.playerDataService.setStance(stance, save.playerData);
        save.actionTimingData.boostLocked = true;
        save.actionTimingData.percentOfMaxBoost = 1.0;

        const gap = 1200.0;
        final report = settle(session, gap);

        // the floor on an interval is the fully boosted one; nothing the
        // loop can do runs an action faster than that
        final stats = session.playerDataService.getStatTotals(save.playerData);
        final ran = session.playerDataService.getStance(save.playerData);
        final ceiling = ran == Stance.fast
            ? ActionTimingService().maxSpeedBoostForStat(
                stats[SkillId.SPEED] ?? 1,
              )
            : 1.0;
        final fastest = interval(session) / ceiling;

        expect(
          report.actionCount,
          lessThanOrEqualTo((gap / fastest).ceil()),
          reason: '${ran?.name} paid more actions than the gap could hold',
        );
        tearDownSession(session);
      }
    });

    test('settling twice pays the second one nothing', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      final first = settle(session, 300);
      expect(first.actionCount, greaterThan(0));

      final logsAfterFirst = save.inventoryData.itemMap[ItemId.LOGS];
      final seq = session.actionTimingController.offlineReportSequence;

      // the window closed on the first pass: lastActionTime is `now`, so a
      // second settle at the same instant has nothing left to replay
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: save.playerData.lastActionTime,
      );

      expect(save.inventoryData.itemMap[ItemId.LOGS], logsAfterFirst);
      expect(session.actionTimingController.offlineReportSequence, seq);
      tearDownSession(session);
    });
  });

  // ------------------------------------------------ activities under a boost

  group('a boost over each activity', () {
    /// Locks the loop at full boost in the stance it is already in.
    void lockBoost(GameSession session) {
      final save = session.saveGameData;
      setLevel(session, SkillId.STAMINA, 40);
      save.playerData.stamina = session.playerDataService.getMaxStamina(
        save.playerData,
      );
      save.actionTimingData.boostLocked = true;
      save.actionTimingData.percentOfMaxBoost = 1.0;
    }

    test('a speed boost buys a crafter more crafts', () {
      int run({required bool boosted}) {
        final session = buildSession();
        final save = session.saveGameData;
        setLevel(session, SkillId.SPEED, 40);
        save.inventoryData.itemMap[ItemId.COPPER_ORE] = 100000;
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        );
        // bench work runs fast with nothing to choose
        expect(
          session.playerDataService.getStance(save.playerData),
          Stance.fast,
        );
        if (boosted) lockBoost(session);

        final count = settle(session, 600).actionCount;
        tearDownSession(session);
        return count;
      }

      expect(run(boosted: true), greaterThan(run(boosted: false)));
    });

    test('a strength boost leaves a gatherer\'s pace alone', () {
      int run({required bool boosted}) {
        final session = buildSession();
        final save = session.saveGameData;
        setLevel(session, SkillId.STRENGTH, 40);
        fight(session, EntityId.COPPER);
        session.playerDataService.setStance(Stance.strong, save.playerData);
        if (boosted) lockBoost(session);

        final count = settle(session, 600).actionCount;
        tearDownSession(session);
        return count;
      }

      // strength buys yield per swing, never swings per minute
      expect(run(boosted: true), run(boosted: false));
    });

    test('a boosted fight still fires whole actions and reports them', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.ATTACK, 30);
      setLevel(session, SkillId.HITPOINTS, 50);
      setLevel(session, SkillId.SPEED, 30);
      save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 5000;
      save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
      fight(session, EntityId.CHICKEN);
      session.playerDataService.setStance(Stance.fast, save.playerData);
      lockBoost(session);

      final report = settle(session, 1800);

      expect(report.actionCount, greaterThan(0));
      expect(report.xp[SkillId.ATTACK], greaterThan(0));
      expect(save.playerData.stamina, greaterThanOrEqualTo(0));
      tearDownSession(session);
    });
  });

  // ---------------------------------------------------- fires and zone buffs

  group('a fire burning out mid-gap', () {
    test('cooks only the share of the gap it was lit for', () {
      int cooksOver({required double burn}) {
        final session = buildSession();
        final save = session.saveGameData;
        setLevel(session, SkillId.COOKING, 20);
        save.inventoryData.itemMap[ItemId.MINNOW] = 100000;

        // light it and bind the cook while it is still burning - the craft
        // will not start on a dead fire - then rewind the clock and pin the
        // fire to go out [burn] into the gap
        session.firemakingSystem.lightOrExtend(
          ItemId.COOKFIRE,
          EntityId.FIREPIT,
          save.playerData.currentZoneId,
          save.playerData.buffData,
        );
        expect(
          session.craftingController.startCraftingActionFor(
            'cook_minnow',
            EntityId.FIREPIT,
          ),
          isTrue,
        );

        final now = goOffline(session, 600);
        final fire = session.buffService.getZoneBuff(
          save.playerData.buffData,
          save.playerData.currentZoneId,
          EntityId.FIREPIT,
        )!;
        fire.expirationTime = save.playerData.lastActionTime.add(
          Duration(microseconds: (burn * 1e6).round()),
        );
        session.offlineProgressSystem.settle(
          save.playerData,
          save.actionTimingData,
          now: now,
        );
        final report = session.actionTimingController.pendingOfflineReport;
        final count = report?.actionCount ?? 0;
        tearDownSession(session);
        return count;
      }

      final short = cooksOver(burn: 120);
      final long = cooksOver(burn: 480);

      // the fire is what makes a cook possible, so a longer burn is worth
      // strictly more cooks - and neither runs the whole ten minutes
      expect(short, greaterThan(0));
      expect(long, greaterThan(short));
    });
  });

  // --------------------------------------------- stopping short, prorated

  group('an action that stops mid-segment', () {
    test('charges only the time it used, and idles the rest', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.STAMINA, 40);
      save.playerData.stamina = 0;
      // four crafts of material against a ten minute gap
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 4;
      session.craftingController.startCraftingActionFor(
        'smelt_copper_bar',
        EntityId.ANVIL,
      );

      const gap = 600.0;
      final step = interval(session);
      final report = settle(session, gap);

      expect(report.actionCount, 4);
      expect(save.actionTimingData.running, isFalse);

      // with nothing boosted, every second of the gap recovers - the four
      // crafts as much as the idle stretch behind them - so the whole gap
      // is paid at the player's own rate rather than only its idle tail
      final rate = session.playerDataService.staminaRecoveryPerSecond(
        save.playerData,
      );
      final cap = session.playerDataService.getMaxStamina(save.playerData);
      expect(gap * rate, lessThan(cap), reason: 'the cap would hide the sum');
      expect(save.playerData.stamina, closeTo(gap * rate, rate * step));
      expect(step, greaterThan(0));
      tearDownSession(session);
    });

    test('a node that runs dry stops the loop and idles the remainder', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.WOODCUTTING, 60);
      fight(session, EntityId.TREE, count: 3);

      final report = settle(session, 600);

      expect(report.entitiesDefeated[EntityId.TREE], 3);
      expect(save.actionTimingData.running, isFalse);
      expect(report.timeAway, const Duration(seconds: 600));
      tearDownSession(session);
    });
  });

  // -------------------------------------------------------- stamina ceiling

  group('stamina over a long idle gap', () {
    test('recovers to the cap and stops there', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.STAMINA, 30);
      save.playerData.stamina = 0;
      // one craft of material, so the loop stops immediately and the rest
      // of the day is idle
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 1;
      session.craftingController.startCraftingActionFor(
        'smelt_copper_bar',
        EntityId.ANVIL,
      );

      settle(session, 86400);

      expect(
        save.playerData.stamina,
        session.playerDataService.getMaxStamina(save.playerData),
      );
      tearDownSession(session);
    });
  });

  // ------------------------------------------------ two skills levelling up

  group('a fight that levels two skills', () {
    test('cuts at the sooner of them and pays both', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.ATTACK, 20);
      setLevel(session, SkillId.HITPOINTS, 40);
      save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 5000;
      save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
      fight(session, EntityId.CHICKEN);

      final attackBefore = xpOf(session, SkillId.ATTACK);
      final hpBefore = xpOf(session, SkillId.HITPOINTS);
      final report = settle(session, 1800);

      // combat trains both, and the report has to account for both
      expect(
        xpOf(session, SkillId.ATTACK) - attackBefore,
        closeTo(report.xp[SkillId.ATTACK]!, 1e-6),
      );
      expect(
        xpOf(session, SkillId.HITPOINTS) - hpBefore,
        closeTo(report.xp[SkillId.HITPOINTS]!, 1e-6),
      );
      expect(report.actionCount, actionsIn(session, 1800));
      tearDownSession(session);
    });
  });

  // ------------------------------------------------------ invariants, swept

  group('invariants that hold for every settle', () {
    /// Every activity the loop can be bound to, as a setup step.
    final activities = <String, void Function(GameSession)>{
      'gathering': (s) => fight(s, EntityId.TREE),
      'mining': (s) => fight(s, EntityId.COPPER),
      'combat': (s) {
        final save = s.saveGameData;
        setLevel(s, SkillId.ATTACK, 30);
        setLevel(s, SkillId.HITPOINTS, 50);
        save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 20000;
        save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
        fight(s, EntityId.CHICKEN);
      },
      'crafting': (s) {
        s.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE] = 100000;
        s.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        );
      },
      'exploration': (s) => s.worldController.startExplore(),
    };

    for (final entry in activities.entries) {
      for (final boosted in [false, true]) {
        final label = boosted ? '${entry.key}, boosted' : entry.key;
        test('$label settles cleanly', () {
          final session = buildSession();
          final save = session.saveGameData;
          setLevel(session, SkillId.SPEED, 25);
          setLevel(session, SkillId.STRENGTH, 25);
          setLevel(session, SkillId.STAMINA, 25);
          entry.value(session);
          if (boosted) {
            save.playerData.stamina = session.playerDataService.getMaxStamina(
              save.playerData,
            );
            save.actionTimingData.boostLocked = true;
            save.actionTimingData.percentOfMaxBoost = 1.0;
          }

          final xpBefore = <SkillId, double>{
            for (final id in SkillId.values)
              id: save.playerData.skillData[id]?.xp ?? 0,
          };
          const gap = 1800.0;
          final now = goOffline(session, gap);
          session.offlineProgressSystem.settle(
            save.playerData,
            save.actionTimingData,
            now: now,
          );
          final report = session.actionTimingController.pendingOfflineReport;

          // the whole gap is always consumed, however the segments fell
          expect(save.playerData.lastActionTime, now, reason: '$label clock');

          expect(report, isNotNull, reason: '$label raised no report');
          expect(report!.timeAway, Duration(seconds: gap.toInt()));
          expect(report.actionCount, greaterThan(0));

          // stamina stays inside its own bounds
          expect(save.playerData.stamina, greaterThanOrEqualTo(0));
          expect(
            save.playerData.stamina,
            lessThanOrEqualTo(
              session.playerDataService.getMaxStamina(save.playerData),
            ),
          );

          // every skill the report claims xp for banked exactly that much,
          // and nothing banked xp the report kept quiet about
          for (final id in SkillId.values) {
            final banked =
                (save.playerData.skillData[id]?.xp ?? 0) - xpBefore[id]!;
            final claimed = report.xp[id] ?? 0;
            expect(
              banked,
              closeTo(claimed, 1e-6),
              reason: '$label: ${id.name} banked $banked, reported $claimed',
            );
          }

          // a settle never leaves a boost locked on an empty pool
          if (save.actionTimingData.boostLocked) {
            expect(save.playerData.stamina, greaterThan(0), reason: label);
          }

          tearDownSession(session);
        });
      }
    }
  });

  // ------------------------------------------------------------------- edges

  group('edges the replay has to survive', () {
    test('a day away terminates and stays inside its bounds', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.ATTACK, 40);
      setLevel(session, SkillId.HITPOINTS, 60);
      setLevel(session, SkillId.STAMINA, 30);
      save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 200000;
      save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
      fight(session, EntityId.CHICKEN);

      final report = settle(session, 86400);

      expect(report.timeAway, const Duration(days: 1));
      expect(report.actionCount, greaterThan(0));
      // a day of chickens levels the skill many times over; every one of
      // those level-ups cuts a segment, and the replay still has to finish
      expect(
        session.skillService.getLevel(
          save.playerData.skillData[SkillId.ATTACK]!,
        ),
        greaterThan(40),
      );
      tearDownSession(session);
    });

    test('exploring a zone with nothing to find settles without stalling', () {
      final session = buildSession();
      final save = session.saveGameData;
      // a settlement has an empty discovery table
      save.playerData.currentZoneId = ZoneId.SOUTH_HAVEN;
      session.worldController.startExplore();

      final now = goOffline(session, 600);
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      // nothing to show for it, but the clock still moved to the end
      expect(save.playerData.lastActionTime, now);
      tearDownSession(session);
    });

    test('a gap of exactly one interval pays exactly one action', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      // a gap this short is under the popup threshold, so it settles
      // without raising a report - count the fires themselves instead
      final fired = <int>[];
      final inner = save.actionTimingData.onFire;
      save.actionTimingData.onFire =
          (count, {bool offline = false, DateTime? at, Duration? span}) {
            fired.add(count);
            return inner(count, offline: offline, at: at, span: span);
          };

      final now = goOffline(session, interval(session));
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      expect(fired.fold<int>(0, (sum, c) => sum + c), 1);
      expect(session.actionTimingController.pendingOfflineReport, isNull);
      tearDownSession(session);
    });

    test('a clock that moved backwards settles nothing at all', () {
      final session = buildSession();
      final save = session.saveGameData;
      fight(session, EntityId.TREE);

      final before = save.playerData.lastActionTime;
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: before.subtract(const Duration(minutes: 5)),
      );

      // no payout, and the clock is left where it was rather than rewound
      expect(session.actionTimingController.pendingOfflineReport, isNull);
      expect(save.playerData.lastActionTime, before);
      expect(save.inventoryData.itemMap[ItemId.LOGS], isNull);
      tearDownSession(session);
    });
  });
}
