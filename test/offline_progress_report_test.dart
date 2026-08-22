import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
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

// What the player is told when they come back: an offline settle buffers
// everything its actions produce into one report, and the shell shows it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final factory = GameSessionFactory();

  // a gap comfortably past the report threshold, whatever it is tuned to
  final longGap =
      OfflineProgressService.reportThreshold + const Duration(seconds: 60);

  // how many actions a gap is worth at the default (unboosted) interval
  int actionsIn(Duration gap) =>
      gap.inMicroseconds ~/
      ActionTimingService.defaultMaxInterval.inMicroseconds;

  GameSession newSession() {
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // puts [gap] of wall clock between the player's last action and the instant
  // handed to the system, without actually waiting
  DateTime goOffline(PlayerData player, Duration gap) {
    final now = DateTime.now();
    player.lastActionTime = now.subtract(gap);
    return now;
  }

  /// Settles [gap] of time away on a session, the way the first frame back
  /// does.
  void settle(GameSession session, Duration gap) {
    final save = session.saveGameData;
    final now = goOffline(save.playerData, gap);
    session.offlineProgressSystem.settle(
      save.playerData,
      save.actionTimingData,
      now: now,
    );
  }

  group('a settle reports what it paid out', () {
    test('an explore reports its actions, its finds and its xp', () {
      final session = newSession();
      session.worldController.startExplore();

      settle(session, longGap);

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      expect(report!.actionCount, actionsIn(longGap));
      expect(report.timeAway.inSeconds, longGap.inSeconds);
      // the meadow pays a flat 8 xp an explore, and the batch pays one
      // explore's worth per explore
      expect(report.xp[SkillId.EXPLORATION], 8.0 * actionsIn(longGap));
      // every explore finds at least once, so the walk turned entities up
      expect(report.entities, isNotEmpty);
      expect(
        report.entities.values.fold<int>(0, (sum, count) => sum + count),
        greaterThanOrEqualTo(actionsIn(longGap)),
      );
      expect(session.actionTimingController.offlineReportSequence, 1);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('an encounter reports what it killed', () {
      final session = newSession();
      // a tree in the starting zone, the way exploring would leave one
      final save = session.saveGameData;
      final tree = EntityId.TREE.build() as EncounterEntity;
      save.worldData.zones[save.playerData.currentZoneId]!.discoveredEntities
          .add(tree);
      expect(session.encounterController.startEncounterActionFor(tree), isTrue);

      settle(session, longGap);

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      // the kills are reported by kind, and the total the dialog's stat row
      // shows is the sum of them
      expect(report!.entitiesDefeated[EntityId.TREE], greaterThan(0));
      expect(report.enemiesDefeated, report.entitiesDefeated[EntityId.TREE]);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('a craft reports the item it made', () {
      final session = newSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 100;

      expect(
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      settle(session, longGap);

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      // crafting settles the whole count a fire is handed, so the report
      // carries every bar the gap was worth
      final crafts = actionsIn(longGap);
      expect(report!.items.itemMap[ItemId.COPPER_BAR], crafts);
      expect(report.xp[SkillId.BLACKSMITHING], 5.0 * crafts);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('the report is cleared once the ui has shown it', () {
      final session = newSession();
      session.worldController.startExplore();
      settle(session, longGap);
      expect(session.actionTimingController.pendingOfflineReport, isNotNull);

      session.actionTimingController.consumeOfflineReport();

      expect(session.actionTimingController.pendingOfflineReport, isNull);
      // the counter is not rewound: it is what the shell compares against
      expect(session.actionTimingController.offlineReportSequence, 1);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('normal play reports nothing', () {
      final session = newSession();
      session.worldController.startExplore();

      // the online path: a frame close enough behind the last one that the
      // loop never reaches for the offline settle
      session.saveGameData.playerData.lastActionTime = DateTime.now();
      session.saveGameData.actionTimingData.lastElapsed = const Duration(
        milliseconds: 16,
      );
      session.actionTimingSystem.frameUpdate(
        const Duration(milliseconds: 32),
        session.saveGameData.actionTimingData,
        session.saveGameData.playerData,
      );

      expect(session.offlineProgressData.processing, isFalse);
      expect(session.offlineProgressData.report.isEmpty, isTrue);
      expect(session.actionTimingController.pendingOfflineReport, isNull);

      session.actionTimingController.stop();
      session.dispose();
    });
  });

  group('what is worth interrupting the player for', () {
    late PlayerDataService playerDataService;
    late ActionTimingService timingService;
    late ActionTimingSystem timingSystem;
    late OfflineProgressService offlineProgressService;
    late OfflineProgressSystem system;
    late OfflineProgressData offlineProgressData;

    setUp(() {
      playerDataService = PlayerDataService(
        buffService: BuffService(),
        equpmentService: EquipmentService(),
        skillService: SkillService(),
      );
      timingService = ActionTimingService();
      offlineProgressData = OfflineProgressData();
      offlineProgressService = OfflineProgressService(InventoryService());
      timingSystem = ActionTimingSystem(
        actionTimingService: timingService,
        playerDataService: playerDataService,
        equipmentService: EquipmentService(),
      );
      system = OfflineProgressSystem(
        actionTimingService: timingService,
        actionTimingSystem: timingSystem,
        playerDataService: playerDataService,
        skillService: SkillService(),
        buffService: BuffService(),
        offlineProgressService: offlineProgressService,
        offlineProgressData: offlineProgressData,
      );
    });

    PlayerData newPlayer() => factory.newGame(factory.catalog1()).playerData;

    // a stand-in action that reports what it did, the way a real one does:
    // the report is built out of results, so an action that says nothing
    // has nothing to show for itself.
    (ActionTimingData, List<int>) recordingState({bool reports = true}) {
      final fired = <int>[];
      final state = ActionTimingData();
      state.running = true;
      state.onFire =
          (count, {bool offline = false, DateTime? at, Duration? span}) {
            fired.add(count);
            offlineProgressService.record(
              offlineProgressData,
              EncounterActionResult()..actionsPerformed = reports ? count : 0,
            );
          };
      return (state, fired);
    }

    test('a gap too short to be worth a popup still settles', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      // a fast action, so the short gap is still worth firing for: the
      // speed stat cuts the interval well under a second
      final speed = player.skillData[SkillId.SPEED]!;
      speed.xp = speed.xpTable[99];
      final shortGap = OfflineProgressService.reportThreshold ~/ 2;

      system.settle(player, state, now: goOffline(player, shortGap));

      // the actions were paid out
      expect(fired, isNotEmpty);
      expect(fired.first, greaterThan(0));
      // but nothing is raised for them
      expect(offlineProgressData.pending, isNull);
      expect(offlineProgressData.reportSequence, 0);
    });

    test('a gap with nothing to show for it raises nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState(reports: false);

      system.settle(player, state, now: goOffline(player, longGap));

      // the actions fired, but the action reported nothing for them - it
      // had nothing to work with, and the report says so rather than
      // announcing a gap's worth of actions that produced nothing
      expect(fired, isNotEmpty);
      expect(offlineProgressData.pending, isNull);
      expect(offlineProgressData.reportSequence, 0);
    });

    test('a locked boost counts both of its stretches under one report', () {
      final player = newPlayer();
      final speed = player.skillData[SkillId.SPEED]!;
      speed.xp = speed.xpTable[20]; // ceiling 2x
      player.stamina = 10;

      final (state, fired) = recordingState();
      state.boostLocked = true;
      state.percentOfMaxBoost = 1.0;
      state.maxBoostMultiplier = timingService.maxSpeedBoostForStat(
        playerDataService.getStatTotals(player)[SkillId.SPEED] ?? 1,
      );

      system.settle(
        player,
        state,
        now: goOffline(player, const Duration(hours: 1)),
      );

      // the stamina runs out partway, so the boosted segments and the
      // unboosted ones fire separately - and land in one report
      expect(fired.length, greaterThan(2));
      expect(offlineProgressData.pending, isNotNull);
      expect(
        offlineProgressData.pending!.actionCount,
        fired.fold<int>(0, (sum, count) => sum + count),
      );
      expect(offlineProgressData.reportSequence, 1);
    });

    test('a death is always worth a report, however short the gap', () {
      final player = newPlayer();

      // a gap far too short to be worth interrupting anyone over, and a
      // fight that ended in it
      offlineProgressService.begin(
        offlineProgressData,
        OfflineProgressService.reportThreshold ~/ 2,
      );
      offlineProgressService.recordDeath(
        offlineProgressData,
        killedBy: EntityId.CHICKEN,
      );
      offlineProgressService.recordDeathTime(
        offlineProgressData,
        const Duration(seconds: 2),
      );
      offlineProgressService.finish(offlineProgressData);

      final report = offlineProgressData.pending;
      expect(report, isNotNull);
      // nothing was gained, but a death is not an empty report
      expect(report!.isEmpty, isFalse);
      expect(report.died, isTrue);
      expect(report.killedBy, EntityId.CHICKEN);
      expect(report.diedAfter, const Duration(seconds: 2));
      expect(player.hitpoints, isNotNull);
    });

    test('a settle with the loop stopped reports nothing', () {
      final player = newPlayer();
      final (state, fired) = recordingState();
      state.running = false;
      goOffline(player, longGap);

      system.settle(player, state, now: DateTime.now());

      expect(fired, isEmpty);
      expect(offlineProgressData.pending, isNull);
    });
  });
}
