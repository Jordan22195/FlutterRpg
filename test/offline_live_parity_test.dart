import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/enchanting_controller.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/offline_progress_service.dart';
import 'support/live_loop.dart';

/// Every activity, played live and settled offline over the same stretch,
/// and held up against each other.
///
/// [offline_parity_test.dart] checks one offline batch against a hand-rolled
/// loop of single actions. This goes one level up: the live side is the real
/// frame loop - boost bar, stamina drain and recovery, the buff sweep and
/// auto-drink, enemy swings, respawns - and the offline side is the whole
/// [OfflineProgressSystem.settle] path, segments and all. See
/// [support/live_loop.dart] for how the live side runs on simulated time.
///
/// What is compared, for every scenario:
/// - the actions performed, and the xp they paid, per skill
/// - what went into and came out of the bag
/// - stamina at the end, and whether the loop is still running
/// - how long every potion and fire has left
/// - and on the offline side, that the report covers exactly the time away
///   and the player's clock lands exactly on now
///
/// The frame loop also pays xp by the second that a settle does not pay at
/// all; that gap has its own group at the bottom. Everywhere else the live
/// side takes that xp back as it lands, so the comparison is of what the
/// settle does pay.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ------------------------------------------------------------- fixtures

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  void bindNode(GameSession session, EntityId id) {
    final save = session.saveGameData;
    final entity = id.build() as EncounterEntity;
    entity.count = 1000000;
    save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities.add(
      entity,
    );
    // the strong stance reads the open entity to know what it is boosting
    save.playerData.currentEntityViewId = id;
    expect(session.encounterController.startEncounterActionFor(entity), isTrue);
  }

  void fullStamina(GameSession session) {
    final player = session.saveGameData.playerData;
    player.stamina = session.playerDataService.getMaxStamina(player);
  }

  // a sturdy all-rounder, so no scenario is about being underlevelled
  void baseline(GameSession session) {
    for (final id in [
      SkillId.ATTACK,
      SkillId.DEFENCE,
      SkillId.STRENGTH,
      SkillId.SPEED,
      SkillId.HITPOINTS,
      SkillId.WOODCUTTING,
      SkillId.MINING,
      SkillId.FISHING,
      SkillId.HERBALISM,
      SkillId.COOKING,
      SkillId.FIREMAKING,
      SkillId.BLACKSMITHING,
      SkillId.ENCHANTING,
      SkillId.EXPLORATION,
    ]) {
      setLevel(session, id, 25);
    }
    // high enough that recovery and stamina do not level inside a window
    setLevel(session, SkillId.STAMINA, 30);
    setLevel(session, SkillId.RECOVERY, 10);
    final player = session.saveGameData.playerData;
    player.hitpoints = session.playerDataService.maxHitpoints(player);
    fullStamina(session);
  }

  // ------------------------------------------------------------ activities

  final activities =
      <
        ({
          String name,
          List<Stance> stances,
          PlaySetup bind,
          double band,
          double seconds,
          double fireSlack,
          double clump,
        })
      >[
        (
          name: 'woodcutting',
          stances: [Stance.fast, Stance.strong],
          bind: (s) => bindNode(s, EntityId.TREE),
          band: 0.15,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'mining',
          stances: [Stance.fast, Stance.strong],
          bind: (s) => bindNode(s, EntityId.COPPER),
          band: 0.15,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'fishing',
          stances: [Stance.fast, Stance.strong],
          bind: (s) => bindNode(s, EntityId.TRANQUIL_POND),
          band: 0.15,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'herbalism',
          stances: [Stance.fast],
          bind: (s) => bindNode(s, EntityId.GUAM),
          band: 0.15,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'combat',
          stances: Stance.values,
          bind: (s) {
            final save = s.saveGameData;
            save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 5000;
            save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
            bindNode(s, EntityId.CHICKEN);
          },
          // a fight is rolled hit by hit live and settled off averages, and
          // what it drops comes in clumps: a longer window, a wider band
          band: 0.35,
          seconds: 1800,
          fireSlack: 0.2,
          // feathers fall several to a kill: a live run's count spreads
          // about eight times wider than a count of single drops would
          clump: 8,
        ),
        (
          name: 'smelting',
          stances: [Stance.fast],
          bind: (s) {
            s.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE] = 100000;
            expect(
              s.craftingController.startCraftingActionFor(
                'smelt_copper_bar',
                EntityId.ANVIL,
              ),
              isTrue,
            );
          },
          // a smelt rolls for bonus bars
          band: 0.05,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'cooking over a tended cookfire',
          stances: [Stance.fast],
          bind: (s) {
            final save = s.saveGameData;
            save.inventoryData.itemMap[ItemId.MINNOW] = 100000;
            save.inventoryData.itemMap[ItemId.LOGS] = 100000;
            save.craftingState.selectedRecipeByEntity[EntityId.FIREPIT] = {
              SkillId.FIREMAKING: 'cookfire',
            };
            s.firemakingSystem.lightOrExtend(
              ItemId.COOKFIRE,
              EntityId.FIREPIT,
              save.playerData.currentZoneId,
              save.playerData.buffData,
            );
            expect(
              s.craftingController.startCraftingActionFor(
                'cook_minnow',
                EntityId.FIREPIT,
              ),
              isTrue,
            );
          },
          // a cook can burn
          band: 0.15,
          seconds: 600,
          // live relights on the first action after the fire is swept, the
          // settle on the instant it went out: up to an action apart
          fireSlack: 3.1,
          clump: 1,
        ),
        (
          name: 'exploration',
          stances: [Stance.fast],
          bind: (s) => s.worldController.startExplore(),
          band: 0.25,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'enchanting',
          stances: [Stance.fast],
          bind: (s) {
            final save = s.saveGameData;
            final helmets = ItemId.COPPER_HELMET.build() as EquipmentItem;
            helmets.count = 10000;
            save.inventoryData.equipment.add(helmets);
            save.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 1000000;
            expect(
              s.enchantingController.startEnchantingActionFor(
                'minor_enchant',
                helmets.instanceId,
              ),
              isTrue,
            );
          },
          band: 0.0,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'disenchanting',
          stances: [Stance.fast],
          bind: (s) {
            final save = s.saveGameData;
            final helmets = ItemId.COPPER_HELMET.build() as EquipmentItem;
            helmets.count = 10000;
            save.inventoryData.equipment.add(helmets);
            expect(
              s.enchantingController.startEnchantingActionFor(
                EnchantingController.disenchantRecipeId,
                helmets.instanceId,
              ),
              isTrue,
            );
          },
          band: 0.2,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
        (
          name: 'a dungeon floor',
          stances: [Stance.fast],
          bind: (s) {
            for (final id in [
              SkillId.ATTACK,
              SkillId.DEFENCE,
              SkillId.HITPOINTS,
              SkillId.MINING,
            ]) {
              setLevel(s, id, 99);
            }
            final player = s.saveGameData.playerData;
            player.hitpoints = s.playerDataService.maxHitpoints(player);
            expect(
              s.dungeonController.startSlot(DungeonId.DEV_TRANSIENT_DUNGEON, 1),
              isTrue,
            );
          },
          band: 0.15,
          seconds: 600,
          fireSlack: 0.2,
          clump: 1,
        ),
      ];

  // ---------------------------------------------------------------- boosts

  // none; held at full for the whole window; and held at full on a pool too
  // small to last it, so the lock breaks partway and the rest runs unboosted
  final boosts = <({String name, PlaySetup apply})>[
    (name: 'unboosted', apply: (_) {}),
    (
      name: 'boost locked',
      apply: (s) {
        setLevel(s, SkillId.STAMINA, 99);
        fullStamina(s);
        s.saveGameData.actionTimingData
          ..boostLocked = true
          ..percentOfMaxBoost = 1.0;
      },
    ),
    (
      name: 'boost locked until it runs dry',
      apply: (s) {
        setLevel(s, SkillId.STAMINA, 5);
        fullStamina(s);
        s.saveGameData.actionTimingData
          ..boostLocked = true
          ..percentOfMaxBoost = 1.0;
      },
    ),
  ];

  // ----------------------------------------------------------------- buffs

  void drink(GameSession s, ItemId id) {
    final save = s.saveGameData;
    save.inventoryData.itemMap[id] = (save.inventoryData.itemMap[id] ?? 0) + 1;
    expect(
      s.potionSystem.drink(id, save.inventoryData, save.playerData.buffData),
      isTrue,
    );
  }

  void light(GameSession s, ItemId fire) {
    final save = s.saveGameData;
    s.firemakingSystem.lightOrExtend(
      fire,
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    );
  }

  // every potion lasts three minutes, so a single one runs out a third of the
  // way through a ten-minute window; an armed stack keeps it up throughout.
  // the campfire burns five minutes, the bonfire exactly the whole window
  final buffs = <({String name, PlaySetup apply, double slack})>[
    (name: 'no buffs', apply: (_) {}, slack: 0.2),
    (
      name: 'a speed potion that runs out',
      apply: (s) => drink(s, ItemId.MINOR_SPEED_POTION),
      slack: 0.2,
    ),
    (
      name: 'auto-drunk speed potions',
      apply: (s) {
        drink(s, ItemId.MINOR_SPEED_POTION);
        s.saveGameData.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION] = 10;
        s.saveGameData.playerData.autoDrinkPotions.add(
          ItemId.MINOR_SPEED_POTION,
        );
      },
      // the live sweep re-drinks on the second after a lapse, the settle on
      // the instant; three lapses in a window is three seconds at most
      slack: 3.5,
    ),
    (
      name: 'a strength potion',
      apply: (s) => drink(s, ItemId.MINOR_STRENGTH_POTION),
      slack: 0.2,
    ),
    (
      name: 'a stamina potion',
      apply: (s) => drink(s, ItemId.MINOR_STAMINA_POTION),
      slack: 0.2,
    ),
    (
      name: 'a recovery potion',
      apply: (s) => drink(s, ItemId.MINOR_RECOVERY_POTION),
      slack: 0.2,
    ),
    (
      name: 'a campfire that burns out',
      apply: (s) => light(s, ItemId.BASIC_CAMPFIRE),
      slack: 0.2,
    ),
    (
      name: 'a bonfire for the whole window',
      apply: (s) => light(s, ItemId.BONFIRE),
      slack: 0.2,
    ),
  ];

  // ------------------------------------------------------------ comparison

  void expectClose(
    String what,
    num offline,
    num live, {
    required double tolerance,
  }) {
    expect(
      offline,
      closeTo(live, tolerance),
      reason:
          '$what: offline $offline vs live $live '
          '(±${tolerance.toStringAsFixed(2)})',
    );
  }

  double banded(num live, double band, double floor) {
    final t = live.abs() * band;
    return t > floor ? t : floor;
  }

  /// [band] is how far apart two runs of the same thing can land on what
  /// is rolled rather than counted - drops, burns, finds. Zero for an
  /// activity with no roll in it, which is then held to the item.
  void expectParity(
    PlayOutcome live,
    PlayOutcome offline, {
    required double seconds,
    double band = 0.15,
    double buffSlack = 0.2,
    double fireSlack = 0.2,
    double actionBand = 0.01,
    double clump = 1,
  }) {
    final context = '\nLIVE $live\nOFFLINE $offline';

    // the time away is the time away, to the microsecond
    expect(
      offline.reportedTimeAway,
      Duration(microseconds: (seconds * 1e6).round()),
      reason: 'the report covers the gap$context',
    );
    expect(
      offline.clockDrift,
      Duration.zero,
      reason: 'the clock lands on now$context',
    );

    // the same number of actions. a settle cuts its segments on whole
    // actions and live carries a part-done one over, so the two can sit an
    // action or two apart at the very end
    expectClose(
      'actions$context',
      offline.actions,
      live.actions,
      tolerance: banded(live.actions, actionBand, 2),
    );

    // what those actions paid. xp is per action, so it is held closer than
    // the drops are even where a roll decides it - a fight's xp is its
    // damage, and ten minutes of rolled hits still spreads it a few percent
    final xpBand = band < 0.03 ? 0.03 : (band > 0.2 ? 0.2 : band);
    final liveXp = live.actionXp;
    final offlineXp = offline.actionXp;
    for (final skill in {...liveXp.keys, ...offlineXp.keys}) {
      expectClose(
        '${skill.name} xp$context',
        offlineXp[skill] ?? 0,
        liveXp[skill] ?? 0,
        tolerance: banded(liveXp[skill] ?? 0, xpBand, 5),
      );
    }

    // and what went in and out of the bag. a rolled count is given its
    // band or four standard deviations of a count that size, whichever is
    // wider - a single live run is one draw. the size is the larger of the
    // two, so a rare drop one side happened not to roll still has room
    for (final item in {...live.items.keys, ...offline.items.keys}) {
      final l = live.items[item] ?? 0;
      final o = offline.items[item] ?? 0;
      final n = l.abs() > o.abs() ? l.abs() : o.abs();
      final noise = band == 0 ? 2.0 : 4 * sqrt(clump * n) + 3;
      expectClose(
        '${item.name}$context',
        offline.items[item] ?? 0,
        l,
        tolerance: banded(l, band == 0 ? 0.01 : band, noise),
      );
    }

    expectClose(
      'stamina$context',
      offline.stamina,
      live.stamina,
      tolerance: live.maxStamina * 0.03 + 1,
    );
    expect(offline.running, live.running, reason: 'still running$context');
    expect(offline.died, live.died, reason: 'died$context');

    // every potion and fire has as long left on it either way
    expect(
      offline.globalBuffsLeft.keys.toSet(),
      live.globalBuffsLeft.keys.toSet(),
      reason: 'potions still up$context',
    );
    for (final id in live.globalBuffsLeft.keys) {
      expect(
        offline.globalBuffsLeft[id],
        closeTo(live.globalBuffsLeft[id]!, buffSlack),
        reason: '${id.name} time left$context',
      );
    }
    expect(
      offline.zoneBuffsLeft.keys.toSet(),
      live.zoneBuffsLeft.keys.toSet(),
      reason: 'fires still burning$context',
    );
    for (final id in live.zoneBuffsLeft.keys) {
      expect(
        offline.zoneBuffsLeft[id],
        closeTo(live.zoneBuffsLeft[id]!, fireSlack),
        reason: '${id.name} burn left$context',
      );
    }
  }

  void compare(
    PlaySetup setup, {
    double seconds = 600,
    double band = 0.15,
    double buffSlack = 0.2,
    double fireSlack = 0.2,
    double actionBand = 0.01,
    double clump = 1,
  }) {
    final live = runLive(setup, seconds);
    final offline = runOffline(setup, seconds);
    expectParity(
      live,
      offline,
      seconds: seconds,
      band: band,
      buffSlack: buffSlack,
      fireSlack: fireSlack,
      actionBand: actionBand,
      clump: clump,
    );
  }

  // ----------------------------------------------------------------- tests

  group('every activity, stance and boost, live against offline', () {
    for (final activity in activities) {
      for (final stance in activity.stances) {
        for (final boost in boosts) {
          test('${activity.name}, ${stance.name} stance, ${boost.name}', () {
            compare(
              (s) {
                baseline(s);
                activity.bind(s);
                s.playerDataService.setStance(
                  stance,
                  s.saveGameData.playerData,
                );
                boost.apply(s);
              },
              seconds: activity.seconds,
              band: activity.band,
              fireSlack: activity.fireSlack,
              clump: activity.clump,
            );
          });
        }
      }
    }
  });

  group('every buff, with and without a boost, live against offline', () {
    // the buffs move speed, strength, stamina and recovery, so the
    // activities picked are the ones each of those reaches: a gatherer in
    // either stance, a fighter, and a bench
    final picked = activities
        .where((a) => ['woodcutting', 'combat', 'smelting'].contains(a.name))
        .toList();
    for (final activity in picked) {
      // the fight is the slow one to run, so it takes the stance that runs
      // on strength and the one that runs on speed rather than all four
      final stances = activity.name == 'combat'
          ? [Stance.offensive, Stance.fast]
          : activity.stances;
      for (final stance in stances) {
        for (final buff in buffs.skip(1)) {
          for (final boost in boosts.take(2)) {
            test(
              '${activity.name}, ${stance.name}, ${buff.name}, ${boost.name}',
              () {
                compare(
                  (s) {
                    baseline(s);
                    activity.bind(s);
                    s.playerDataService.setStance(
                      stance,
                      s.saveGameData.playerData,
                    );
                    buff.apply(s);
                    boost.apply(s);
                  },
                  // potions and fires are tuned in minutes, so ten of them
                  // is enough to see each one start, lapse and come back
                  seconds: 600,
                  band: activity.band,
                  buffSlack: buff.slack,
                  clump: activity.clump,
                );
              },
            );
          }
        }
      }
    }

    test('a campfire and a recovery potion while idle-recovering', () {
      // nothing boosted, the pool starting empty: the window is all about
      // the recovery rate, which both the fire and the potion move
      compare((s) {
        baseline(s);
        activities.first.bind(s);
        drink(s, ItemId.MINOR_RECOVERY_POTION);
        light(s, ItemId.BASIC_CAMPFIRE);
        s.saveGameData.playerData.stamina = 0;
      });
    });

    test('every potion and the bonfire at once, on a boost that runs dry', () {
      compare((s) {
        baseline(s);
        activities.first.bind(s);
        for (final id in [
          ItemId.MINOR_SPEED_POTION,
          ItemId.MINOR_STRENGTH_POTION,
          ItemId.MINOR_STAMINA_POTION,
          ItemId.MINOR_RECOVERY_POTION,
          ItemId.MINOR_ATTACK_POTION,
          ItemId.MINOR_DEFENCE_POTION,
        ]) {
          drink(s, id);
        }
        light(s, ItemId.BONFIRE);
        boosts[2].apply(s);
      });
    });

    test('a stamina potion lapsing under a locked boost', () {
      // the pool shrinks when the potion goes: a boost still burning when
      // it does is burning out of a smaller tank
      compare((s) {
        baseline(s);
        activities.first.bind(s);
        setLevel(s, SkillId.STAMINA, 10);
        drink(s, ItemId.MINOR_STAMINA_POTION);
        fullStamina(s);
        s.saveGameData.actionTimingData
          ..boostLocked = true
          ..percentOfMaxBoost = 1.0;
      });
    });
  });

  // ----------------------------------------------------------------- edges

  group('the loop stopping partway through', () {
    test('a bench that runs out of ore stops at the same craft', () {
      compare((s) {
        baseline(s);
        activities.firstWhere((a) => a.name == 'smelting').bind(s);
        s.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE] = 90;
        // a smelt rolls for bonus bars
      }, band: 0.05);
    });

    test('a boosted bench that runs out stops and recovers the rest', () {
      compare((s) {
        baseline(s);
        activities.firstWhere((a) => a.name == 'smelting').bind(s);
        s.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE] = 90;
        boosts[1].apply(s);
      }, band: 0.05);
    });

    test('an enchanter that runs out of dust stops at the same item', () {
      compare((s) {
        baseline(s);
        activities.firstWhere((a) => a.name == 'enchanting').bind(s);
        s.saveGameData.inventoryData.itemMap[ItemId.ENCHANTING_DUST] = 900;
      }, band: 0);
    });

    test('a node that runs dry stops at the same swing', () {
      compare(
        (s) {
          baseline(s);
          final save = s.saveGameData;
          final tree = EntityId.TREE.build() as EncounterEntity;
          tree.count = 40;
          save
              .worldData
              .zones[save.playerData.currentZoneId]!
              .discoveredEntities
              .add(tree);
          expect(s.encounterController.startEncounterActionFor(tree), isTrue);
        },
        // forty trees is forty kills' worth of rolled hits: a live run has
        // taken anywhere from 81 to 90 swings to fell them, and the settle,
        // pricing a kill off the average, lands inside that spread
        actionBand: 0.15,
      );
    });

    test('a fire with no logs to relight it ends the cooking', () {
      compare((s) {
        baseline(s);
        activities.firstWhere((a) => a.name.startsWith('cooking')).bind(s);
        s.saveGameData.inventoryData.itemMap.remove(ItemId.LOGS);
      }, fireSlack: 3.1);
    });
  });

  group('dying while away', () {
    // an unfed level-25 against something far above it: both sides die,
    // and at about the same point in the window
    void doomed(GameSession s) {
      baseline(s);
      setLevel(s, SkillId.HITPOINTS, 10);
      setLevel(s, SkillId.DEFENCE, 1);
      final player = s.saveGameData.playerData;
      player.hitpoints = s.playerDataService.maxHitpoints(player);
      bindNode(s, EntityId.COW_LEGENDARY);
    }

    test('both sides die, at about the same time', () {
      final live = runLive(doomed, 600);
      final offline = runOffline(doomed, 600);
      final context = '\nLIVE $live\nOFFLINE $offline';
      expect(live.died, isTrue, reason: context);
      expect(offline.died, isTrue, reason: context);
      expect(offline.running, isFalse, reason: context);
      expect(
        offline.diedAfter!.inMilliseconds,
        closeTo(
          live.diedAfter!.inMilliseconds,
          live.diedAfter!.inMilliseconds * 0.5 + 3000,
        ),
        reason: context,
      );
      // the report still covers the whole gap, and the clock lands on now
      expect(offline.reportedTimeAway, const Duration(seconds: 600));
      expect(offline.clockDrift, Duration.zero);
    });

    test('a short stack of food runs out, then the fight is lost', () {
      void fedBriefly(GameSession s) {
        doomed(s);
        final save = s.saveGameData;
        save.inventoryData.itemMap[ItemId.COOKED_CHICKEN] = 5;
        save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
      }

      final live = runLive(fedBriefly, 600);
      final offline = runOffline(fedBriefly, 600);
      final context = '\nLIVE $live\nOFFLINE $offline';
      expect(live.died, isTrue, reason: context);
      expect(offline.died, isTrue, reason: context);
      // both eat on the way down. a hit big enough to go from above the eat
      // line to nothing can land before the stack is finished, on either
      // side, so how many is a roll - but never more than the stack, and
      // never none
      expect(live.items[ItemId.COOKED_CHICKEN], inInclusiveRange(-5, -1));
      expect(offline.items[ItemId.COOKED_CHICKEN], inInclusiveRange(-5, -1));
    });
  });

  group('enemies that die in one hit, on short and long swing timers', () {
    // an enemy's swing timer starts over with each one that stands up, so a
    // swing only lands when an enemy outlives its interval. a one-hit kill
    // rarely does, which is why both ends of the timer range are worth
    // running: the shortest the catalog has, and the longest
    const timers = <({EntityId id, double interval})>[
      (id: EntityId.GIANT_BAT, interval: 1.0),
      (id: EntityId.ROTWOOD_SCARECROW, interval: 2.5),
    ];

    PlaySetup oneHit(EntityId id) => (s) {
      baseline(s);
      // out-damages the pool in a single swing
      for (final skill in [
        SkillId.ATTACK,
        SkillId.STRENGTH,
        SkillId.SPEED,
        SkillId.DEFENCE,
        SkillId.HITPOINTS,
      ]) {
        setLevel(s, skill, 99);
      }
      final save = s.saveGameData;
      save.playerData.equipmentData.armorEquipment[ArmorSlots.WEAPON_1H] =
          EquipmentItem(id: ItemId.DRAGON_SWORD);
      // fed, so a bat that does get a swing in costs food rather than the run
      save.inventoryData.itemMap[ItemId.COOKED_SHARK] = 5000;
      save.playerData.equipmentData.equipedFood = ItemId.COOKED_SHARK;
      save.playerData.hitpoints = s.playerDataService.maxHitpoints(
        save.playerData,
      );
      bindNode(s, id);
    };

    for (final timer in timers) {
      test('${timer.id.name}, swinging every ${timer.interval}s: live and '
          'offline agree', () {
        final setup = oneHit(timer.id);

        // it is the fight it claims to be
        final probe = buildPlaySession();
        setup(probe);
        final enemy = probe.saveGameData.encounterData.entity as CombatEntity;
        final details = probe.worldController.entityDetails(enemy);
        probe.dispose();
        expect(enemy.attackInterval, timer.interval);
        expect(
          details.playerMaxHit,
          greaterThanOrEqualTo(enemy.maxHitPoints),
          reason: 'one hit must be enough',
        );

        final live = runLive(setup, 600);
        final offline = runOffline(setup, 600);
        final context = '\nLIVE $live\nOFFLINE $offline';

        // a long run of kills, not a fight that stalls or ends in a death
        expect(live.actions, greaterThan(100), reason: context);
        expect(live.died, isFalse, reason: context);
        expect(offline.died, isFalse, reason: context);

        expectParity(live, offline, seconds: 600, band: 0.35, clump: 8);

        // what the enemy's swings cost, in food: the parity above compares
        // it among the items, this names it. a timer that carried its
        // wind-up over each death would eat far more than one that starts
        // over, on whichever side forgot to reset
        final liveEaten = -(live.items[ItemId.COOKED_SHARK] ?? 0);
        final offlineEaten = -(offline.items[ItemId.COOKED_SHARK] ?? 0);
        expectClose(
          'food eaten$context',
          offlineEaten,
          liveEaten,
          tolerance: banded(liveEaten, 0.5, 8),
        );
      });
    }
  });

  group('a window long enough to level in', () {
    // both sides start at level 1 and level as they go: the settle has to
    // cut a segment at every level-up to keep up with the live loop
    int levelOf(Map<SkillId, double> xp, SkillId id, GameSession probe) {
      final data = probe.saveGameData.playerData.skillData[id]!;
      final start = data.xp;
      data.xp = start + (xp[id] ?? 0);
      final level = probe.skillService.getLevel(data);
      data.xp = start;
      return level;
    }

    for (final activity in [
      (name: 'woodcutting', skill: SkillId.WOODCUTTING),
      (name: 'smelting', skill: SkillId.BLACKSMITHING),
      (name: 'exploration', skill: SkillId.EXPLORATION),
    ]) {
      test('an hour of ${activity.name} from level 1', () {
        void setup(GameSession s) {
          activities.firstWhere((a) => a.name == activity.name).bind(s);
        }

        final live = runLive(setup, 3600, fps: 10);
        final offline = runOffline(setup, 3600);
        final probe = buildPlaySession();
        final liveLevel = levelOf(live.xp, activity.skill, probe);
        final offlineLevel = levelOf(offline.xp, activity.skill, probe);
        probe.dispose();

        final context = '\nLIVE $live\nOFFLINE $offline';
        expect(liveLevel, greaterThan(5), reason: context);
        expect(offlineLevel, closeTo(liveLevel, 1), reason: context);
        expectClose(
          'actions$context',
          offline.actions,
          live.actions,
          tolerance: banded(live.actions, 0.01, 2),
        );
        expectClose(
          'xp$context',
          offline.xp[activity.skill]!,
          live.xp[activity.skill]!,
          tolerance: live.xp[activity.skill]! * 0.05,
        );
        expect(offline.reportedTimeAway, const Duration(hours: 1));
        expect(offline.clockDrift, Duration.zero);
      });
    }
  });

  group('time away', () {
    void smelt(GameSession s) {
      baseline(s);
      activities.firstWhere((a) => a.name == 'smelting').bind(s);
    }

    for (final seconds in [1.0, 2.999, 3.0, 3.001, 4.999, 5.0, 59.5, 600.0]) {
      test('a ${seconds}s gap settles exactly ${seconds}s', () {
        final offline = runOffline(smelt, seconds);
        expect(
          offline.reportedTimeAway,
          Duration(microseconds: (seconds * 1e6).round()),
        );
        expect(offline.clockDrift, Duration.zero);
        // under the threshold the crafts still land, there is just no
        // dialog about them
        final shown =
            offline.report!.timeAway >= OfflineProgressService.reportThreshold;
        expect(shown || offline.actions <= 2, isTrue);
      });
    }

    for (final activity in activities) {
      test('${activity.name}: a day away reports a day, and ends on now', () {
        final offline = runOffline((s) {
          baseline(s);
          activity.bind(s);
          boosts[2].apply(s);
        }, 86400);
        expect(offline.reportedTimeAway, const Duration(days: 1));
        expect(offline.clockDrift, Duration.zero);
      });
    }
  });

  group('state the live loop carries into a gap', () {
    // a settle replays the gap from the state the last live frame left
    // behind. what that frame was in the middle of has to carry over, the
    // same way it would have if the frames had kept coming

    test('a part-done action is finished, not thrown away', () {
      // backgrounded nine tenths of the way through a three-second craft,
      // and back two seconds later: live, that craft lands
      void setup(GameSession s) {
        baseline(s);
        activities.firstWhere((a) => a.name == 'smelting').bind(s);
        s.saveGameData.actionTimingData.actionProgressPercentComplete = 0.9;
      }

      final live = runLive(setup, 2);
      final offline = runOffline(setup, 2);
      expect(live.actions, 1);
      expect(offline.actions, live.actions);
    });

    test('a string of short gaps pays what playing through them pays', () {
      // every time the phone is glanced away from for under an action - a
      // notification, the lock button - the settle runs a gap too short to
      // hold one. what it could not spend has to carry into the next
      void setup(GameSession s) {
        baseline(s);
        activities.firstWhere((a) => a.name == 'smelting').bind(s);
      }

      // gaps of two seconds against a 2.4s craft: not one of them is long
      // enough to hold a craft on its own
      final live = runLive(setup, 250);

      final session = buildPlaySession();
      setup(session);
      final save = session.saveGameData;
      // counted in ore, a craft each: the bars a smelt pays are rolled
      final before = save.inventoryData.itemMap[ItemId.COPPER_ORE] ?? 0;
      for (var i = 0; i < 125; i++) {
        final now = DateTime.now();
        save.playerData.lastActionTime = now.subtract(
          const Duration(seconds: 2),
        );
        session.offlineProgressSystem.settle(
          save.playerData,
          save.actionTimingData,
          now: now,
        );
      }
      final crafts =
          before - (save.inventoryData.itemMap[ItemId.COPPER_ORE] ?? 0);
      session.actionTimingController.stop();
      session.dispose();

      expect(-live.items[ItemId.COPPER_ORE]!, closeTo(250 / 2.4, 1));
      expect(crafts, closeTo(-live.items[ItemId.COPPER_ORE]!, 2));
    });

    test('a boost bar left full but unlocked drains, it does not hold', () {
      // the button let go of an instant before the app went away: live, the
      // bar falls to nothing in a second and a half and the rest of the
      // stretch runs unboosted
      void setup(GameSession s) {
        baseline(s);
        activities.firstWhere((a) => a.name == 'smelting').bind(s);
        s.saveGameData.actionTimingData.percentOfMaxBoost = 1.0;
      }

      final live = runLive(setup, 600);
      final offline = runOffline(setup, 600);
      // a smelt rolls for bonus bars
      expectParity(live, offline, seconds: 600, band: 0.05);
    });
  });

  // ------------------------------------------------------- frame-loop xp

  group('the xp the frame loop pays by the second', () {
    // the live loop pays the boost skill and stamina for every second spent
    // boosted, and recovery for every second spent refilling - none of it
    // tied to an action. a settle pays the same off the stamina bar, segment
    // by segment, so the summary can show the core skills moving
    test('a settle pays it too', () {
      void setup(GameSession s) {
        baseline(s);
        activities.first.bind(s);
        boosts[2].apply(s);
      }

      final live = runLive(setup, 600);
      final offline = runOffline(setup, 600);
      final context = '\nLIVE $live\nOFFLINE $offline';
      for (final id in [SkillId.SPEED, SkillId.STAMINA, SkillId.RECOVERY]) {
        final l = live.frameXp[id] ?? 0;
        expect(l, greaterThan(0), reason: '${id.name}$context');
        expect(
          offline.frameXp[id] ?? 0,
          closeTo(l, l * 0.1 + 5),
          reason: '${id.name}$context',
        );
      }
    });
  });
}
