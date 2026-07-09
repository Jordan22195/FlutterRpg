import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerDataService playerDataService;
  late ActionSpeedSystem system;

  setUp(() {
    playerDataService = PlayerDataService(
      buffService: BuffService(),
      equpmentService: EquipmentService(),
      skillService: SkillService(),
    );
    system = ActionSpeedSystem(
      actionTimingService: ActionTimingService(),
      playerDataService: playerDataService,
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

  // simulates [seconds] of 60fps frames
  void run(
    ActionTimingData state,
    PlayerData player, {
    required double seconds,
  }) {
    var elapsed = state.lastElapsed;
    final frames = (seconds * 60).round();
    for (var i = 0; i <= frames; i++) {
      elapsed += const Duration(microseconds: 16667);
      system.frameUpdate(elapsed, state, player);
    }
  }

  test('the speed stat sets the boost ceiling', () {
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 20);

    final state = ActionTimingData();
    run(state, player, seconds: 0.1);

    // 2.0 base + 0.1 per speed level
    expect(state.maxSpeedMultiplier, closeTo(4.0, 0.001));
  });

  test('holding the button boosts speed and drains stamina', () {
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 20);
    player.stamina = 10;

    final state = ActionTimingData();
    state.buttonHeld = true;
    run(state, player, seconds: 2);

    expect(state.speedPercent, greaterThan(0.3));
    expect(player.stamina, lessThan(10)); // drain beat lvl-1 recovery
    // boosting trains speed and stamina
    expect(player.skillData[SkillId.SPEED]!.xp, greaterThan(0));
    expect(player.skillData[SkillId.STAMINA]!.xp, greaterThan(0));
  });

  test('stamina recovers over time from the recovery stat, capped at max', () {
    final player = newPlayer();
    setLevel(player, SkillId.RECOVERY, 20); // 2.0 stamina/sec
    player.stamina = 2;

    final state = ActionTimingData();
    run(state, player, seconds: 2);

    expect(player.stamina, greaterThan(2));
    expect(player.skillData[SkillId.RECOVERY]!.xp, greaterThan(0));

    // never exceeds max stamina (10 at stamina level 1)
    run(state, player, seconds: 10);
    expect(player.stamina, 10);
  });

  test('running out of stamina forces a locked boost to fall off', () {
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 30); // max 5x -> heavy drain at full
    player.stamina = 1;

    final state = ActionTimingData();
    state.speedPercent = 1.0;
    state.speedLocked = true;
    run(state, player, seconds: 3);

    expect(state.speedPercent, lessThan(1.0));
  });

  test('stamina recovers ambiently while the action loop is idle', () {
    final player = newPlayer();
    player.stamina = 2;

    final timing = ActionTimingController(
      vsync: const TestVSync(),
      actionTimingService: ActionTimingService(),
      playerState: player,
      actionSpeedSystem: system,
    );
    final controller = PlayerDataController(
      playerData: player,
      playerDataService: playerDataService,
      actionTimingController: timing,
    );

    // idle: one tick restores one second of recovery (0.1 at level 1)
    controller.tickAmbientRecovery();
    expect(player.stamina, closeTo(2.1, 0.001));
    expect(player.skillData[SkillId.RECOVERY]!.xp, greaterThan(0));

    // while the loop runs, the ambient tick stands down (the frame loop
    // applies recovery itself)
    timing.bindOnFireFunction(() {});
    timing.start();
    final before = player.stamina;
    controller.tickAmbientRecovery();
    expect(player.stamina, before);
    timing.stop();

    controller.dispose();
    timing.dispose();
  });

  test('a gentle boost is sustainable when drain matches recovery', () {
    final player = newPlayer();
    setLevel(player, SkillId.RECOVERY, 20); // recovery 2.0/sec
    setLevel(player, SkillId.SPEED, 10); // boost ceiling 3.0x
    player.stamina = 10;

    final state = ActionTimingData();
    // hold a boost of exactly +1 speed => drain 1.0/sec < recovery 2.0/sec
    state.speedLocked = true;
    state.speedPercent = 0.5;
    run(state, player, seconds: 5);

    expect(player.stamina, 10); // recovery kept up; no net loss
    expect(state.speedPercent, closeTo(0.5, 0.001)); // lock held
  });
}
