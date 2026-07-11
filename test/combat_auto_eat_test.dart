import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/item_catalog.dart';
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

  // new game: hitpoints level 10 => max hp 10, so 75% is 7.5
  void equipFood(GameSession session, {int count = 5}) {
    session.inventoryService.setItemCount(
      session.saveGameData.inventoryData,
      ItemId.COOKED_CHICKEN,
      count,
    );
    session.saveGameData.playerData.equipmentData.equipedFood =
        ItemId.COOKED_CHICKEN;
  }

  test('eats at or below 75% hp, not above', () {
    final session = buildSession();
    final player = session.saveGameData.playerData;
    equipFood(session);
    expect(
      session.playerDataService.getStatTotals(player)[SkillId.HITPOINTS],
      10,
    );

    // 80% -> no eat
    player.hitpoints = 8;
    expect(session.encounterSystem.autoEat(
      playerState: player,
      playerInventory: session.saveGameData.inventoryData,
    ), isFalse);
    expect(
      session.inventoryService.getItemCount(
        session.saveGameData.inventoryData,
        ItemId.COOKED_CHICKEN,
      ),
      5,
    );

    // 70% (<=75%) -> eats one and heals
    player.hitpoints = 7;
    expect(session.encounterSystem.autoEat(
      playerState: player,
      playerInventory: session.saveGameData.inventoryData,
    ), isTrue);
    expect(player.hitpoints, greaterThan(7));
    expect(
      session.inventoryService.getItemCount(
        session.saveGameData.inventoryData,
        ItemId.COOKED_CHICKEN,
      ),
      4,
    );

    session.dispose();
  });

  test('no-op without equipped food', () {
    final session = buildSession();
    final player = session.saveGameData.playerData;
    player.hitpoints = 1;
    expect(session.encounterSystem.autoEat(
      playerState: player,
      playerInventory: session.saveGameData.inventoryData,
    ), isFalse);
    session.dispose();
  });

  test('dungeon and world combat share the same auto-eat rule', () {
    final session = buildSession();
    final player = session.saveGameData.playerData;
    equipFood(session);

    // both systems delegate to the shared service: eat at 70%
    player.hitpoints = 7;
    expect(session.dungeonSystem.autoEat(
      playerState: player,
      playerInventory: session.saveGameData.inventoryData,
    ), isTrue);

    session.dispose();
  });
}
