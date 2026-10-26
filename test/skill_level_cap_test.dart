import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/data/debug_settings.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/skill_service.dart';

void main() {
  group('debug max skill level', () {
    late DebugSettings debug;
    late SkillService service;
    late SkillData skill;

    setUp(() {
      debug = DebugSettings();
      service = SkillService(debugSettings: debug);
      skill = SkillData(name: 'ATTACK', xp: 0);
      service.setLevel(40, skill);
    });

    test('no cap reads the earned level', () {
      expect(service.getLevel(skill), 40);
    });

    test('a cap holds the level and reads as maxed', () {
      debug.maxSkillLevel = 20;

      expect(service.getLevel(skill), 20);
      expect(service.percentProgressToLevelUp(skill), 1.0);
      expect(service.xpToLevelUp(skill), 0);
      expect(service.nextLevelXp(skill), 0);
    });

    test('a cap above the earned level changes nothing', () {
      debug.maxSkillLevel = 60;

      expect(service.getLevel(skill), 40);
      expect(service.xpToLevelUp(skill), greaterThan(0));
    });

    test('xp keeps accruing under the cap and lifting it restores the '
        'earned level', () {
      debug.maxSkillLevel = 20;
      service.setLevel(50, skill);
      expect(service.getLevel(skill), 20);

      debug.maxSkillLevel = null;
      expect(service.getLevel(skill), 50);
    });

    test('a cap at 1 reads every skill at level 1', () {
      debug.maxSkillLevel = 1;
      expect(service.getLevel(skill), 1);
    });
  });

  test('the cap flows into stat totals and survives a save round trip', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final attack = save.playerData.skillData[SkillId.ATTACK]!;
    attack.xp = attack.xpTable[30];
    save.debugSettings.maxSkillLevel = 5;

    final restored = SaveGameData.fromJson(save.toJson());
    expect(restored.debugSettings.maxSkillLevel, 5);

    final session = factory.create(
      save: restored,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    addTearDown(session.dispose);

    final totals = session.playerDataService.getStatTotals(restored.playerData);
    // nothing is equipped on a new game, so the stat is the level alone
    expect(totals[SkillId.ATTACK], 5);

    session.settingsController.setMaxSkillLevel(null);
    expect(
      session.playerDataService.getStatTotals(
        restored.playerData,
      )[SkillId.ATTACK],
      30,
    );
  });

  test('malformed debug settings fall back to no cap', () {
    expect(DebugSettings.fromJson({'maxSkillLevel': 'x'}).maxSkillLevel, null);
    expect(DebugSettings.fromJson({'maxSkillLevel': 0}).maxSkillLevel, null);
  });
}
