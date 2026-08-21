import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
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
    bool selected = false,
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
              selected: selected,
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

    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);

    save.playerData.currentEntityViewId = EntityId.FIREPIT;
  });

  tearDown(() => session.dispose());

  void setLevel(SkillId skill, int level) {
    final data = save.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  /// The card's own outline, or null when it carries none — which is now
  /// every case: the shortfall is flagged on the short input tile instead.
  Color? cardBorderColor(WidgetTester tester) {
    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape;
    if (shape is! RoundedRectangleBorder) return null;
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

    // the shortfall is marked on the short input alone, not on the card.
    // an explicit red, not the scheme's error colour, which is a pale pink
    // on a dark theme
    expect(cardBorderColor(tester), isNull);

    final logsTile = tester.widget<ItemStackTile>(
      find.byWidgetPredicate((w) => w is ItemStackTile && w.id == ItemId.LOGS),
    );
    expect(logsTile.borderColor, RecipeCard.missingMaterialColor);

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

  testWidgets('nothing craftable reads as depleted, with no zero badge', (
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
    // the darkened art is what says it is spent; a "0" badge would only
    // add noise on top of that
    expect(output.depleted, isTrue);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('only the picker marks the recipe already in play', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    save.inventoryData.itemMap[ItemId.LOGS] = 10;

    // the card that merely displays the selection is never marked: it is
    // always showing the selection, so a highlight would say nothing
    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);
    expect(cardBorderColor(tester), isNull);

    // a picker row for the recipe in play carries the mark
    await pumpCard(
      tester,
      recipeId: 'cookfire',
      lockWhenUnderLevel: true,
      selected: true,
    );
    expect(cardBorderColor(tester), ThemeData().colorScheme.primary);
  });
}
