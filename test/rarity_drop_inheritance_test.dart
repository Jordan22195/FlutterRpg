import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/combat_archetype.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

CombatEntityDefinition combat(EntityId id) =>
    id.definition as CombatEntityDefinition;

ItemDropType only(List<ItemDropType> drops, ItemId id) =>
    drops.singleWhere((d) => d.id == id);

void main() {
  group('a variant that writes no drops', () {
    test('inherits the common table, stacks scaled by its rarity', () {
      final common = combat(EntityId.CHICKEN).itemDrops;
      for (final id in [
        EntityId.CHICKEN_UNCOMMON,
        EntityId.CHICKEN_RARE,
        EntityId.CHICKEN_EPIC,
        EntityId.CHICKEN_LEGENDARY,
      ]) {
        final def = combat(id);
        final m = def.rarity.dropCountMultiplier;
        final drops = def.itemDrops;
        expect(drops.map((d) => d.id), common.map((d) => d.id));
        expect(drops.map((d) => d.weight), common.map((d) => d.weight));

        // fixed count: 1 meat -> m meat, still fixed
        final meat = only(drops, ItemId.CHICKEN_MEAT);
        expect(meat.lowCount, m);
        expect(meat.highCount, 0);
        // range: 1..5 feathers -> m..5m
        final feather = only(drops, ItemId.FEATHER);
        expect(feather.lowCount, m);
        expect(feather.highCount, 5 * m);
      }
    });

    test('raises equipment a rung per rarity step and keeps its count', () {
      final common = combat(EntityId.ROTWOOD_SCARECROW).itemDrops;
      final epic = combat(EntityId.ROTWOOD_SCARECROW_EPIC).itemDrops;
      expect(only(common, ItemId.PITCHFORK).rarity, Rarity.COMMON);
      expect(only(epic, ItemId.PITCHFORK).rarity, Rarity.EPIC);
      expect(only(epic, ItemId.PITCHFORK).lowCount, 1);
      expect(only(epic, ItemId.WOOD_SHIELD).rarity, Rarity.EPIC);
      // non-equipment stays common, just more of it
      expect(only(epic, ItemId.LOGS).rarity, Rarity.COMMON);
      expect(only(epic, ItemId.LOGS).highCount, 4 * 5);
    });

    test('raises a stamped quality further, stopping at legendary', () {
      final table = [
        const ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.RARE),
        const NestedDrop([
          ItemDropType(id: ItemId.WOOD_SHIELD),
        ], rarity: Rarity.UNCOMMON),
      ];
      final scaled = table.scaledTo(Rarity.EPIC);
      expect(only(scaled, ItemId.PITCHFORK).rarity, Rarity.LEGENDARY);
      expect(only(scaled, ItemId.WOOD_SHIELD).rarity, Rarity.LEGENDARY);
    });

    test('inherits bonus rolls at the same chance, entries scaled', () {
      final common = combat(EntityId.WRAITH).bonusDrops.single;
      final rare = combat(EntityId.WRAITH_RARE).bonusDrops.single;
      expect(rare.chance, common.chance);
      // the wraith's rags are uncommon; two rungs up is epic
      expect(rare.entries.map((e) => e.rarity).toSet(), {Rarity.EPIC});
    });
  });

  group('a variant that writes drops', () {
    const base = CombatEntityDefinition(
      chicken,
      name: 'Chicken',
      itemDrops: [ItemDropType(id: ItemId.FEATHER, lowCount: 1, highCount: 5)],
    );

    test('replaces the inherited table with itemDrops', () {
      // a hand-written variant keeps exactly what it wrote
      final elder = combat(EntityId.FOREST_WOLF_UNCOMMON).itemDrops;
      expect(elder.map((d) => d.id), [ItemId.FANG, ItemId.WOLF_PELT]);
      expect(only(elder, ItemId.FANG).highCount, 5);
    });

    test('adds extraItemDrops on top of the inherited table', () {
      final def = combat(EntityId.CHICKEN_RARE).copyWith(
        extraItemDrops: const [
          ItemDropType(id: ItemId.WOOL_CLOAK, weight: 0.1),
        ],
      );
      expect(def.itemDrops.map((d) => d.id), [
        ItemId.CHICKEN_MEAT,
        ItemId.FEATHER,
        ItemId.WOOL_CLOAK,
      ]);
      // the extra line is taken as written, not scaled
      expect(only(def.itemDrops, ItemId.WOOL_CLOAK).rarity, Rarity.COMMON);
    });

    test('turns inherited bonus rolls off with bonusDrops: const []', () {
      expect(combat(EntityId.GOBLIN).bonusDrops, isNotEmpty);
      expect(combat(EntityId.GOBLIN_UNCOMMON).bonusDrops, isEmpty);
      expect(
        combat(EntityId.WRAITH_RARE).copyWith(bonusDrops: const []).bonusDrops,
        isEmpty,
      );
    });

    test('adds extraBonusDrops to the inherited rolls', () {
      final def = combat(EntityId.WRAITH_UNCOMMON).copyWith(
        extraBonusDrops: const [
          DropRoll(chance: 0.5, entries: [ItemDropType(id: ItemId.FEATHER)]),
        ],
      );
      expect(def.bonusDrops.map((r) => r.chance), [0.15, 0.5]);
    });

    test('a common has nothing to inherit', () {
      expect(base.base, isNull);
      expect(combat(EntityId.CHICKEN).base, isNull);
      // the goblin scout's archetype starts at uncommon
      expect(combat(EntityId.GOBLIN_SCOUT).base, isNull);
      // a stub common hands down a stub table
      expect(combat(EntityId.MINOTAUR_RARE).itemDrops, isEmpty);
    });

    test('a copy at another rarity re-scales what it inherits', () {
      final legendary = combat(
        EntityId.CHICKEN_UNCOMMON,
      ).copyWith(rarity: Rarity.LEGENDARY);
      expect(only(legendary.itemDrops, ItemId.FEATHER).highCount, 5 * 8);
    });
  });

  test('every archetype has at most one common regular to inherit from', () {
    final commons = <CombatArchetype, List<EntityId>>{};
    for (final id in EntityId.values) {
      if (id.definition case final CombatEntityDefinition def
          when def.rarity == Rarity.COMMON && !def.isDungeonBoss) {
        commons.putIfAbsent(def.archetype, () => []).add(id);
      }
    }
    expect(
      commons.entries.where((e) => e.value.length > 1).map((e) => e.value),
      isEmpty,
    );
  });
}
