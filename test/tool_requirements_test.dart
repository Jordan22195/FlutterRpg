import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// Trees want an axe, ore a pickaxe, and fishing spots a rod: without the
// tool equipped the action will not start, will not land a swing, and
// settles nothing offline. Herbs are picked by hand and fights use the
// weapon slots, so neither asks for a tool.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  /// Puts one [id] in the player's zone and makes it the encounter.
  EncounterEntity encounterWith(GameSession session, EntityId id) {
    final save = session.saveGameData;
    session.explorationService.addEntityToCurrentZone(
      id,
      5,
      save.playerData,
      save.worldData,
    );
    final entity =
        session.explorationService.getEntity(
              id,
              save.playerData.currentZoneId,
              save.worldData,
            )
            as EncounterEntity;
    session.encounterService.setEncounterEntity(save.encounterData, entity);
    return entity;
  }

  void equip(GameSession session, SkillId skill, ItemId tool) {
    session.saveGameData.playerData.equipmentData.equipedTools[skill] =
        EquipmentItem(id: tool);
  }

  // a stretch of swings or casts, settled the way time away is
  EncounterActionResult work(GameSession session, EntityId id) {
    final save = session.saveGameData;
    if (id.definition is FishingEntityDefinition) {
      return session.encounterSystem.executeFishingAction(
        playerState: save.playerData,
        encounter: save.encounterData,
        world: save.worldData,
        playerInventory: save.inventoryData,
        actionCount: 200,
        offline: true,
      );
    }
    return session.encounterSystem.executePlayerAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      worldState: save.worldData,
      playerInventory: save.inventoryData,
      actionCount: 200,
      offline: true,
      span: const Duration(minutes: 10),
    );
  }

  const cases = [
    (EntityId.TREE, SkillId.WOODCUTTING, ItemId.STONE_AXE),
    (EntityId.COPPER, SkillId.MINING, ItemId.STONE_PICKAXE),
    (EntityId.TRANQUIL_POND, SkillId.FISHING, ItemId.SIMPLE_FISHING_ROD),
  ];

  for (final (node, skill, tool) in cases) {
    group('${node.name} wants ${tool.name}', () {
      test('bare-handed, it will not start and works nothing', () {
        final session = buildSession();
        final entity = encounterWith(session, node);
        final player = session.saveGameData.playerData;

        expect(session.encounterSystem.requiredToolSkill(node), skill);
        expect(session.encounterSystem.hasRequiredTool(player, node), isFalse);
        expect(session.worldController.missingToolFor(node), skill);
        expect(
          session.encounterController.startEncounterActionFor(entity),
          isFalse,
        );

        final result = work(session, node);
        expect(result.actionsPerformed, 0);
        expect(result.items, isEmpty);

        session.actionTimingController.stop();
        session.dispose();
      });

      test('with the tool in hand, it starts and pays out', () {
        final session = buildSession();
        equip(session, skill, tool);
        final entity = encounterWith(session, node);

        expect(session.worldController.missingToolFor(node), isNull);
        expect(
          session.encounterController.startEncounterActionFor(entity),
          isTrue,
        );
        session.actionTimingController.stop();

        encounterWith(session, node);
        final result = work(session, node);
        expect(result.actionsPerformed, greaterThan(0));
        expect(result.items, isNotEmpty);

        session.dispose();
      });
    });
  }

  test('a tool for one skill does not open another', () {
    final session = buildSession();
    // an axe in hand, and a copper vein in front of you
    equip(session, SkillId.WOODCUTTING, ItemId.STONE_AXE);
    final ore = encounterWith(session, EntityId.COPPER);

    expect(session.encounterController.startEncounterActionFor(ore), isFalse);

    session.actionTimingController.stop();
    session.dispose();
  });

  test('herbs and fights ask for no tool', () {
    final session = buildSession();
    final player = session.saveGameData.playerData;

    for (final id in [EntityId.GUAM, EntityId.CHICKEN]) {
      expect(session.encounterSystem.requiredToolSkill(id), isNull);
      expect(session.encounterSystem.hasRequiredTool(player, id), isTrue);
      expect(session.worldController.missingToolFor(id), isNull);
    }

    // a chicken is fought bare-handed as it always was
    final chicken = encounterWith(session, EntityId.CHICKEN);
    expect(
      session.encounterController.startEncounterActionFor(chicken),
      isTrue,
    );

    session.actionTimingController.stop();
    session.dispose();
  });
}
