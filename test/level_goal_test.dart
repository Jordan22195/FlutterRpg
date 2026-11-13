import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// the skill detail screen's level goal divides the xp left by what one
// action pays, which applyXp notes on the skill.
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

  test('a skill has no action xp until it has paid out', () {
    final session = buildSession();
    expect(
      session.playerDataController.getLastActionXp(SkillId.MINING),
      isNull,
    );
    session.dispose();
  });

  test('action xp is the last action paid, not a sum', () {
    final session = buildSession();
    final save = session.saveGameData;
    final service = session.playerDataService;

    service.applyXp(save.playerData, {SkillId.MINING: 10});
    service.applyXp(save.playerData, {SkillId.MINING: 4});

    expect(session.playerDataController.getLastActionXp(SkillId.MINING), 4);
    session.dispose();
  });

  test('combat skills average over hits', () {
    final session = buildSession();
    final save = session.saveGameData;
    final service = session.playerDataService;

    service.applyXp(save.playerData, {SkillId.ATTACK: 10});
    service.applyXp(save.playerData, {SkillId.ATTACK: 30});

    final avg = session.playerDataController.getLastActionXp(SkillId.ATTACK)!;
    expect(avg, greaterThan(10));
    expect(avg, lessThan(30));
    session.dispose();
  });

  test('trickle xp is not an action', () {
    final session = buildSession();
    final save = session.saveGameData;
    session.playerDataService.applyXp(save.playerData, {
      SkillId.STAMINA: 0.02,
    }, isAction: false);

    expect(
      session.playerDataController.getLastActionXp(SkillId.STAMINA),
      isNull,
    );
    session.dispose();
  });

  test('xp at a level is the table entry, and survives a save', () {
    final session = buildSession();
    final controller = session.playerDataController;
    expect(controller.getXpAtLevel(SkillId.MINING, 1), 0);
    expect(
      controller.getXpAtLevel(SkillId.MINING, 99),
      greaterThan(controller.getXpAtLevel(SkillId.MINING, 98)),
    );

    final skill = SkillData(name: 'x', xp: 5, lastActionXp: 2.5);
    expect(SkillData.fromJson(skill.toJson()).lastActionXp, 2.5);
    skill.goalLevel = 42;
    expect(SkillData.fromJson(skill.toJson()).goalLevel, 42);
    // saves from the old tracker still load
    expect(
      SkillData.fromJson({
        'name': 'x',
        'xp': 5,
        'trackerStartTime': '2026-01-01T00:00:00.000',
        'trackerStartXp': 1,
      }).lastActionXp,
      isNull,
    );
    session.dispose();
  });

  test('the goal is remembered per skill and unset by default', () {
    final session = buildSession();
    final controller = session.playerDataController;
    expect(controller.getGoalLevel(SkillId.MINING), isNull);

    var notified = 0;
    controller.addListener(() => notified++);
    controller.setGoalLevel(SkillId.MINING, 50);

    expect(controller.getGoalLevel(SkillId.MINING), 50);
    expect(controller.getGoalLevel(SkillId.FISHING), isNull);
    expect(notified, greaterThan(0));
    session.dispose();
  });
}
