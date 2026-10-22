import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

// A food's tile says how much it heals: a heart and the amount in green,
// top-left, clear of the count along the bottom.
void main() {
  setUpAll(() {
    registerCatalogIconResolvers();
    EnumImageProviderLookup.register<SkillId>(SkillController.imageProviderFor);
  });

  Future<void> pumpTile(WidgetTester tester, ItemId id, {double size = 56}) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ItemStackTile(size: size, count: 12, id: id),
            ),
          ),
        ),
      );

  testWidgets('a food wears its heal amount, in green beside a heart', (
    tester,
  ) async {
    await pumpTile(tester, ItemId.COOKED_CHICKEN);

    final heal =
        (ItemId.COOKED_CHICKEN.definition as FoodItemDefinition).restoreAmount;
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    final amount = tester.widget<Text>(find.text('$heal'));
    expect(amount.style?.color, GameColors.standard.heal);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.favorite)).color,
      GameColors.standard.hp,
    );

    // top-left, above the count in the bottom-right
    final tile = tester.getRect(find.byType(ItemStackTile<ItemId>));
    final heart = tester.getCenter(find.byIcon(Icons.favorite));
    expect(heart.dx, lessThan(tile.center.dx));
    expect(heart.dy, lessThan(tile.center.dy));
    expect(find.text('12'), findsOneWidget);
  });

  testWidgets('every food carries one', (tester) async {
    for (final id in ItemId.values) {
      if (id.definition is! FoodItemDefinition) continue;
      await pumpTile(tester, id);
      expect(find.byIcon(Icons.favorite), findsOneWidget, reason: id.name);
    }
  });

  testWidgets('nothing that is not food wears a heart', (tester) async {
    await pumpTile(tester, ItemId.LOGS);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('a tile too small for it keeps just its count', (tester) async {
    await pumpTile(tester, ItemId.COOKED_CHICKEN, size: 30);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  group('buff items wear their stats the same way', () {
    Finder chipFor(SkillId skill) =>
        find.byWidgetPredicate((w) => w is BuffBadge && w.skill == skill);

    testWidgets('a potion wears its stat and amount, top-left', (tester) async {
      await pumpTile(tester, ItemId.MINOR_SPEED_POTION);

      final bonus = (ItemId.MINOR_SPEED_POTION.definition as BuffItemDefinition)
          .skillBonus;
      expect(find.byType(BuffBadge), findsNWidgets(bonus.length));
      for (final stat in bonus.entries) {
        final chip = chipFor(stat.key);
        expect(chip, findsOneWidget);
        // the stat's own sprite, and the amount in the heal green
        expect(
          find.descendant(
            of: chip,
            matching: find.byWidgetPredicate(
              (w) => w is IconRenderer<SkillId> && w.id == stat.key,
            ),
          ),
          findsOneWidget,
        );
        final amount = tester.widget<Text>(
          find.descendant(of: chip, matching: find.text('${stat.value}')),
        );
        expect(amount.style?.color, GameColors.standard.heal);
      }

      // in the food's corner, clear of the count
      final tile = tester.getRect(find.byType(ItemStackTile<ItemId>));
      final chip = tester.getCenter(find.byType(BuffBadge).first);
      expect(chip.dx, lessThan(tile.center.dx));
      expect(chip.dy, lessThan(tile.center.dy));
      expect(find.text('12'), findsOneWidget);
      // and no heart: it does not heal
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('a two-stat buff stacks a chip for each', (tester) async {
      await pumpTile(tester, ItemId.BASIC_CAMPFIRE);

      expect(chipFor(SkillId.STAMINA), findsOneWidget);
      expect(chipFor(SkillId.RECOVERY), findsOneWidget);
      // one above the other, in the order the fire lists them
      expect(
        tester.getTopLeft(chipFor(SkillId.STAMINA)).dy,
        lessThan(tester.getTopLeft(chipFor(SkillId.RECOVERY)).dy),
      );
    });

    testWidgets('every buff item carries them', (tester) async {
      for (final id in ItemId.values) {
        final def = id.definition;
        if (def is! BuffItemDefinition || def.skillBonus.isEmpty) continue;
        await pumpTile(tester, id);
        expect(
          find.byType(BuffBadge),
          findsNWidgets(def.skillBonus.length),
          reason: id.name,
        );
      }
    });

    testWidgets('nothing that is not a buff wears one', (tester) async {
      await pumpTile(tester, ItemId.LOGS);
      expect(find.byType(BuffBadge), findsNothing);
      await pumpTile(tester, ItemId.COOKED_CHICKEN);
      expect(find.byType(BuffBadge), findsNothing);
    });

    testWidgets('a tile too small for them keeps just its count', (
      tester,
    ) async {
      await pumpTile(tester, ItemId.MINOR_SPEED_POTION, size: 30);
      expect(find.byType(BuffBadge), findsNothing);
    });
  });
}
