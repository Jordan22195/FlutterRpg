import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

/// Entity rarity, and the border it paints.
///
/// The claim under test is that an entity frames itself: no screen passes a
/// color in, so every tile in the game gets the same border for the same
/// entity.
void main() {
  /// The border the tile actually painted, read off its decoration.
  BorderSide borderOf(WidgetTester tester) {
    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(ItemStackTile<EntityId>),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    return ((box.decoration as BoxDecoration).border as Border).top;
  }

  Future<void> pumpTile(
    WidgetTester tester,
    EntityId id, {
    Color? borderColor,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ItemStackTile<EntityId>(
              size: 52,
              count: 1,
              id: id,
              showInfoDialogOnTap: false,
              borderColor: borderColor,
            ),
          ),
        ),
      ),
    );
  }

  group('rarity colors', () {
    test('rarity and equipment quality share one ladder', () {
      const pairs = <ItemQuality, Rarity>{
        ItemQuality.COMMON: Rarity.COMMON,
        ItemQuality.UNCOMMON: Rarity.UNCOMMON,
        ItemQuality.RARE: Rarity.RARE,
        ItemQuality.EPIC: Rarity.EPIC,
        ItemQuality.LEGENDARY: Rarity.LEGENDARY,
      };

      // every tier is covered, so a new one cannot be added to either enum
      // without this test being updated
      expect(pairs.keys, containsAll(ItemQuality.values));
      expect(pairs.values, containsAll(Rarity.values));

      pairs.forEach((quality, rarity) {
        expect(
          qualityBorderColor(quality),
          rarityBorderColor(rarity),
          reason: 'a $rarity entity and a $quality item must match',
        );
      });
    });

    test('common is the only uncolored tier, and every other is distinct', () {
      expect(rarityBorderColor(Rarity.COMMON), isNull);

      final colored = Rarity.values
          .where((r) => r != Rarity.COMMON)
          .map(rarityBorderColor)
          .toList();
      expect(colored, everyElement(isNotNull));
      expect(colored.toSet(), hasLength(colored.length));
    });
  });

  group('entity catalog', () {
    test('every entity carries a rarity, defaulting to common', () {
      for (final id in EntityId.values) {
        expect(id.definition.rarity, isNotNull, reason: '$id');
      }
      expect(EntityId.CHICKEN.definition.rarity, Rarity.COMMON);
      expect(EntityId.GOBLIN_QUEEN.definition.rarity, Rarity.LEGENDARY);
    });

    test('copyWith carries rarity, and can override it', () {
      final def = EntityId.GEM_VEIN.definition;
      expect(def.rarity, Rarity.EPIC);
      expect(def.copyWith(name: 'Richer Vein').rarity, Rarity.EPIC);
      expect(def.copyWith(rarity: Rarity.LEGENDARY).rarity, Rarity.LEGENDARY);
    });
  });

  group('the tile borders itself', () {
    testWidgets('a rare entity gets its rarity color, unasked', (tester) async {
      await pumpTile(tester, EntityId.COAL_VEIN);

      final side = borderOf(tester);
      expect(side.color, rarityBorderColor(Rarity.RARE));
      expect(side.width, 2);
    });

    testWidgets('a legendary entity is framed differently from a rare one', (
      tester,
    ) async {
      await pumpTile(tester, EntityId.GOBLIN_QUEEN);
      final legendary = borderOf(tester).color;

      await pumpTile(tester, EntityId.COAL_VEIN);
      final rare = borderOf(tester).color;

      expect(legendary, isNot(rare));
      expect(legendary, rarityBorderColor(Rarity.LEGENDARY));
    });

    testWidgets('a common entity keeps the plain outline', (tester) async {
      await pumpTile(tester, EntityId.CHICKEN);

      final side = borderOf(tester);
      expect(side.width, 1);
      expect(side.color, isNot(rarityBorderColor(Rarity.UNCOMMON)));
    });

    testWidgets('an explicit border still wins', (tester) async {
      await pumpTile(
        tester,
        EntityId.GOBLIN_QUEEN,
        borderColor: Colors.pinkAccent,
      );

      expect(borderOf(tester).color, Colors.pinkAccent);
    });
  });
}
