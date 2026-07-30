import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// the skills grid and the skill detail screen read xp through
// PlayerDataController, but xp is awarded by the encounter, crafting,
// dungeon and enchanting domains. these cover the wiring that keeps those
// readouts live.
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

  test('gathering xp notifies player data listeners', () {
    final session = buildSession();
    final save = session.saveGameData;

    session.worldService.addEntityToCurrentZone(
      EntityId.GUAM,
      3,
      session.catalogBundle.entityCatalog,
      save.playerData,
      save.worldData,
    );
    final herb =
        session.worldService.getEntity(
              EntityId.GUAM,
              save.playerData.currentZoneId,
              save.worldData,
            )
            as EncounterEntity;
    session.encounterService.setEncounterEntity(save.encounterData, herb);

    var notifications = 0;
    session.playerDataController.addListener(() => notifications++);

    final xpBefore = session.playerDataController.getSkillXp(SkillId.HERBALISM);
    session.encounterController.doHerbalismEncounterAction();

    expect(
      session.playerDataController.getSkillXp(SkillId.HERBALISM),
      greaterThan(xpBefore),
    );
    expect(notifications, greaterThan(0));

    session.dispose();
  });

  test('equipment changes notify player data listeners', () {
    final session = buildSession();

    var notifications = 0;
    session.playerDataController.addListener(() => notifications++);

    // equipment feeds stat totals (max stamina, hitpoints), so the readouts
    // have to rebuild on a gear change too
    session.equipmentController.unequipSlot(ArmorSlots.WEAPON_1H);

    expect(notifications, greaterThan(0));

    session.dispose();
  });

  testWidgets('the heartbeat republishes player data every second', (
    tester,
  ) async {
    final session = buildSession();
    final controller = session.playerDataController;

    // stamina starts full on a new game, so the ambient recovery tick is a
    // no-op. the heartbeat still has to notify: it is what keeps the xp
    // trackers' clock and the xp the action loop awards continuously
    // showing up on screen
    expect(controller.getStamina(), controller.getMaxStamina());

    var notifications = 0;
    controller.addListener(() => notifications++);

    await tester.pump(const Duration(seconds: 1));

    expect(notifications, greaterThan(0));

    session.dispose();
  });
}
