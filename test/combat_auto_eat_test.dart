import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/data/combat_tuning.dart';

import 'package:rpg/catalogs/items/items.dart';
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

  // new game: hitpoints level 10 => max hp 30, so 75% is 22.5
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
    // hitpoints level 10, at the shared rate per point
    final maxHp = session.playerDataService.maxHitpoints(player);
    expect(maxHp, 10 * hitpointsPerStatPoint);

    // 80% -> no eat
    player.hitpoints = (maxHp * 0.8).round();
    expect(
      session.encounterSystem.autoEat(
        playerState: player,
        playerInventory: session.saveGameData.inventoryData,
      ),
      isFalse,
    );
    expect(
      session.inventoryService.getItemCount(
        session.saveGameData.inventoryData,
        ItemId.COOKED_CHICKEN,
      ),
      5,
    );

    // 70% (<=75%) -> eats one and heals
    final low = (maxHp * 0.7).round();
    player.hitpoints = low;
    expect(
      session.encounterSystem.autoEat(
        playerState: player,
        playerInventory: session.saveGameData.inventoryData,
      ),
      isTrue,
    );
    expect(player.hitpoints, greaterThan(low));
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
    expect(
      session.encounterSystem.autoEat(
        playerState: player,
        playerInventory: session.saveGameData.inventoryData,
      ),
      isFalse,
    );
    session.dispose();
  });

  // dungeon cards run through the encounter loop, so they get this rule by
  // construction rather than through a second implementation — which is
  // what the two assertions above already cover.

  group('when a stack runs out', () {
    // bag: two foods above, one beside and one below the chicken (4):
    // shark 35, beef 5, trout 5, chicken 4, minnow 1
    void stock(GameSession session, Map<ItemId, int> counts) {
      for (final entry in counts.entries) {
        session.inventoryService.setItemCount(
          session.saveGameData.inventoryData,
          entry.key,
          entry.value,
        );
      }
    }

    ItemId equipped(GameSession session) =>
        session.saveGameData.playerData.equipmentData.equipedFood;

    /// Auto-eats one, from low enough that it will.
    void eatOne(GameSession session) {
      final player = session.saveGameData.playerData;
      player.hitpoints = 1;
      expect(
        session.encounterSystem.autoEat(
          playerState: player,
          playerInventory: session.saveGameData.inventoryData,
        ),
        isTrue,
      );
    }

    test('the food list runs most healing first, ties by name', () {
      final session = buildSession();
      stock(session, {
        ItemId.COOKED_MINNOW: 1,
        ItemId.COOKED_TROUT: 1,
        ItemId.COOKED_SHARK: 1,
        ItemId.COOKED_CHICKEN: 1,
        ItemId.COOKED_BEEF: 1,
      });
      expect(session.inventoryController.getFoodItems(), [
        ItemId.COOKED_SHARK,
        ItemId.COOKED_BEEF,
        ItemId.COOKED_TROUT,
        ItemId.COOKED_CHICKEN,
        ItemId.COOKED_MINNOW,
      ]);
      session.dispose();
    });

    test('auto-eat moves on to the next food down the list', () {
      final session = buildSession();
      stock(session, {
        ItemId.COOKED_SHARK: 3,
        ItemId.COOKED_CHICKEN: 1,
        ItemId.COOKED_MINNOW: 3,
      });
      session.saveGameData.playerData.equipmentData.equipedFood =
          ItemId.COOKED_CHICKEN;

      eatOne(session);
      // the last chicken went: minnow heals less, so it is next
      expect(equipped(session), ItemId.COOKED_MINNOW);
      session.dispose();
    });

    test('a tie is next in the list, not skipped', () {
      final session = buildSession();
      stock(session, {
        ItemId.COOKED_BEEF: 1,
        ItemId.COOKED_TROUT: 2,
        ItemId.COOKED_CHICKEN: 2,
      });
      session.saveGameData.playerData.equipmentData.equipedFood =
          ItemId.COOKED_BEEF;

      eatOne(session);
      // beef and trout both heal 5; trout is listed after beef
      expect(equipped(session), ItemId.COOKED_TROUT);
      session.dispose();
    });

    test('the least healing food wraps back to the top', () {
      final session = buildSession();
      stock(session, {
        ItemId.COOKED_SHARK: 2,
        ItemId.COOKED_CHICKEN: 2,
        ItemId.COOKED_MINNOW: 1,
      });
      session.saveGameData.playerData.equipmentData.equipedFood =
          ItemId.COOKED_MINNOW;

      eatOne(session);
      // nothing heals less than a minnow, so the best food is next
      expect(equipped(session), ItemId.COOKED_SHARK);
      session.dispose();
    });

    test('a stack with food left is not switched off', () {
      final session = buildSession();
      stock(session, {ItemId.COOKED_SHARK: 2, ItemId.COOKED_CHICKEN: 3});
      session.saveGameData.playerData.equipmentData.equipedFood =
          ItemId.COOKED_CHICKEN;

      eatOne(session);
      expect(equipped(session), ItemId.COOKED_CHICKEN);
      session.dispose();
    });

    test('with nothing else to eat, the spent food stays selected', () {
      final session = buildSession();
      stock(session, {ItemId.COOKED_CHICKEN: 1});
      session.saveGameData.playerData.equipmentData.equipedFood =
          ItemId.COOKED_CHICKEN;

      eatOne(session);
      expect(equipped(session), ItemId.COOKED_CHICKEN);
      session.dispose();
    });

    test('the eat button moves on too', () {
      final session = buildSession();
      stock(session, {ItemId.COOKED_CHICKEN: 1, ItemId.COOKED_MINNOW: 2});
      final player = session.saveGameData.playerData;
      player.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;
      player.hitpoints = 1;

      expect(
        session.encounterSystem.eatEquipedFood(
          playerState: player,
          playerInventory: session.saveGameData.inventoryData,
        ),
        isTrue,
      );
      expect(equipped(session), ItemId.COOKED_MINNOW);
      session.dispose();
    });
  });
}
