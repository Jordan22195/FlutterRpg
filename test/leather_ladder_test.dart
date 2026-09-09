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
/// puts half there and half into attack, so leather has to sit a rung higher
/// to match plate — and buys the attack on top.
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

  // piece suffix -> the slot it fills and the rung tier 1 starts on. Chest and
  // legs are the major pieces and sit one rung above the rest, the same spread
  // the metal ladder has.
  const pieces = <String, (ArmorSlots, int)>{
    'COIF': (ArmorSlots.HEAD, 1),
    'SPAULDERS': (ArmorSlots.SHOULDER, 1),
    'CHEST': (ArmorSlots.CHEST, 2),
    'BELT': (ArmorSlots.WAIST, 1),
    'BRACERS': (ArmorSlots.WRIST, 1),
    'PANTS': (ArmorSlots.LEGS, 2),
    'BOOTS': (ArmorSlots.FEET, 1),
    'GLOVES': (ArmorSlots.HANDS, 1),
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

  test('every piece splits its budget evenly between attack and defence', () {
    for (var tier = 0; tier < tiers.length; tier++) {
      for (final piece in pieces.keys) {
        final def = defFor(tier, piece);
        expect(def.statWeights, {
          SkillId.ATTACK: 1,
          SkillId.DEFENCE: 1,
        }, reason: '${tiers[tier]}_$piece is not a hybrid');
        // an even split at rung 0 gives {1, 1} at common AND at uncommon,
        // because weightedShare floors each share at 1 — so the ladder has
        // to start at rung 1 or rarity stops meaning anything
        expect(
          def.fibLevel,
          greaterThanOrEqualTo(1),
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

  test('the hybrid split cost the shipped light leather no defence', () {
    // these six were pure-defence pieces before the ladder existed. Moving
    // them up a rung is what pays for the attack rider, so a save that
    // already holds one loads no weaker than it was.
    const before = {
      ItemId.LIGHT_LETHER_CHEST: 2,
      ItemId.LIGHT_LEATHER_PANTS: 2,
      ItemId.LIGHT_LEATHER_BOOTS: 1,
      ItemId.LIGHT_LEATHER_GLOVES: 1,
      ItemId.LIGHT_LEATHER_BELT: 1,
      ItemId.LIGHT_LEATHER_BRACERS: 1,
    };
    for (final entry in before.entries) {
      final piece = entry.key.build() as EquipmentItem;
      expect(
        piece.effectiveSkillBonus[SkillId.DEFENCE],
        greaterThanOrEqualTo(entry.value),
        reason: '${entry.key.name} lost defence',
      );
      expect(
        piece.effectiveSkillBonus[SkillId.ATTACK],
        greaterThan(0),
        reason: '${entry.key.name} gained no attack for the trade',
      );
    }
  });

  test('leather trades a rung of defence for the attack it carries', () {
    // the whole point of the split, asserted against the metal spine rather
    // than assumed: leather at rung n defends like plate at rung n-1
    int defenceOf(ItemId id) =>
        (id.build() as EquipmentItem).effectiveSkillBonus[SkillId.DEFENCE]!;

    // light leather jerkin sits at rung 2, copper chestplate at rung 1
    expect(defFor(0, 'CHEST').fibLevel, 2);
    expect(
      (ItemId.COPPER_CHESTPLATE.definition as EquipmentItemDefinition).fibLevel,
      1,
    );
    expect(
      defenceOf(ItemId.LIGHT_LETHER_CHEST),
      defenceOf(ItemId.COPPER_CHESTPLATE),
    );
    expect(
      (ItemId.LIGHT_LETHER_CHEST.build() as EquipmentItem)
          .effectiveSkillBonus[SkillId.ATTACK],
      greaterThan(0),
    );
    expect(
      (ItemId.COPPER_CHESTPLATE.build() as EquipmentItem)
          .effectiveSkillBonus[SkillId.ATTACK],
      anyOf(isNull, 0),
    );
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
