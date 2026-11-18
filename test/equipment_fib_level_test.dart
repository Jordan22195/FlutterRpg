import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';

/// Equipment stats are never written by hand: a [fibLevel] sets the size of
/// the stat budget, [statWeights] splits it, and rarity scales the primary
/// half — 1.0x/1.2x/1.4x/1.6x from uncommon, floored so rare and up are
/// worth at least +1/+2/+3 primary over the common — while the secondary
/// half is rolled per piece (see secondary_stat_rolls_test.dart).
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
        // a damage weapon deals its rung rather than carrying stats
        if (def is WeaponItemDefinition && def.usesDamage) continue;
        // an xp gem reads its rung as an xp percent rather than stats
        if (def is JewelleryDefinition && def.gem.boostsXp) continue;
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
        // nothing is lost in the split when there is only one share. a
        // weapon prices its stats off its metal alone, its budget rung
        expect(
          def.statsAt(Rarity.COMMON).values.single,
          Util.fib(def.budgetRung),
          reason: '${entry.key.name} at COMMON',
        );
        if (!def.rarityScalesStats) continue;
        for (final rarity in Rarity.ladder) {
          expect(
            def.statsAt(rarity).values.single,
            def.budgetAt(rarity),
            reason: '${entry.key.name} at ${rarity.name}',
          );
        }
      }
    });
  });

  group('rarity scales the primary budget', () {
    int totalAt(EquipmentItemDefinition def, Rarity rarity) =>
        def.statsAt(rarity).values.fold(0, (sum, stat) => sum + stat);

    test('every piece is worth strictly more primary from uncommon up', () {
      // the thing the multiplier alone cannot promise: a +1 item scaled by
      // 1.2 rounds straight back to +1, so a rare copper helmet would be
      // worth exactly what an uncommon one is. uncommon itself sits level
      // with common — it pays its step as a secondary roll instead
      for (final entry in equipment()) {
        final def = entry.value;
        // damage weapons carry no stats, and dev items state theirs outright
        if (def.statWeights.isEmpty ||
            def.fixedStats != null ||
            !def.rarityScalesStats) {
          continue;
        }
        if (def.rollsSecondaries) {
          expect(
            totalAt(def, Rarity.UNCOMMON),
            totalAt(def, Rarity.COMMON),
            reason: '${entry.key.name}: uncommon moved its primary stats',
          );
        }
        var previous = totalAt(def, Rarity.UNCOMMON);
        for (final rarity in [Rarity.RARE, Rarity.EPIC, Rarity.LEGENDARY]) {
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
        // damage weapons carry no stats, and dev items state theirs
        // outright. jewellery keeps its own single-multiplier ladder
        if (def.statWeights.isEmpty ||
            def.fixedStats != null ||
            !def.rarityScalesStats) {
          continue;
        }
        final common = totalAt(def, Rarity.COMMON);
        for (final rarity in Rarity.ladder) {
          final owed = def.rollsSecondaries
              ? rarity.minPrimaryBonus
              : rarity.minStatBonus;
          expect(
            totalAt(def, rarity) - common,
            greaterThanOrEqualTo(owed),
            reason:
                '${entry.key.name} at ${rarity.name} owes common '
                '+$owed and does not pay it',
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
      expect(big.budgetAt(Rarity.UNCOMMON), 89); // pays a roll instead
      expect(big.budgetAt(Rarity.RARE), 107); // 89 * 1.2
      expect(big.budgetAt(Rarity.EPIC), 125); // 89 * 1.4
      expect(big.budgetAt(Rarity.LEGENDARY), 142); // 89 * 1.6
      // and each secondary roll is a fifth of the common budget
      expect(big.secondaryRollValue, 18); // 89 * 0.2
    });

    test('a one-point piece rides the floor instead', () {
      // 1.2x of 1 rounds to 1, so rare and up ride minPrimaryBonus
      const tiny = EquipmentItemDefinition(
        name: 'Test',
        value: 1,
        armorSlot: ArmorSlots.HEAD,
        fibLevel: 0,
        statWeights: {SkillId.DEFENCE: 1},
      );
      expect(tiny.statsAt(Rarity.COMMON), {SkillId.DEFENCE: 1});
      expect(tiny.statsAt(Rarity.UNCOMMON), {SkillId.DEFENCE: 1});
      expect(tiny.statsAt(Rarity.RARE), {SkillId.DEFENCE: 2});
      expect(tiny.statsAt(Rarity.EPIC), {SkillId.DEFENCE: 3});
      expect(tiny.statsAt(Rarity.LEGENDARY), {SkillId.DEFENCE: 4});
      // a fifth of 1 still rolls a whole point
      expect(tiny.secondaryRollValue, 1);
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
      for (final rarity in Rarity.ladder) {
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

  test('the copper-to-mithril spine is pinned', () {
    // the armour/weapon/tool curve is Fibonacci; pinned so a retune says by
    // how much it moved. iron and up sit one rung higher than copper's
    // spacing alone would put them (iron 2 .. dragon 7)
    const spine = {
      ItemId.COPPER_HELMET: 1,
      ItemId.IRON_HELMET: 3,
      ItemId.STEEL_HELMET: 5,
      ItemId.MITHRIL_HELMET: 8,
      ItemId.COPPER_SHIELD: 3,
      ItemId.IRON_SHIELD: 8,
      ItemId.STEEL_SHIELD: 13,
      ItemId.MITHRIL_SHIELD: 21,
      ItemId.MITHRIL_CHESTPLATE: 13,
      ItemId.MITHRIL_LEGS: 13,
    };
    for (final entry in spine.entries) {
      final piece = entry.key.build() as EquipmentItem;
      expect(
        piece.effectiveSkillBonus[SkillId.DEFENCE],
        entry.value,
        reason: entry.key.name,
      );
    }

    // a weapon is a damage dealer, not a stat stick: the spine shows in the
    // rung it is made from, and in what a swing deals
    const weapons = {
      ItemId.COPPER_DAGGER: 0,
      ItemId.IRON_DAGGER: 2,
      ItemId.STEEL_DAGGER: 3,
      ItemId.MITHRIL_DAGGER: 4,
    };
    double? previousDamage;
    for (final entry in weapons.entries) {
      final def = entry.key.definition as WeaponItemDefinition;
      expect(def.materialRung, entry.value, reason: entry.key.name);
      final damage = def.damageAt(Rarity.COMMON);
      if (previousDamage != null) {
        expect(damage, greaterThan(previousDamage), reason: entry.key.name);
      }
      previousDamage = damage;
    }

    expect(
      (ItemId.MITHRIL_SICKLE.build() as EquipmentItem)
          .effectiveSkillBonus[SkillId.HERBALISM],
      13,
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
    // still ignore it: a rung-0 helmet at epic is 3 by the +2 floor, not
    // fib(3) = 5.
    expect(helmet.fibLevel, def.fibLevel + Rarity.EPIC.rung);
    expect(helmet.effectiveSkillBonus[SkillId.DEFENCE], 3);
    expect(Util.fib(helmet.fibLevel), 5);
  });
}
