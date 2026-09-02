import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';

/// Equipment stats are never written by hand: a [fibLevel] sets the size of
/// the stat budget, [statWeights] splits it, and rarity walks the rung up
/// the same ladder a monster's does.
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
        for (final rarity in Rarity.values) {
          expect(
            def.statsAt(rarity).values.single,
            Util.fib(def.fibLevel + rarity.index),
            reason: '${entry.key.name} at ${rarity.name}',
          );
        }
      }
    });

    test('rarity moves every stat on every piece', () {
      // the thing rarityStatMinBonus used to paper over: a +1 item scaled
      // by 1.1 rounded straight back to +1, so an uncommon copper helmet
      // was worth exactly what a common one was
      for (final entry in equipment()) {
        final def = entry.value;
        var previous = 0;
        for (final rarity in Rarity.values) {
          final total = def
              .statsAt(rarity)
              .values
              .fold(0, (sum, stat) => sum + stat);
          expect(
            total,
            greaterThan(previous),
            reason: '${entry.key.name} is not worth more at ${rarity.name}',
          );
          previous = total;
        }
      }
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
      ItemId.PITCHFORK: 5,
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

  test("a piece's rung is its definition's plus the rarity rolled on it", () {
    final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
    final def = ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;

    expect(helmet.fibLevel, def.fibLevel);
    helmet.quality = Rarity.EPIC;
    expect(helmet.fibLevel, def.fibLevel + 3);
    expect(
      helmet.effectiveSkillBonus[SkillId.DEFENCE],
      Util.fib(def.fibLevel + 3),
    );
  });
}
