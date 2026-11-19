import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/systems/crafting_system.dart';

// A potion has no rarity, so a brew rolls the crafting quality table and
// pays the tier out in potions, the same ladder a smelt pays bars on.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const recipeId = 'alch_minor_speed_potion';

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

  void stock(GameSession session, int count) {
    final items = session.saveGameData.inventoryData.itemMap;
    items[ItemId.MEADOWSWEET] = count;
    items[ItemId.SMALL_FEATHER] = count;
  }

  int brew(GameSession session, int crafts, {required bool offline}) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = EntityId.ALCHEMY_STATION;
    save.craftingState.craftingZoneId = save.playerData.currentZoneId;
    save.craftingState.activeRecipeId = recipeId;
    final result = session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
      craftCount: crafts,
      offline: offline,
    );
    return result.items.fold(0, (sum, s) => sum + s.count);
  }

  double meanPotions(GameSession session, int level) {
    final recipe = RecipeCatalog().recipeById(recipeId);
    final chances = WeightedDropTableService.chances(
      session.craftingSystem.qualityEntries(level, recipe.levelRequirement),
    );
    return chances.entries.fold(
      0.0,
      (sum, e) => sum + e.value * CraftingSystem.bonusOutputFor(e.key),
    );
  }

  test('every alchemy recipe rolls for bonus potions', () {
    final alchemy = [
      for (final r in RecipeCatalog().recipes)
        if (r.skill == SkillId.ALCHEMY) r,
    ];
    expect(alchemy, isNotEmpty);
    for (final recipe in alchemy) {
      expect(recipe.rollsBonusOutput, isTrue, reason: recipe.id);
    }
  });

  test('a batch of brews pays the table\'s worth of potions', () {
    final session = buildSession();
    setLevel(session, SkillId.ALCHEMY, 99);
    stock(session, 1000);

    final potions = brew(session, 1000, offline: true);

    final items = session.saveGameData.inventoryData.itemMap;
    // the herb and reagent are paid per craft, not per potion
    expect(items[ItemId.MEADOWSWEET], isNull);
    expect(items[ItemId.SMALL_FEATHER], isNull);
    expect(items[ItemId.MINOR_SPEED_POTION], potions);
    expect(potions, closeTo(1000 * meanPotions(session, 99), 10));
    expect(potions, greaterThan(1000));
  });

  test('a live brew pays between one and five potions', () {
    final session = buildSession();
    setLevel(session, SkillId.ALCHEMY, 99);
    stock(session, 200);

    final seen = <int>{};
    for (var i = 0; i < 200; i++) {
      final potions = brew(session, 1, offline: false);
      expect(potions, inInclusiveRange(1, 5));
      seen.add(potions);
    }
    expect(seen.length, greaterThan(1));
  });
}
