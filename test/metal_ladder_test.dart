import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';

/// The metal spine: four tiers across six slots, every piece pouring its
/// whole rung into defence.
///
/// None of it is written by hand any more. A plate piece names the metal it
/// is made of and the slot it fills, and both its rung and its split fall
/// out of those two — so a new tier is a row in [EquipmentMaterialId] rather
/// than six hand-tuned numbers that can drift apart.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // tiers in ascending order, and the material each one is cut from
  const tiers = <String, EquipmentMaterialId>{
    'COPPER': EquipmentMaterialId.COPPER,
    'IRON': EquipmentMaterialId.IRON,
    'STEEL': EquipmentMaterialId.STEEL,
    'MITHRIL': EquipmentMaterialId.MITHRIL,
  };

  const pieces = <String, ArmorSlots>{
    'HELMET': ArmorSlots.HEAD,
    'CHESTPLATE': ArmorSlots.CHEST,
    'LEGS': ArmorSlots.LEGS,
    'BOOTS': ArmorSlots.FEET,
    'GLOVES': ArmorSlots.HANDS,
    'SHIELD': ArmorSlots.OFFHAND,
  };

  ItemId idFor(String tier, String piece) {
    final name = '${tier}_$piece';
    return ItemId.values.firstWhere(
      (i) => i.name == name,
      orElse: () => throw StateError('no ItemId named $name'),
    );
  }

  EquipmentItemDefinition defFor(String tier, String piece) =>
      idFor(tier, piece).definition as EquipmentItemDefinition;

  test('every tier covers every slot, in the metal it is named for', () {
    for (final tier in tiers.entries) {
      for (final piece in pieces.entries) {
        final def = defFor(tier.key, piece.key);
        expect(
          def.armorSlot,
          piece.value,
          reason: '${tier.key}_${piece.key} is in the wrong slot',
        );
        expect(
          def.materialId,
          tier.value,
          reason: '${tier.key}_${piece.key} is not made of ${tier.key}',
        );
      }
    }
  });

  test('a piece takes its rung from its material and its slot', () {
    // the assertion the migration exists for: no plate piece states a rung
    // of its own, so none of them can drift off the material it is cut from
    for (final tier in tiers.entries) {
      for (final piece in pieces.entries) {
        final def = defFor(tier.key, piece.key);
        expect(
          def.fibLevel,
          tier.value.parameters.fibLevel + piece.value.fibOffset,
          reason: '${tier.key}_${piece.key} states a rung of its own',
        );
      }
    }
  });

  test('a piece takes its split from its material: all of it to defence', () {
    for (final tier in tiers.keys) {
      for (final piece in pieces.keys) {
        final def = defFor(tier, piece);
        expect(def.statWeights, {
          SkillId.DEFENCE: 1,
        }, reason: '$tier\_$piece is not pure plate');
        // a single weight is the whole budget, whatever number it is
        // written as, so the rung is exactly what the piece pays out
        expect(
          def.statsAt(Rarity.COMMON)[SkillId.DEFENCE],
          Util.fib(def.fibLevel),
        );
      }
    }
  });

  test('a tier is worth exactly one rung over the tier below', () {
    final ladder = tiers.keys.toList();
    for (final piece in pieces.keys) {
      for (var tier = 1; tier < ladder.length; tier++) {
        expect(
          defFor(ladder[tier], piece).fibLevel,
          defFor(ladder[tier - 1], piece).fibLevel + 1,
          reason: '${ladder[tier]}_$piece is off the ladder',
        );
      }
    }
  });

  test('a major piece outranks a minor one at the same tier', () {
    for (final tier in tiers.keys) {
      final helmet = defFor(tier, 'HELMET').fibLevel;
      expect(
        defFor(tier, 'CHESTPLATE').fibLevel,
        helmet + 1,
        reason: '$tier lost the major/minor spread',
      );
      expect(defFor(tier, 'LEGS').fibLevel, helmet + 1);
      expect(
        defFor(tier, 'SHIELD').fibLevel,
        helmet + 2,
        reason: '$tier shield is not worth the slot it costs',
      );
    }
  });

  test('moving the ladder onto materials changed nobody\'s gear', () {
    // every defence total the hand-written ladder paid out, at every
    // rarity, frozen from the catalog as it shipped: a save that holds a
    // plate piece loads reading exactly what it read before
    const before = <ItemId, List<int>>{
      // COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
      ItemId.COPPER_HELMET: [1, 2, 3, 4, 5],
      ItemId.IRON_HELMET: [2, 3, 4, 5, 6],
      ItemId.STEEL_HELMET: [3, 4, 5, 6, 7],
      ItemId.MITHRIL_HELMET: [5, 6, 7, 8, 9],
      ItemId.COPPER_CHESTPLATE: [2, 3, 4, 5, 6],
      ItemId.IRON_CHESTPLATE: [3, 4, 5, 6, 7],
      ItemId.STEEL_CHESTPLATE: [5, 6, 7, 8, 9],
      ItemId.MITHRIL_CHESTPLATE: [8, 10, 11, 13, 14],
      ItemId.COPPER_LEGS: [2, 3, 4, 5, 6],
      ItemId.IRON_LEGS: [3, 4, 5, 6, 7],
      ItemId.STEEL_LEGS: [5, 6, 7, 8, 9],
      ItemId.MITHRIL_LEGS: [8, 10, 11, 13, 14],
      ItemId.COPPER_BOOTS: [1, 2, 3, 4, 5],
      ItemId.IRON_BOOTS: [2, 3, 4, 5, 6],
      ItemId.STEEL_BOOTS: [3, 4, 5, 6, 7],
      ItemId.MITHRIL_BOOTS: [5, 6, 7, 8, 9],
      ItemId.COPPER_GLOVES: [1, 2, 3, 4, 5],
      ItemId.IRON_GLOVES: [2, 3, 4, 5, 6],
      ItemId.STEEL_GLOVES: [3, 4, 5, 6, 7],
      ItemId.MITHRIL_GLOVES: [5, 6, 7, 8, 9],
      ItemId.COPPER_SHIELD: [3, 4, 5, 6, 7],
      ItemId.IRON_SHIELD: [5, 6, 7, 8, 9],
      ItemId.STEEL_SHIELD: [8, 10, 11, 13, 14],
      ItemId.MITHRIL_SHIELD: [13, 16, 18, 21, 23],
    };

    for (final entry in before.entries) {
      final def = entry.key.definition as EquipmentItemDefinition;
      expect(
        [for (final r in Rarity.values) def.statsAt(r)[SkillId.DEFENCE]],
        entry.value,
        reason: '${entry.key.name} is not the piece it used to be',
      );
    }
  });
}
