import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/action_result.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// A crafting tick settles [count] crafts at once: one during normal play, and
// however many the player was away for when the loop catches up on offline
// progress. These cover what a batch has to pay out to be worth the same as
// the crafts it stands in for.
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

  void setLevel(GameSession session, SkillId skill, int level) {
    final data = session.saveGameData.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  double xpFor(GameSession session, SkillId skill) =>
      session.saveGameData.playerData.skillData[skill]!.xp;

  // runs one crafting tick of [recipeId] settling [craftCount] crafts
  EncounterActionResult craft(
    GameSession session,
    String recipeId, {
    int craftCount = 1,
    EntityId station = EntityId.ANVIL,
  }) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = station;
    save.craftingState.craftingZoneId = save.playerData.currentZoneId;
    save.craftingState.activeRecipeId = recipeId;
    return session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
      craftCount: craftCount,
    );
  }

  group('craftActiveRecipe in batch', () {
    test('pays the inputs, output and xp of every craft it settles', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 200;
      final xpBefore = xpFor(session, SkillId.BLACKSMITHING);

      final result = craft(session, 'smelt_copper_bar', craftCount: 50);

      // 50 ore in, 50 bars out, and 50 crafts' worth of xp - the recipe
      // pays 5 an ore
      expect(save.inventoryData.itemMap[ItemId.COPPER_ORE], 150);
      expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], 50);
      expect(xpFor(session, SkillId.BLACKSMITHING), xpBefore + 5 * 50);
      expect(result.xp[SkillId.BLACKSMITHING], 5 * 50);
      expect(
        result.items.fold<int>(0, (sum, stack) => sum + stack.count),
        50,
      );
    });

    test('stops at the materials on hand rather than crafting on credit', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 3;
      final xpBefore = xpFor(session, SkillId.BLACKSMITHING);

      final result = craft(session, 'smelt_copper_bar', craftCount: 500);

      expect(save.inventoryData.itemMap[ItemId.COPPER_ORE], isNull);
      expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], 3);
      expect(xpFor(session, SkillId.BLACKSMITHING), xpBefore + 5 * 3);
      expect(result.xp[SkillId.BLACKSMITHING], 5 * 3);
    });

    test('with nothing to craft with, changes nothing', () {
      final session = buildSession();
      final xpBefore = xpFor(session, SkillId.BLACKSMITHING);

      final result = craft(session, 'smelt_copper_bar', craftCount: 500);

      expect(result.items, isEmpty);
      expect(result.xp, isEmpty);
      expect(xpFor(session, SkillId.BLACKSMITHING), xpBefore);
    });

    test('a recipe over the player level crafts nothing', () {
      final session = buildSession();
      final save = session.saveGameData;
      // iron smelting needs blacksmithing 10; a fresh player is level 1
      save.inventoryData.itemMap[ItemId.IRON_ORE] = 200;

      final result = craft(session, 'smelt_iron_bar', craftCount: 50);

      expect(result.items, isEmpty);
      expect(save.inventoryData.itemMap[ItemId.IRON_ORE], 200);
    });

    test('rolls a quality for every piece of equipment in the batch', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.BLACKSMITHING, 16);
      save.inventoryData.itemMap[ItemId.COPPER_BAR] = 100;

      final result = craft(session, 'forge_copper_dagger', craftCount: 100);

      // 100 daggers, stacked by quality in the player's inventory, the
      // session grid and the result alike
      int total(Iterable<EquipmentItem> stacks) =>
          stacks.fold<int>(0, (sum, stack) => sum + stack.count);

      expect(total(save.inventoryData.equipment), 100);
      expect(total(save.craftingState.craftedItems.equipment), 100);
      expect(total(result.equipment), 100);
      expect(
        save.inventoryData.equipment.length,
        lessThanOrEqualTo(ItemQuality.values.length),
      );
      // ~30% of pieces are above common at this level, so a batch of 100
      // virtually guarantees a spread rather than one flat stack
      expect(
        total(
          save.inventoryData.equipment.where(
            (e) => e.quality != ItemQuality.COMMON,
          ),
        ),
        greaterThan(0),
      );
      // the pieces handed to each inventory are separate instances, or a
      // stack merge in one would be felt in the other
      expect(
        save.inventoryData.equipment.first.instanceId,
        isNot(save.craftingState.craftedItems.equipment.first.instanceId),
      );
    });

    test('a batch of fires is worth the whole batch of burn time', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.FIREMAKING, 10);
      save.inventoryData.itemMap[ItemId.LOGS] = 200;

      // a cookfire is 2 logs for 3 minutes of fire
      craft(
        session,
        'cookfire',
        craftCount: 10,
        station: EntityId.FIREPIT,
      );

      final fire = session.firemakingSystem.activeFire(
        EntityId.FIREPIT,
        save.playerData.currentZoneId,
        save.playerData.buffData,
      );

      expect(fire, isNotNull);
      final burning = fire!.expirationTime.difference(DateTime.now());
      expect(burning.inMinutes, closeTo(30, 1));
      expect(save.inventoryData.itemMap[ItemId.LOGS], 180);
    });

    test('a single craft still rolls one craft', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 10;

      craft(session, 'smelt_copper_bar');

      expect(save.inventoryData.itemMap[ItemId.COPPER_ORE], 9);
      expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], 1);
    });
  });

  group('settling time away', () {
    // puts [seconds] of wall clock between the player's last action and the
    // instant handed to the timing system, without actually waiting
    DateTime goOffline(GameSession session, double seconds) {
      final now = DateTime.now();
      session.saveGameData.playerData.lastActionTime = now.subtract(
        Duration(microseconds: (seconds * 1e6).round()),
      );
      return now;
    }

    test('a gap away crafts and reports what the loop would have', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 200;

      expect(
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      // 60s away at the 3s bench interval is 20 crafts
      final now = goOffline(session, 60);
      session.actionTimingSystem.offlineProgressUpdate(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      expect(save.inventoryData.itemMap[ItemId.COPPER_ORE], 180);
      expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], 20);

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      expect(report!.actionCount, 20);
      expect(report.items.itemMap[ItemId.COPPER_BAR], 20);
      expect(report.xp[SkillId.BLACKSMITHING], 5 * 20);

      session.actionTimingController.stop();
      session.dispose();
    });

    test('the report carries a batch of equipment as a stack, not one', () {
      final session = buildSession();
      final save = session.saveGameData;
      setLevel(session, SkillId.BLACKSMITHING, 16);
      save.inventoryData.itemMap[ItemId.COPPER_BAR] = 200;

      expect(
        session.craftingController.startCraftingActionFor(
          'forge_copper_dagger',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      final now = goOffline(session, 60);
      session.actionTimingSystem.offlineProgressUpdate(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      final report = session.actionTimingController.pendingOfflineReport;
      expect(report, isNotNull);
      expect(
        report!.items.equipment.fold<int>(0, (sum, e) => sum + e.count),
        20,
      );

      session.actionTimingController.stop();
      session.dispose();
    });

    test('running out of materials while away stops the loop', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COPPER_ORE] = 5;

      expect(
        session.craftingController.startCraftingActionFor(
          'smelt_copper_bar',
          EntityId.ANVIL,
        ),
        isTrue,
      );

      // an hour away is far more crafts than the ore can pay for
      final now = goOffline(session, 3600);
      session.actionTimingSystem.offlineProgressUpdate(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      expect(save.inventoryData.itemMap[ItemId.COPPER_BAR], 5);
      expect(session.actionTimingController.isRunning, isFalse);

      session.dispose();
    });
  });
}
