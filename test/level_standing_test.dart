import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/level_standing.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// An entity's level against the player's: half as high again is hard, two
// thirds or less is easy, and a gap under two levels is always even. The
// player's combat level is read the way a creature's is, so the two compare.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('standing', () {
    test('half as high again is hard', () {
      expect(LevelStanding.of(5, 3), LevelStanding.hard);
      expect(LevelStanding.of(30, 20), LevelStanding.hard);
      expect(LevelStanding.of(89, 34), LevelStanding.hard);
    });

    test('two thirds or less is easy', () {
      expect(LevelStanding.of(1, 3), LevelStanding.easy);
      expect(LevelStanding.of(20, 30), LevelStanding.easy);
    });

    test('close is even', () {
      expect(LevelStanding.of(3, 3), LevelStanding.even);
      expect(LevelStanding.of(22, 20), LevelStanding.even);
      expect(LevelStanding.of(25, 30), LevelStanding.even);
    });

    test('a gap under two levels is even, however it reads as a ratio', () {
      // 2 against 1 is double, but it is one level
      expect(LevelStanding.of(2, 1), LevelStanding.even);
      expect(LevelStanding.of(1, 2), LevelStanding.even);
    });
  });

  group('the player\'s combat level', () {
    GameSession buildSession() {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      return factory.create(
        save: factory.newGame(catalogs),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
    }

    test('is read off the totals the way a creature\'s level is', () {
      final session = buildSession();
      final player = session.saveGameData.playerData;
      final stats = session.playerDataService.getStatTotals(player);

      final best = [
        SkillId.ATTACK,
        SkillId.RANGED,
        SkillId.MAGIC,
      ].map((s) => stats[s] ?? 1).reduce((a, b) => a > b ? a : b);
      expect(
        session.playerDataService.combatLevel(player),
        CombatType.levelOf(
          attack: best,
          defence: stats[SkillId.DEFENCE] ?? 1,
          hitpoints: stats[SkillId.HITPOINTS] ?? 1,
        ),
      );
      expect(
        session.playerDataController.getCombatLevel(),
        session.equipmentController.getCombatLevel(),
      );

      session.dispose();
    });

    test('gear that adds defence raises it', () {
      final session = buildSession();
      final player = session.saveGameData.playerData;
      final before = session.playerDataService.combatLevel(player);

      // enough armour to move the average
      for (final piece in [
        ItemId.MITHRIL_CHESTPLATE,
        ItemId.MITHRIL_LEGS,
        ItemId.MITHRIL_HELMET,
      ]) {
        session.equipmentService.equipItem(
          piece.build() as EquipmentItem,
          player.equipmentData,
        );
      }

      expect(
        session.playerDataService.combatLevel(player),
        greaterThan(before),
      );
      session.dispose();
    });
  });
}
