import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/offline_progress_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/offline_progress_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/systems/offline_progress_system.dart';

// A settle replays the gap rather than paying it out in one lump: segment by
// segment, each one running to the next moment the state changes under it -
// a buff burning out, a locked boost running dry, a level-up. These cover
// where the cuts land and what each segment is worth.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerDataService playerDataService;
  late SkillService skillService;
  late BuffService buffService;
  late ActionTimingService timingService;
  late ActionTimingSystem timingSystem;
  late OfflineProgressService offlineProgressService;
  late OfflineProgressData offlineProgressData;
  late OfflineProgressSystem system;

  setUp(() {
    buffService = BuffService();
    skillService = SkillService();
    playerDataService = PlayerDataService(
      buffService: buffService,
      equpmentService: EquipmentService(),
      skillService: skillService,
    );
    timingService = ActionTimingService();
    timingSystem = ActionTimingSystem(
      actionTimingService: timingService,
      playerDataService: playerDataService,
      equipmentService: EquipmentService(),
    );
    offlineProgressData = OfflineProgressData();
    offlineProgressService = OfflineProgressService(InventoryService());
    system = OfflineProgressSystem(
      actionTimingService: timingService,
      actionTimingSystem: timingSystem,
      playerDataService: playerDataService,
      skillService: skillService,
      buffService: buffService,
      offlineProgressService: offlineProgressService,
      offlineProgressData: offlineProgressData,
    );
  });

  PlayerData newPlayer() {
    return GameSessionFactory()
        .newGame(GameSessionFactory().catalog1())
        .playerData;
  }

  void setLevel(PlayerData player, SkillId skill, int level) {
    final data = player.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  // one fire of the bound action, as the loop asked for it
  ({int count, bool offline, DateTime? at}) fire(
    int count,
    bool offline,
    DateTime? at,
  ) => (count: count, offline: offline, at: at);

  // a running action state with a recording onFire. every fire the loop
  // makes is appended, so a test can tell one batch of 20 from two of 10.
  (ActionTimingData, List<({int count, bool offline, DateTime? at})>)
  recordingState() {
    final fired = <({int count, bool offline, DateTime? at})>[];
    final state = ActionTimingData();
    state.running = true;
    state.onFire =
        (count, {bool offline = false, DateTime? at, Duration? span}) =>
            fired.add(fire(count, offline, at));
    return (state, fired);
  }

  List<int> counts(List<({int count, bool offline, DateTime? at})> fired) =>
      fired.map((f) => f.count).toList();

  int totalActions(List<({int count, bool offline, DateTime? at})> fired) =>
      fired.fold(0, (sum, f) => sum + f.count);

  // puts [seconds] of wall clock between the player's last action and the
  // instant handed to the system, without actually waiting
  DateTime goOffline(PlayerData player, double seconds) {
    final now = DateTime.now();
    player.lastActionTime = now.subtract(
      Duration(microseconds: (seconds * 1e6).round()),
    );
    return now;
  }

  // the unboosted interval the loop will run [player] at, in seconds
  double idleInterval(PlayerData player) =>
      timingSystem.intervalFor(null, player).inMicroseconds / 1e6;

  group('segments', () {
    test('a gap with nothing in its way is a probe and then the rest', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // 60s away at the 3s default interval is 20 actions: one to measure
      // the action's xp rate, then the other 19
      final now = goOffline(player, 60);

      system.settle(player, state, now: now);

      expect(counts(fired), [1, 19]);
      expect(player.lastActionTime, now);
    });

    test('every fire is a batch, at the instant it is replaying', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      final start = player.lastActionTime;
      final now = goOffline(player, 60);
      final windowStart = player.lastActionTime;

      system.settle(player, state, now: now);

      expect(start, isNot(windowStart));
      // the first segment starts where the gap did, and the second picks up
      // exactly one action later - the replay's own clock, not the wall's
      expect(fired.every((f) => f.offline), isTrue);
      expect(fired.first.at, windowStart);
      expect(
        fired.last.at,
        windowStart.add(
          Duration(microseconds: (idleInterval(player) * 1e6).round()),
        ),
      );
    });

    test('a gap of nothing settles nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      final now = DateTime.now();
      player.lastActionTime = now;

      system.settle(player, state, now: now);

      expect(fired, isEmpty);
    });

    test('closes the window, so an immediate second pass does nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      final now = goOffline(player, 60);

      system.settle(player, state, now: now);
      expect(totalActions(fired), 20);
      expect(player.lastActionTime, now);

      // no further time has passed
      system.settle(player, state, now: now);
      expect(totalActions(fired), 20);
    });
  });

  group('the boost', () {
    test('a locked boost burns stamina and the rest runs unboosted', () {
      final player = newPlayer();
      setLevel(player, SkillId.SPEED, 20); // ceiling 2x
      player.stamina = 10;

      final (state, fired) = recordingState();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      state.maxBoostMultiplier = timingService.maxSpeedBoostForStat(
        playerDataService.getStatTotals(player)[SkillId.SPEED] ?? 1,
      );

      final now = goOffline(player, 3600);
      system.settle(player, state, now: now);

      // the stamina ran out long before the hour did, so the boost broke
      // and the segments after it ran at the idle interval - recovering,
      // which is what the player would have been doing with it stopped
      expect(state.boostLocked, isFalse);
      expect(player.stamina, playerDataService.getMaxStamina(player));
      expect(fired.length, greaterThanOrEqualTo(3));
      // the tail segment covers most of the hour, so it dwarfs the boosted
      // ones however the cuts landed
      expect(fired.last.count, greaterThan(totalActions(fired) ~/ 2));
    });

    test('a locked boost never outlasts the time actually spent away', () {
      final player = newPlayer();
      setLevel(player, SkillId.SPEED, 20);
      setLevel(player, SkillId.STAMINA, 99); // far more than the gap can burn
      player.stamina = playerDataService.getMaxStamina(player);
      final staminaBefore = player.stamina;

      final (state, fired) = recordingState();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      state.maxBoostMultiplier = timingService.maxSpeedBoostForStat(
        playerDataService.getStatTotals(player)[SkillId.SPEED] ?? 1,
      );

      final multiplier = timingService.getCurrentSpeedMultiplier(state);
      final drainPerSecond =
          ActionTimingService.staminaDrainPerBoost * (multiplier - 1);

      const seconds = 10.0;
      final now = goOffline(player, seconds);
      system.settle(player, state, now: now);

      // exactly 10s of drain - not the ~1000s the stamina pool could fund
      expect(
        player.stamina,
        closeTo(staminaBefore - seconds * drainPerSecond, 1e-6),
      );
      expect(state.boostLocked, isTrue);
      expect(fired, isNotEmpty);
    });

    test('a boosted gap fires more actions than an idle one', () {
      final player = newPlayer();
      setLevel(player, SkillId.SPEED, 20);
      setLevel(player, SkillId.STAMINA, 99);
      player.stamina = playerDataService.getMaxStamina(player);

      final (boosted, boostedFired) = recordingState();
      boosted.boostLocked = true;
      boosted.percentOfMaxBoost = 1.0;
      boosted.maxBoostMultiplier = timingService.maxSpeedBoostForStat(
        playerDataService.getStatTotals(player)[SkillId.SPEED] ?? 1,
      );
      system.settle(player, boosted, now: goOffline(player, 60));

      final idlePlayer = newPlayer();
      final (idle, idleFired) = recordingState();
      system.settle(idlePlayer, idle, now: goOffline(idlePlayer, 60));

      expect(totalActions(boostedFired), greaterThan(totalActions(idleFired)));
    });

    test('a locked boost worth nothing does not divide by zero', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // locked at zero boost: the multiplier is exactly 1, so the drain
      // rate is 0 and the boost can never be exhausted
      state.boostLocked = true;
      state.percentOfMaxBoost = 0.0;
      final now = goOffline(player, 60);

      system.settle(player, state, now: now);

      expect(totalActions(fired), 20);
      expect(player.stamina, isNot(isNaN));
    });

    test('an already-empty locked boost still settles the gap', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // a zero-length boost threshold must not read as "the settle is over"
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      state.maxBoostMultiplier = 2.0;
      player.stamina = 0;

      system.settle(player, state, now: goOffline(player, 60));

      expect(totalActions(fired), 20);
      expect(state.boostLocked, isFalse);
    });
  });

  group('stamina', () {
    test('recovers while away with no boost held', () {
      final player = newPlayer();
      setLevel(player, SkillId.RECOVERY, 20); // 2.0 stamina/sec
      setLevel(player, SkillId.STAMINA, 20); // room to recover into
      player.stamina = 5;
      final (state, _) = recordingState();
      final now = goOffline(player, 10);

      system.settle(player, state, now: now);

      // 10s * 2.0/sec on top of the 5 it started with
      expect(player.stamina, closeTo(25.0, 1e-6));
    });

    test('caps recovered stamina at the maximum', () {
      final player = newPlayer();
      setLevel(player, SkillId.RECOVERY, 20);
      player.stamina = 5;
      final (state, _) = recordingState();
      final now = goOffline(player, 3600); // an hour away

      system.settle(player, state, now: now);

      expect(player.stamina, playerDataService.getMaxStamina(player));
    });
  });

  group('buffs', () {
    // a fire in the player's zone, burning until [endsAt]
    void lightFireUntil(PlayerData player, DateTime endsAt) {
      final fire = ItemId.COOKFIRE.build() as FireItem;
      fire.expirationTime = endsAt;
      buffService.setZoneBuff(
        fire,
        player.buffData,
        player.currentZoneId,
        EntityId.FIREPIT,
      );
    }

    test('the window splits where a buff runs out', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      final now = goOffline(player, 60);
      // 30s in: 10 of the 20 actions the gap is worth
      lightFireUntil(
        player,
        player.lastActionTime.add(const Duration(seconds: 30)),
      );

      system.settle(player, state, now: now);

      // a probe, the rest of the fire's 30s, then the unlit remainder
      expect(counts(fired), [1, 9, 10]);
    });

    test('it splits at the earliest of several, and skips other zones', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      final now = goOffline(player, 60);
      final start = player.lastActionTime;

      lightFireUntil(player, start.add(const Duration(seconds: 30)));
      final potion = ItemId.COOKFIRE.build() as FireItem;
      potion.expirationTime = start.add(const Duration(seconds: 15));
      buffService.setZoneBuff(
        potion,
        player.buffData,
        player.currentZoneId,
        EntityId.ANVIL,
      );
      // another zone's fire is nothing to do with this settle
      final elsewhere = ItemId.COOKFIRE.build() as FireItem;
      elsewhere.expirationTime = start.add(const Duration(seconds: 42));
      buffService.setZoneBuff(
        elsewhere,
        player.buffData,
        ZoneId.values.firstWhere((z) => z != player.currentZoneId),
        EntityId.FIREPIT,
      );

      system.settle(player, state, now: now);

      // probe, up to 15s, up to 30s, then the rest - 42s never cuts
      expect(counts(fired), [1, 4, 5, 10]);
    });

    test('a buff is swept at the instant it went out, not at the end', () {
      final player = newPlayer();
      final (state, _) = recordingState();
      final now = goOffline(player, 60);
      final start = player.lastActionTime;
      lightFireUntil(player, start.add(const Duration(seconds: 30)));

      // still burning at the segment that covers it
      expect(
        buffService.getZoneBuff(
          player.buffData,
          player.currentZoneId,
          EntityId.FIREPIT,
        ),
        isNotNull,
      );

      system.settle(player, state, now: now);

      expect(
        buffService.getZoneBuff(
          player.buffData,
          player.currentZoneId,
          EntityId.FIREPIT,
        ),
        isNull,
      );
    });
  });

  group('buffed stats', () {
    test('a segment is worth what the buffs up for it were worth', () {
      final player = newPlayer();
      setLevel(player, SkillId.STAMINA, 10); // room to recover into
      player.stamina = 0;
      final (state, _) = recordingState();

      final now = goOffline(player, 60);
      // a recovery buff covering the first half of the gap: 21 recovery for
      // 30s, then the player's own 1 for the rest
      final potion = BuffItem(
        id: ItemId.NULL,
        name: 'test',
        value: 0,
        skillBonus: {SkillId.RECOVERY: 20},
        duration: const Duration(seconds: 30),
      );
      potion.expirationTime = player.lastActionTime.add(
        const Duration(seconds: 30),
      );
      buffService.addBuff(potion, player.buffData);

      system.settle(player, state, now: now);

      // 30s at 2.1/sec then 30s at 0.1/sec. reading the wall clock instead
      // would have paid the whole gap at 0.1 - the buff is long expired by
      // the time the settle runs
      expect(player.stamina, closeTo(30 * 2.1 + 30 * 0.1, 1e-6));
    });
  });

  group('levelling up', () {
    test('the window splits on the action that levels a skill', () {
      final player = newPlayer();
      final xpToLevel = skillService.xpToLevelUp(
        player.skillData[SkillId.WOODCUTTING]!,
      );
      // a quarter of a level an action: the probe pays one, three more
      // finish it
      final xpPerAction = xpToLevel / 4;

      final fired = <int>[];
      final state = ActionTimingData();
      state.running = true;
      state.onFire =
          (count, {bool offline = false, DateTime? at, Duration? span}) {
            fired.add(count);
            final result = EncounterActionResult()
              ..actionsPerformed = count
              ..xp = {SkillId.WOODCUTTING: xpPerAction * count};
            playerDataService.applyXp(player, result.xp);
            offlineProgressService.record(offlineProgressData, result);
          };

      system.settle(player, state, now: goOffline(player, 60));

      expect(fired.take(2), [1, 3]);
      expect(
        skillService.getLevel(player.skillData[SkillId.WOODCUTTING]!),
        greaterThan(1),
      );
    });
  });

  group('stopping short', () {
    test('an action that stops the loop ends the settle', () {
      final player = newPlayer();
      setLevel(player, SkillId.RECOVERY, 20);
      setLevel(player, SkillId.STAMINA, 99);
      player.stamina = 0;

      final fired = <int>[];
      final state = ActionTimingData();
      state.running = true;
      state.onFire =
          (count, {bool offline = false, DateTime? at, Duration? span}) {
            fired.add(count);
            // the second fire is the one whose requirements fail
            if (fired.length >= 2) timingService.stop(state);
          };

      system.settle(player, state, now: goOffline(player, 3600));

      expect(fired, hasLength(2));
      // the rest of the hour was spent idle, recovering
      expect(player.stamina, greaterThan(0));
      expect(state.running, isFalse);
    });
  });

  group('crediting the time a batch used', () {
    test('a batch that stops short reports only what it did', () {
      final player = newPlayer();
      final fired = <int>[];

      // an action that manages half of what it was asked for and stops
      final state = ActionTimingData();
      state.running = true;
      state.onFire =
          (count, {bool offline = false, DateTime? at, Duration? span}) {
            fired.add(count);
            final done = count > 1 ? count ~/ 2 : count;
            offlineProgressService.record(
              offlineProgressData,
              EncounterActionResult()..actionsPerformed = done,
            );
            // the probe measures the rate; the segment after it stops short
            if (count > 1) timingService.stop(state);
          };

      const gap = 100.0;
      system.settle(player, state, now: goOffline(player, gap));

      // the probe, then half of what the segment after it asked for. the
      // stretch it did not use is charged as idle instead - what that buys
      // is pinned end to end by the offline death in
      // offline_encounter_damage_test, where the time it saves is the
      // difference between dying two minutes in and dying an hour in.
      final interval =
          timingService.getCurrentActionDuration(state).inMicroseconds / 1e6;
      expect(fired, hasLength(2));
      expect(
        offlineProgressData.report.actionCount,
        closeTo((gap / interval).floor() / 2, 2),
      );
      expect(player.lastActionTime.isAtSameMomentAs(DateTime.now()), isFalse);
    });
  });

  group('stances', () {
    // a settle re-reads the stance every segment, the same way the frame
    // loop does: only the fast stance runs on speed, and only the fast
    // stance shortens the interval. get that wrong and a settle pays a
    // strength stance at speed-stance rates for the whole gap.
    test('only the fast stance shortens the interval offline', () {
      int actionsOver(Stance stance) {
        final player = newPlayer();
        setLevel(player, SkillId.SPEED, 50); // 50% off in the fast stance
        setLevel(player, SkillId.STRENGTH, 50);
        playerDataService.setStance(stance, player);

        final (state, fired) = recordingState();
        system.settle(player, state, now: goOffline(player, 300));
        return totalActions(fired);
      }

      final fast = actionsOver(Stance.fast);
      final strong = actionsOver(Stance.strong);

      // 300s at the 3s bench interval is 100 actions; the fast stance's
      // 50 speed takes 50% off that interval and buys exactly twice as many
      expect(strong, 100);
      expect(fast, 200);
    });

    test('a locked boost takes its ceiling from the stance offline', () {
      ActionTimingData settleWith(Stance stance) {
        final player = newPlayer();
        setLevel(player, SkillId.SPEED, 20);
        setLevel(player, SkillId.STRENGTH, 10);
        setLevel(player, SkillId.STAMINA, 99);
        player.stamina = playerDataService.getMaxStamina(player);
        playerDataService.setStance(stance, player);

        final (state, _) = recordingState();
        state.boostLocked = true;
        state.percentOfMaxBoost = 1.0;
        system.settle(player, state, now: goOffline(player, 60));
        return state;
      }

      // the strength stances spend strength: their ceiling is 1 + 0.1 a
      // point, and the boost buys damage rather than speed
      final strong = settleWith(Stance.strong);
      expect(strong.boostingSpeed, isFalse);
      expect(strong.maxBoostMultiplier, closeTo(1.0 + 0.1 * 10, 0.001));

      // the fast stance runs on speed: 1 + 0.05 a point, and it is the only
      // one the action interval divides by
      final fast = settleWith(Stance.fast);
      expect(fast.boostingSpeed, isTrue);
      expect(fast.maxBoostMultiplier, closeTo(1.0 + 0.05 * 20, 0.001));
    });

    test('a locked boost trains the stance it runs on, offline', () {
      final player = newPlayer();
      setLevel(player, SkillId.STRENGTH, 10);
      setLevel(player, SkillId.STAMINA, 99);
      player.stamina = playerDataService.getMaxStamina(player);
      playerDataService.setStance(Stance.offensive, player);

      final speedBefore = player.skillData[SkillId.SPEED]!.xp;

      final (state, _) = recordingState();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      system.settle(player, state, now: goOffline(player, 600));

      // the settle does not pay boost xp at all - that is a per-frame thing
      // the frame loop does - so neither stat moves, and speed least of all
      expect(player.skillData[SkillId.SPEED]!.xp, speedBefore);
      expect(state.boostingSpeed, isFalse);
    });
  });

  group('the report', () {
    test('is the sum of what every segment reported', () {
      final player = newPlayer();
      final state = ActionTimingData();
      state.running = true;
      state.onFire =
          (count, {bool offline = false, DateTime? at, Duration? span}) {
            offlineProgressService.record(
              offlineProgressData,
              EncounterActionResult()
                ..actionsPerformed = count
                ..xp = {SkillId.WOODCUTTING: 2.0 * count},
            );
          };

      system.settle(player, state, now: goOffline(player, 60));

      final report = offlineProgressData.pending;
      expect(report, isNotNull);
      expect(report!.actionCount, 20);
      expect(report.xp[SkillId.WOODCUTTING], 40.0);
    });

    test('a settle whose action did nothing raises no report', () {
      final player = newPlayer();
      final (state, _) = recordingState();

      system.settle(player, state, now: goOffline(player, 3600));

      expect(offlineProgressData.pending, isNull);
    });
  });

  group('the buff sweep stands down for a settle', () {
    // the 1s buff tick and the first frame back are not ordered against
    // each other, so the sweep has to be the one that yields: it would
    // otherwise delete the fire that the replay still has to cook on
    test('the tick leaves a burnt-out buff alone while a settle is owed', () {
      fakeAsync((async) {
        // built inside the zone so its 1s tick is one this test can advance
        final factory = GameSessionFactory();
        final catalogs = factory.catalog1();
        final session = factory.create(
          save: factory.newGame(catalogs),
          catalogs: catalogs,
          vsync: const TestVSync(),
        );
        final save = session.saveGameData;
        final zone = save.playerData.currentZoneId;
        final buffData = save.playerData.buffData;

        final fire = ItemId.COOKFIRE.build() as FireItem;
        fire.expirationTime = DateTime.now().subtract(const Duration(hours: 1));
        buffService.setZoneBuff(fire, buffData, zone, EntityId.FIREPIT);

        // the loop is running and the app has been away: a settle is owed
        save.actionTimingData.running = true;
        save.playerData.lastActionTime = DateTime.now().subtract(
          const Duration(minutes: 30),
        );

        async.elapse(const Duration(seconds: 5));
        expect(
          buffService.getZoneBuff(buffData, zone, EntityId.FIREPIT),
          isNotNull,
          reason: 'the record the settle still has to replay',
        );

        // once nothing is owed, the tick sweeps as it always did
        save.actionTimingData.running = false;
        async.elapse(const Duration(seconds: 5));
        expect(
          buffService.getZoneBuff(buffData, zone, EntityId.FIREPIT),
          isNull,
        );

        session.dispose();
      });
    });
  });

  group('settlePending', () {
    test('is true while a settle is owed, and false once it is done', () {
      final player = newPlayer();
      final (state, _) = recordingState();
      goOffline(player, 60);

      expect(system.settlePending(player, state), isTrue);

      system.settle(player, state, now: DateTime.now());

      expect(system.settlePending(player, state), isFalse);
    });

    test('is false for a loop that is not running', () {
      final player = newPlayer();
      final (state, _) = recordingState();
      state.running = false;
      goOffline(player, 60);

      expect(system.settlePending(player, state), isFalse);
    });
  });
}
