import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/recipe_details.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/recipe_info_body.dart';

/// What the bench panel's info tab reports for a recipe: its cost against
/// live inventory, and the odds the craft actually rolls.
///
/// The odds are the point. They move with the player's level, so most of
/// these pin the direction they move in rather than a fixed number.
void main() {
  late GameSession session;
  late SaveGameData save;

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

    save.playerData.currentEntityViewId = EntityId.ANVIL;
  });

  tearDown(() => session.dispose());

  void setLevel(SkillId skill, int level) {
    final data = save.playerData.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  void give(ItemId id, int count) {
    save.inventoryData.itemMap[id] = count;
  }

  RecipeDetails detailsFor(String recipeId) =>
      session.craftingController.recipeDetails(recipeId);

  double chanceOf(RecipeDetails d, Rarity quality) =>
      d.outcomes.firstWhere((o) => o.quality == quality).chance;

  group('quality odds', () {
    test('every tier is reported and the odds sum to one', () {
      setLevel(SkillId.BLACKSMITHING, 20);
      final details = detailsFor('forge_copper_dagger');

      expect(details.rollsQuality, isTrue);
      expect(
        details.outcomes.map((o) => o.quality).toList(),
        Rarity.values,
        reason: 'the tab should show the whole ladder, in ladder order',
      );
      final sum = details.outcomes.fold<double>(0, (s, o) => s + o.chance);
      expect(sum, closeTo(1.0, 1e-9));
    });

    test('at the recipe requirement the odds are the bare weights', () {
      // forge_copper_dagger requires level 1, so level 1 is levelBonus 0
      setLevel(SkillId.BLACKSMITHING, 1);
      final details = detailsFor('forge_copper_dagger');

      const total = 100 + 1 + 0.1 + 0.01 + 0.001;
      expect(chanceOf(details, Rarity.COMMON), closeTo(100 / total, 1e-9));
      expect(chanceOf(details, Rarity.UNCOMMON), closeTo(1 / total, 1e-9));
      expect(chanceOf(details, Rarity.RARE), closeTo(0.1 / total, 1e-9));
      expect(chanceOf(details, Rarity.EPIC), closeTo(0.01 / total, 1e-9));
      expect(
        chanceOf(details, Rarity.LEGENDARY),
        closeTo(0.001 / total, 1e-9),
      );
    });

    test('levelling shifts weight off common and onto the top tiers', () {
      setLevel(SkillId.BLACKSMITHING, 1);
      final low = detailsFor('forge_copper_dagger');
      setLevel(SkillId.BLACKSMITHING, 50);
      final high = detailsFor('forge_copper_dagger');

      expect(
        chanceOf(high, Rarity.COMMON),
        lessThan(chanceOf(low, Rarity.COMMON)),
      );
      for (final tier in [
        Rarity.UNCOMMON,
        Rarity.RARE,
        Rarity.EPIC,
        Rarity.LEGENDARY,
      ]) {
        expect(
          chanceOf(high, tier),
          greaterThan(chanceOf(low, tier)),
          reason: '$tier should get likelier with level',
        );
      }
    });

    test('the level reported is the effective one the roll reads', () {
      setLevel(SkillId.BLACKSMITHING, 30);
      final details = detailsFor('forge_copper_dagger');
      final effective =
          session.playerDataService.getStatTotals(
            save.playerData,
          )[SkillId.BLACKSMITHING] ??
          0;

      expect(details.effectiveSkillLevel, effective);
      // a bare skill level here would disagree with the odds beside it
      expect(
        details.effectiveSkillLevel,
        greaterThanOrEqualTo(
          session.playerDataService.getSkillLevel(
            SkillId.BLACKSMITHING,
            save.playerData,
          ),
        ),
      );
    });
  });

  group('recipes without a quality roll', () {
    test('a bar reports no quality and no odds worth showing', () {
      setLevel(SkillId.BLACKSMITHING, 20);
      final details = detailsFor('smelt_copper_bar');

      expect(details.rollsQuality, isFalse);
      expect(details.outcomes.single.itemId, ItemId.COPPER_BAR);
      // one certain outcome is not a table
      expect(details.hasOdds, isFalse);
    });

    test('cooking reports a burn chance that falls as the level rises', () {
      setLevel(SkillId.COOKING, 1);
      final low = detailsFor('cook_chicken');
      setLevel(SkillId.COOKING, 50);
      final high = detailsFor('cook_chicken');

      double burn(RecipeDetails d) =>
          d.outcomes.firstWhere((o) => o.itemId == ItemId.BURNT_FOOD).chance;

      expect(low.rollsQuality, isFalse);
      expect(low.hasOdds, isTrue);
      expect(burn(high), lessThan(burn(low)));
    });

    test('outcomes are listed commonest first', () {
      setLevel(SkillId.COOKING, 40);
      final chances = detailsFor('cook_chicken').outcomes
          .map((o) => o.chance)
          .toList();
      for (var i = 1; i < chances.length; i++) {
        expect(chances[i], lessThanOrEqualTo(chances[i - 1]));
      }
    });
  });

  group('materials', () {
    test('inputs read live inventory and flag the short one', () {
      setLevel(SkillId.BLACKSMITHING, 5);
      final empty = detailsFor('forge_copper_dagger');
      expect(empty.materials.single.itemId, ItemId.COPPER_BAR);
      expect(empty.materials.single.required, 1);
      expect(empty.materials.single.held, 0);
      expect(empty.materials.single.isShort, isTrue);
      expect(empty.hasMaterials, isFalse);
      expect(empty.craftableCount, 0);

      give(ItemId.COPPER_BAR, 4);
      final stocked = detailsFor('forge_copper_dagger');
      expect(stocked.materials.single.held, 4);
      expect(stocked.materials.single.isShort, isFalse);
      expect(stocked.hasMaterials, isTrue);
      expect(stocked.craftableCount, 4);
    });

    test('xp and the level gate come straight off the recipe', () {
      final details = detailsFor('cook_chicken');
      expect(details.recipe.name, 'Cooked Chicken');
      expect(details.recipe.xp, 10);
      expect(details.recipe.levelRequirement, 1);
      expect(details.skill, SkillId.COOKING);
    });
  });

  group('no selection', () {
    test('an unset recipe id is not real rather than throwing', () {
      final details = detailsFor('');
      expect(details.isReal, isFalse);
      expect(detailsFor('no_such_recipe').isReal, isFalse);
    });
  });

  group('the info body', () {
    Future<void> pumpBody(WidgetTester tester, String recipeId) async {
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
              body: SingleChildScrollView(
                child: RecipeInfoBody(recipeId: recipeId),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('an equipment recipe shows its name, xp and quality ladder', (
      tester,
    ) async {
      setLevel(SkillId.BLACKSMITHING, 20);
      give(ItemId.COPPER_BAR, 3);
      await pumpBody(tester, 'forge_copper_dagger');

      expect(find.text('Copper Dagger'), findsOneWidget);
      expect(find.text('Xp per craft'), findsOneWidget);
      expect(find.text('2.0'), findsOneWidget);
      expect(find.text('Your level'), findsOneWidget);
      // materials: held / required
      expect(find.text('3 / 1'), findsOneWidget);

      expect(find.text('QUALITY'), findsOneWidget);
      for (final tier in Rarity.values) {
        final label = tier.label.isEmpty ? 'Common' : tier.label;
        expect(find.text(label), findsOneWidget, reason: 'missing $label row');
      }
    });

    testWidgets('a bar recipe shows no odds table at all', (tester) async {
      setLevel(SkillId.BLACKSMITHING, 20);
      await pumpBody(tester, 'smelt_copper_bar');

      expect(find.text('Copper Bar'), findsWidgets);
      expect(find.text('QUALITY'), findsNothing);
      expect(find.text('OUTCOME'), findsNothing);
    });

    testWidgets('a cooking recipe shows the burnt-food row', (tester) async {
      setLevel(SkillId.COOKING, 10);
      await pumpBody(tester, 'cook_chicken');

      expect(find.text('OUTCOME'), findsOneWidget);
      expect(find.text('Burnt Food'), findsOneWidget);
    });

    testWidgets('nothing selected reads as nothing selected', (tester) async {
      await pumpBody(tester, '');
      expect(find.text('No recipe selected'), findsOneWidget);
    });
  });
}
