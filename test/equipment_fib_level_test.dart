import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';

/// Equipment stats are never written by hand: a [fibLevel] sets the size of
/// the stat budget, [statWeights] splits it, and rarity multiplies it —
/// 1.2x/1.4x/1.6x/1.8x, floored so the tier is worth at least +1/+2/+3/+4
/// total stats over the common.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Iterable<MapEntry<ItemId, EquipmentItemDefinition>> equipment() sync* {
    for (final id in ItemId.values) {
      final def = id.definition;
      if (def is EquipmentItemDefinition) yield MapEntry(id, def);
    }
  }

  group('the ladder', () {
    test('every piece is on it, at every rarity', () {
      for (final entry in equipment()) {
        final def = entry.value;
        expect(
          def.fibLevel,
          greaterThanOrEqualTo(0),
          reason: '${entry.key.name} has a rung below 0',
        );
        // the top rarity has to be reachable, or a legendary roll of this
        // piece throws instead of dropping
        expect(
          () => def.budgetAt(Rarity.LEGENDARY),
          returnsNormally,
          reason:
              '${entry.key.name} at rung ${def.fibLevel} runs off the end of '
              'the ladder when a legendary is rolled',
        );
      }
    });

    test('every weight is positive, so no stat is dead', () {
      for (final entry in equipment()) {
        final def = entry.value;
        expect(
          def.statWeights,
          isNotEmpty,
          reason: '${entry.key.name} splits its budget across nothing',
        );
        for (final weight in def.statWeights.entries) {
          expect(
            weight.value,
            greaterThan(0),
            reason: '${entry.key.name} weights ${weight.key.name} at 0',
          );
        }
      }
    });

    test('a single-weight piece is worth its whole rung', () {
      for (final entry in equipment()) {
        final def = entry.value;
        if (def.statWeights.length != 1) continue;
        // nothing is lost in the split when there is only one share
        expect(
          def.statsAt(Rarity.COMMON).values.single,
          Util.fib(def.fibLevel),
          reason: '${entry.key.name} at COMMON',
        );
        for (final rarity in Rarity.values) {
          expect(
            def.statsAt(rarity).values.single,
            def.budgetAt(rarity),
            reason: '${entry.key.name} at ${rarity.name}',
          );
        }
      }
    });
  });

  group('rarity multiplies the budget', () {
    int totalAt(EquipmentItemDefinition def, Rarity rarity) =>
        def.statsAt(rarity).values.fold(0, (sum, stat) => sum + stat);

    test('every piece is worth strictly more at every step up', () {
      // the thing the multiplier alone cannot promise: a +1 item scaled by
      // 1.2 rounds straight back to +1, so an uncommon copper helmet would
      // be worth exactly what a common one is
      for (final entry in equipment()) {
        final def = entry.value;
        var previous = 0;
        for (final rarity in Rarity.values) {
          final total = totalAt(def, rarity);
          expect(
            total,
            greaterThan(previous),
            reason: '${entry.key.name} is not worth more at ${rarity.name}',
          );
          previous = total;
        }
      }
    });

    test('the minimum each tier owes over common is paid on every piece', () {
      for (final entry in equipment()) {
        final def = entry.value;
        final common = totalAt(def, Rarity.COMMON);
        for (final rarity in Rarity.values) {
          expect(
            totalAt(def, rarity) - common,
            greaterThanOrEqualTo(rarity.minStatBonus),
            reason:
                '${entry.key.name} at ${rarity.name} owes common '
                '+${rarity.minStatBonus} and does not pay it',
          );
        }
      }
    });

    test('a big enough piece is the multiplier and nothing more', () {
      // rung 9 is a budget of 89, well past where the floors bite, so the
      // tiers land on exactly the percentages
      const big = EquipmentItemDefinition(
        name: 'Test',
        value: 1,
        armorSlot: ArmorSlots.HEAD,
        fibLevel: 9,
        statWeights: {SkillId.DEFENCE: 1},
      );
      expect(big.budgetAt(Rarity.COMMON), 89);
      expect(big.budgetAt(Rarity.UNCOMMON), 107); // 89 * 1.2
      expect(big.budgetAt(Rarity.RARE), 125); // 89 * 1.4
      expect(big.budgetAt(Rarity.EPIC), 142); // 89 * 1.6
      expect(big.budgetAt(Rarity.LEGENDARY), 160); // 89 * 1.8
    });

    test('a one-point piece rides the floor instead', () {
      // 1.2x of 1 rounds to 1, so the whole ladder here is minStatBonus
      const tiny = EquipmentItemDefinition(
        name: 'Test',
        value: 1,
        armorSlot: ArmorSlots.HEAD,
        fibLevel: 0,
        statWeights: {SkillId.DEFENCE: 1},
      );
      expect(tiny.statsAt(Rarity.COMMON), {SkillId.DEFENCE: 1});
      expect(tiny.statsAt(Rarity.UNCOMMON), {SkillId.DEFENCE: 2});
      expect(tiny.statsAt(Rarity.RARE), {SkillId.DEFENCE: 3});
      expect(tiny.statsAt(Rarity.EPIC), {SkillId.DEFENCE: 4});
      expect(tiny.statsAt(Rarity.LEGENDARY), {SkillId.DEFENCE: 5});
    });
  });

  group('weights are a ratio, not amounts', () {
    const base = EquipmentItemDefinition(
      name: 'Test',
      value: 1,
      armorSlot: ArmorSlots.HEAD,
      fibLevel: 6,
      statWeights: {SkillId.ATTACK: 2, SkillId.DEFENCE: 1},
    );
    const scaled = EquipmentItemDefinition(
      name: 'Test',
      value: 1,
      armorSlot: ArmorSlots.HEAD,
      fibLevel: 6,
      statWeights: {SkillId.ATTACK: 4, SkillId.DEFENCE: 2},
    );

    test('doubling every weight describes the same piece', () {
      for (final rarity in Rarity.values) {
        expect(scaled.statsAt(rarity), base.statsAt(rarity));
      }
    });

    test('the split follows the ratio', () {
      // rung 6 is a budget of 21, split two to one
      expect(base.budgetAt(Rarity.COMMON), 21);
      expect(base.statsAt(Rarity.COMMON), {
        SkillId.ATTACK: 14,
        SkillId.DEFENCE: 7,
      });
    });
  });

  test('the copper-to-mithril spine did not move', () {
    // this change was not supposed to touch the core progression: the
    // armour/weapon/tool curve was already Fibonacci, so putting it on the
    // ladder has to reproduce it exactly
    const spine = {
      ItemId.COPPER_HELMET: 1,
      ItemId.IRON_HELMET: 2,
      ItemId.STEEL_HELMET: 3,
      ItemId.MITHRIL_HELMET: 5,
      ItemId.COPPER_SHIELD: 3,
      ItemId.IRON_SHIELD: 5,
      ItemId.STEEL_SHIELD: 8,
      ItemId.MITHRIL_SHIELD: 13,
      ItemId.MITHRIL_CHESTPLATE: 8,
      ItemId.MITHRIL_LEGS: 8,
    };
    for (final entry in spine.entries) {
      final piece = entry.key.build() as EquipmentItem;
      expect(
        piece.effectiveSkillBonus[SkillId.DEFENCE],
        entry.value,
        reason: entry.key.name,
      );
    }

    const weapons = {
      ItemId.COPPER_DAGGER: 1,
      ItemId.IRON_DAGGER: 2,
      ItemId.STEEL_DAGGER: 3,
      ItemId.MITHRIL_DAGGER: 5,
      ItemId.PITCHFORK: 3,
    };
    for (final entry in weapons.entries) {
      final piece = entry.key.build() as EquipmentItem;
      expect(
        piece.effectiveSkillBonus[SkillId.ATTACK],
        entry.value,
        reason: entry.key.name,
      );
    }

    expect(
      (ItemId.MITHRIL_PICKAXE.build() as EquipmentItem)
          .effectiveSkillBonus[SkillId.MINING],
      8,
    );
  });

  test('an enchant is added flat, on top of the rung', () {
    final helmet = ItemId.MITHRIL_SHIELD.build() as EquipmentItem;
    final bare = helmet.effectiveSkillBonus[SkillId.DEFENCE]!;

    helmet.enchantBonus = {SkillId.DEFENCE: 4, SkillId.ATTACK: 2};

    expect(helmet.effectiveSkillBonus[SkillId.DEFENCE], bare + 4);
    // a skill the piece has no weight in still gets the enchant's points
    expect(helmet.effectiveSkillBonus[SkillId.ATTACK], 2);
  });

  test("a rolled piece's stats are its definition's, multiplied", () {
    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    final def = ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;

    expect(
      helmet.effectiveSkillBonus[SkillId.DEFENCE],
      def.budgetAt(helmet.quality),
    );
    helmet.quality = Rarity.EPIC;
    expect(
      helmet.effectiveSkillBonus[SkillId.DEFENCE],
      def.budgetAt(Rarity.EPIC),
    );

    // EquipmentItem.fibLevel is the other tuning of the same idea, kept in
    // case the ladder is worth going back to. It still walks, and stats
    // still ignore it: a rung-0 helmet at epic is 4 by the +3 floor, not
    // fib(3) = 5.
    expect(helmet.fibLevel, def.fibLevel + Rarity.EPIC.index);
    expect(helmet.effectiveSkillBonus[SkillId.DEFENCE], 4);
    expect(Util.fib(helmet.fibLevel), 5);
  });
}
