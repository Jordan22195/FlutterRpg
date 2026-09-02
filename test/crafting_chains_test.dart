import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/data/skill_data.dart';

/// The production chains hang together: every recipe input is something the
/// game can actually produce, and each tier's gear is reachable from the ore
/// that feeds it.
///
/// These are reachability checks, not balance ones — they assert that a chain
/// closes, never what a level or an xp award happens to be.
void main() {
  final recipes = RecipeCatalog();

  /// Every item any recipe can output.
  Set<ItemId> craftable() => {
    for (final r in recipes.recipes)
      for (final o in r.output) o.id,
  };

  CraftingRecipe? making(ItemId item) {
    for (final r in recipes.recipes) {
      if (r.output.any((o) => o.id == item)) return r;
    }
    return null;
  }

  group('the steel tier', () {
    test('steel bar is an alloy of coal and iron ore', () {
      final bar = making(ItemId.STEEL_BAR);
      expect(bar, isNotNull, reason: 'nothing smelts a steel bar');
      expect(bar!.inputs.keys, containsAll([ItemId.COAL, ItemId.IRON_ORE]));
      // ore straight into the furnace with the coal — going through an iron
      // bar first would charge the player two smelts for one steel bar
      expect(bar.inputs.containsKey(ItemId.IRON_BAR), isFalse);
      expect(bar.skill, SkillId.BLACKSMITHING);
    });

    test('every steel item can be forged, and only from steel bars', () {
      final steel = ItemId.values.where(
        (i) => i.name.startsWith('STEEL_') && i != ItemId.STEEL_BAR,
      );
      expect(steel, isNotEmpty);
      for (final item in steel) {
        final r = making(item);
        expect(r, isNotNull, reason: 'nothing forges ${item.name}');
        expect(
          r!.inputs.keys.single,
          ItemId.STEEL_BAR,
          reason: '${item.name} should be forged from steel bars',
        );
      }
    });

    test('steel gear outranks the iron piece it replaces', () {
      // the Fibonacci ladder: each slot steps one index per tier, so the
      // steel piece is strictly better than its iron counterpart
      for (final pair in [
        (ItemId.IRON_HELMET, ItemId.STEEL_HELMET),
        (ItemId.IRON_CHESTPLATE, ItemId.STEEL_CHESTPLATE),
        (ItemId.IRON_SHIELD, ItemId.STEEL_SHIELD),
        (ItemId.IRON_DAGGER, ItemId.STEEL_DAGGER),
      ]) {
        final iron = pair.$1.build() as EquipmentItem;
        final steel = pair.$2.build() as EquipmentItem;
        for (final entry in iron.effectiveSkillBonus.entries) {
          expect(
            steel.effectiveSkillBonus[entry.key],
            greaterThan(entry.value),
            reason: '${pair.$2.name} should beat ${pair.$1.name}',
          );
        }
      }
    });
  });

  group('the mithril tier', () {
    test('mithril bar is an alloy of coal and mithril ore', () {
      final bar = making(ItemId.MITHRIL_BAR);
      expect(bar, isNotNull, reason: 'nothing smelts a mithril bar');
      expect(bar!.inputs.keys, containsAll([ItemId.COAL, ItemId.MITHRIL_ORE]));
      // ore straight into the furnace with the coal, the way steel works —
      // going through another bar first would charge two smelts for one
      expect(bar.inputs.containsKey(ItemId.STEEL_BAR), isFalse);
      expect(bar.inputs.containsKey(ItemId.IRON_BAR), isFalse);
      expect(bar.skill, SkillId.BLACKSMITHING);
    });

    test('every mithril item can be forged, and only from mithril bars', () {
      final mithril = ItemId.values.where(
        (i) =>
            i.name.startsWith('MITHRIL_') &&
            i != ItemId.MITHRIL_BAR &&
            i != ItemId.MITHRIL_ORE,
      );
      expect(mithril, isNotEmpty);
      for (final item in mithril) {
        final r = making(item);
        expect(r, isNotNull, reason: 'nothing forges ${item.name}');
        expect(
          r!.inputs.keys.single,
          ItemId.MITHRIL_BAR,
          reason: '${item.name} should be forged from mithril bars',
        );
      }
    });

    test('mithril gear outranks the steel piece it replaces', () {
      for (final pair in [
        (ItemId.STEEL_HELMET, ItemId.MITHRIL_HELMET),
        (ItemId.STEEL_CHESTPLATE, ItemId.MITHRIL_CHESTPLATE),
        (ItemId.STEEL_SHIELD, ItemId.MITHRIL_SHIELD),
        (ItemId.STEEL_DAGGER, ItemId.MITHRIL_DAGGER),
      ]) {
        final steel = pair.$1.build() as EquipmentItem;
        final mithril = pair.$2.build() as EquipmentItem;
        for (final entry in steel.effectiveSkillBonus.entries) {
          expect(
            mithril.effectiveSkillBonus[entry.key],
            greaterThan(entry.value),
            reason: '${pair.$2.name} should beat ${pair.$1.name}',
          );
        }
      }
    });

    test('it costs more to make than the tier below', () {
      final steel = making(ItemId.STEEL_BAR)!;
      final mithril = making(ItemId.MITHRIL_BAR)!;
      expect(
        mithril.levelRequirement,
        greaterThan(steel.levelRequirement),
        reason: 'mithril should open after steel',
      );
      expect(
        mithril.inputs[ItemId.COAL],
        greaterThan(steel.inputs[ItemId.COAL]!),
        reason: 'a tier 4 bar should not be cheaper than a tier 3 one',
      );
    });
  });

  group('the gathering tools', () {
    test('every tier can forge all three, from its own bar', () {
      // the sickles were missing at copper and iron for a while, which left
      // Herbalism with no craftable tool below steel
      const tiers = {
        ItemId.COPPER_BAR: [
          ItemId.COPPER_PICKAXE,
          ItemId.COPPER_AXE,
          ItemId.COPPER_SICKLE,
        ],
        ItemId.IRON_BAR: [
          ItemId.IRON_PICKAXE,
          ItemId.IRON_AXE,
          ItemId.IRON_SICKLE,
        ],
        ItemId.STEEL_BAR: [
          ItemId.STEEL_PICKAXE,
          ItemId.STEEL_AXE,
          ItemId.STEEL_SICKLE,
        ],
        ItemId.MITHRIL_BAR: [
          ItemId.MITHRIL_PICKAXE,
          ItemId.MITHRIL_AXE,
          ItemId.MITHRIL_SICKLE,
        ],
      };
      tiers.forEach((bar, tools) {
        for (final tool in tools) {
          final r = making(tool);
          expect(r, isNotNull, reason: 'nothing forges ${tool.name}');
          expect(
            r!.inputs.keys.single,
            bar,
            reason: '${tool.name} should be forged from ${bar.name}',
          );
        }
      });
    });

    test('a tier gates its three tools together', () {
      // pickaxe, axe and sickle are one rung: no reason mining should open
      // before herbalism within a tier
      for (final tools in [
        ['forge_copper_pickaxe', 'forge_copper_axe', 'forge_copper_sickle'],
        ['forge_iron_pickaxe', 'forge_iron_axe', 'forge_iron_sickle'],
        ['forge_steel_pickaxe', 'forge_steel_axe', 'forge_steel_sickle'],
        ['forge_mithril_pickaxe', 'forge_mithril_axe', 'forge_mithril_sickle'],
      ]) {
        final levels = tools
            .map((id) => recipes.recipeById(id).levelRequirement)
            .toSet();
        expect(
          levels,
          hasLength(1),
          reason: '$tools should share one level, got $levels',
        );
      }
    });
  });

  group('the gold and jewellery chain', () {
    test('gold ore smelts to a bar, which becomes both bases', () {
      final bar = making(ItemId.GOLD_BAR);
      expect(bar, isNotNull, reason: 'nothing smelts a gold bar');
      expect(bar!.inputs.keys.single, ItemId.GOLD_ORE);

      for (final base in [ItemId.GOLD_RING, ItemId.GOLD_NECKLACE]) {
        final r = making(base);
        expect(r, isNotNull, reason: 'nothing makes ${base.name}');
        expect(r!.inputs.keys.single, ItemId.GOLD_BAR);
        expect(r.skill, SkillId.JEWELCRAFTING);
      }
    });

    test('no copper jewellery recipe survives the move to gold', () {
      final ids = recipes.recipes.map((r) => r.id).toList();
      expect(ids, isNot(contains('forge_copper_ring')));
      expect(ids, isNot(contains('forge_copper_necklace')));
    });

    test('every gem recipe is fed by a base something makes', () {
      final made = craftable();
      final gemRecipes = recipes.recipes.where(
        (r) =>
            r.skill == SkillId.JEWELCRAFTING &&
            (r.inputs.containsKey(ItemId.GOLD_RING) ||
                r.inputs.containsKey(ItemId.GOLD_NECKLACE)),
      );
      expect(gemRecipes, isNotEmpty);
      // the bases are the whole point: a gem recipe with no way to obtain
      // its base is an unplayable skill, which is what this guards
      expect(made, contains(ItemId.GOLD_RING));
      expect(made, contains(ItemId.GOLD_NECKLACE));
    });
  });

  group('the willow fires', () {
    test('all three burn willow logs, which woodcutting yields', () {
      for (final fire in [
        ItemId.WILLOW_COOKFIRE,
        ItemId.WILLOW_CAMPFIRE,
        ItemId.WILLOW_BONFIRE,
      ]) {
        final r = making(fire);
        expect(r, isNotNull, reason: 'nothing lays a ${fire.name}');
        expect(r!.inputs.keys.single, ItemId.WILLOW_LOGS);
        expect(r.skill, SkillId.FIREMAKING);
      }
    });

    test('the fire ladder climbs, tier over tier', () {
      // cooking 3 / 5 / 8 across the three cookfires, and the campfire and
      // bonfire lines climb the same way. Assert the climb, not the numbers.
      int cooking(ItemId id) =>
          (id.build() as FireItem).skillBonus[SkillId.COOKING] ?? 0;
      expect(cooking(ItemId.COOKFIRE), lessThan(cooking(ItemId.OAK_COOKFIRE)));
      expect(
        cooking(ItemId.OAK_COOKFIRE),
        lessThan(cooking(ItemId.WILLOW_COOKFIRE)),
      );

      Duration burn(ItemId id) => (id.build() as FireItem).duration;
      expect(burn(ItemId.OAK_BONFIRE), greaterThan(burn(ItemId.BONFIRE)));
      expect(
        burn(ItemId.WILLOW_BONFIRE),
        greaterThan(burn(ItemId.OAK_BONFIRE)),
      );
    });

    test('only cookfires can be cooked on, at every tier', () {
      for (final id in [
        ItemId.COOKFIRE,
        ItemId.OAK_COOKFIRE,
        ItemId.WILLOW_COOKFIRE,
      ]) {
        expect((id.build() as FireItem).canCook, isTrue, reason: id.name);
      }
      for (final id in [ItemId.WILLOW_CAMPFIRE, ItemId.WILLOW_BONFIRE]) {
        expect((id.build() as FireItem).canCook, isFalse, reason: id.name);
      }
    });
  });

  group('recipe inputs are all obtainable', () {
    test('every input is craftable, gathered, or dropped somewhere', () {
      // A recipe whose input nothing produces is a dead recipe. Crafted
      // outputs cover the chains; anything else has to come from the world,
      // which the catalog integrity suite already checks drop tables for.
      final made = craftable();
      for (final r in recipes.recipes) {
        for (final input in r.inputs.keys) {
          if (made.contains(input)) continue;
          // a raw input: it must at least be a real, named item
          expect(
            input,
            isNot(ItemId.NULL),
            reason: 'recipe ${r.id} takes a NULL input',
          );
        }
      }
    });
  });
}
