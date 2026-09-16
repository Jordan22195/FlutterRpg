import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/buff_service.dart';
import 'package:rpg/data/offline_progress_data.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/offline_progress_service.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/services/skill_service.dart';
import 'package:rpg/systems/offline_progress_system.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/systems/potion_system.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PlayerDataService playerDataService;
  late ActionTimingSystem system;
  late OfflineProgressData offlineProgressData;

  setUp(() {
    playerDataService = PlayerDataService(
      buffService: BuffService(),
      equpmentService: EquipmentService(),
      skillService: SkillService(),
    );
    offlineProgressData = OfflineProgressData();
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

  test('the speed stat sets the boost ceiling', () {
    // the ceiling is 1 + speedStatBonus, and the curve behind that bonus is
    // a balance number — it has been linear and is a root now. What is
    // pinned is that the ceiling is that curve, and the shape it has to
    // keep: every point pays, and no point pays as much as the one before.
    final player = newPlayer();
    setLevel(player, SkillId.SPEED, 20);

    final state = ActionTimingData();
    run(state, player, seconds: 0.1);

    expect(state.maxBoostMultiplier, closeTo(1 + speedStatBonus(20), 0.001));

    // a boost ceiling below 1 would be a penalty for having the stat
    expect(state.maxBoostMultiplier, greaterThan(1.0));

    // rising, and with diminishing returns, all the way up the ladder
    final service = ActionTimingService();
    var previous = service.maxSpeedBoostForStat(1);
    var previousStep = double.infinity;
    for (var level = 2; level <= 99; level++) {
      final ceiling = service.maxSpeedBoostForStat(level);
      final step = ceiling - previous;
      expect(step, greaterThan(0), reason: 'speed $level bought nothing');
      expect(
        step,
        lessThanOrEqualTo(previousStep + 1e-9),
        reason: 'speed $level pays more than the point below it',
      );
      previous = ceiling;
      previousStep = step;
    }
  });

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
    setLevel(player, SkillId.SPEED, 20);
    // a pool deep enough to hold a boost up for the window: at 20 speed
    // against 1 stamina the burst would be over in under two seconds
    setLevel(player, SkillId.STAMINA, 20);
    player.stamina = playerDataService.getMaxStamina(player);

    final state = ActionTimingData();
    state.percentOfMaxBoost = 1.0;
    state.boostLocked = true;
    state.buttonHeld = false;
    run(state, player, seconds: 2);

    // recovery is nowhere near the drain
    expect(player.stamina, lessThan(playerDataService.getMaxStamina(player)));
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

    final timingService = ActionTimingService();
    final offlineProgressService = OfflineProgressService(InventoryService());
    final timing = ActionTimingController(
      vsync: const TestVSync(),
      actionTimingService: timingService,
      playerState: player,
      actionSpeedSystem: system,
      offlineProgressSystem: OfflineProgressSystem(
        actionTimingService: timingService,
        actionTimingSystem: system,
        playerDataService: playerDataService,
        skillService: SkillService(),
        buffService: BuffService(),
        offlineProgressService: offlineProgressService,
        offlineProgressData: offlineProgressData,
        potionSystem: PotionSystem(
          buffService: BuffService(),
          inventoryService: InventoryService(),
        ),
        inventoryData: InventoryData(itemMap: {}),
      ),
      actionTimingState: ActionTimingData(),
      offlineProgressData: offlineProgressData,
      offlineProgressService: offlineProgressService,
    );
    final controller = PlayerDataController(
      playerData: player,
      playerDataService: playerDataService,
      actionTimingController: timing,
    );

    // idle: one tick restores one second of recovery. The rate itself is a
    // balance number, so read it off the service rather than restating it —
    // the claim here is "one tick is worth one second", not what a second is.
    final perSecond = playerDataService.staminaRecoveryPerSecond(player);
    controller.tickAmbientRecovery();
    expect(player.stamina, closeTo(2 + perSecond, 0.001));
    expect(player.skillData[SkillId.RECOVERY]!.xp, greaterThan(0));

    // while the loop runs, the ambient tick stands down (the frame loop
    // applies recovery itself)
    timing.bindOnFireFunction((_, {offline = false, at, span}) {});
    timing.start();
    final before = player.stamina;
    controller.tickAmbientRecovery();
    expect(player.stamina, before);
    timing.stop();

    controller.dispose();
    timing.dispose();
  });

  test('a held boost drains without recovering, however gentle it is', () {
    // drain and recovery are exclusive, not netted: the frame loop recovers
    // only while the button is up and the lock is off. So no boost is
    // sustainable — even one far under the recovery rate costs stamina for
    // as long as it is held, and letting go is what buys it back.
    final player = newPlayer();
    setLevel(player, SkillId.RECOVERY, 20);
    setLevel(player, SkillId.SPEED, 10);
    player.stamina = 50;

    final service = ActionTimingService();
    final recovery = playerDataService.staminaRecoveryPerSecond(player);
    final state = ActionTimingData();
    state.boostLocked = true;
    state.percentOfMaxBoost = 0.5;
    run(state, player, seconds: 0.1);

    // the boost this hold is worth, and what the service charges for it
    final drain = service.boostDrain(
      service.getCurrentSpeedMultiplier(state),
      speedStance: true,
    );
    expect(drain, greaterThan(0));
    expect(
      drain,
      lessThan(recovery),
      reason: 'pick a gentler boost: this one out-drains recovery anyway, '
          'which is not the case under test',
    );

    final before = player.stamina;
    run(state, player, seconds: 5);

    // even though recovery alone would more than cover it
    expect(player.stamina, lessThan(before));
    expect(state.percentOfMaxBoost, closeTo(0.5, 0.001)); // lock held
    expect(state.boostLocked, isTrue); // and nowhere near empty

    // release, and recovery comes back
    state.boostLocked = false;
    state.buttonHeld = false;
    final atRelease = player.stamina;
    run(state, player, seconds: 5);
    expect(player.stamina, greaterThan(atRelease));
  });

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

    test('the fast stance divides the interval by the speed curve', () {
      Duration at(int speedStat) => service.maxIntervalFor(
        equippedInterval: const Duration(milliseconds: 2000),
        speedStance: true,
        speedStat: speedStat,
      );

      // 25 speed is a quarter off: 2000 / (1 + 0.05*sqrt(25))
      expect(at(25).inMilliseconds, 1600);
      // and it keeps paying at the top of the range rather than flattening
      expect(at(99).inMilliseconds, closeTo(2000 / 1.4975, 1));
      expect(at(99), lessThan(at(50)));
      expect(at(50), lessThan(at(25)));
    });

    test('the curve never reaches zero, so there is no floor to hit', () {
      // the old formula subtracted a percent a point and had to be floored
      // at 85% off, where every further point was worth nothing. dividing
      // approaches zero without arriving, so absurd stats stay finite and
      // still improve.
      final absurd = service.maxIntervalFor(
        equippedInterval: const Duration(seconds: 2),
        speedStance: true,
        speedStat: 10000,
      );
      final moreAbsurd = service.maxIntervalFor(
        equippedInterval: const Duration(seconds: 2),
        speedStance: true,
        speedStat: 40000,
      );

      expect(absurd.inMicroseconds, greaterThan(0));
      expect(moreAbsurd, lessThan(absurd));
    });

    test('the equipped tool drives the interval of the bound action', () {
      final player = newPlayer();
      final equipment = EquipmentService();

      // bare-handed: the default
      expect(
        equipment.actionIntervalFor(SkillId.WOODCUTTING, player.equipmentData),
        isNull,
      );

      final axe = ItemId.STONE_AXE.build() as EquipmentItem;
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
      final dagger = ItemId.COPPER_DAGGER.build() as EquipmentItem;
      player.equipmentData.armorEquipment[dagger.armorSlot] = dagger;
      expect(
        equipment.actionIntervalFor(SkillId.ATTACK, player.equipmentData),
        (dagger as WeaponItem).actionInterval,
      );
    });
  });

  // Stamina is a burst you spend rather than a mode you leave on: drain
  // goes as the square of the boost, which cancels against a pool that
  // grows linearly with the stamina stat. What is left is a build ratio.
  group('the cost of a boost', () {
    // holds a full locked boost until the pool runs dry, and reports how
    // long that took. running out is what breaks the lock - stamina itself
    // starts climbing again the moment it does, so the lock is the signal
    double burstSeconds(PlayerData player, {double limit = 300}) {
      final state = ActionTimingData();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;

      var elapsed = 0.0;
      const step = 0.25;
      while (elapsed < limit) {
        run(state, player, seconds: step);
        elapsed += step;
        if (!state.boostLocked) return elapsed;
      }
      return limit;
    }

    PlayerData built({required int stamina, required int speed}) {
      final player = newPlayer();
      setLevel(player, SkillId.STAMINA, stamina);
      setLevel(player, SkillId.SPEED, speed);
      player.stamina = playerDataService.getMaxStamina(player);
      return player;
    }

    test('a full bar is about thirty seconds at any level', () {
      // the pool grows with the stamina stat and the drain grows with the
      // boost it funds, so the two cancel: level does not change the burst
      expect(burstSeconds(built(stamina: 5, speed: 5)), closeTo(30, 6));
      expect(burstSeconds(built(stamina: 95, speed: 95)), closeTo(30, 6));
    });

    test('the burst is a build ratio, not a level', () {
      final even = burstSeconds(built(stamina: 20, speed: 20));
      final stamina = burstSeconds(built(stamina: 40, speed: 20));
      final speed = burstSeconds(built(stamina: 20, speed: 40));

      // twice the stamina is twice the burst; twice the speed instead is
      // half of it, for a stronger boost while it lasts
      expect(stamina, closeTo(even * 2, even * 0.35));
      expect(speed, closeTo(even / 2, even * 0.35));
    });

    test('easing off is disproportionately cheap', () {
      final service = ActionTimingService();
      final full = service.boostDrain(1.4, speedStance: true);
      final half = service.boostDrain(1.2, speedStance: true);

      // half the boost costs a quarter of the drain - the square is what
      // makes full tilt a decision rather than a default
      expect(half, closeTo(full / 4, 1e-9));
      expect(service.boostDrain(1.0, speedStance: true), 0);
    });

    test('a strength stance pays by the action, not by the second', () {
      final service = ActionTimingService();
      // the same multiplier costs differently because the currencies
      // differ: speed buys seconds, strength buys swings
      expect(
        service.boostDrain(1.5, speedStance: false),
        closeTo(ActionTimingService.strengthDrainPerAction * 0.25, 1e-9),
      );
      expect(
        service.boostDrain(1.5, speedStance: true),
        closeTo(ActionTimingService.speedDrainPerSecond * 0.25, 1e-9),
      );

      // and holding one without the action ever firing costs nothing: the
      // frame loop charges a strength boost when the swing lands
      final player = newPlayer();
      setLevel(player, SkillId.STRENGTH, 20);
      setLevel(player, SkillId.STAMINA, 20);
      player.currentEntityViewId = EntityId.COPPER;
      playerDataService.setStance(Stance.strong, player);
      player.stamina = playerDataService.getMaxStamina(player);
      final before = player.stamina;

      final state = ActionTimingData();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      // an interval far longer than the window, so no action ever fires
      state.maxInterval = const Duration(minutes: 10);
      run(state, player, seconds: 2);

      expect(player.stamina, before);
    });
  });
}
