import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/utilities/util.dart';

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
    test('equipment climbs the same ladder entities are colored by', () {
      // one enum, read the same way by both halves of the game: a tier is
      // its index in rungs up the Fibonacci ladder. common is the identity
      // - the definition's own rung - and every tier above it is a real
      // step, which is what the old 1.1x multiplier could not manage on a
      // +1 item.
      final def = ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;
      expect(def.budgetAt(Rarity.COMMON), Util.fib(def.fibLevel));

      final budgets = Rarity.values.map(def.budgetAt).toList();
      for (var i = 1; i < budgets.length; i++) {
        expect(
          budgets[i],
          greaterThan(budgets[i - 1]),
          reason: '${Rarity.values[i]} must beat ${Rarity.values[i - 1]}',
        );
      }

      // and a monster reads its tier off the very same expression
      final chicken = EntityId.CHICKEN.definition as CombatEntityDefinition;
      final epicChicken =
          EntityId.CHICKEN_EPIC.definition as CombatEntityDefinition;
      expect(epicChicken.level, Util.fib(chicken.fibLevel + Rarity.EPIC.index));
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
      // which tier the gem vein sits at is a balance choice; what is under
      // test is that a copy keeps it unless asked to change it
      final def = EntityId.GEM_VEIN.definition;
      final original = def.rarity;
      final other = original == Rarity.LEGENDARY
          ? Rarity.COMMON
          : Rarity.LEGENDARY;
      expect(def.copyWith(name: 'Richer Vein').rarity, original);
      expect(def.copyWith(rarity: other).rarity, other);
    });
  });

  group('the tile borders itself', () {
    testWidgets('a rare entity gets its rarity color, unasked', (tester) async {
      const id = EntityId.GEM_VEIN;
      final rarity = id.definition.rarity;
      // the fixture has to actually be non-common or this proves nothing —
      // a rebalance that makes it common should fail here, loudly, rather
      // than quietly leave the test asserting the plain outline
      expect(rarity, isNot(Rarity.COMMON));

      await pumpTile(tester, id);

      final side = borderOf(tester);
      expect(side.color, rarityBorderColor(rarity));
      expect(side.width, 2);
    });

    testWidgets('a legendary entity is framed differently from a rare one', (
      tester,
    ) async {
      await pumpTile(tester, EntityId.GOBLIN_QUEEN);
      final legendary = borderOf(tester).color;

      // GEM_VEIN, not a common entity: comparing legendary against the plain
      // outline would pass even if every rarity shared one color
      expect(EntityId.GEM_VEIN.definition.rarity, isNot(Rarity.COMMON));
      await pumpTile(tester, EntityId.GEM_VEIN);
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
