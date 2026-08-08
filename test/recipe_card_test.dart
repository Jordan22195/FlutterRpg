import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/recipe_card.dart';

// Renders a single RecipeCard through the real provider tree, so what the
// card shows comes from live inventory and skill state.
void main() {
  late GameSession session;
  late SaveGameData save;

  Future<void> pumpCard(
    WidgetTester tester, {
    required String recipeId,
    required bool lockWhenUnderLevel,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<GameSession>.value(value: session),
          ChangeNotifierProvider<CraftingController>.value(
            value: session.craftingController,
          ),
          ChangeNotifierProvider<InventoryController>.value(
            value: session.inventoryController,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RecipeCard(
              recipeId: recipeId,
              lockWhenUnderLevel: lockWhenUnderLevel,
              onTap: onTap ?? () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    save = factory.newGame(catalogs);
    session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );

    ItemCatalog.init();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
    EnumImageProviderLookup.register<EntityId>(
      session.catalogBundle.entityCatalog.imageProviderFor,
    );

    save.playerData.currentEntityViewId = EntityId.FIREPIT;
  });

  tearDown(() => session.dispose());

  void setLevel(SkillId skill, int level) {
    final data = save.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  Color? cardBorderColor(WidgetTester tester) {
    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    return shape.side.style == BorderStyle.none ? null : shape.side.color;
  }

  testWidgets('an under-levelled recipe locks and refuses the tap', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 1);
    save.inventoryData.itemMap[ItemId.LOGS] = 100;

    var taps = 0;
    // bonfire needs firemaking 15
    await pumpCard(
      tester,
      recipeId: 'bonfire',
      lockWhenUnderLevel: true,
      onTap: () => taps++,
    );

    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tester.tap(find.byType(RecipeCard));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('a met level requirement leaves the recipe selectable', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    save.inventoryData.itemMap[ItemId.LOGS] = 100;

    var taps = 0;
    await pumpCard(
      tester,
      recipeId: 'bonfire',
      lockWhenUnderLevel: true,
      onTap: () => taps++,
    );

    expect(find.byIcon(Icons.lock), findsNothing);

    await tester.tap(find.byType(RecipeCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('the selected-recipe card never locks, so the picker stays '
      'reachable', (tester) async {
    setLevel(SkillId.FIREMAKING, 1);

    var taps = 0;
    await pumpCard(
      tester,
      recipeId: 'bonfire',
      lockWhenUnderLevel: false,
      onTap: () => taps++,
    );

    expect(find.byIcon(Icons.lock), findsNothing);

    await tester.tap(find.byType(RecipeCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('missing materials flag the card and the short input red', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    // cookfire costs 2 logs
    save.inventoryData.itemMap[ItemId.LOGS] = 1;

    var taps = 0;
    await pumpCard(
      tester,
      recipeId: 'cookfire',
      lockWhenUnderLevel: true,
      onTap: () => taps++,
    );

    final error = ThemeData().colorScheme.error;
    expect(cardBorderColor(tester), error);

    // the input tile itself is flagged
    final logsTile = tester.widget<ItemStackTile>(
      find.byWidgetPredicate((w) => w is ItemStackTile && w.id == ItemId.LOGS),
    );
    expect(logsTile.borderColor, error);

    // a shortfall is fixable, so the recipe is still selectable
    await tester.tap(find.byType(RecipeCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('enough materials leave the card unflagged', (tester) async {
    setLevel(SkillId.FIREMAKING, 20);
    save.inventoryData.itemMap[ItemId.LOGS] = 10;

    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    expect(cardBorderColor(tester), isNull);

    final logsTile = tester.widget<ItemStackTile>(
      find.byWidgetPredicate((w) => w is ItemStackTile && w.id == ItemId.LOGS),
    );
    expect(logsTile.borderColor, isNull);
  });

  testWidgets('output counts the crafts, inputs count what one craft costs', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    // 10 logs at 2 per cookfire is 5 crafts
    save.inventoryData.itemMap[ItemId.LOGS] = 10;

    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    final output = tester.widget<ItemStackTile>(
      find.byWidgetPredicate(
        (w) => w is ItemStackTile && w.id == ItemId.COOKFIRE,
      ),
    );
    expect(output.count, 5);
    expect(output.depleted, isFalse);

    final logs = tester.widget<ItemStackTile>(
      find.byWidgetPredicate((w) => w is ItemStackTile && w.id == ItemId.LOGS),
    );
    expect(logs.count, 2);

    // and both numbers are actually painted
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('nothing craftable shows a depleted zero on the output', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    save.inventoryData.itemMap[ItemId.LOGS] = 0;

    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    final output = tester.widget<ItemStackTile>(
      find.byWidgetPredicate(
        (w) => w is ItemStackTile && w.id == ItemId.COOKFIRE,
      ),
    );
    expect(output.count, 0);
    expect(output.depleted, isTrue);
    expect(find.text('0'), findsOneWidget);
  });
}
