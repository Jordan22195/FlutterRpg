import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/data/cooking_recipes.dart';
import 'package:rpg/data/skill_data.dart';

// The fish cooking ladder: each fish opens later and pays more than the one
// before it, and no stretch between two fish runs past ten levels below 80.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const raw = [
    ItemId.MINNOW,
    ItemId.CARP,
    ItemId.CRAYFISH,
    ItemId.BLUEGILL,
    ItemId.TROUT,
    ItemId.PIKE,
    ItemId.SALMON,
    ItemId.CATFISH,
    ItemId.BASS,
    ItemId.WHITEFISH,
    ItemId.STURGEON,
    ItemId.TUNA,
    ItemId.SWORDFISH,
    ItemId.SHARK,
  ];
  final ladder = [
    for (final fish in raw)
      cookingRecipes.singleWhere((r) => r.inputs.keys.single == fish),
  ];

  test('each fish opens later and pays more than the last', () {
    for (var i = 1; i < ladder.length; i++) {
      final (a, b) = (ladder[i - 1], ladder[i]);
      expect(b.levelRequirement, greaterThan(a.levelRequirement), reason: b.id);
      expect(b.xp, greaterThan(a.xp), reason: b.id);
    }
  });

  test('each fish pays its tuned xp and heals one Fibonacci step up', () {
    // paced so 1 to 99 takes about thirty days of three-second cooks
    expect(ladder.map((r) => r.xp), [
      2, 3, 3.5, 4, 5, 5.5, 6, 6.2, 7.9, 9.6, 11, 12, 15.4, 20.6, //
    ]);
    final heals = [
      for (final r in ladder)
        (r.output.first.id.definition as FoodItemDefinition).restoreAmount,
    ];
    expect(heals, [1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610]);
  });

  test('the creek opens at 7 on the crayfish', () {
    final creek = EntityId.CREEK.definition as FishingEntityDefinition;
    expect(creek.requiredLevel, 7);
    expect(creek.itemDrops.map((d) => (d.id, d.unlockLevel, d.weight)), [
      (ItemId.CRAYFISH, 7, 1.0),
      (ItemId.BLUEGILL, 10, 0.5),
      (ItemId.TROUT, 15, 0.25),
    ]);
  });

  test('no gap past ten levels before the ocean', () {
    for (var i = 1; i < ladder.length; i++) {
      if (ladder[i].levelRequirement > 80) break;
      expect(
        ladder[i].levelRequirement - ladder[i - 1].levelRequirement,
        lessThanOrEqualTo(15),
        reason: '${ladder[i - 1].id} to ${ladder[i].id}',
      );
    }
    // the stretch the sturgeon was added to split
    final sturgeon = ladder[raw.indexOf(ItemId.STURGEON)];
    expect(sturgeon.levelRequirement, 70);
    expect(sturgeon.skill, SkillId.COOKING);
    expect(sturgeon.output.first.id, ItemId.COOKED_STURGEON);
  });

  test('the lake catches the sturgeon from Fishing 70', () {
    final lake = EntityId.LAKE.definition as FishingEntityDefinition;
    final drop = lake.itemDrops.singleWhere((d) => d.id == ItemId.STURGEON);
    expect(drop.unlockLevel, 70);
    // half the whitefish's share, as the bass is beside the catfish
    final whitefish = lake.itemDrops.singleWhere(
      (d) => d.id == ItemId.WHITEFISH,
    );
    expect(drop.weight, whitefish.weight / 2);
  });
}
