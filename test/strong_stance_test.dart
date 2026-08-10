import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
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

  test('strong stance boosts mining and woodcutting, not strength', () {
    final player = newPlayer();
    setLevel(player, SkillId.STRENGTH, 10);
    setLevel(player, SkillId.MINING, 20);
    setLevel(player, SkillId.WOODCUTTING, 20);
    player.stamina = 100;
    playerDataService.setStance(Stance.strong, player);

    // the stance alone already pays: +1% per point of strength, so 20
    // mining at 10 strength reads 22 before any boost is held
    final baseline = playerDataService.getStatTotals(player);
    expect(baseline[SkillId.MINING], 22);

    final state = ActionTimingData();
    state.buttonHeld = true;
    run(state, player, seconds: 5); // hold to the ceiling

    expect(player.boostMultiplier, greaterThan(1.0));

    // the held boost stacks on top of what the stance already gave
    final boosted = playerDataService.getStatTotals(player);
    expect(boosted[SkillId.MINING], greaterThan(baseline[SkillId.MINING]!));
    expect(
      boosted[SkillId.WOODCUTTING],
      greaterThan(baseline[SkillId.WOODCUTTING]!),
    );
    // strength itself stays raw, so the ceiling can't feed back into itself
    expect(boosted[SkillId.STRENGTH], 10);
    expect(state.maxBoostMultiplier, closeTo(1.0 + 0.1 * 10, 0.001));
  });

  test('fast stance leaves the gathering stats alone', () {
    final player = newPlayer();
    setLevel(player, SkillId.STRENGTH, 10);
    setLevel(player, SkillId.MINING, 20);
    player.stamina = 100;
    playerDataService.setStance(Stance.fast, player);

    final state = ActionTimingData();
    state.buttonHeld = true;
    run(state, player, seconds: 5);

    final boosted = playerDataService.getStatTotals(player);
    expect(boosted[SkillId.MINING], 20);
  });

  // only the fast stance runs on speed; the combat stances spend strength,
  // the same as strong does
  for (final stance in [Stance.offensive, Stance.defensive]) {
    test('${stance.name} stance runs the boost on strength', () {
      final player = newPlayer();
      setLevel(player, SkillId.STRENGTH, 10);
      setLevel(player, SkillId.SPEED, 50);
      player.stamina = 100;
      playerDataService.setStance(stance, player);

      final speedBefore = playerDataService.getSkillXp(SkillId.SPEED, player);
      final strengthBefore = playerDataService.getSkillXp(
        SkillId.STRENGTH,
        player,
      );

      final state = ActionTimingData();
      state.buttonHeld = true;
      run(state, player, seconds: 2);

      // the ceiling comes from strength, not the far higher speed stat
      expect(state.boostingSpeed, isFalse);
      expect(state.maxBoostMultiplier, closeTo(1.0 + 0.1 * 10, 0.001));

      // and the boost xp lands on strength, leaving speed untouched
      expect(
        playerDataService.getSkillXp(SkillId.STRENGTH, player),
        greaterThan(strengthBefore),
      );
      expect(playerDataService.getSkillXp(SkillId.SPEED, player), speedBefore);
    });
  }

  test('fast stance runs the boost on speed', () {
    final player = newPlayer();
    setLevel(player, SkillId.STRENGTH, 50);
    setLevel(player, SkillId.SPEED, 10);
    player.stamina = 100;
    playerDataService.setStance(Stance.fast, player);

    final speedBefore = playerDataService.getSkillXp(SkillId.SPEED, player);
    final strengthBefore = playerDataService.getSkillXp(
      SkillId.STRENGTH,
      player,
    );

    final state = ActionTimingData();
    state.buttonHeld = true;
    run(state, player, seconds: 2);

    expect(state.boostingSpeed, isTrue);
    expect(state.maxBoostMultiplier, closeTo(1.0 + 0.05 * 10, 0.001));

    expect(
      playerDataService.getSkillXp(SkillId.SPEED, player),
      greaterThan(speedBefore),
    );
    expect(
      playerDataService.getSkillXp(SkillId.STRENGTH, player),
      strengthBefore,
    );
  });
}
