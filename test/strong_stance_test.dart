import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';

import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/catalogs/entities/entities.dart';
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

  test('strong stance boosts what the open entity is worked with', () {
    final player = newPlayer();
    setLevel(player, SkillId.STRENGTH, 10);
    setLevel(player, SkillId.MINING, 20);
    setLevel(player, SkillId.WOODCUTTING, 20);
    // enough stamina to hold the boost for the whole run
    setLevel(player, SkillId.STAMINA, 20);
    player.stamina = 200;
    // the stance is resolved against whatever is open: a copper rock is
    // mined, so mining is what strength lends itself to here
    player.currentEntityViewId = EntityId.COPPER;
    playerDataService.setStance(Stance.strong, player);

    // the stance alone already pays the idle curve, so 20 mining at 10
    // strength reads 20 plus those points before any boost
    final baseline = playerDataService.getStatTotals(player);
    expect(baseline[SkillId.MINING], 20 + strengthIdleBonus(10).round());
    // and only that one stat - woodcutting isn't what is being worked
    expect(baseline[SkillId.WOODCUTTING], 20);

    final state = ActionTimingData();
    state.buttonHeld = true;
    run(state, player, seconds: 5); // hold to the ceiling

    expect(player.boostFill, greaterThan(0.0));

    // the held boost climbs from the idle curve toward the max one
    final boosted = playerDataService.getStatTotals(player);
    expect(boosted[SkillId.MINING], greaterThan(baseline[SkillId.MINING]!));
    expect(boosted[SkillId.WOODCUTTING], 20);
    // strength itself stays raw, so the ceiling can't feed back into itself
    expect(boosted[SkillId.STRENGTH], 10);
    expect(state.maxBoostMultiplier, closeTo(1 + boostStatBonus(10), 1e-9));
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
      expect(state.maxBoostMultiplier, closeTo(1 + boostStatBonus(10), 1e-9));

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
    expect(state.maxBoostMultiplier, closeTo(1 + speedStatBonus(10), 1e-9));

    expect(
      playerDataService.getSkillXp(SkillId.SPEED, player),
      greaterThan(speedBefore),
    );
    expect(
      playerDataService.getSkillXp(SkillId.STRENGTH, player),
      strengthBefore,
    );
  });

  // an activity with no stance to pick must not leave a combat stance
  // running in the background: it would boost the wrong skill and hold the
  // action at its unreduced interval, with no picker on screen to fix it
  group('stances follow the activity', () {
    GameSession buildSession() {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      return factory.create(
        save: factory.newGame(catalogs),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
    }

    test('starting a craft drops a stance carried in from a fight', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 50;
      session.playerDataService.setStance(Stance.offensive, save.playerData);

      expect(
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      // bench work offers no stance, so it runs fast
      expect(save.playerData.stance, Stance.fast);
      expect(save.playerData.skillBoost, SkillId.SPEED);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('a node coerces a stance it does not offer', () {
      final session = buildSession();
      final save = session.saveGameData;
      // a fishing spot offers nothing to choose between
      final pond = EntityId.TRANQUIL_POND.build() as EncounterEntity;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(pond);
      session.playerDataService.setStance(Stance.offensive, save.playerData);

      expect(session.encounterController.startEncounterActionFor(pond), isTrue);

      expect(save.playerData.stance, Stance.fast);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('a tree keeps the strong stance, a chicken keeps a combat one', () {
      final session = buildSession();
      final save = session.saveGameData;

      final tree = EntityId.TREE.build() as EncounterEntity;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(tree);
      session.playerDataService.setStance(Stance.strong, save.playerData);
      expect(session.encounterController.startEncounterActionFor(tree), isTrue);
      // woodcutting trades power for pace, so strong is on the menu
      expect(save.playerData.stance, Stance.strong);
      expect(save.playerData.skillBoost, isNot(SkillId.SPEED));

      final chicken = EntityId.CHICKEN.build() as EncounterEntity;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(chicken);
      session.playerDataService.setStance(Stance.defensive, save.playerData);
      expect(
        session.encounterController.startEncounterActionFor(chicken),
        isTrue,
      );
      expect(save.playerData.stance, Stance.defensive);

      session.actionTimingController.stop();
      session.dispose();
    });
  });

  // Both boost stats run on one curve: a root rather than a line, so a
  // hundred points is worth about triple rather than eleven times, with an
  // idle share that is always on and a boost bar that buys the rest.
  group('the boost curve', () {
    // the stat a strength stance is spent on, at a given boost multiplier
    // gear stats live on the item's definition, so the fixture wears a real
    // pickaxe and reads what it is worth rather than writing a number onto
    // the instance
    final pickaxeMining =
        (ItemId.COPPER_PICKAXE.definition as EquipmentItemDefinition).statsAt(
          Rarity.COMMON,
        )[SkillId.MINING]!;

    int minedAt(
      double fill, {
      int strength = 10,
      bool geared = false,
      int mining = 20,
    }) {
      final player = newPlayer();
      setLevel(player, SkillId.STRENGTH, strength);
      setLevel(player, SkillId.MINING, mining);
      player.currentEntityViewId = EntityId.COPPER;
      playerDataService.setStance(Stance.strong, player);
      playerDataService.setBoostFill(fill, player);
      if (geared) {
        final pickaxe = ItemId.COPPER_PICKAXE.build() as EquipmentItem;
        player.equipmentData.equipedTools[SkillId.MINING] = pickaxe;
      }
      return playerDataService.getStatTotals(player)[SkillId.MINING]!;
    }

    test('standing still is worth the idle curve', () {
      for (final strength in [10, 99]) {
        final expected = 20 + strengthIdleBonus(strength).round();
        expect(minedAt(0.0, strength: strength), expected, reason: '$strength');
      }
    });

    test('a full bar is worth the max curve, and half a bar half of it', () {
      final full = minedAt(1.0);
      final half = minedAt(0.5);
      final idle = minedAt(0.0);

      expect(full, 20 + strengthMaxBonus(10).round());
      // composed, not competing: the first stretch of the bar pays from the
      // moment it leaves zero, where the old max() left it dead until it
      // beat standing still
      expect(half, greaterThan(idle));
      expect(half, lessThan(full));
      expect(half, closeTo((idle + full) / 2, 1));
    });

    test('gear is added flat, not multiplied', () {
      // the same skill with and without the pickaxe differs by exactly what
      // the pickaxe is worth, at rest and at full tilt alike - multiplying
      // the geared total was where most of the old overpowering lived
      expect(minedAt(0.0, geared: true) - minedAt(0.0), pickaxeMining);
      expect(minedAt(1.0, geared: true) - minedAt(1.0), pickaxeMining);
    });

    test('the boost is added, not multiplied', () {
      // the whole point of the additive curve: a stance is worth the same
      // number of points whether it lands on mining 20 or mining 60, where
      // the old multiplier paid three times as much on the higher skill
      for (final fill in [0.0, 0.5, 1.0]) {
        expect(
          minedAt(fill, mining: 60) - 60,
          minedAt(fill, mining: 20) - 20,
          reason: 'fill $fill',
        );
      }
    });

    test('the curve exponents are what they are tuned to', () {
      // 16 is picked because both exponents land on a whole number there,
      // so a drifting exponent cannot hide inside the rounding
      expect(strengthIdleBonus(16), closeTo(8, 1e-9)); // 16 ^ 0.75
      expect(strengthMaxBonus(16), closeTo(17, 1e-9)); // 16 ^ 1 + 1
      // no strength at all still buys a point at a full bar, and nothing
      // standing still
      expect(strengthIdleBonus(0), 0);
      expect(strengthMaxBonus(0), kStrengthMaxOffset);
      // and a negative stat is floored rather than returning a NaN
      expect(strengthIdleBonus(-5), 0);
    });

    test('both ceilings are the curve, so nothing can drift', () {
      final service = ActionTimingService();
      for (final stat in [1, 10, 50, 99]) {
        expect(
          service.maxStrengthBoostForStat(stat),
          closeTo(1 + boostStatBonus(stat), 1e-9),
        );
        expect(
          service.maxSpeedBoostForStat(stat),
          closeTo(1 + speedStatBonus(stat), 1e-9),
        );
      }
      // a hundred points is worth about double, not eleven times. The
      // coefficient was halved in "ui and balance tweaks" (7cbb76b); this
      // guard exists to catch the curve drifting again, so it is deliberately
      // a magnitude the root has to be retuned to break.
      expect(service.maxStrengthBoostForStat(99), closeTo(2.0, 0.05));
    });

    test('speed divides the interval and keeps paying past the old floor', () {
      final service = ActionTimingService();
      Duration at(int speed) => service.maxIntervalFor(
        equippedInterval: const Duration(seconds: 3),
        speedStance: true,
        speedStat: speed,
      );

      expect(
        at(25).inMicroseconds,
        closeTo(3000000 / (1 + speedIdleBonus(25)), 1000),
      );
      // the old formula floored at 85% off, so 85 and 500 were identical
      expect(at(500), lessThan(at(85)));
      expect(at(85), lessThan(at(50)));
    });
  });
}
