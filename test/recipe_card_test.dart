import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/zone_palette.dart';
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
          // the item details a tile opens read the buffs
          ChangeNotifierProvider<BuffController>.value(
            value: session.buffController,
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

    final logsTile = tester.widget<RecipeTile>(
      find.byWidgetPredicate((w) => w is RecipeTile && w.id == ItemId.LOGS),
    );
    expect(logsTile.borderColor, RecipeCard.missingMaterialColor);

    // a shortfall is fixable, so the recipe is still selectable
    await tester.tap(find.byType(RecipeCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('under its level, a recipe flags no missing ingredient', (
    tester,
  ) async {
    // bonfire needs firemaking 15, and there are no logs to burn
    setLevel(SkillId.FIREMAKING, 1);
    save.inventoryData.itemMap[ItemId.LOGS] = 0;

    // in the picker, where it locks, and as the station's own card, where
    // it does not: the level is what stands in the way, so no input is red
    for (final lock in [true, false]) {
      await pumpCard(tester, recipeId: 'bonfire', lockWhenUnderLevel: lock);
      final flagged = tester
          .widgetList<RecipeTile>(find.byType(RecipeTile))
          .where((tile) => tile.borderColor != null);
      expect(flagged, isEmpty, reason: 'lockWhenUnderLevel: $lock');
    }
  });

  testWidgets('enough materials leave the card unflagged', (tester) async {
    setLevel(SkillId.FIREMAKING, 20);
    save.inventoryData.itemMap[ItemId.LOGS] = 10;

    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    expect(cardBorderColor(tester), isNull);

    final logsTile = tester.widget<RecipeTile>(
      find.byWidgetPredicate((w) => w is RecipeTile && w.id == ItemId.LOGS),
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

    final output = tester.widget<RecipeTile>(
      find.byWidgetPredicate((w) => w is RecipeTile && w.id == ItemId.COOKFIRE),
    );
    expect(output.count, 5);
    expect(output.depleted, isFalse);

    final logs = tester.widget<RecipeTile>(
      find.byWidgetPredicate((w) => w is RecipeTile && w.id == ItemId.LOGS),
    );
    expect(logs.count, 2);

    // and both numbers are actually painted
    expect(find.text('5'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // read left to right: what it costs, then what it makes
    expect(
      tester
          .getTopLeft(
            find.byWidgetPredicate(
              (w) => w is RecipeTile && w.id == ItemId.LOGS,
            ),
          )
          .dx,
      lessThan(
        tester
            .getTopLeft(
              find.byWidgetPredicate(
                (w) => w is RecipeTile && w.id == ItemId.COOKFIRE,
              ),
            )
            .dx,
      ),
    );
  });

  testWidgets('nothing craftable reads as depleted, with no zero badge', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    save.inventoryData.itemMap[ItemId.LOGS] = 0;

    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    final output = tester.widget<RecipeTile>(
      find.byWidgetPredicate((w) => w is RecipeTile && w.id == ItemId.COOKFIRE),
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
    // outside a zone theme the meadow's palette stands in
    expect(cardBorderColor(tester), ZonePalette.meadow.text);
  });

  testWidgets('the level reads on its own, with no "Requires" before it', (
    tester,
  ) async {
    setLevel(SkillId.FIREMAKING, 20);
    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    final level = session.craftingController
        .getRecipe('cookfire')
        .levelRequirement;
    expect(find.text('Lv $level'), findsOneWidget);
    expect(find.text('Requires'), findsNothing);
  });

  testWidgets('the card says what one craft is worth in xp', (tester) async {
    setLevel(SkillId.FIREMAKING, 20);
    await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

    final xp = session.craftingController.getRecipe('cookfire').xp;
    final shown = xp == xp.roundToDouble()
        ? '${xp.round()}'
        : xp.toStringAsFixed(1);
    final label = find.textContaining('+$shown', findRichText: true);
    expect(label, findsOneWidget);

    // in the xp gold, as every xp number is
    final spans = <TextSpan>[];
    tester.widget<RichText>(label).text.visitChildren((span) {
      if (span is TextSpan) spans.add(span);
      return true;
    });
    final number = spans.firstWhere((span) => span.text == '+$shown');
    expect(number.style?.color, GameColors.standard.xp);
  });

  testWidgets('a cooked food on the card says how much it heals', (
    tester,
  ) async {
    save.inventoryData.itemMap[ItemId.CHICKEN_MEAT] = 5;
    await pumpCard(tester, recipeId: 'cook_chicken', lockWhenUnderLevel: true);

    Finder heartOn(ItemId id) => find.descendant(
      of: find.byWidgetPredicate((w) => w is RecipeTile && w.id == id),
      matching: find.byIcon(Icons.favorite),
    );
    final heal =
        (ItemId.COOKED_CHICKEN.definition as FoodItemDefinition).restoreAmount;

    // the cooked chicken it makes heals; the raw meat it costs does not
    expect(heartOn(ItemId.COOKED_CHICKEN), findsOneWidget);
    expect(
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is RecipeTile && w.id == ItemId.COOKED_CHICKEN,
        ),
        matching: find.text('$heal'),
      ),
      findsOneWidget,
    );
    expect(heartOn(ItemId.CHICKEN_MEAT), findsNothing);
  });

  group('taps', () {
    Finder tileOf(ItemId id) =>
        find.byWidgetPredicate((w) => w is RecipeTile && w.id == id);

    testWidgets('a tile opens its item\'s details, not the recipe', (
      tester,
    ) async {
      setLevel(SkillId.FIREMAKING, 20);
      save.inventoryData.itemMap[ItemId.LOGS] = 10;
      var taps = 0;
      await pumpCard(
        tester,
        recipeId: 'cookfire',
        lockWhenUnderLevel: true,
        onTap: () => taps++,
      );

      // the input
      await tester.tap(tileOf(ItemId.LOGS));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(ItemId.LOGS.definition.name),
        ),
        findsOneWidget,
      );
      expect(taps, 0);
      Navigator.of(tester.element(find.byType(AlertDialog))).pop();
      await tester.pump();

      // and the output
      await tester.tap(tileOf(ItemId.COOKFIRE));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(ItemId.COOKFIRE.definition.name),
        ),
        findsOneWidget,
      );
      expect(taps, 0);
    });

    testWidgets('the card around the tiles picks the recipe', (tester) async {
      setLevel(SkillId.FIREMAKING, 20);
      save.inventoryData.itemMap[ItemId.LOGS] = 10;
      var taps = 0;
      await pumpCard(
        tester,
        recipeId: 'cookfire',
        lockWhenUnderLevel: true,
        onTap: () => taps++,
      );

      // the level column is dead space as far as the tiles go
      await tester.tap(find.textContaining('Lv '));
      await tester.pump();
      expect(taps, 1);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a locked recipe still opens its items\' details', (
      tester,
    ) async {
      setLevel(SkillId.FIREMAKING, 1);
      var taps = 0;
      await pumpCard(
        tester,
        recipeId: 'cookfire',
        lockWhenUnderLevel: true,
        onTap: () => taps++,
      );

      await tester.tap(tileOf(ItemId.COOKFIRE));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(taps, 0);
    });

    testWidgets('a piece of equipment opens the equipment details', (
      tester,
    ) async {
      await pumpCard(
        tester,
        recipeId: 'forge_copper_dagger',
        lockWhenUnderLevel: false,
      );

      await tester.tap(tileOf(ItemId.COPPER_DAGGER));
      await tester.pump();
      // the equipment dialog titles the piece by its display name
      final piece = ItemId.COPPER_DAGGER.build() as EquipmentItem;
      expect(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text(piece.displayName),
        ),
        findsOneWidget,
      );
    });
  });

  group('the output wears its stats', () {
    Finder chipFor(SkillId skill) =>
        find.byWidgetPredicate((w) => w is BuffBadge && w.skill == skill);

    testWidgets('a fire says what it burns for', (tester) async {
      await pumpCard(tester, recipeId: 'cookfire', lockWhenUnderLevel: true);

      // the cookfire raises cooking and hitpoints: a chip for each, on the
      // fire's own tile
      final fire = (ItemId.COOKFIRE.definition as FireItemDefinition);
      for (final stat in fire.skillBonus.entries) {
        final chip = chipFor(stat.key);
        expect(chip, findsOneWidget, reason: stat.key.name);
        expect(
          find.ancestor(of: chip, matching: find.byType(RecipeTile)),
          findsOneWidget,
        );
        expect(
          find.descendant(of: chip, matching: find.text('${stat.value}')),
          findsOneWidget,
        );
      }
    });

    testWidgets('a campfire wears its two stats', (tester) async {
      await pumpCard(
        tester,
        recipeId: 'basic_campfire',
        lockWhenUnderLevel: true,
      );
      expect(chipFor(SkillId.STAMINA), findsOneWidget);
      expect(chipFor(SkillId.RECOVERY), findsOneWidget);
    });

    testWidgets('a smithed piece wears none', (tester) async {
      await pumpCard(
        tester,
        recipeId: 'forge_copper_dagger',
        lockWhenUnderLevel: false,
      );
      expect(find.byType(BuffBadge), findsNothing);
      expect(find.byType(HealBadge), findsNothing);
    });
  });
}
