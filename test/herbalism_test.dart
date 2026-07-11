import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/player_data.dart';
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

  test('picking an herb yields 1-5 herbs, xp, and consumes one count', () {
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

    final xpBefore = save.playerData.skillData[SkillId.HERBALISM]!.xp;
    final result = session.encounterSystem.executeHerbalismAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      worldState: save.worldData,
      playerInventory: save.inventoryData,
    );

    final gathered = result.items.single;
    expect(gathered.id, ItemId.GUAM_LEAF);
    expect(gathered.count, inInclusiveRange(1, 5));
    expect(
      session.inventoryService.getItemCount(
        save.inventoryData,
        ItemId.GUAM_LEAF,
      ),
      gathered.count,
    );

    // one pick, one herb gone from the patch of 3
    expect(herb.count, 2);

    expect(
      save.playerData.skillData[SkillId.HERBALISM]!.xp,
      greaterThan(xpBefore),
    );

    session.dispose();
  });

  test('a depleted herb node is removed from the zone', () {
    final session = buildSession();
    final save = session.saveGameData;

    session.worldService.addEntityToCurrentZone(
      EntityId.GUAM,
      1,
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

    session.encounterSystem.executeHerbalismAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      worldState: save.worldData,
      playerInventory: save.inventoryData,
    );

    expect(herb.count, 0);
    expect(
      session.worldService
          .getEntity(
            EntityId.GUAM,
            save.playerData.currentZoneId,
            save.worldData,
          )
          .id,
      EntityId.NULL,
    );

    session.dispose();
  });

  test('herbs above the herbalism level cannot be picked', () {
    final session = buildSession();
    final save = session.saveGameData;

    session.worldService.addEntityToCurrentZone(
      EntityId.TORSTOL,
      3,
      session.catalogBundle.entityCatalog,
      save.playerData,
      save.worldData,
    );
    final herb =
        session.worldService.getEntity(
              EntityId.TORSTOL,
              save.playerData.currentZoneId,
              save.worldData,
            )
            as EncounterEntity;

    expect(session.encounterSystem.herbRequiredLevel(EntityId.TORSTOL), 75);
    expect(
      session.encounterSystem.meetsHerbRequirement(
        save.playerData,
        EntityId.TORSTOL,
      ),
      isFalse,
    );

    // the action refuses to start on a locked herb
    expect(session.encounterController.startEncounterActionFor(herb), isFalse);

    // and a forced tick gathers nothing
    session.encounterService.setEncounterEntity(save.encounterData, herb);
    final result = session.encounterSystem.executeHerbalismAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      worldState: save.worldData,
      playerInventory: save.inventoryData,
    );
    expect(result.items, isEmpty);
    expect(herb.count, 3);

    session.dispose();
  });

  test('yield stays in 1-5 and grows as herbalism outscales difficulty', () {
    final service = buildSession().encounterService;
    final rng = Random(42);

    var outmatchedTotal = 0;
    var dominantTotal = 0;
    const samples = 300;
    for (var i = 0; i < samples; i++) {
      final outmatched = service.rollHerbYield(
        herbalismStat: 1,
        defence: 75,
        rng: rng,
      );
      final dominant = service.rollHerbYield(
        herbalismStat: 99,
        defence: 1,
        rng: rng,
      );
      expect(outmatched, inInclusiveRange(1, 5));
      expect(dominant, inInclusiveRange(1, 5));
      outmatchedTotal += outmatched;
      dominantTotal += dominant;
    }

    // ~5% bonus chance vs ~95%: averages near 1.2 and 4.8
    expect(outmatchedTotal / samples, lessThan(2.0));
    expect(dominantTotal / samples, greaterThan(4.0));
  });

  test('saves with the old FORAGING skill load as HERBALISM', () {
    final session = buildSession();
    final save = session.saveGameData;
    save.playerData.skillData[SkillId.HERBALISM]!.xp = 1234;

    final json = save.playerData.toJson();
    final skillJson = json['skillData'] as Map<String, dynamic>;
    skillJson['FORAGING'] = skillJson.remove('HERBALISM');

    final loaded = PlayerData.fromJson(json);
    expect(loaded.skillData[SkillId.HERBALISM]!.xp, 1234);

    session.dispose();
  });
}
