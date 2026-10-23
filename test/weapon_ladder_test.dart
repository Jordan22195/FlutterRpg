import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/combat_tuning.dart';
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

  test('an axe and a pickaxe swing damage; a sickle pours its rung', () {
    for (final metal in metals.keys) {
      for (final tool in ['AXE', 'PICKAXE']) {
        final def = defFor(metal, tool);
        expect(def.armorSlot, ArmorSlots.TOOL);
        // no stat to add: the swing's damage is what the tool is
        expect(def.statWeights, isEmpty, reason: '${metal}_$tool');
        expect(def.usesDamage, isTrue);
        expect(
          def.damageAt(Rarity.COMMON),
          weaponDamageForRung(metals[metal]!.parameters.fibLevel) *
              2 *
              toolDamageScale,
          reason: '${metal}_$tool is off the damage ladder',
        );
      }
      // a sickle does not hit anything: herbalism is what its roll reads
      final sickle = defFor(metal, 'SICKLE');
      expect(sickle.usesDamage, isFalse);
      expect(sickle.statWeights.keys, [SkillId.HERBALISM]);
      expect(
        sickle.statsAt(Rarity.COMMON)[SkillId.HERBALISM],
        Util.fib(sickle.fibLevel),
      );
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

  test('every shape of a metal lands the same damage per second', () {
    // a slower shape hits harder by exactly what it gives up in speed, so
    // the shapes differ in which stance boost they take, not in their rate
    for (final metal in metals.entries) {
      final perSecond = <double>[];
      for (final shape in ['DAGGER', 'SWORD', 'GREATSWORD']) {
        final def = defFor(metal.key, shape);
        // the damage is the whole of what it is: no attack on it
        expect(def.statWeights, isEmpty, reason: '${metal.key}_$shape');
        expect(def.statsAt(Rarity.COMMON), isEmpty);
        final seconds = def.actionInterval.inMicroseconds / 1e6;
        perSecond.add(def.damageAt(Rarity.COMMON) / seconds);

        // a better roll scales it the way it scales any piece's stats
        for (final rarity in Rarity.values) {
          expect(
            def.damageAt(rarity),
            closeTo(def.damageAt(Rarity.COMMON) * rarity.statMultiplier, 1e-9),
          );
        }
      }
      expect(perSecond.toSet(), {
        weaponDamageForRung(metal.value.parameters.fibLevel),
      }, reason: '${metal.key} shapes are not even per second');
    }
  });

  test('the shapes lean on different stances', () {
    // a dagger turns speed into the most swings, a greatsword strength into
    // the most damage, and a sword sits between
    final dagger = WeaponTypeId.DAGGER.parameters;
    final sword = WeaponTypeId.SWORD.parameters;
    final greatsword = WeaponTypeId.GREATSWORD.parameters;
    expect(dagger.speedAffinity, greaterThan(sword.speedAffinity));
    expect(sword.speedAffinity, greaterThan(greatsword.speedAffinity));
    expect(greatsword.strengthAffinity, greaterThan(sword.strengthAffinity));
    expect(sword.strengthAffinity, greaterThan(dagger.strengthAffinity));
  });
}
