import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';

/// A weapon is two halves: the metal it is cut from and the shape it is cut
/// into. The metal sets the rung, the shape sets what it is worth over that
/// rung, what it swings at and how fast — so a copper sword is
/// `COPPER + SWORD` and not a single hand-tuned number anywhere.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const metals = <String, EquipmentMaterialId>{
    'COPPER': EquipmentMaterialId.COPPER,
    'IRON': EquipmentMaterialId.IRON,
    'STEEL': EquipmentMaterialId.STEEL,
    'MITHRIL': EquipmentMaterialId.MITHRIL,
  };

  // suffix in the catalog -> the shape it is cut into
  const shapes = <String, WeaponTypeId>{
    'DAGGER': WeaponTypeId.DAGGER,
    'SWORD': WeaponTypeId.SWORD,
    'GREATSWORD': WeaponTypeId.GREATSWORD,
    'AXE': WeaponTypeId.AXE,
    'PICKAXE': WeaponTypeId.PICKAXE,
    'SICKLE': WeaponTypeId.SICKLE,
  };

  WeaponItemDefinition defFor(String metal, String shape) {
    final name = '${metal}_$shape';
    final id = ItemId.values.firstWhere(
      (i) => i.name == name,
      orElse: () => throw StateError('no ItemId named $name'),
    );
    return id.definition as WeaponItemDefinition;
  }

  test('every metal comes in every shape, and says which it is', () {
    for (final metal in metals.entries) {
      for (final shape in shapes.entries) {
        final def = defFor(metal.key, shape.key);
        expect(def.materialId, metal.value);
        expect(def.weaponType, shape.value);
      }
    }
  });

  test('a weapon takes its rung from its metal plus its shape', () {
    // the assertion the migration exists for: no weapon states a rung, a
    // slot, a split or a speed of its own, so none of them can drift
    for (final metal in metals.entries) {
      for (final shape in shapes.entries) {
        final def = defFor(metal.key, shape.key);
        final type = shape.value.parameters;
        expect(
          def.fibLevel,
          metal.value.parameters.fibLevel + type.fibOffset,
          reason: '${metal.key}_${shape.key} states a rung of its own',
        );
        expect(def.armorSlot, type.slot);
        expect(def.actionInterval, type.actionInterval);
        expect(def.statWeights, type.statWeight);
      }
    }
  });

  test(
    'a weapon is wielded with its shape\'s skill, at its metal\'s level',
    () {
      // the two halves answer different halves of the same question: a copper
      // sword asks for attack because it is a sword, at the level copper asks
      // for because it is copper
      const wieldedWith = {
        'DAGGER': SkillId.ATTACK,
        'SWORD': SkillId.ATTACK,
        'GREATSWORD': SkillId.ATTACK,
        'AXE': SkillId.WOODCUTTING,
        'PICKAXE': SkillId.MINING,
        'SICKLE': SkillId.HERBALISM,
      };
      for (final metal in metals.entries) {
        for (final shape in wieldedWith.entries) {
          final def = defFor(metal.key, shape.key);
          expect(
            def.skillRequirement,
            shape.value,
            reason: '${metal.key}_${shape.key} is wielded with the wrong skill',
          );
          expect(
            def.skillLevelRequirement,
            metal.value.parameters.skillLevelRequirement,
            reason: '${metal.key}_${shape.key} is not gated by its metal',
          );
        }
      }
      // armour keeps taking both halves from the metal
      final helmet =
          ItemId.MITHRIL_HELMET.definition as EquipmentItemDefinition;
      expect(helmet.skillRequirement, SkillId.DEFENCE);
      expect(helmet.skillLevelRequirement, 60);
    },
  );

  test('the shape is the trade: slower swing, higher rung', () {
    // a dagger at the same metal is two rungs under a greatsword, and
    // swings three times in the time the greatsword swings once
    for (final metal in metals.keys) {
      final dagger = defFor(metal, 'DAGGER');
      final sword = defFor(metal, 'SWORD');
      final great = defFor(metal, 'GREATSWORD');

      expect(sword.fibLevel, dagger.fibLevel + 1);
      expect(great.fibLevel, sword.fibLevel + 1);
      expect(sword.actionInterval, greaterThan(dagger.actionInterval));
      expect(great.actionInterval, greaterThan(sword.actionInterval));
    }
  });

  test('a tool pours its rung into its own skill, not into attack', () {
    const tools = {
      'AXE': SkillId.WOODCUTTING,
      'PICKAXE': SkillId.MINING,
      'SICKLE': SkillId.HERBALISM,
    };
    for (final metal in metals.keys) {
      for (final tool in tools.entries) {
        final def = defFor(metal, tool.key);
        expect(def.armorSlot, ArmorSlots.TOOL);
        expect(def.statWeights.keys, [tool.value]);
        expect(
          def.statsAt(Rarity.COMMON)[tool.value],
          Util.fib(def.fibLevel),
          reason: '${metal}_${tool.key} does not pay out its whole rung',
        );
      }
    }
  });

  test('the pieces off the metal ladder still stand where they stood', () {
    // stone, bone and boss drops have no metal to take a rung from, so they
    // state one outright — the override has to keep winning over the pair
    const before = <ItemId, (int, ArmorSlots, int)>{
      // rung, slot, swing in ms
      ItemId.STONE_AXE: (0, ArmorSlots.TOOL, 2000),
      ItemId.STONE_PICKAXE: (0, ArmorSlots.TOOL, 2000),
      ItemId.FISHBONE_DAGGER: (2, ArmorSlots.WEAPON_1H, 1000),
      ItemId.SIMPLE_FISHING_ROD: (0, ArmorSlots.TOOL, 2000),
      ItemId.PITCHFORK: (2, ArmorSlots.WEAPON_2H, 3000),
      ItemId.GOBLIN_SCEPTER: (5, ArmorSlots.WEAPON_1H, 2000),
    };
    for (final entry in before.entries) {
      final def = entry.key.definition as WeaponItemDefinition;
      expect(def.fibLevel, entry.value.$1, reason: '${entry.key.name} rung');
      expect(def.armorSlot, entry.value.$2, reason: '${entry.key.name} slot');
      expect(
        def.actionInterval.inMilliseconds,
        entry.value.$3,
        reason: '${entry.key.name} swing',
      );
    }
    // the goblin scepter is the one weapon that defends as well as attacks
    expect(
      (ItemId.GOBLIN_SCEPTER.definition as WeaponItemDefinition).statWeights,
      {SkillId.ATTACK: 12, SkillId.DEFENCE: 4},
    );
  });

  test('every equipment definition names a slot, one way or the other', () {
    // armour has no type to fall back on, so a slot left off an armour
    // definition throws rather than defaulting to somewhere plausible
    for (final id in ItemId.values) {
      final def = id.definition;
      if (def is! EquipmentItemDefinition) continue;
      expect(
        () => def.armorSlot,
        returnsNormally,
        reason: '${id.name} states no slot and has no type to take one from',
      );
    }
  });

  test('moving weapons onto the pair changed nobody\'s gear', () {
    // every attack total the hand-written ladder paid out, frozen from the
    // catalog as it shipped
    const before = <ItemId, List<int>>{
      // COMMON, UNCOMMON, RARE, EPIC, LEGENDARY
      ItemId.COPPER_DAGGER: [1, 2, 3, 4, 5],
      ItemId.IRON_DAGGER: [2, 3, 4, 5, 6],
      ItemId.STEEL_DAGGER: [3, 4, 5, 6, 7],
      ItemId.MITHRIL_DAGGER: [5, 6, 7, 8, 9],
      ItemId.COPPER_SWORD: [2, 3, 4, 5, 6],
      ItemId.IRON_SWORD: [3, 4, 5, 6, 7],
      ItemId.STEEL_SWORD: [5, 6, 7, 8, 9],
      ItemId.MITHRIL_SWORD: [8, 10, 11, 13, 14],
      ItemId.COPPER_GREATSWORD: [3, 4, 5, 6, 7],
      ItemId.IRON_GREATSWORD: [5, 6, 7, 8, 9],
      ItemId.STEEL_GREATSWORD: [8, 10, 11, 13, 14],
      ItemId.MITHRIL_GREATSWORD: [13, 16, 18, 21, 23],
    };
    for (final entry in before.entries) {
      final def = entry.key.definition as WeaponItemDefinition;
      expect(
        [for (final r in Rarity.values) def.statsAt(r)[SkillId.ATTACK]],
        entry.value,
        reason: '${entry.key.name} is not the weapon it used to be',
      );
    }
  });
}
