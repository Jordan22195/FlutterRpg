import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';

// Frames stop arriving when the app is backgrounded. The frame loop's job is
// only to notice that - it hands the gap to OfflineProgressSystem rather than
// running it as a frame. What the settle then pays out is covered in
// offline_progress_system_test.dart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerDataService playerDataService;
  late ActionTimingService timingService;
  late ActionTimingSystem system;

  setUp(() {
    playerDataService = PlayerDataService(
      buffService: BuffService(),
      equpmentService: EquipmentService(),
      skillService: SkillService(),
    );
    timingService = ActionTimingService();
    system = ActionTimingSystem(
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


  // an action state with a recording onFire. every count the loop fires is
  // appended, so a test can tell one batch of 20 from two batches of 10.
  (ActionTimingData, List<int>) recordingState() {
    final fired = <int>[];
    final state = ActionTimingData();
    state.onFire = (count, {bool offline = false, DateTime? at}) =>
        fired.add(count);
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

  group('frameUpdate offline handover', () {
    // one frame, far enough after the last for [dt] to be non-zero. returns
    // whether the frame turned out to be a gap for the caller to settle.
    bool tick(ActionTimingData state, PlayerData player) {
      state.lastElapsed = const Duration(milliseconds: 16);
      return system.frameUpdate(
        const Duration(milliseconds: 32),
        state,
        player,
      );
    }

    test('a short gap stays on the normal per-frame path', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = true;
      goOffline(player, ActionTimingService.offlineThreshold.inSeconds - 1);

      expect(tick(state, player), isFalse);

      expect(fired, isEmpty);
      // the frame path refreshes the timestamp rather than settling a gap
      expect(
        DateTime.now().difference(player.lastActionTime).inSeconds,
        lessThan(1),
      );
    });

    test('a gap past the threshold is handed back to be settled', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = true;
      final gapStart = player.lastActionTime;
      goOffline(player, 60);

      expect(tick(state, player), isTrue);

      // the frame does none of the settling itself, and leaves the window
      // open for whoever does
      expect(fired, isEmpty);
      expect(player.lastActionTime, isNot(gapStart));
      expect(
        DateTime.now().difference(player.lastActionTime).inSeconds,
        greaterThanOrEqualTo(60),
      );
    });

    // the first frame of a resumed run reports a dt of zero, which is not a
    // frame the offline check can act on. it must not stamp the timestamp
    // either, or the gap is gone before the frame that could settle it
    test('the first frame of a run leaves the gap for the next one', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = true;
      goOffline(player, 60);
      final gapStart = player.lastActionTime;

      // a fresh ticker starts its elapsed clock at zero
      state.lastElapsed = Duration.zero;
      expect(
        system.frameUpdate(const Duration(milliseconds: 16), state, player),
        isFalse,
      );

      expect(fired, isEmpty);
      expect(player.lastActionTime, gapStart);

      // the next frame carries a real dt, and hands the whole 60s on
      expect(
        system.frameUpdate(const Duration(milliseconds: 32), state, player),
        isTrue,
      );
    });

    test('a gap while the loop is stopped settles nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = false;
      goOffline(player, 60);

      expect(tick(state, player), isFalse);

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
      timing.bindOnFireFunction(
        (count, {bool offline = false, DateTime? at}) => fired.add(count),
      );

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
