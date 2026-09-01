import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/countdown_timer.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

// The minor potion tier, end to end: what the six potions are, how they are
// brewed, and what drinking one does. The distinction that drives most of
// this is global-vs-zone — a potion buffs the player and travels with them,
// where a fire buffs the zone and stays behind.
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

  // the six, paired with the stat each is supposed to move
  const potionStats = <ItemId, SkillId>{
    ItemId.MINOR_SPEED_POTION: SkillId.SPEED,
    ItemId.MINOR_DEFENCE_POTION: SkillId.DEFENCE,
    ItemId.MINOR_STAMINA_POTION: SkillId.STAMINA,
    ItemId.MINOR_RECOVERY_POTION: SkillId.RECOVERY,
    ItemId.MINOR_ATTACK_POTION: SkillId.ATTACK,
    ItemId.MINOR_STRENGTH_POTION: SkillId.STRENGTH,
  };

  const newReagents = <ItemId>[
    ItemId.SCALE,
    ItemId.SILK,
    ItemId.CLAW,
    ItemId.VENOM,
  ];

  // runs one craft of [recipeId] at [station] through the real crafting path
  void craftAt(GameSession session, String recipeId, EntityId station) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = station;
    save.craftingState.activeRecipeId = recipeId;
    session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
    );
  }

  group('the potion catalog', () {
    test('every minor potion is a drinkable one-minute +1', () {
      potionStats.forEach((id, stat) {
        final definition = id.definition;
        expect(
          definition,
          isA<BuffItemDefinition>(),
          reason: '${id.name} must be a buff item',
        );
        // a fire is also a BuffItemDefinition; a potion must not be one of
        // those, or drinking a bonfire becomes possible
        expect(
          definition,
          isNot(isA<ZoneBuffItemDefinition>()),
          reason: '${id.name} must be a global buff, not a zone buff',
        );

        final buff = definition as BuffItemDefinition;
        expect(buff.duration, const Duration(minutes: 1));
        expect(buff.skillBonus, {
          stat: 1,
        }, reason: '${id.name} must be exactly +1 ${stat.name}');
      });
    });

    test('the new reagents are plain, sellable items', () {
      // deliberately says nothing about where they drop from: sources are
      // being filled in as the zones get them, and pinning that here would
      // just mean editing this test every time one lands
      for (final id in newReagents) {
        final definition = id.definition;
        expect(definition, isNot(isA<BuffItemDefinition>()));
        expect(definition, isNot(isA<EquipmentItemDefinition>()));
        expect(definition.value, greaterThan(0));
        expect(definition.name, isNotEmpty);
      }
    });

    test('build() hands back a mutable BuffItem with a live expiration', () {
      final potion = ItemId.MINOR_SPEED_POTION.build();
      expect(potion, isA<BuffItem>());
      expect(
        (potion as BuffItem).expirationTime.isAfter(DateTime.now()),
        isTrue,
      );

      // the const definition cannot be written through at all: the
      // instance reads its stats off the definition and hands them out
      // read-only, so there is nowhere for a divergent copy to live
      final definition =
          ItemId.MINOR_SPEED_POTION.definition as BuffItemDefinition;
      expect(potion.skillBonus, definition.skillBonus);
      expect(
        () => potion.skillBonus[SkillId.SPEED] = 99,
        throwsUnsupportedError,
      );
      expect(definition.skillBonus[SkillId.SPEED], 1);
    });
  });

  group('the alchemy recipes', () {
    test('six recipes, two per level tier, xp climbing with level', () {
      final recipes = RecipeCatalog().recipesForSkill(SkillId.ALCHEMY);
      expect(recipes.length, 6);
      expect(recipes.map((r) => r.levelRequirement).toList()..sort(), [
        1,
        1,
        5,
        5,
        10,
        10,
      ]);

      // every recipe at a higher tier is worth more than every recipe below
      for (final low in recipes) {
        for (final high in recipes) {
          if (high.levelRequirement <= low.levelRequirement) continue;
          expect(
            high.xp,
            greaterThan(low.xp),
            reason: '${high.id} is gated above ${low.id} but worth no more',
          );
        }
      }
    });

    test('every alchemy recipe is one guam leaf plus one reagent', () {
      final recipes = RecipeCatalog().recipesForSkill(SkillId.ALCHEMY);
      for (final recipe in recipes) {
        expect(recipe.inputs.length, 2, reason: recipe.id);
        expect(recipe.inputs[ItemId.GUAM_LEAF], 1, reason: recipe.id);
        expect(recipe.output.length, 1, reason: recipe.id);

        final produced = recipe.output.single.id;
        expect(potionStats.containsKey(produced), isTrue, reason: recipe.id);
        expect(recipe.output.single.count, 1);
        expect(recipe.output.single.weight, 1);
      }

      // each potion is brewed by exactly one recipe
      expect(
        recipes.map((r) => r.output.single.id).toSet(),
        potionStats.keys.toSet(),
      );
    });

    test('the alchemy station stands in the dev forest and crafts alchemy', () {
      final definition = EntityId.ALCHEMY_STATION.definition;
      expect(definition, isA<CraftingEntityDefinition>());
      expect(
        (definition as CraftingEntityDefinition).craftingSkill,
        SkillId.ALCHEMY,
      );
      expect(
        ZoneId.DEV_FOREST.definition.permanentEntities,
        contains(EntityId.ALCHEMY_STATION),
      );
    });

    test('brewing spends the inputs, yields the potion, and pays xp', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.GUAM_LEAF] = 5;
      save.inventoryData.itemMap[ItemId.FEATHER] = 5;
      final xpBefore = save.playerData.skillData[SkillId.ALCHEMY]!.xp;

      craftAt(session, 'alch_minor_speed_potion', EntityId.ALCHEMY_STATION);

      // a potion is an ordinary item: unlike firemaking, crafting one does
      // not put a buff up, it fills a stack
      expect(save.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION], 1);
      expect(save.inventoryData.itemMap[ItemId.GUAM_LEAF], 4);
      expect(save.inventoryData.itemMap[ItemId.FEATHER], 4);
      expect(save.playerData.buffData.globalBuffs, isEmpty);
      expect(save.playerData.skillData[SkillId.ALCHEMY]!.xp, xpBefore + 15);

      session.dispose();
    });

    test('a level-10 recipe is locked until alchemy reaches 10', () {
      final session = buildSession();
      final save = session.saveGameData;
      final alchemy = save.playerData.skillData[SkillId.ALCHEMY]!;

      expect(
        session.craftingController.meetsRecipeLevelRequirement(
          'alch_minor_strength_potion',
        ),
        isFalse,
      );

      alchemy.xp = alchemy.xpTable[10];
      expect(
        session.craftingController.meetsRecipeLevelRequirement(
          'alch_minor_strength_potion',
        ),
        isTrue,
      );

      session.dispose();
    });
  });

  group('drinking a potion', () {
    test('spends one and puts the stat up', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION] = 2;

      final before =
          session.playerDataService.getStatTotals(
            save.playerData,
          )[SkillId.SPEED] ??
          0;

      expect(
        session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION),
        isTrue,
      );

      expect(save.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION], 1);
      expect(
        save.playerData.buffData.globalBuffs.containsKey(
          ItemId.MINOR_SPEED_POTION,
        ),
        isTrue,
      );
      expect(
        session.playerDataService.getStatTotals(save.playerData)[SkillId.SPEED],
        before + 1,
      );

      session.dispose();
    });

    test('drinking with an empty stack changes nothing', () {
      final session = buildSession();
      final save = session.saveGameData;

      expect(
        session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION),
        isFalse,
      );
      expect(save.playerData.buffData.globalBuffs, isEmpty);
      expect(
        save.inventoryData.itemMap.containsKey(ItemId.MINOR_SPEED_POTION),
        isFalse,
      );

      session.dispose();
    });

    test('a fire is not drinkable even when held', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.COOKFIRE] = 1;

      expect(session.potionSystem.isDrinkable(ItemId.COOKFIRE), isFalse);
      expect(session.inventoryController.drinkPotion(ItemId.COOKFIRE), isFalse);
      expect(save.inventoryData.itemMap[ItemId.COOKFIRE], 1);
      expect(save.playerData.buffData.globalBuffs, isEmpty);

      // and nor is an ordinary item
      expect(session.potionSystem.isDrinkable(ItemId.LOGS), isFalse);

      session.dispose();
    });

    test('a second dose extends rather than restarts', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION] = 2;

      session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION);
      final firstExpiry = save
          .playerData
          .buffData
          .globalBuffs[ItemId.MINOR_SPEED_POTION]!
          .expirationTime;

      session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION);
      final secondExpiry = save
          .playerData
          .buffData
          .globalBuffs[ItemId.MINOR_SPEED_POTION]!
          .expirationTime;

      // one entry, running longer — not two entries, and not restarted
      expect(save.playerData.buffData.globalBuffs.length, 1);
      expect(secondExpiry.isAfter(firstExpiry), isTrue);
      expect(secondExpiry.difference(firstExpiry), const Duration(minutes: 1));
      expect(
        save.inventoryData.itemMap.containsKey(ItemId.MINOR_SPEED_POTION),
        isFalse,
      );

      session.dispose();
    });

    test('the buff lapses after its minute', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.MINOR_ATTACK_POTION] = 1;
      session.inventoryController.drinkPotion(ItemId.MINOR_ATTACK_POTION);

      final buffData = save.playerData.buffData;
      final zone = save.playerData.currentZoneId;
      final expiry =
          buffData.globalBuffs[ItemId.MINOR_ATTACK_POTION]!.expirationTime;

      expect(
        session.buffService.getBuffedStatTotal(
          buffData,
          zone,
          at: expiry.subtract(const Duration(seconds: 1)),
        )[SkillId.ATTACK],
        1,
      );
      expect(
        session.buffService.getBuffedStatTotal(
          buffData,
          zone,
          at: expiry.add(const Duration(seconds: 1)),
        )[SkillId.ATTACK],
        isNull,
      );

      session.buffService.checkBuffExpriations(
        buffData,
        at: expiry.add(const Duration(seconds: 1)),
      );
      expect(buffData.globalBuffs, isEmpty);

      session.dispose();
    });

    test('a potion buff travels between zones, where a fire would not', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.MINOR_STAMINA_POTION] = 1;
      session.inventoryController.drinkPotion(ItemId.MINOR_STAMINA_POTION);

      final here = save.playerData.currentZoneId;
      final elsewhere = ZoneId.values.firstWhere(
        (z) => z != here && z != ZoneId.NULL,
      );
      save.playerData.currentZoneId = elsewhere;

      expect(
        session.buffService.getBuffedStatTotal(
          save.playerData.buffData,
          elsewhere,
        )[SkillId.STAMINA],
        1,
      );

      session.dispose();
    });

    test('a potion buff survives a save round trip', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.MINOR_RECOVERY_POTION] = 1;
      session.inventoryController.drinkPotion(ItemId.MINOR_RECOVERY_POTION);

      final original =
          save.playerData.buffData.globalBuffs[ItemId.MINOR_RECOVERY_POTION]!;
      final restored = BuffData.fromJson(
        jsonDecode(jsonEncode(save.playerData.buffData.toJson()))
            as Map<String, dynamic>,
      );

      final buff = restored.globalBuffs[ItemId.MINOR_RECOVERY_POTION];
      expect(buff, isNotNull);
      expect(buff!.skillBonus, {SkillId.RECOVERY: 1});
      expect(buff.expirationTime, original.expirationTime);

      session.dispose();
    });
  });

  group('the item dialog', () {
    // BuffController ticks a periodic timer that never settles, so these use
    // fixed pumps rather than pumpAndSettle.
    Future<void> settle(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }

    Future<GameSession> pumpTile(
      WidgetTester tester,
      ItemId id, {
      int held = 0,
    }) async {
      final session = buildSession();
      session.saveGameData.inventoryData.itemMap[id] = held;

      registerCatalogIconResolvers();
      EnumImageProviderLookup.register<SkillId>(
        SkillController.imageProviderFor,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GameSession>.value(value: session),
            ChangeNotifierProvider<InventoryController>.value(
              value: session.inventoryController,
            ),
            ChangeNotifierProvider<BuffController>.value(
              value: session.buffController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ItemStackTile<ItemId>(size: 60, id: id, count: held),
            ),
          ),
        ),
      );
      await settle(tester);

      await tester.tap(find.byType(ItemStackTile<ItemId>));
      await settle(tester);
      return session;
    }

    testWidgets('a tap drinks one and leaves the dialog up', (tester) async {
      final session = await pumpTile(
        tester,
        ItemId.MINOR_SPEED_POTION,
        held: 2,
      );
      expect(find.text('Drink'), findsOneWidget);

      await tester.tap(find.text('Drink'));
      await settle(tester);

      final save = session.saveGameData;
      expect(save.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION], 1);
      expect(save.playerData.buffData.globalBuffs, isNotEmpty);
      // the dialog stays open on a drink, so the next one is one tap away
      expect(find.text('Drink'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      session.dispose();
    });

    testWidgets('the icon wears the held count, and it follows a drink', (
      tester,
    ) async {
      final session = await pumpTile(
        tester,
        ItemId.MINOR_SPEED_POTION,
        held: 3,
      );
      // scoped to the dialog, because the tile underneath wears a badge of
      // its own; and to Text rather than find.text, which would also match
      // the dev stack-count field's EditableText
      Finder badge(String count) => find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byWidgetPredicate((w) => w is Text && w.data == count),
      );

      expect(badge('3'), findsOneWidget);

      await tester.tap(find.text('Drink'));
      await settle(tester);
      expect(badge('3'), findsNothing);
      expect(badge('2'), findsOneWidget);

      session.dispose();
    });

    testWidgets('the icon wears no count for an item you do not hold', (
      tester,
    ) async {
      // a recipe's input tile opens this dialog too, and a badge there would
      // claim a stack the player has not got
      final session = await pumpTile(tester, ItemId.MINOR_SPEED_POTION);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byWidgetPredicate((w) => w is Text && w.data == '0'),
        ),
        findsNothing,
      );
      session.dispose();
    });

    testWidgets('the dialog shows how long is left, and it climbs', (
      tester,
    ) async {
      final session = await pumpTile(
        tester,
        ItemId.MINOR_SPEED_POTION,
        held: 2,
      );
      // nothing on the clock before the first drink
      expect(find.text(' left'), findsNothing);

      await tester.tap(find.text('Drink'));
      await settle(tester);
      expect(find.text(' left'), findsOneWidget);
      final firstShown = tester
          .widget<CountdownTimer>(find.byType(CountdownTimer))
          .expirationTime;

      // a second dose extends rather than restarts, and the readout follows
      await tester.tap(find.text('Drink'));
      await settle(tester);
      final secondShown = tester
          .widget<CountdownTimer>(find.byType(CountdownTimer))
          .expirationTime;

      expect(secondShown.difference(firstShown), const Duration(minutes: 1));
      // and it is the live buff being shown, not a recomputed guess
      expect(
        secondShown,
        session
            .saveGameData
            .playerData
            .buffData
            .globalBuffs[ItemId.MINOR_SPEED_POTION]!
            .expirationTime,
      );

      session.dispose();
    });

    testWidgets('the last drink retires the button, dialog still up', (
      tester,
    ) async {
      final session = await pumpTile(
        tester,
        ItemId.MINOR_SPEED_POTION,
        held: 1,
      );

      await tester.tap(find.text('Drink'));
      await settle(tester);

      expect(find.text('Drink'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
      expect(find.text(' left'), findsOneWidget);

      session.dispose();
    });

    testWidgets('holding Drink drinks repeatedly, and stops when the stack '
        'runs out', (tester) async {
      final session = await pumpTile(
        tester,
        ItemId.MINOR_SPEED_POTION,
        held: 4,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Drink')),
      );
      // past the long-press threshold the button fires once, then repeats
      // on its own interval for as long as it is held
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.up();
      await settle(tester);

      final save = session.saveGameData;
      // the whole stack went down in one hold, and the repeat no-ops rather
      // than throwing once there is nothing left to drink
      expect(
        save.inventoryData.itemMap.containsKey(ItemId.MINOR_SPEED_POTION),
        isFalse,
      );
      // one buff, extended four times over — not four buffs
      expect(save.playerData.buffData.globalBuffs.length, 1);
      final buff =
          save.playerData.buffData.globalBuffs[ItemId.MINOR_SPEED_POTION]!;
      expect(
        buff.expirationTime.difference(DateTime.now()),
        greaterThan(const Duration(minutes: 3, seconds: 30)),
      );
      expect(find.text('Drink'), findsNothing);

      session.dispose();
    });

    // the inventory grid's own corner, distinct from the dialog's readout
    testWidgets('the inventory tile counts an active potion down', (
      tester,
    ) async {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.MINOR_SPEED_POTION] = 2;
      save.inventoryData.itemMap[ItemId.LOGS] = 5;

      registerCatalogIconResolvers();
      EnumImageProviderLookup.register<SkillId>(
        SkillController.imageProviderFor,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<GameSession>.value(value: session),
            ChangeNotifierProvider<InventoryController>.value(
              value: session.inventoryController,
            ),
            ChangeNotifierProvider<BuffController>.value(
              value: session.buffController,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Consumer<InventoryController>(
                builder: (context, inventory, _) => InventoryGrid(
                  items: inventory.getObjectStackList(),
                  shrinkWrap: true,
                  showActiveBuffTimers: true,
                ),
              ),
            ),
          ),
        ),
      );
      await settle(tester);

      // nothing is running, so no corner timer on any tile
      expect(find.byType(CountdownTimer), findsNothing);

      session.inventoryController.drinkPotion(ItemId.MINOR_SPEED_POTION);
      await settle(tester);

      // exactly one: the potion's tile, not the logs beside it
      expect(find.byType(CountdownTimer), findsOneWidget);
      expect(
        tester.widget<CountdownTimer>(find.byType(CountdownTimer)).showIcon,
        isFalse,
      );

      // and it goes away with the buff
      session.buffService.checkBuffExpriations(
        save.playerData.buffData,
        at: DateTime.now().add(const Duration(minutes: 2)),
      );
      session.buffController.refresh();
      await settle(tester);
      expect(find.byType(CountdownTimer), findsNothing);

      session.dispose();
    });

    testWidgets('offers no Drink for a potion you do not hold', (tester) async {
      final session = await pumpTile(tester, ItemId.MINOR_SPEED_POTION);
      expect(find.text('Drink'), findsNothing);
      expect(find.text('Close'), findsOneWidget);
      session.dispose();
    });

    testWidgets('offers no Drink for an ordinary item', (tester) async {
      final session = await pumpTile(tester, ItemId.LOGS, held: 5);
      expect(find.text('Drink'), findsNothing);
      session.dispose();
    });

    // the one the ZoneBuffItemDefinition guard exists for: a fire is a buff
    // item too, and holding one must not make it a drink
    testWidgets('offers no Drink for a fire', (tester) async {
      final session = await pumpTile(tester, ItemId.COOKFIRE, held: 1);
      expect(find.text('Drink'), findsNothing);
      session.dispose();
    });
  });
}
