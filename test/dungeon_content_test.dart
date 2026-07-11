import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeon_catalog.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

void main() {
  group('layered drop tables', () {
    final service = WeightedDropTableService();

    test('a guaranteed roll always fires; a chance roll fires ~its rate', () {
      final rng = Random(1);
      final rolls = [
        DropRoll<ItemId>(
          entries: [
            WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1),
          ],
        ),
        DropRoll<ItemId>(
          chance: 0.25,
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.GOBLIN_QUEEN_KEY,
              weight: 1,
            ),
          ],
        ),
      ];

      var coins = 0;
      var keys = 0;
      const n = 4000;
      for (var i = 0; i < n; i++) {
        final out = service.rollBonus(rolls, rng: rng);
        coins += out.where((s) => s.id == ItemId.COINS).length;
        keys += out.where((s) => s.id == ItemId.GOBLIN_QUEEN_KEY).length;
      }

      expect(coins, n); // guaranteed
      expect(keys / n, closeTo(0.25, 0.05));
    });

    test('empty rolls are skipped', () {
      final out = service.rollBonus(<DropRoll<ItemId>>[
        DropRoll<ItemId>(entries: const []),
      ]);
      expect(out, isEmpty);
    });
  });

  group('goblin key drop', () {
    test('goblin has a 5% bonus roll for the Goblin Queen key', () {
      final catalog = EntityCatalog();
      final def =
          catalog.getDefinitionFor(EntityId.GOBLIN) as CombatEntityDefinition;

      // main drop is unchanged (coins)
      expect(def.itemDrops.single.id, ItemId.COINS);

      // exactly one bonus roll, 5%, yielding the key
      expect(def.bonusDrops, hasLength(1));
      expect(def.bonusDrops.single.chance, 0.05);
      expect(def.bonusDrops.single.entries.single.id, ItemId.GOBLIN_QUEEN_KEY);
    });
  });

  group('Goblin Queen boss', () {
    final catalog = EntityCatalog();
    final service = WeightedDropTableService();

    test('is a stat-check combat boss', () {
      final def =
          catalog.getDefinitionFor(EntityId.GOBLIN_QUEEN)
              as CombatEntityDefinition;
      expect(def.entityType, SkillId.ATTACK);
      expect(def.hitpoints, greaterThan(100));
    });

    test('every kill yields a guaranteed unique plus bulk coins', () {
      final def =
          catalog.getDefinitionFor(EntityId.GOBLIN_QUEEN)
              as CombatEntityDefinition;
      final rng = Random(7);

      const uniques = {ItemId.GOBLIN_CROWN, ItemId.GOBLIN_SCEPTER};
      for (var i = 0; i < 200; i++) {
        final drops = <dynamic>[
          service.roll(def.itemDrops, rng: rng),
          ...service.rollBonus(def.bonusDrops, rng: rng),
        ];
        final ids = drops.map((s) => s.id).toSet();
        // guaranteed one of the uniques
        expect(ids.intersection(uniques), isNotEmpty);
        // guaranteed bulk coin stack
        final coinStack = drops.firstWhere((s) => s.id == ItemId.COINS);
        expect(coinStack.count, 500);
      }
    });
  });

  group('Goblin Queen dungeon definition', () {
    final catalog = DungeonCatalog();

    test('is a keyed, non-repeatable landmark', () {
      final d = catalog.getDefinitionFor(DungeonId.GOBLIN_QUEEN_LAIR)!;
      expect(d.type, DungeonType.LANDMARK);
      expect(d.isKeyed, isTrue);
      expect(d.keyItemId, ItemId.GOBLIN_QUEEN_KEY);
      expect(d.repeatable, isFalse);
      expect(catalog.landmarks, contains(d));
    });

    test('floors are ordered and the boss is the final pack', () {
      final d = catalog.getDefinitionFor(DungeonId.GOBLIN_QUEEN_LAIR)!;
      expect(d.floors, isNotEmpty);
      for (final floor in d.floors) {
        expect(floor.packs, isNotEmpty);
      }
      expect(d.bossEntityId, EntityId.GOBLIN_QUEEN);
    });

    test('every entity the dungeon references exists in the entity catalog', () {
      final entities = EntityCatalog();
      final d = catalog.getDefinitionFor(DungeonId.GOBLIN_QUEEN_LAIR)!;
      for (final floor in d.floors) {
        for (final pack in floor.packs) {
          final def = entities.getDefinitionFor(pack.entityId);
          expect(def.name, isNotEmpty, reason: '${pack.entityId} missing');
          expect(pack.count, greaterThan(0));
        }
      }
    });
  });
}
