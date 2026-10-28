import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/equipment_service.dart';

/// The leather ladder: nine tiers across eight slots, every piece splitting
/// its budget evenly between attack and defence.
///
/// The split is what makes leather a choice rather than a downgrade. A metal
/// piece puts its whole rung into defence; a leather piece at the same rung
/// splits that same budget exactly between the two, so it matches plate on
/// total stats — and buys the attack by giving up some of the defence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // tiers in ascending order; the tier-1 chest carries a frozen misspelling
  const tiers = [
    'LIGHT_LEATHER',
    'MEDIUM_LEATHER',
    'HEAVY_LEATHER',
    'LIGHT_DRAGONHIDE',
    'MEDIUM_DRAGONHIDE',
    'HEAVY_DRAGONHIDE',
    'LIGHT_DEMONHIDE',
    'MEDIUM_DEMONHIDE',
    'HEAVY_DEMONHIDE',
  ];

  // piece suffix -> the slot it fills and the rung tier 1 starts on. Chest,
  // legs and shoulders are the major pieces and sit one rung above the rest,
  // the same spread the metal ladder has.
  const pieces = <String, (ArmorSlots, int)>{
    'COIF': (ArmorSlots.HEAD, 0),
    'SPAULDERS': (ArmorSlots.SHOULDER, 1),
    'CHEST': (ArmorSlots.CHEST, 1),
    'BELT': (ArmorSlots.WAIST, 0),
    'BRACERS': (ArmorSlots.WRIST, 0),
    'PANTS': (ArmorSlots.LEGS, 1),
    'BOOTS': (ArmorSlots.FEET, 0),
    'GLOVES': (ArmorSlots.HANDS, 0),
  };

  ItemId idFor(int tier, String piece) {
    // LIGHT_LETHER_CHEST shipped misspelled and the name is the save format
    final name = tier == 0 && piece == 'CHEST'
        ? 'LIGHT_LETHER_CHEST'
        : '${tiers[tier]}_$piece';
    return ItemId.values.firstWhere(
      (i) => i.name == name,
      orElse: () => throw StateError('no ItemId named $name'),
    );
  }

  EquipmentItemDefinition defFor(int tier, String piece) =>
      idFor(tier, piece).definition as EquipmentItemDefinition;

  test('every tier covers every slot', () {
    for (var tier = 0; tier < tiers.length; tier++) {
      for (final piece in pieces.entries) {
        expect(
          defFor(tier, piece.key).armorSlot,
          piece.value.$1,
          reason: '${tiers[tier]}_${piece.key} is in the wrong slot',
        );
      }
    }
  });

  test('a piece takes its rung and its split from the hide it is cut from', () {
    // the assertion the migration exists for: no hide piece states a rung or
    // a split of its own, so a tier cannot drift off the material it names
    for (var tier = 0; tier < tiers.length; tier++) {
      final material = EquipmentMaterialId.values.byName(tiers[tier]);
      for (final piece in pieces.entries) {
        final def = defFor(tier, piece.key);
        expect(
          def.materialId,
          material,
          reason: '${tiers[tier]}_${piece.key} is not cut from ${tiers[tier]}',
        );
        expect(
          def.fibLevel,
          material.parameters.fibLevel + piece.value.$1.fibOffset,
          reason: '${tiers[tier]}_${piece.key} states a rung of its own',
        );
        expect(
          def.statWeights,
          material.parameters.statWeight,
          reason: '${tiers[tier]}_${piece.key} states a split of its own',
        );
      }
    }
  });

  test('a hide sits on the rung of the plate it is gated like', () {
    // a hide splits its rung exactly, so it adds up to the plate of the same
    // rung and is gated like it — the two ladders stay level at every tier
    // they share
    const plateBelow = {
      'LIGHT_LEATHER': EquipmentMaterialId.COPPER,
      'MEDIUM_LEATHER': EquipmentMaterialId.IRON,
      'HEAVY_LEATHER': EquipmentMaterialId.STEEL,
      'LIGHT_DRAGONHIDE': EquipmentMaterialId.MITHRIL,
      'MEDIUM_DRAGONHIDE': EquipmentMaterialId.ADAMANT,
      'HEAVY_DRAGONHIDE': EquipmentMaterialId.RUNE,
      'LIGHT_DEMONHIDE': EquipmentMaterialId.DRAGON,
    };
    for (final entry in plateBelow.entries) {
      final hide = EquipmentMaterialId.values.byName(entry.key);
      expect(
        hide.parameters.fibLevel,
        entry.value.parameters.fibLevel,
        reason: '${entry.key} is not on the rung of ${entry.value.name}',
      );
      expect(
        hide.parameters.skillLevelRequirement,
        entry.value.parameters.skillLevelRequirement,
        reason: '${entry.key} is not gated like ${entry.value.name}',
      );
    }
    // the last two hides run past the end of the metal ladder, so they run
    // up to the level cap instead of alongside a plate tier
    expect(
      EquipmentMaterialId.MEDIUM_DEMONHIDE.parameters.skillLevelRequirement,
      95,
    );
    expect(
      EquipmentMaterialId.HEAVY_DEMONHIDE.parameters.skillLevelRequirement,
      99,
    );
  });

  test('every piece splits its budget evenly between attack and defence', () {
    for (var tier = 0; tier < tiers.length; tier++) {
      for (final piece in pieces.keys) {
        final def = defFor(tier, piece);
        expect(def.statWeights, {
          SkillId.ATTACK: 1,
          SkillId.DEFENCE: 1,
        }, reason: '${tiers[tier]}_$piece is not a hybrid');
        // the split is exact, so the budget is the total and a rarity roll
        // always pays out its floor, even on the bottom rung
        int total(Rarity r) =>
            def.statsAt(r).values.fold(0, (sum, stat) => sum + stat);
        expect(
          total(Rarity.UNCOMMON),
          greaterThanOrEqualTo(
            total(Rarity.COMMON) + Rarity.UNCOMMON.minStatBonus,
          ),
          reason: '${tiers[tier]}_$piece would not gain from a rarity roll',
        );
      }
    }
  });

  test('a tier is worth exactly one rung over the tier below', () {
    for (final piece in pieces.entries) {
      for (var tier = 0; tier < tiers.length; tier++) {
        expect(
          defFor(tier, piece.key).fibLevel,
          piece.value.$2 + tier,
          reason: '${tiers[tier]}_${piece.key} is off the ladder',
        );
      }
    }
  });

  test('a major piece outranks a minor one at the same tier', () {
    for (var tier = 0; tier < tiers.length; tier++) {
      final chest = defFor(tier, 'CHEST').fibLevel;
      final boots = defFor(tier, 'BOOTS').fibLevel;
      expect(
        chest,
        boots + 1,
        reason: 'tier ${tiers[tier]} lost the major/minor spread',
      );
    }
  });

  test('a tier is strictly stronger than the tier below, at every rarity', () {
    // the split rounds, and a rung is only ~1.6x the one under it, so this
    // is the assertion that a tier actually buys something rather than
    // rounding back to what the player already wears
    for (final piece in pieces.keys) {
      for (var tier = 1; tier < tiers.length; tier++) {
        for (final rarity in Rarity.values) {
          int total(int t) => defFor(
            t,
            piece,
          ).statsAt(rarity).values.fold(0, (sum, stat) => sum + stat);
          expect(
            total(tier),
            greaterThan(total(tier - 1)),
            reason:
                '${tiers[tier]}_$piece is worth no more than '
                '${tiers[tier - 1]}_$piece at ${rarity.name}',
          );
        }
      }
    }
  });

  test('a tier is worth twice the coin of the tier below', () {
    for (final piece in pieces.keys) {
      for (var tier = 1; tier < tiers.length; tier++) {
        expect(
          defFor(tier, piece).value,
          defFor(tier - 1, piece).value * 2,
          reason: '${tiers[tier]}_$piece is off the price curve',
        );
      }
    }
  });

  test('a piece\'s stats add up to its budget, the odd point to attack', () {
    // the rung's fib value split exactly: nothing rounds up on both sides,
    // and an odd budget gives its spare point to attack
    for (var tier = 0; tier < tiers.length; tier++) {
      for (final piece in pieces.keys) {
        final def = defFor(tier, piece);
        for (final rarity in Rarity.values) {
          final stats = def.statsAt(rarity);
          final attack = stats[SkillId.ATTACK]!;
          final defence = stats[SkillId.DEFENCE]!;
          final name = '${tiers[tier]}_$piece at ${rarity.name}';
          expect(attack + defence, def.budgetAt(rarity), reason: name);
          expect(attack - defence, anyOf(0, 1), reason: name);
        }
      }
    }
  });

  test('the common pieces read straight off the fib ladder', () {
    // rung -> fib: 0 -> 1, 1 -> 2, 2 -> 3, 3 -> 5, 4 -> 8
    Map<SkillId, int> common(ItemId id) =>
        (id.build() as EquipmentItem).effectiveSkillBonus;

    // light leather: a minor piece at rung 0, a major one at rung 1
    expect(common(ItemId.LIGHT_LEATHER_BOOTS), {
      SkillId.ATTACK: 1,
      SkillId.DEFENCE: 0,
    });
    expect(common(ItemId.LIGHT_LETHER_CHEST), {
      SkillId.ATTACK: 1,
      SkillId.DEFENCE: 1,
    });
    // medium leather, a rung up: 2 and 3
    expect(common(idFor(1, 'BOOTS')), {SkillId.ATTACK: 1, SkillId.DEFENCE: 1});
    expect(common(idFor(1, 'CHEST')), {SkillId.ATTACK: 2, SkillId.DEFENCE: 1});
    // heavy leather's chest at rung 3 is 5
    expect(common(idFor(2, 'CHEST')), {SkillId.ATTACK: 3, SkillId.DEFENCE: 2});
  });

  test('the exact split favours attack only on a tie', () {
    // the rule itself, off the ladder: larger remainders win the spare
    // points first, and a tie goes to attack whatever order it is listed in
    expect(
      EquipmentItemDefinition.exactSplit(3, {
        SkillId.DEFENCE: 1,
        SkillId.ATTACK: 1,
      }),
      {SkillId.DEFENCE: 1, SkillId.ATTACK: 2},
    );
    expect(
      EquipmentItemDefinition.exactSplit(10, {
        SkillId.ATTACK: 1,
        SkillId.DEFENCE: 2,
      }),
      {SkillId.ATTACK: 3, SkillId.DEFENCE: 7},
    );
  });

  test('plate keeps its own rounding', () {
    // only the hides split exactly; a pure-defence plate piece is its whole
    // budget, as before
    final plate =
        ItemId.COPPER_CHESTPLATE.definition as EquipmentItemDefinition;
    expect(plate.statsAt(Rarity.COMMON), {
      SkillId.DEFENCE: plate.budgetAt(Rarity.COMMON),
    });
  });

  group('the shoulder slot, which nothing in the game filled before', () {
    // spaulders are the first content to use ArmorSlots.SHOULDER. The slot
    // was already declared and already rendered by the gear screen, so this
    // covers the plumbing between the two rather than the layout.
    EquipmentItem spaulders(int tier) =>
        idFor(tier, 'SPAULDERS').build() as EquipmentItem;

    test('a fresh EquipmentData has an empty SHOULDER slot', () {
      final equipment = EquipmentData();

      expect(equipment.armorEquipment.containsKey(ArmorSlots.SHOULDER), isTrue);
      expect(equipment.armorEquipment[ArmorSlots.SHOULDER], isNull);
    });

    test('equipping spaulders fills the slot and adds both stats', () {
      final service = EquipmentService();
      final equipment = EquipmentData();
      final worn = spaulders(8); // heavy demonhide

      final displaced = service.equipItem(worn, equipment);

      expect(displaced, isEmpty);
      expect(
        equipment.armorEquipment[ArmorSlots.SHOULDER]?.name,
        'Heavy Demonhide Spaulders',
      );
      final totals = service.getStatTotals(equipment);
      expect(
        totals[SkillId.DEFENCE],
        worn.effectiveSkillBonus[SkillId.DEFENCE],
      );
      expect(totals[SkillId.ATTACK], worn.effectiveSkillBonus[SkillId.ATTACK]);
      expect(totals[SkillId.ATTACK], greaterThan(0));
    });

    test('a second pair displaces the first, and only the shoulder slot', () {
      final service = EquipmentService();
      final equipment = EquipmentData();
      final worn = spaulders(0);

      service.equipItem(worn, equipment);
      final displaced = service.equipItem(spaulders(8), equipment);

      expect(displaced?.map((item) => item.instanceId), [worn.instanceId]);
      expect(
        equipment.armorEquipment[ArmorSlots.SHOULDER]?.name,
        'Heavy Demonhide Spaulders',
      );
    });

    test('equipped spaulders survive a JSON round trip', () {
      final equipment = EquipmentData();
      EquipmentService().equipItem(spaulders(4), equipment);

      final restored = EquipmentData.fromJson(
        jsonDecode(jsonEncode(equipment.toJson())) as Map<String, dynamic>,
      );

      expect(
        restored.armorEquipment[ArmorSlots.SHOULDER]?.name,
        'Medium Dragonhide Spaulders',
      );
    });
  });
}
