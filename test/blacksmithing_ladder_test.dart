import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/data/skill_data.dart';

/// The blacksmithing ladder: seven metals, each forged across the same
/// thirteen rungs of shapes.
///
/// The recipes are generated from a tier table rather than written out, so
/// these assert the table produces the ladder the design calls for — the
/// level a piece opens at, the bars it eats, and that no tier has a hole in
/// it. Balance is the point here, where crafting_chains_test only asserts
/// that the chains close.
void main() {
  final catalog = RecipeCatalog();
  final blacksmithing = catalog.recipesForSkill(SkillId.BLACKSMITHING);

  // metal -> the level its bar smelts at
  const bases = <String, int>{
    'copper': 1,
    'iron': 20,
    'steel': 40,
    'mithril': 60,
    'adamant': 70,
    'rune': 80,
    'dragon': 90,
  };

  // shape -> (rung, bars). The rung is the design's "base level + x".
  const pieces = <String, (int, int)>{
    'pickaxe': (1, 1),
    'axe': (1, 1),
    'sickle': (1, 1),
    'dagger': (2, 1),
    'helmet': (3, 1),
    'bracers': (4, 1),
    'chestplate': (5, 3),
    'gloves': (6, 1),
    'sword': (7, 2),
    'belt': (8, 1),
    'legs': (9, 2),
    'boots': (10, 1),
    'pauldrons': (11, 2),
    'shield': (12, 2),
    'greatsword': (13, 3),
  };

  // how far over its metal's base level each rung sits, per metal. The
  // bottom three are stretched to reach the tier above them; dragon is
  // squeezed to fit under the level cap.
  const stretched = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25];
  const tight = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];
  const capped = [1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 8, 8, 9];
  const rungs = <String, List<int>>{
    'copper': stretched,
    'iron': stretched,
    'steel': stretched,
    'mithril': tight,
    'adamant': tight,
    'rune': tight,
    'dragon': capped,
  };

  CraftingRecipe forge(String metal, String piece) =>
      catalog.recipeById('forge_${metal}_$piece');

  test('every metal forges every shape', () {
    for (final metal in bases.keys) {
      for (final piece in pieces.keys) {
        final r = forge(metal, piece);
        expect(
          r.skill,
          SkillId.BLACKSMITHING,
          reason: 'no recipe forges $metal $piece',
        );
        expect(r.output.single.id.name, '${_prefix(metal)}_${_id(piece)}');
      }
      expect(
        catalog.recipeById('smelt_${metal}_bar').skill,
        SkillId.BLACKSMITHING,
        reason: 'nothing smelts a $metal bar',
      );
    }
  });

  test('a shape opens at its metal\'s base level plus its rung', () {
    for (final metal in bases.keys) {
      for (final entry in pieces.entries) {
        final rung = rungs[metal]![entry.value.$1 - 1];
        expect(
          forge(metal, entry.key).levelRequirement,
          bases[metal]! + rung,
          reason: '$metal ${entry.key} is off its rung',
        );
      }
      expect(
        catalog.recipeById('smelt_${metal}_bar').levelRequirement,
        bases[metal],
        reason: '$metal bar does not smelt at the level the metal opens at',
      );
    }
  });

  test('a shape eats the same number of bars in every metal', () {
    for (final metal in bases.keys) {
      final bar = catalog.recipeById('smelt_${metal}_bar').output.single.id;
      for (final entry in pieces.entries) {
        final r = forge(metal, entry.key);
        expect(
          r.inputs,
          {bar: entry.value.$2},
          reason: '$metal ${entry.key} is not ${entry.value.$2} $bar',
        );
      }
    }
  });

  test('no recipe asks for a level the skill cannot reach', () {
    // SkillData builds a 99-level xp table, so anything above it is a
    // recipe nobody can ever forge
    for (final r in blacksmithing) {
      expect(
        r.levelRequirement,
        lessThanOrEqualTo(99),
        reason: '${r.id} is gated above the level cap',
      );
    }
  });

  test('each metal\'s tail runs past the next metal\'s head', () {
    // the overlap is the point of the stretched spacing: a tier has to
    // still have something left to forge once the tier above it opens
    final metals = bases.keys.toList();
    for (var i = 0; i < metals.length - 1; i++) {
      expect(
        forge(metals[i], 'greatsword').levelRequirement,
        greaterThan(bases[metals[i + 1]]!),
        reason: '${metals[i]} runs out before ${metals[i + 1]} opens',
      );
    }
  });

  test('a metal never opens below the one under it', () {
    final levels = bases.values.toList();
    for (var i = 1; i < levels.length; i++) {
      expect(levels[i], greaterThan(levels[i - 1]));
    }
    for (final piece in pieces.keys) {
      final metals = bases.keys.toList();
      for (var i = 1; i < metals.length; i++) {
        expect(
          forge(metals[i], piece).levelRequirement,
          greaterThan(forge(metals[i - 1], piece).levelRequirement),
          reason: '$piece does not climb from ${metals[i - 1]} '
              'to ${metals[i]}',
        );
      }
    }
  });

  test('a metal gates by what it is made of, not what it forges', () {
    // the equipable level is the material's business; this asserts the two
    // ladders agree, so nothing is forgeable long before it is wearable
    for (final metal in bases.keys) {
      for (final piece in pieces.keys) {
        final def =
            forge(metal, piece).output.single.id.definition
                as EquipmentItemDefinition;
        expect(
          def.skillLevelRequirement,
          bases[metal],
          reason: '$metal $piece is not gated at the $metal tier',
        );
      }
    }
  });

  test('forging pays for the bars it eats', () {
    for (final metal in bases.keys) {
      final perBar = forge(metal, 'dagger').xp;
      for (final entry in pieces.entries) {
        expect(
          forge(metal, entry.key).xp,
          perBar * entry.value.$2,
          reason: '$metal ${entry.key} is not paid by the bar',
        );
      }
    }
  });

  test('every recipe id the catalog shipped still exists', () {
    // ids are the save format: a queued craft in an old save is looked up
    // by these strings, so the generator must keep spelling them
    const shipped = <String>{
      'smelt_copper_bar',
      'forge_copper_dagger',
      'forge_copper_sword',
      'forge_copper_greatsword',
      'forge_copper_pickaxe',
      'forge_copper_axe',
      'forge_copper_sickle',
      'forge_copper_helmet',
      'forge_copper_gloves',
      'forge_copper_boots',
      'forge_copper_legs',
      'forge_copper_chestplate',
      'forge_copper_shield',
      'smelt_iron_bar',
      'forge_iron_dagger',
      'forge_iron_sword',
      'forge_iron_greatsword',
      'forge_iron_pickaxe',
      'forge_iron_axe',
      'forge_iron_sickle',
      'forge_iron_helmet',
      'forge_iron_gloves',
      'forge_iron_boots',
      'forge_iron_legs',
      'forge_iron_chestplate',
      'forge_iron_shield',
      'smelt_steel_bar',
      'forge_steel_dagger',
      'forge_steel_sword',
      'forge_steel_greatsword',
      'forge_steel_pickaxe',
      'forge_steel_axe',
      'forge_steel_sickle',
      'forge_steel_helmet',
      'forge_steel_gloves',
      'forge_steel_boots',
      'forge_steel_legs',
      'forge_steel_chestplate',
      'forge_steel_shield',
      'smelt_gold_bar',
      'smelt_mithril_bar',
      'forge_mithril_dagger',
      'forge_mithril_sword',
      'forge_mithril_greatsword',
      'forge_mithril_pickaxe',
      'forge_mithril_axe',
      'forge_mithril_sickle',
      'forge_mithril_helmet',
      'forge_mithril_gloves',
      'forge_mithril_boots',
      'forge_mithril_legs',
      'forge_mithril_chestplate',
      'forge_mithril_shield',
    };
    expect(blacksmithing.map((r) => r.id).toSet(), containsAll(shipped));
  });
}

/// The [ItemId] prefix for a metal. Two tiers' bars and ores were named for
/// the mineral rather than the metal, but the gear is named for the metal.
String _prefix(String metal) => metal.toUpperCase();

/// The [ItemId] suffix for a shape.
String _id(String piece) => piece.toUpperCase();
