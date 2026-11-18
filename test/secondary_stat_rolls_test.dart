import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/inventory_service.dart';

/// Gear's budget comes in two halves. The primary half (attack, defence or
/// a skill) scales by the rarity's primary multiplier. The secondary half
/// is one roll per rarity step above common, each worth a fifth of the
/// common budget and each landing on one of the four core stats on its own,
/// so a legendary can stack all four on one stat or spread them across four.
/// Jewellery (neck and finger) keeps its old single-multiplier ladder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  int total(Map<SkillId, int> stats) => stats.values.fold(0, (a, b) => a + b);

  EquipmentItem shield(Rarity rarity) =>
      (ItemId.MITHRIL_SHIELD.build() as EquipmentItem)..quality = rarity;

  test('the budget table: primary multiplier and roll count per tier', () {
    expect(
      [for (final r in Rarity.ladder) r.primaryMultiplier],
      [1.0, 1.0, 1.2, 1.4, 1.6],
    );
    expect([for (final r in Rarity.ladder) r.secondaryRolls], [0, 1, 2, 3, 4]);
  });

  test('each tier rolls its count of core stats, a fifth of budget each', () {
    final def = ItemId.MITHRIL_SHIELD.definition as EquipmentItemDefinition;
    // rung 6: 21 common, so a roll is 21 * 0.2 = 4
    expect(def.secondaryRollValue, 4);
    for (final rarity in Rarity.ladder) {
      final piece = shield(rarity)..rollSecondaries(Random(rarity.index));
      expect(piece.secondaryRolls, hasLength(rarity.secondaryRolls));
      expect(
        piece.secondaryRolls,
        everyElement(isIn(EquipmentItemDefinition.secondaryStatPool)),
      );
      expect(
        total(piece.effectiveSkillBonus),
        def.budgetAt(rarity) + rarity.secondaryRolls * 4,
        reason: rarity.name,
      );
    }
  });

  test('rolls are separate: they can stack on one stat or spread', () {
    final def = ItemId.MITHRIL_SHIELD.definition as EquipmentItemDefinition;
    expect(
      def.secondaryStatsFor(const [
        SkillId.SPEED,
        SkillId.SPEED,
        SkillId.SPEED,
        SkillId.SPEED,
      ]),
      {SkillId.SPEED: 16},
    );
    expect(
      def.secondaryStatsFor(const [
        SkillId.STAMINA,
        SkillId.SPEED,
        SkillId.STRENGTH,
        SkillId.RECOVERY,
      ]),
      {
        SkillId.STAMINA: 4,
        SkillId.SPEED: 4,
        SkillId.STRENGTH: 4,
        SkillId.RECOVERY: 4,
      },
    );
    // over enough legendaries, both shapes come up
    final rng = Random(7);
    final shapes = <int>{};
    for (var i = 0; i < 500; i++) {
      final piece = shield(Rarity.LEGENDARY)..rollSecondaries(rng);
      shapes.add(piece.secondaryRolls.toSet().length);
    }
    expect(shapes, containsAll([1, 4]));
  });

  test('crafted jewellery rolls nothing and keeps its old ladder', () {
    var seen = 0;
    for (final id in ItemId.values) {
      final def = id.definition;
      if (def is! JewelleryDefinition) continue;
      seen++;
      expect(def.rollsSecondaries, isFalse, reason: id.name);
      final piece = (id.build() as EquipmentItem)..quality = Rarity.LEGENDARY;
      expect(piece.needsSecondaryRolls, isFalse, reason: id.name);
      piece.rollSecondaries();
      expect(piece.secondaryRolls, isEmpty, reason: id.name);
    }
    expect(seen, greaterThan(0));
  });

  group('uniques', () {
    test('take their secondaries from the catalog, in tier order', () {
      final def = ItemId.CHICKEN_CHARM.definition as EquipmentItemDefinition;
      final set = def.catalogSecondaries!;
      for (final rarity in Rarity.ladder) {
        final piece = (ItemId.CHICKEN_CHARM.build() as EquipmentItem)
          ..quality = rarity;
        expect(piece.needsSecondaryRolls, isFalse);
        expect(piece.secondaryRolls, set.take(rarity.secondaryRolls));
        // nothing to roll: asking changes nothing
        piece.rollSecondaries(Random(3));
        expect(piece.secondaryRolls, set.take(rarity.secondaryRolls));
      }
    });

    test('a primary plus its catalog secondaries, like any gear', () {
      final def = ItemId.LEVIATHAN_GIRDLE.definition as EquipmentItemDefinition;
      final piece = (ItemId.LEVIATHAN_GIRDLE.build() as EquipmentItem)
        ..quality = Rarity.EPIC;
      final expected = def.statsAt(Rarity.EPIC);
      for (final stat in def.catalogSecondaries!.take(3)) {
        expected[stat] = (expected[stat] ?? 0) + def.secondaryRollValue;
      }
      expect(piece.effectiveSkillBonus, expected);
      expect(
        def.statWeights.keys,
        everyElement(isIn({SkillId.ATTACK, SkillId.DEFENCE})),
      );
    });

    test('a weapon unique carries secondaries on top of its damage', () {
      final piece = (ItemId.PITCHFORK.build() as EquipmentItem)
        ..quality = Rarity.UNCOMMON;
      final def = ItemId.PITCHFORK.definition as EquipmentItemDefinition;
      expect(piece.effectiveSkillBonus, {
        def.catalogSecondaries!.first: def.secondaryRollValue,
      });
    });

    test('are not stored on the piece, so retuning moves every copy', () {
      final piece = (ItemId.QUEENS_TRAIN.build() as EquipmentItem)
        ..quality = Rarity.EPIC;
      expect(piece.toJson().containsKey('secondaryRolls'), isFalse);
      final inventory = InventoryData(itemMap: {});
      InventoryService().addEquipment(inventory, piece..count = 5);
      // identical by definition, so they stay one stack
      expect(inventory.equipment.single.count, 5);
    });
  });

  test('changing quality drops the old rolls', () {
    final piece = shield(Rarity.EPIC)..rollSecondaries();
    expect(piece.needsSecondaryRolls, isFalse);
    piece.quality = Rarity.RARE;
    expect(piece.secondaryRolls, isEmpty);
    expect(piece.needsSecondaryRolls, isTrue);
  });

  test('copies keep their rolls; different rolls do not stack', () {
    final a = shield(Rarity.EPIC)..rollSecondaries(Random(1));
    final copy = a.copy();
    expect(copy.secondaryRolls, a.secondaryRolls);
    expect(copy.canStackWith(a), isTrue);

    final b = shield(Rarity.EPIC);
    // find a roll that differs from a's
    var seed = 2;
    do {
      b.rollSecondaries(Random(seed++));
    } while ((b.secondaryRolls.toList()..sort((x, y) => x.index - y.index))
            .join() ==
        (a.secondaryRolls.toList()..sort((x, y) => x.index - y.index)).join());
    expect(b.canStackWith(a), isFalse);
  });

  group('inventory', () {
    final service = InventoryService();

    test('an unrolled stack is split into pieces rolled on their own', () {
      final inventory = InventoryData(itemMap: {});
      service.addEquipment(inventory, shield(Rarity.LEGENDARY)..count = 30);

      expect(inventory.equipment.fold(0, (sum, e) => sum + e.count), 30);
      expect(
        inventory.equipment.map((e) => e.needsSecondaryRolls),
        everyElement(isFalse),
      );
      // thirty legendaries over 35 possible roll multisets: they do not all
      // land on the same one
      expect(inventory.equipment.length, greaterThan(1));
    });

    test('common gear still stacks whole', () {
      final inventory = InventoryData(itemMap: {});
      service.addEquipment(inventory, shield(Rarity.COMMON)..count = 5);
      expect(inventory.equipment.single.count, 5);
    });
  });
}
