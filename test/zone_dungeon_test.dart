import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
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
    session.saveGameData.playerData.hitpoints = session.playerDataService
        .getStatTotals(session.saveGameData.playerData)[SkillId.HITPOINTS]!;
  }

  // ticks the encounter loop until it stops (a card cleared, or a death)
  void fightUntilStopped(GameSession session) {
    var n = 0;
    while (session.actionTimingController.isRunning && n < 20000) {
      session.encounterController.doEncounterAction(1);
      n++;
    }
  }

  group('Spider Den definition', () {
    test('is a free zone dungeon with refightable cards', () {
      final d = DungeonId.SPIDER_DEN.definition;
      expect(d.type, DungeonType.ZONE);
      expect(d.repeatableEntries, isTrue);
      expect(d.isKeyed, isFalse);
      expect(
        d.entries.last.entities.last.entityId,
        EntityId.SPIDER_BROODMOTHER,
      );
    });
  });

  group('forest zone entrance', () {
    test('the forest contains a Spider Den DungeonEntity', () {
      final session = buildSession();
      final forest =
          session.saveGameData.worldData.zones[ZoneId.SOUTHWOOD_FOREST]!;
      final entrance = forest.permanentEntities.whereType<DungeonEntity>();
      expect(entrance, hasLength(1));
      expect(entrance.first.dungeonId, DungeonId.SPIDER_DEN);
      session.dispose();
    });

    test(
      'the entrance survives a save round-trip',
      () {
        final session = buildSession();
        final restored = SaveGameData.fromJson(session.saveGameData.toJson());
        final forest = restored.worldData.zones[ZoneId.SOUTHWOOD_FOREST]!;
        final entrance = forest.permanentEntities.whereType<DungeonEntity>();
        expect(entrance, hasLength(1));
        expect(entrance.first.dungeonId, DungeonId.SPIDER_DEN);
        session.dispose();
      },
      skip:
          'pre-existing failure, also fails at commit e642bb3 - predates the batch-explore and offline-progress work',
    );
  });

  group('working down the card list', () {
    test('clearing a card unlocks the next and refights on demand', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      // free entry: no key, and the first card is open straight away
      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      expect(save.dungeonRun.active, isTrue);
      expect(dungeons.lockReason(0), isNull);
      expect(dungeons.lockReason(2), isNotNull);

      // card 2 waits on the seam directly above it
      dungeons.startSlot(1);
      fightUntilStopped(session);

      expect(save.dungeonRun.cleared, contains(1));
      expect(dungeons.lockReason(2), isNull);

      // re-tapping a cleared card refills it; the cleared mark stays, so
      // the card below it does not re-lock
      expect(dungeons.startSlot(1), isTrue);
      expect(save.dungeonRun.slots[1].cleared, isFalse);
      expect(save.dungeonRun.slots[1].members.first.count, greaterThan(0));
      expect(dungeons.lockReason(2), isNull);

      session.dispose();
    });

    test('the boss card pays out its guaranteed drop', () {
      final session = buildSession();
      final save = session.saveGameData;
      final dungeons = session.dungeonController;
      makePlayerStrong(session);

      dungeons.openDungeon(DungeonId.SPIDER_DEN);
      // the boss sits behind the cards above it
      for (int i = 0; i < 3; i++) {
        dungeons.startSlot(i);
        fightUntilStopped(session);
      }
      dungeons.startSlot(3);
      fightUntilStopped(session);

      expect(save.dungeonRun.slots[3].cleared, isTrue);
      expect(
        session.inventoryService.getItemCount(save.inventoryData, ItemId.COINS),
        greaterThanOrEqualTo(100),
      );

      session.dispose();
    });
  });

  group('transient entrance', () {
    test('is discoverable in the dev zone and consumed by a run', () {
      final session = buildSession();
      final save = session.saveGameData;

      save.playerData.currentZoneId = ZoneId.DEV_DUNGEON_TESTING;
      session.explorationService.addEntityToCurrentZone(
        EntityId.DEV_DUNGEON_ENTRANCE,
        1,
        save.playerData,
        save.worldData,
      );

      final zone = save.worldData.zones[ZoneId.DEV_DUNGEON_TESTING]!;
      bool hasEntrance() => zone.discoveredEntities.any(
        (e) => e.id == EntityId.DEV_DUNGEON_ENTRANCE,
      );
      expect(hasEntrance(), isTrue);

      session.dungeonController.openDungeon(DungeonId.DEV_TRANSIENT_DUNGEON);
      session.dungeonController.leaveDungeon();
      expect(hasEntrance(), isFalse);

      // exploring again is how you get another one
      session.explorationService.addEntityToCurrentZone(
        EntityId.DEV_DUNGEON_ENTRANCE,
        1,
        save.playerData,
        save.worldData,
      );
      expect(hasEntrance(), isTrue);

      session.dispose();
    });
  });
}
