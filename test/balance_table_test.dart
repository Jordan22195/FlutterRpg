import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/combat_tuning.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/encounter_service.dart';
import 'support/gathering_tools.dart';

// The balance the weapon rework is for, read off the game's own pipeline:
// the equipped weapon's damage, the stance's hit multiplier and the boosted
// interval the timing system quotes. A weapon's damage scales with its
// swing, so the three shapes of a metal start even; each then wins in the
// stance that suits it — a dagger with speed, a greatsword with strength —
// and a sword sits between. Prints the table it checks.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // the shape a weapon is, and what each tier is made of
  const shapes = ['DAGGER', 'SWORD', 'GREATSWORD'];
  // (label, every stat, the metal it fights in, the monster level faced)
  const tiers = [
    (name: 'early', stat: 10, metal: 'COPPER', level: 10),
    (name: 'mid', stat: 40, metal: 'MITHRIL', level: 40),
    (name: 'late', stat: 90, metal: 'DRAGON', level: 90),
  ];

  // today's best pace, from the live game before the rework: a dagger in
  // the fast stance with an empty bar, at each tier. pinned from the worked
  // numbers in the plan
  const oldDaggerFastIdle = {'early': 3.24, 'mid': 9.38, 'late': 17.81};

  ItemId weapon(String metal, String shape) =>
      ItemId.values.byName('${metal}_$shape');

  GameSession sessionAt(int stat) {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final session = factory.create(
      save: withGatheringTools(factory.newGame(catalogs)),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final skills = session.saveGameData.playerData.skillData;
    for (final skill in [
      SkillId.ATTACK,
      SkillId.STRENGTH,
      SkillId.SPEED,
      SkillId.WOODCUTTING,
    ]) {
      skills[skill]!.xp = skills[skill]!.xpTable[stat];
    }
    return session;
  }

  /// Expected damage (or hitpoints felled) per second for a swing of
  /// [skill] at [defence], in [stance] with the boost bar at [fill].
  double perSecond(
    GameSession session, {
    required SkillId skill,
    required int defence,
    required Stance stance,
    required double fill,
  }) {
    final save = session.saveGameData;
    final player = save.playerData;
    final timing = save.actionTimingData;
    session.playerDataService.setStance(stance, player);

    if (stance == Stance.fast) {
      // what the frame loop sets: the ceiling off speed, of which the
      // equipped shape takes its share
      final speed = session.playerDataService.getStatTotals(
        player,
      )[SkillId.SPEED]!;
      timing
        ..boostingSpeed = true
        ..actionSkill = skill
        ..maxBoostMultiplier = ActionTimingService().maxSpeedBoostForStat(
          speed,
          speedAffinity: session.actionTimingSystem.speedAffinity(
            skill,
            player,
          ),
        )
        ..percentOfMaxBoost = fill;
      session.playerDataService.setBoostFill(0, player);
    } else {
      timing
        ..boostingSpeed = false
        ..actionSkill = skill
        ..percentOfMaxBoost = 0;
      session.playerDataService.setBoostFill(fill, player);
    }

    final stats = session.playerDataService.getStatTotals(player);
    final attack = stats[skill] ?? 0;
    final damage = session.playerDataService.swingDamage(player, skill)!;
    final hit = session.encounterService.chanceToHit(attack, defence);
    final maxHit = session.encounterService.weaponMaxHit(
      damage: damage,
      attack: attack,
      defense: defence,
      // a strength stance swings harder through the multiplier, of which the
      // shape takes its affinity
      multiplier: session.playerDataService.strengthDamageMultiplier(player),
    );
    final seconds =
        session.actionTimingController
            .boostedActionDurationFor(skill)
            .inMicroseconds /
        1e6;
    return hit * (1 + maxHit) / 2 / seconds;
  }

  /// [perSecond] for every shape of a tier's metal, in [stance] at [fill].
  Map<String, double> row(
    ({String name, int stat, String metal, int level}) tier,
    Stance stance,
    double fill,
  ) {
    final defence = CombatType.BALANCE.defenceAt(tier.level);
    return {
      for (final shape in shapes)
        shape: () {
          final session = sessionAt(tier.stat);
          session.equipmentService.equipItem(
            weapon(tier.metal, shape).build() as EquipmentItem,
            session.saveGameData.playerData.equipmentData,
          );
          final value = perSecond(
            session,
            skill: SkillId.ATTACK,
            defence: defence,
            stance: stance,
            fill: fill,
          );
          session.dispose();
          return value;
        }(),
    };
  }

  test('the attack multiplier doubles at 10 and flattens late', () {
    expect(attackMultiplier(10), closeTo(2.0, 1e-9));
    expect(attackMultiplier(1), greaterThan(1.0));
    expect(attackMultiplier(40), closeTo(3.0, 1e-9));
    // the top of the ladder can't run away: the hardest a dragon greatsword
    // can land at 99 attack on an unarmoured target, with no stance boost
    final greatsword =
        ItemId.DRAGON_GREATSWORD.definition as WeaponItemDefinition;
    final ceiling = greatsword.damageAt(Rarity.COMMON) * attackMultiplier(99);
    expect(ceiling, lessThan(150));
  });

  for (final tier in tiers) {
    group('${tier.name}: stats ${tier.stat}, ${tier.metal.toLowerCase()} '
        'vs a level ${tier.level} balanced monster', () {
      late Map<String, double> neutral;
      late Map<String, double> fastIdle;
      late Map<String, double> fastFull;
      late Map<String, double> strongIdle;
      late Map<String, double> strongFull;

      setUpAll(() {
        // the defensive stance lends defence, not rate or hit: the shapes
        // with nothing leaning on them
        neutral = row(tier, Stance.defensive, 0);
        fastIdle = row(tier, Stance.fast, 0);
        fastFull = row(tier, Stance.fast, 1);
        strongIdle = row(tier, Stance.offensive, 0);
        strongFull = row(tier, Stance.offensive, 1);

        String line(String label, Map<String, double> r) =>
            '${label.padRight(14)}'
            '${[for (final s in shapes) r[s]!.toStringAsFixed(2).padLeft(8)].join()}';
        // ignore: avoid_print
        print(
          [
            '\n${tier.name}: dps by ${shapes.join(' / ')}',
            line('neutral', neutral),
            line('fast idle', fastIdle),
            line('fast full', fastFull),
            line('strength idle', strongIdle),
            line('strength full', strongFull),
          ].join('\n'),
        );
      });

      test('with nothing leaning on the swing the three shapes are even', () {
        final values = neutral.values.toList()..sort();
        // whole-number max hits are the only thing between them
        expect(values.last / values.first, lessThan(1.10), reason: '$neutral');
      });

      test('a stance leans toward its shape even with the bar empty', () {
        // the idle share of each boost already favours its weapon, by no
        // more than a quarter
        expect(fastIdle['DAGGER']!, greaterThanOrEqualTo(fastIdle['SWORD']!));
        expect(
          fastIdle['SWORD']!,
          greaterThanOrEqualTo(fastIdle['GREATSWORD']!),
        );
        // early on the strength stance's idle share is smaller than what
        // rounding a max hit of a few points to a whole number moves
        if (tier.name != 'early') {
          expect(
            strongIdle['GREATSWORD']!,
            greaterThanOrEqualTo(strongIdle['DAGGER']!),
          );
        }
        for (final r in [fastIdle, strongIdle]) {
          final values = r.values.toList()..sort();
          expect(values.last / values.first, lessThan(1.25), reason: '$r');
        }
      });

      test('a full speed boost favours the dagger, then the sword', () {
        expect(fastFull['DAGGER']!, greaterThan(fastFull['SWORD']!));
        expect(fastFull['SWORD']!, greaterThan(fastFull['GREATSWORD']!));
      });

      test('a full strength boost favours the greatsword, then the sword', () {
        expect(strongFull['GREATSWORD']!, greaterThan(strongFull['SWORD']!));
        // early on the whole-number max hits blunt the gap to nothing
        expect(
          strongFull['SWORD']!,
          greaterThanOrEqualTo(strongFull['DAGGER']! * 0.99),
        );
      });
    });
  }

  test('a strength stance on a heavy axe is no longer wasted on a tree', () {
    // overflow is off in the game until it returns as a weapon modifier;
    // this keeps the code it runs on honest in the meantime
    EncounterService.nodeOverflowEnabled = true;
    addTearDown(() => EncounterService.nodeOverflowEnabled = false);

    // overflow: past a tree's 5 hitpoints a swing runs on into the next,
    // so a strength boost's bigger hits fell more trees rather than the
    // same one harder
    double treesPerSecond(Stance stance, double fill) {
      final session = sessionAt(60);
      session.saveGameData.playerData.equipmentData.equipedTools[SkillId
              .WOODCUTTING] =
          ItemId.MITHRIL_AXE.build() as EquipmentItem;
      session.saveGameData.playerData.currentEntityViewId = EntityId.TREE;
      final tree = EntityId.TREE.build() as EncounterEntity;
      final perHp = perSecond(
        session,
        skill: SkillId.WOODCUTTING,
        defence: tree.defence,
        stance: stance,
        fill: fill,
      );
      session.dispose();
      return perHp / tree.maxHitPoints;
    }

    final resting = treesPerSecond(Stance.strong, 0);
    final boosted = treesPerSecond(Stance.strong, 1);
    // the boost is worth more than the stat it would have added flat, and
    // on a tree well below a single swing
    expect(boosted, greaterThan(resting * 1.3));
  });
}
