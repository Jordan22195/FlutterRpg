import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipe_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/crafting_service.dart';

// Burning is measured from the recipe's own level: half the time at it,
// falling straight to a 1% floor twenty levels past it. And every fish the
// spots yield, and every meat, has a recipe that cooks it.
void main() {
  final service = CraftingService();
  final catalog = RecipeCatalog();

  double burn(int level, int requiredLevel) =>
      service.calculateBurnChance(level: level, requiredLevel: requiredLevel);

  group('the burn curve', () {
    test(
      'half at the requirement, a quarter ten past, the floor at twenty',
      () {
        expect(burn(15, 15), closeTo(0.5, 1e-9));
        expect(burn(25, 15), closeTo(0.25, 1e-9));
        expect(burn(35, 15), closeTo(0.01, 1e-9));
        expect(burn(99, 15), closeTo(0.01, 1e-9));
      },
    );

    test('it is how far past the requirement that counts, not the recipe', () {
      // a hard recipe twenty past is as safe as an easy one twenty past
      expect(burn(113, 93), burn(21, 1));
      expect(burn(60, 55), burn(10, 5));
    });

    test('a shark at 99 burns less than it did, but still burns', () {
      // six levels past its 93: well under the old one-in-two
      final shark = burn(99, 93);
      expect(shark, lessThan(0.5));
      expect(shark, greaterThan(0.01));
    });

    test('the cooking table rolls burnt food at exactly that chance', () {
      for (final recipe in catalog.recipesForSkill(SkillId.COOKING)) {
        final level = recipe.levelRequirement + 7;
        final table = service.adjustActiveRecipeDropTable(recipe, {
          SkillId.COOKING: level,
        });
        final total = table.fold<double>(0, (sum, e) => sum + e.weight);
        final burnt = table
            .where((e) => e.id == ItemId.BURNT_FOOD)
            .fold<double>(0, (sum, e) => sum + e.weight);
        expect(
          burnt / total,
          closeTo(burn(level, recipe.levelRequirement), 1e-9),
          reason: recipe.id,
        );
      }
    });

    test('the recipe in the catalog is left alone', () {
      final recipe = catalog.recipeById('cook_shark');
      final before = [for (final e in recipe.output) e.weight];
      service.adjustActiveRecipeDropTable(recipe, {SkillId.COOKING: 99});
      expect([for (final e in recipe.output) e.weight], before);
    });
  });

  group('what cooks', () {
    test('beef is cooked from cow meat', () {
      expect(catalog.recipeById('cook_beef').inputs.keys, [ItemId.COW_MEAT]);
    });

    test('bass cooks at its Fishing level', () {
      final bass = catalog.recipeById('cook_bass');
      expect(bass.inputs.keys, [ItemId.BASS]);
      expect(bass.output.first.id, ItemId.COOKED_BASS);
      expect(bass.levelRequirement, 55);
    });

    test('every fish a spot yields has a recipe', () {
      final cooked = {
        for (final r in catalog.recipesForSkill(SkillId.COOKING))
          ...r.inputs.keys,
      };
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! FishingEntityDefinition) continue;
        for (final fish in def.itemDrops) {
          expect(cooked, contains(fish.id), reason: '${fish.id.name} at $id');
        }
      }
    });
  });
}
