import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/catalog_icons.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/utilities/image_resolver.dart';
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
}
