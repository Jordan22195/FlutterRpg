import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';

// frames stop arriving when the app is backgrounded, so the loop settles the
// gap in one pass when they start again: the actions that would have fired,
// and the stamina that would have drained or recovered.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerDataService playerDataService;
  late ActionTimingService timingService;
  late ActionSpeedSystem system;

  setUp(() {
    playerDataService = PlayerDataService(
      buffService: BuffService(),
      equpmentService: EquipmentService(),
      skillService: SkillService(),
    );
    timingService = ActionTimingService();
    system = ActionSpeedSystem(
      actionTimingService: timingService,
      playerDataService: playerDataService,
      equipmentService: EquipmentService(),
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

  // an action state with a recording onFire. every count the loop fires is
  // appended, so a test can tell one batch of 20 from two batches of 10.
  (ActionTimingData, List<int>) recordingState() {
    final fired = <int>[];
    final state = ActionTimingData();
    state.onFire = fired.add;
    return (state, fired);
  }

  // puts [seconds] of wall clock between the player's last action and the
  // instant handed to the system, without actually waiting
  DateTime goOffline(PlayerData player, double seconds) {
    final now = DateTime.now();
    player.lastActionTime = now.subtract(
      Duration(microseconds: (seconds * 1e6).round()),
    );
    return now;
  }

  group('offlineProgressUpdate', () {
    test('fires the actions the gap was worth, at the idle interval', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // 60s away at the 3s default interval is 20 actions
      final now = goOffline(player, 60);

      system.offlineProgressUpdate(player, state, now: now);

      expect(state.maxInterval, ActionTimingService.defaultMaxInterval);
      expect(fired, [20]);
    });

    test('recovers stamina while away with no boost held', () {
      final player = newPlayer();
      setLevel(player, SkillId.RECOVERY, 20); // 2.0 stamina/sec
      setLevel(player, SkillId.STAMINA, 20); // room to recover into
      player.stamina = 5;
      final (state, _) = recordingState();
      final now = goOffline(player, 10);

      system.offlineProgressUpdate(player, state, now: now);

      // 10s * 2.0/sec on top of the 5 it started with
      expect(player.stamina, closeTo(25.0, 1e-6));
    });

    test('caps recovered stamina at the maximum', () {
      final player = newPlayer();
      setLevel(player, SkillId.RECOVERY, 20);
      player.stamina = 5;
      final (state, _) = recordingState();
      final now = goOffline(player, 3600); // an hour away

      system.offlineProgressUpdate(player, state, now: now);

      expect(player.stamina, playerDataService.getMaxStamina(player));
    });

    test('a locked boost burns stamina and stops when it runs out', () {
      final player = newPlayer();
      setLevel(player, SkillId.SPEED, 20); // ceiling 2x
      player.stamina = 10;

      final (state, fired) = recordingState();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      state.maxBoostMultiplier = timingService.maxSpeedBoostForStat(
        playerDataService.getStatTotals(player)[SkillId.SPEED] ?? 1,
      );

      // drain is staminaDrainPerBoost * (multiplier - 1), so 10 stamina
      // buys a fixed number of seconds well short of the hour spent away
      final multiplier = timingService.getCurrentSpeedMultiplier(state);
      final drainPerSecond =
          ActionTimingService.staminaDrainPerBoost * (multiplier - 1);
      final affordableSeconds = 10 / drainPerSecond;

      final now = goOffline(player, 3600);
      system.offlineProgressUpdate(player, state, now: now);

      expect(affordableSeconds, lessThan(3600));
      expect(player.stamina, closeTo(0, 1e-6));
      // a boosted stretch then an unboosted one, fired separately
      expect(fired, hasLength(2));
      expect(fired.first, greaterThan(0));
      expect(fired.last, greaterThan(0));
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
      system.offlineProgressUpdate(player, state, now: now);

      // exactly 10s of drain - not the ~1000s the stamina pool could fund
      expect(
        player.stamina,
        closeTo(staminaBefore - seconds * drainPerSecond, 1e-6),
      );
      // the boost covered the whole gap, so there is no unboosted remainder
      expect(fired, hasLength(1));
    });

    test('a boosted stretch fires more actions than an unboosted one', () {
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
      system.offlineProgressUpdate(
        player,
        boosted,
        now: goOffline(player, 60),
      );

      final idlePlayer = newPlayer();
      final (idle, idleFired) = recordingState();
      system.offlineProgressUpdate(
        idlePlayer,
        idle,
        now: goOffline(idlePlayer, 60),
      );

      expect(boostedFired.first, greaterThan(idleFired.first));
    });

    test('a sub-second interval does not divide by zero', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // half a second an action: truncating to whole seconds would make
      // this a division by zero and an infinite action count
      state.maxInterval = const Duration(milliseconds: 500);
      final now = goOffline(player, 10);

      system.offlineProgressUpdate(player, state, now: now);

      expect(fired, [20]);
    });

    test('a locked boost worth nothing does not divide by zero', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // locked at zero boost: the multiplier is exactly 1, so the drain
      // rate is 0 and the boost can never be exhausted
      state.boostLocked = true;
      state.percentOfMaxBoost = 0.0;
      final now = goOffline(player, 60);

      system.offlineProgressUpdate(player, state, now: now);

      expect(fired, [20]);
      expect(player.stamina, isNot(isNaN));
    });

    test('closes the window, so an immediate second pass does nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      final now = goOffline(player, 60);

      system.offlineProgressUpdate(player, state, now: now);
      expect(fired, [20]);
      expect(player.lastActionTime, now);

      // no further time has passed
      system.offlineProgressUpdate(player, state, now: now);
      expect(fired, [20]);
    });
  });

  group('frameUpdate offline handover', () {
    // one frame, far enough after the last for [dt] to be non-zero
    void tick(ActionTimingData state, PlayerData player) {
      state.lastElapsed = const Duration(milliseconds: 16);
      system.frameUpdate(const Duration(milliseconds: 32), state, player);
    }

    test('a short gap stays on the normal per-frame path', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = true;
      goOffline(player, ActionTimingService.offlineThreshold.inSeconds - 1);

      tick(state, player);

      expect(fired, isEmpty);
      // the frame path refreshes the timestamp rather than settling a gap
      expect(
        DateTime.now().difference(player.lastActionTime).inSeconds,
        lessThan(1),
      );
    });

    test('a gap past the threshold settles as offline progress', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = true;
      goOffline(player, 60);

      tick(state, player);

      expect(fired, [20]);
    });

    test('a gap while the loop is stopped settles nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = false;
      goOffline(player, 60);

      tick(state, player);

      expect(fired, isEmpty);
    });

    test('starting the loop discards time spent with it stopped', () {
      final session = GameSessionFactory();
      final catalogs = session.catalog1();
      final game = session.create(
        save: session.newGame(catalogs),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );

      final fired = <int>[];
      final timing = game.actionTimingController;
      timing.bindOnFireFunction(fired.add);

      // the player was on another screen for a minute, not backgrounded
      goOffline(game.saveGameData.playerData, 60);
      timing.start();

      expect(
        DateTime.now()
            .difference(game.saveGameData.playerData.lastActionTime)
            .inSeconds,
        lessThan(1),
      );

      timing.stop();
      game.dispose();
    });
  });
}
