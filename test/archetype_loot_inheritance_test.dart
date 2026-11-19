import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/utilities/util.dart';

/// A monster is an archetype (art, how it fights, common loot) plus its own
/// definition (name, rung, loot of its own, the border it is drawn with).
/// These pin the two rules that hold that together: every level is a rung
/// of the Fibonacci ladder, and inherited loot scales with how far above
/// the archetype's [CombatArchetype.lootFibLevel] a monster stands — never
/// with its rarity.

CombatEntityDefinition combat(EntityId id) =>
    id.definition as CombatEntityDefinition;

ItemDropType only(List<ItemDropType> drops, ItemId id) =>
    drops.singleWhere((d) => d.id == id);

/// [id] moved [steps] rungs above where the catalog puts it.
CombatEntityDefinition raised(EntityId id, int steps) {
  final def = combat(id);
  return def.copyWith(fibLevel: def.fibLevel + steps);
}

/// A table as plain text, so two tables compare line for line.
List<String> describe(List<ItemDropType> drops) => [
  for (final d in drops.flattened)
    '${d.id.name}/${d.rarity.name}/${d.lowCount}-${d.highCount}/${d.weight}',
];

/// A test bird: a fixed line and a range, so scaling shows on both. The
/// catalog's chicken no longer drops a range since its feathers became the
/// derived reagent roll.
const testBird = CombatArchetype(
  iconAsset: 'assets/images/entities/chicken.png',
  lootFibLevel: 2,
  combatType: CombatType.LEATHER_DPS,
  itemDrops: [
    ItemDropType(id: ItemId.CHICKEN_MEAT, weight: 1),
    ItemDropType(id: ItemId.ANIMAL_PELT, lowCount: 1, highCount: 5, weight: 1),
  ],
);
const bird = CombatEntityDefinition(testBird, fibLevel: 2, name: 'Bird');

Iterable<(EntityId, CombatEntityDefinition)> everyMonster() sync* {
  for (final id in EntityId.values) {
    if (id.definition case final CombatEntityDefinition def) yield (id, def);
  }
}

