import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeon_catalog.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/data/dungeon_run.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void makePlayerStrong(GameSession session) {
    final skills = session.saveGameData.playerData.skillData;
    for (final id in [SkillId.ATTACK, SkillId.DEFENCE, SkillId.HITPOINTS]) {
      final s = skills[id]!;
      s.xp = s.xpTable[99];
    }
    session.saveGameData.playerData.hitpoints =
        session.playerDataService.getStatTotals(
          session.saveGameData.playerData,
        )[SkillId.HITPOINTS]!;
  }

  // ticks combat until the run pauses for a floor choice or ends
  void tickUntilPauseOrEnd(GameSession session, DungeonRun run) {
    var n = 0;
    while (run.active && !run.awaitingFloorChoice && n < 20000) {
      session.dungeonSystem.executeDungeonAction(
        run: run,
        playerState: session.saveGameData.playerData,
        playerInventory: session.saveGameData.inventoryData,
      );
      n++;
    }
  }

  group('Spider Den definition', () {
    final catalog = DungeonCatalog();

    test('is a free, repeatable zone dungeon with the Broodmother boss', () {
      final d = catalog.getDefinitionFor(DungeonId.SPIDER_DEN)!;
      expect(d.type, DungeonType.ZONE);
      expect(d.repeatable, isTrue);
      expect(d.isKeyed, isFalse);
      expect(d.bossEntityId, EntityId.SPIDER_BROODMOTHER);
    });
  });

  group('forest zone entrance', () {
    test('the forest contains a Spider Den DungeonEntity', () {
      final session = buildSession();
      final forest =
          session.saveGameData.worldData.zones[ZoneId.STARTING_FOREST]!;
      final entrance = forest.permanentEntities.whereType<DungeonEntity>();
      expect(entrance, hasLength(1));
      expect(entrance.first.dungeonId, DungeonId.SPIDER_DEN);
      session.dispose();
    });

    test('the entrance survives a save round-trip', () {
      final session = buildSession();
      final restored = SaveGameData.fromJson(
        session.saveGameData.toJson(),
      );
      final forest = restored.worldData.zones[ZoneId.STARTING_FOREST]!;
      final entrance = forest.permanentEntities.whereType<DungeonEntity>();
      expect(entrance, hasLength(1));
      expect(entrance.first.dungeonId, DungeonId.SPIDER_DEN);
      session.dispose();
    });
  });

  group('repeatable run (loop / continue)', () {
    test('enters free, loops a floor, then continues to the boss', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);

      // free entry, no key needed
      expect(
        session.dungeonSystem.canEnter(
          run: save.dungeonRun,
          dungeonId: DungeonId.SPIDER_DEN,
          playerState: save.playerData,
          playerInventory: save.inventoryData,
        ),
        isTrue,
      );
      session.dungeonSystem.enterDungeon(
        run: save.dungeonRun,
        dungeonId: DungeonId.SPIDER_DEN,
        playerState: save.playerData,
        playerInventory: save.inventoryData,
      );

      // clear floor 0 -> pauses for the loop/continue choice
      tickUntilPauseOrEnd(session, save.dungeonRun);
      expect(save.dungeonRun.awaitingFloorChoice, isTrue);
      expect(save.dungeonRun.floorIndex, 0);
      expect(save.dungeonRun.maxClearedFloor, 0);

      // loop it: back to floor 0, fighting again
      session.dungeonSystem.loopFloor(save.dungeonRun);
      expect(save.dungeonRun.awaitingFloorChoice, isFalse);
      expect(save.dungeonRun.floorIndex, 0);
      expect(save.dungeonRun.fight.entity?.id, EntityId.GIANT_SPIDER);

      // clear floor 0 again, then descend through the floors to the boss
      tickUntilPauseOrEnd(session, save.dungeonRun);
      expect(save.dungeonRun.awaitingFloorChoice, isTrue);

      session.dungeonSystem.continueFloor(save.dungeonRun); // -> floor 1
      tickUntilPauseOrEnd(session, save.dungeonRun);
      expect(save.dungeonRun.floorIndex, 1);

      session.dungeonSystem.continueFloor(save.dungeonRun); // -> floor 2 (boss)
      tickUntilPauseOrEnd(session, save.dungeonRun);
      expect(save.dungeonRun.floorIndex, 2);

      // boss floor cleared: the choice is loop-the-boss or finish
      expect(save.dungeonRun.awaitingFloorChoice, isTrue);
      // (uses the controller helper for the boss-floor flag)
      expect(session.dungeonController.atBossFloorChoice, isTrue);

      // the Broodmother died at least once -> its guaranteed 100-coin drop
      expect(
        session.inventoryService.getItemCount(save.inventoryData, ItemId.COINS),
        greaterThanOrEqualTo(100),
      );

      // finishing ends the run
      session.dungeonSystem.continueFloor(save.dungeonRun);
      expect(save.dungeonRun.active, isFalse);

      session.dispose();
    });
  });
}
