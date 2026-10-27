import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/systems/crafting_system.dart';

// A bar has no rarity, so a smelt rolls the crafting quality table and pays
// the tier out in bars: common 1, uncommon 2, rare 3, epic 4, legendary 5.
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

  int smelt(GameSession session, int crafts, {required bool offline}) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = EntityId.ANVIL;
    save.craftingState.craftingZoneId = save.playerData.currentZoneId;
    save.craftingState.activeRecipeId = 'smelt_copper_bar';
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

  // what a smelt pays on average at [level], off the same table it rolls
  double meanBars(GameSession session, int level) {
    final recipe = RecipeCatalog().recipeById('smelt_copper_bar');
    final chances = WeightedDropTableService.chances(
      session.craftingSystem.qualityEntries(level, recipe.levelRequirement),
    );
    return chances.entries.fold(
      0.0,
      (sum, e) => sum + e.value * CraftingSystem.bonusOutputFor(e.key),
    );
  }

  test('each tier pays its step on the ladder in bars', () {
    expect(
      [for (final tier in Rarity.values) CraftingSystem.bonusOutputFor(tier)],
      [1, 2, 3, 4, 5],
    );
  });

  test('every bar recipe rolls for bonus bars, and no forge does', () {
    for (final recipe in RecipeCatalog().recipes) {
      final makesBar = recipe.id.startsWith('smelt_');
      expect(recipe.rollsBonusOutput, makesBar, reason: recipe.id);
    }
  });

  test('a batch of smelts pays the table\'s worth of bars', () {
    final session = buildSession();
    setLevel(session, SkillId.BLACKSMITHING, 99);
    session.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE] = 1000;

    final bars = smelt(session, 1000, offline: true);

    // the ore is paid per craft, not per bar
    expect(
      session.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE],
      isNull,
    );
    expect(session.saveGameData.inventoryData.itemMap[ItemId.COPPER_BAR], bars);
    // a batch settles its tiers in proportion rather than drawing each, so
    // it lands on the mean to within a tier or two of rounding
    expect(bars, closeTo(1000 * meanBars(session, 99), 10));
    expect(bars, greaterThan(1000));
  });

  test('a live smelt pays between one and five bars', () {
    final session = buildSession();
    setLevel(session, SkillId.BLACKSMITHING, 99);
    session.saveGameData.inventoryData.itemMap[ItemId.COPPER_ORE] = 200;

    final seen = <int>{};
    for (var i = 0; i < 200; i++) {
      final bars = smelt(session, 1, offline: false);
      expect(bars, inInclusiveRange(1, 5));
      seen.add(bars);
    }
    // at 99 the upper tiers are common enough that 200 smelts show some
    expect(seen.length, greaterThan(1));
  });

  test('the recipe tab lists the bars each tier pays, with its odds', () {
    final session = buildSession();
    final save = session.saveGameData;
    final details = session.craftingSystem.buildRecipeDetails(
      save.playerData,
      save.inventoryData,
      'smelt_copper_bar',
    );

    expect(details.rollsQuality, isFalse);
    expect(
      [for (final o in details.outcomes) o.label],
      [
        '1x Copper Bar',
        '2x Copper Bar',
        '3x Copper Bar',
        '4x Copper Bar',
        '5x Copper Bar',
      ],
    );
    expect([for (final o in details.outcomes) o.quality], Rarity.values);
    expect(
      details.outcomes.fold(0.0, (sum, o) => sum + o.chance),
      closeTo(1, 1e-9),
    );
  });
}