void main() {
  group('every monster stands on a rung', () {
    test('its fibLevel is on the ladder and its level is that rung', () {
      for (final (id, def) in everyMonster()) {
        expect(
          def.fibLevel,
          inInclusiveRange(0, Util.fibonacciCache.length - 1),
          reason: id.name,
        );
        expect(def.level, Util.fib(def.fibLevel), reason: id.name);
      }
    });

    test('none inherits loot written for a rung above its own', () {
      for (final (id, def) in everyMonster()) {
        if (def.lootSteps >= 0) continue;
        final reason =
            '${id.name} is on rung ${def.fibLevel}, below its '
            "archetype's lootFibLevel ${def.archetype.lootFibLevel}, so it "
            'must write its own tables';
        if (def.archetype.itemDrops.isNotEmpty) {
          expect(def.ownItemDrops, isNotNull, reason: reason);
        }
        if (def.archetype.bonusDrops.isNotEmpty) {
          expect(def.ownBonusDrops, isNotNull, reason: reason);
        }
      }
    });

    test('fibLevel alone sets the level', () {
      final chicken = combat(EntityId.CHICKEN);
      expect(chicken.copyWith(fibLevel: 10).level, 144);
      expect(chicken.copyWith(fibLevel: 11).level, 233);
    });
  });

  group('rarity is cosmetic', () {
    test('no rarity moves a monster\'s level, stats or loot', () {
      for (final (id, def) in everyMonster()) {
        for (final rarity in Rarity.values) {
          final recolored = def.copyWith(rarity: rarity);
          final reason = '${id.name} at ${rarity.name}';
          expect(recolored.level, def.level, reason: reason);
          expect(recolored.attack, def.attack, reason: reason);
          expect(recolored.defence, def.defence, reason: reason);
          expect(recolored.hitpoints, def.hitpoints, reason: reason);
          expect(
            describe(recolored.itemDrops),
            describe(def.itemDrops),
            reason: reason,
          );
          expect(
            [for (final r in recolored.bonusDrops) describe(r.entries)],
            [for (final r in def.bonusDrops) describe(r.entries)],
            reason: reason,
          );
        }
      }
    });
  });

  group('a monster that writes no drops', () {
    test('on the loot rung, drops the archetype table as written', () {
      final chicken = combat(EntityId.CHICKEN);
      expect(chicken.lootSteps, 0);
      expect(
        describe(chicken.itemDrops),
        describe(chicken.archetype.itemDrops),
      );
    });

    test('above it, stacks scale by fib(steps)', () {
      for (var steps = 1; steps <= 4; steps++) {
        final drops = bird.copyWith(fibLevel: 2 + steps).itemDrops;
        final m = Util.fib(steps);
        expect(drops.map((d) => d.id), [
          ItemId.CHICKEN_MEAT,
          ItemId.ANIMAL_PELT,
        ]);
        // fixed count: 1 meat -> m meat, still fixed
        final meat = only(drops, ItemId.CHICKEN_MEAT);
        expect(meat.lowCount, m, reason: 'steps $steps');
        expect(meat.highCount, 0, reason: 'steps $steps');
        // range: 1..5 pelts -> m..5m
        final feather = only(drops, ItemId.ANIMAL_PELT);
        expect(feather.lowCount, m, reason: 'steps $steps');
        expect(feather.highCount, 5 * m, reason: 'steps $steps');
      }
    });

    test('raises equipment a rung per step and keeps its count', () {
      final common = combat(EntityId.ROTWOOD_SCARECROW).itemDrops;
      final three = raised(EntityId.ROTWOOD_SCARECROW, 3).itemDrops;
      expect(only(common, ItemId.PITCHFORK).rarity, Rarity.COMMON);
      expect(only(three, ItemId.PITCHFORK).rarity, Rarity.EPIC);
      expect(only(three, ItemId.PITCHFORK).lowCount, 1);
      expect(only(three, ItemId.WOOD_SHIELD).rarity, Rarity.EPIC);
      // non-equipment stays common, just more of it
      expect(only(three, ItemId.LOGS).rarity, Rarity.COMMON);
      expect(only(three, ItemId.LOGS).highCount, 4 * 5);
    });

    test('raises a stamped quality further, stopping at legendary', () {
      final table = [
        const ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.RARE),
        const NestedDrop([
          ItemDropType(id: ItemId.WOOD_SHIELD),
        ], rarity: Rarity.UNCOMMON),
      ];
      final scaled = table.scaledBy(3);
      expect(only(scaled, ItemId.PITCHFORK).rarity, Rarity.LEGENDARY);
      expect(only(scaled, ItemId.WOOD_SHIELD).rarity, Rarity.LEGENDARY);
    });

    test('inherits bonus rolls at the same chance, entries scaled', () {
      // a bare definition on the archetype: the catalog's wraiths sit below
      // its loot rung and write their own
      const on = CombatEntityDefinition(wraith, fibLevel: 10, name: 'Wraith');
      final common = on.bonusDrops.single;
      final two = on.copyWith(fibLevel: 12).bonusDrops.single;
      expect(two.chance, common.chance);
      // the wraith's rags are uncommon; two rungs up is epic
      expect(two.entries.map((e) => e.rarity).toSet(), {Rarity.EPIC});
    });

    test('a stub archetype hands down a stub table', () {
      expect(combat(EntityId.MINOTAUR).archetype.itemDrops, isEmpty);
      expect(raised(EntityId.MINOTAUR, 2).itemDrops, isEmpty);
    });
  });

  group('a monster that writes drops', () {
    test('replaces the inherited table with itemDrops', () {
      // a hand-written monster keeps exactly what it wrote
      final elder = combat(EntityId.FOREST_WOLF_UNCOMMON).itemDrops;
      expect(elder.map((d) => d.id), [ItemId.WOLF_PELT]);
      expect(only(elder, ItemId.WOLF_PELT).highCount, 5);
    });

    test('adds extraItemDrops on top of the inherited table', () {
      final def = bird
          .copyWith(fibLevel: 4)
          .copyWith(
            extraItemDrops: const [
              ItemDropType(id: ItemId.WOOL_CLOAK, weight: 0.1),
            ],
          );
      expect(def.itemDrops.map((d) => d.id), [
        ItemId.CHICKEN_MEAT,
        ItemId.ANIMAL_PELT,
        ItemId.WOOL_CLOAK,
      ]);
      // the extra line is taken as written, not scaled
      expect(only(def.itemDrops, ItemId.WOOL_CLOAK).rarity, Rarity.COMMON);
    });

    test('turns inherited bonus rolls off with bonusDrops: const []', () {
      expect(combat(EntityId.GOBLIN).bonusDrops, isNotEmpty);
      expect(combat(EntityId.GOBLIN_UNCOMMON).bonusDrops, isEmpty);
      expect(
        raised(EntityId.WRAITH, 2).copyWith(bonusDrops: const []).bonusDrops,
        isEmpty,
      );
    });

    test('adds extraBonusDrops to the inherited rolls', () {
      final def = raised(EntityId.WRAITH, 1).copyWith(
        extraBonusDrops: const [
          DropRoll(
            chance: 0.5,
            entries: [ItemDropType(id: ItemId.SMALL_FEATHER)],
          ),
        ],
      );
      expect(def.bonusDrops.map((r) => r.chance), [0.15, 0.5]);
    });

    test('a copy on another rung re-scales what it inherits', () {
      final four = bird.copyWith(fibLevel: 3).copyWith(fibLevel: 2 + 4);
      expect(only(four.itemDrops, ItemId.ANIMAL_PELT).highCount, 5 * 8);
    });
  });

  group('the reagent part', () {
    test(
      'every monster on a tagged archetype drops its family at its grade',
      () {
        for (final (id, def) in everyMonster()) {
          final family = def.archetype.reagentFamily;
          final roll = def.reagentDrop;
          if (family == null) {
            expect(roll, isNull, reason: id.name);
            continue;
          }
          final part = roll!.entries.single.id;
          final partDef = part.definition as ReagentPartDefinition;
          expect(partDef.family, family, reason: id.name);
          expect(partDef.grade, ReagentGrade.forRung(def.fibLevel));
          expect(
            def.rolledBonusDrops.last.entries.single.id,
            part,
            reason: id.name,
          );
          expect(roll.chance, def.isDungeonBoss ? 1.0 : 0.5, reason: id.name);
        }
      },
    );

    test('the grade climbs a rung at a time from Small at 13 and below', () {
      expect(ReagentGrade.forRung(0), ReagentGrade.SMALL);
      expect(ReagentGrade.forRung(5), ReagentGrade.SMALL);
      expect(ReagentGrade.forRung(6), ReagentGrade.STURDY);
      expect(ReagentGrade.forRung(8), ReagentGrade.HEAVY);
      expect(ReagentGrade.forRung(10), ReagentGrade.PRIMAL);
      expect(ReagentGrade.forRung(13), ReagentGrade.PRIMAL);
      expect(ReagentGrade.forLevel(20), ReagentGrade.SMALL);
      expect(ReagentGrade.forLevel(21), ReagentGrade.STURDY);
      expect(ReagentGrade.forLevel(144), ReagentGrade.PRIMAL);
    });
  });

  test('a monster may swing at its own pace', () {
    final wolf = combat(EntityId.FOREST_WOLF);
    expect(wolf.attackInterval, wolf.archetype.attackInterval);
    expect(wolf.copyWith(attackInterval: 3.0).attackInterval, 3.0);
  });
}
