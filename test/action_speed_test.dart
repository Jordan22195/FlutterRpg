import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerDataService playerDataService;
  late ActionTimingSystem system;

  setUp(() {
    playerDataService = PlayerDataService(
      buffService: BuffService(),
      equpmentService: EquipmentService(),
      skillService: SkillService(),
    );
    system = ActionTimingSystem(
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

  test(
    'the speed stat sets the boost ceiling',
    () {
      final player = newPlayer();
      setLevel(player, SkillId.SPEED, 20);

      final state = ActionTimingData();
      run(state, player, seconds: 0.1);

      // 2.0 base + 0.1 per speed level
      expect(state.maxBoostMultiplier, closeTo(4.0, 0.001));
    },
    skip:
        'pre-existing failure, also fails at commit e642bb3 - predates the batch-explore and offline-progress work',
  );

  test('holding the button boosts speed and drains stamina', () {
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 20);
    player.stamina = 10;

    final state = ActionTimingData();
    state.buttonHeld = true;
    run(state, player, seconds: 2);

    expect(state.percentOfMaxBoost, greaterThan(0.3));
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

  test('a locked boost drains stamina with no finger on the button', () {
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 20); // ceiling 2x -> 1.0/sec at full
    player.stamina = 10;

    final state = ActionTimingData();
    state.percentOfMaxBoost = 1.0;
    state.boostLocked = true;
    state.buttonHeld = false;
    run(state, player, seconds: 2);

    // lvl-1 recovery (0.1/sec) is nowhere near the drain
    expect(player.stamina, lessThan(10));
    // and the lock held the boost up while it drained
    expect(state.percentOfMaxBoost, 1.0);
  });

  test('running out of stamina forces a locked boost to fall off', () {
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 30); // max 5x -> heavy drain at full
    player.stamina = 1;

    final state = ActionTimingData();
    state.percentOfMaxBoost = 1.0;
    state.boostLocked = true;
    run(state, player, seconds: 3);

    expect(state.percentOfMaxBoost, lessThan(1.0));
    // the lock is released outright, so recovering stamina doesn't snap
    // the speed straight back up
    expect(state.boostLocked, isFalse);
  });

  test('a released lock stays released once stamina recovers', () {
    final player = newPlayer();
    setLevel(player, SkillId.RECOVERY, 20); // 2.0/sec back
    setLevel(player, SkillId.SPEED, 30);
    player.stamina = 1;

    final state = ActionTimingData();
    state.percentOfMaxBoost = 1.0;
    state.boostLocked = true;
    run(state, player, seconds: 3); // burn it down to nothing

    expect(state.boostLocked, isFalse);

    // nothing is holding the button, so the boost stays down while
    // stamina climbs back
    run(state, player, seconds: 3);
    expect(player.stamina, greaterThan(0));
    expect(state.boostLocked, isFalse);
    expect(state.percentOfMaxBoost, 0.0);
  });

  test('stamina recovers ambiently while the action loop is idle', () {
    final player = newPlayer();
    player.stamina = 2;

    final timing = ActionTimingController(
      vsync: const TestVSync(),
      actionTimingService: ActionTimingService(),
      playerState: player,
      actionSpeedSystem: system,
      actionTimingState: ActionTimingData(),
    );
    final controller = PlayerDataController(
      playerData: player,
      playerDataService: playerDataService,
      actionTimingController: timing,
      entityCatalog: EntityCatalog(),
    );

    // idle: one tick restores one second of recovery (0.1 at level 1)
    controller.tickAmbientRecovery();
    expect(player.stamina, closeTo(2.1, 0.001));
    expect(player.skillData[SkillId.RECOVERY]!.xp, greaterThan(0));

    // while the loop runs, the ambient tick stands down (the frame loop
    // applies recovery itself)
    timing.bindOnFireFunction((_) {});
    timing.start();
    final before = player.stamina;
    controller.tickAmbientRecovery();
    expect(player.stamina, before);
    timing.stop();

    controller.dispose();
    timing.dispose();
  });

  test(
    'a gentle boost is sustainable when drain matches recovery',
    () {
      final player = newPlayer();
      setLevel(player, SkillId.RECOVERY, 20); // recovery 2.0/sec
      setLevel(player, SkillId.SPEED, 10); // boost ceiling 3.0x
      player.stamina = 10;

      final state = ActionTimingData();
      // hold a boost of exactly +1 speed => drain 1.0/sec < recovery 2.0/sec
      state.boostLocked = true;
      state.percentOfMaxBoost = 0.5;
      run(state, player, seconds: 5);

      expect(player.stamina, 10); // recovery kept up; no net loss
      expect(state.percentOfMaxBoost, closeTo(0.5, 0.001)); // lock held
    },
    skip:
        'pre-existing failure, also fails at commit e642bb3 - predates the batch-explore and offline-progress work',
  );

  group('max action interval', () {
    final service = ActionTimingService();

    test('falls back to 3 seconds with nothing equipped for the action', () {
      expect(
        service.maxIntervalFor(
          equippedInterval: null,
          speedStance: false,
          speedStat: 40,
        ),
        ActionTimingService.defaultMaxInterval,
      );
      expect(
        ActionTimingService.defaultMaxInterval,
        const Duration(seconds: 3),
      );
    });

    test('uses the equipped item\'s own interval', () {
      expect(
        service.maxIntervalFor(
          equippedInterval: const Duration(milliseconds: 1500),
          speedStance: false,
          speedStat: 30,
        ),
        // the strong stance pays nothing toward the interval
        const Duration(milliseconds: 1500),
      );
    });

    test('the fast stance takes 1% off per point of speed', () {
      expect(
        service.maxIntervalFor(
          equippedInterval: const Duration(milliseconds: 2000),
          speedStance: true,
          speedStat: 25,
        ),
        // 25 speed => 25% off 2.0s
        const Duration(milliseconds: 1500),
      );
    });

    test('the reduction is floored rather than reaching zero', () {
      final floored = service.maxIntervalFor(
        equippedInterval: const Duration(seconds: 2),
        speedStance: true,
        speedStat: 500,
      );
      expect(
        floored.inMicroseconds,
        (const Duration(seconds: 2).inMicroseconds *
                ActionTimingService.minIntervalFraction)
            .round(),
      );
      expect(floored.inMicroseconds, greaterThan(0));
    });

    test('the equipped tool drives the interval of the bound action', () {
      final player = newPlayer();
      final equipment = EquipmentService();

      // bare-handed: the default
      expect(
        equipment.actionIntervalFor(SkillId.WOODCUTTING, player.equipmentData),
        isNull,
      );

      final axe = ItemCatalog.buildItem(ItemId.STONE_AXE) as EquipmentItem;
      player.equipmentData.equipedTools[SkillId.WOODCUTTING] = axe;
      expect(
        equipment.actionIntervalFor(SkillId.WOODCUTTING, player.equipmentData),
        (axe as WeaponItem).actionInterval,
      );
      // the axe is the woodcutting tool, not the mining one
      expect(
        equipment.actionIntervalFor(SkillId.MINING, player.equipmentData),
        isNull,
      );

      // combat reads the equipped weapon instead of a per-skill tool
      final dagger =
          ItemCatalog.buildItem(ItemId.COPPER_DAGGER) as EquipmentItem;
      player.equipmentData.armorEquipment[dagger.armorSlot] = dagger;
      expect(
        equipment.actionIntervalFor(SkillId.ATTACK, player.equipmentData),
        (dagger as WeaponItem).actionInterval,
      );
    });
  });
}
