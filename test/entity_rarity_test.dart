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
    test('equipment scales on the same ladder entities are colored by', () {
      // the ladder is one enum, so a tier added to it must bring a
      // multiplier with it rather than silently scaling by nothing
      expect(rarityStatMultiplier.keys, containsAll(Rarity.values));

      // common is the identity, and the ladder climbs from there
      expect(statMultiplierFor(Rarity.COMMON), 1.0);
      final multipliers = Rarity.values.map(statMultiplierFor).toList();
      for (var i = 1; i < multipliers.length; i++) {
        expect(
          multipliers[i],
          greaterThan(multipliers[i - 1]),
          reason: '${Rarity.values[i]} must beat ${Rarity.values[i - 1]}',
        );
      }
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
