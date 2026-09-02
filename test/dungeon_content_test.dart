import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

void main() {
  group('layered drop tables', () {
    final service = WeightedDropTableService();

    test('a guaranteed roll always fires; a chance roll fires ~its rate', () {
      final rng = Random(1);
      final rolls = [
        DropRoll(entries: [ItemDropType(id: ItemId.COINS)]),
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY)],
        ),
      ];

      var coins = 0;
      var keys = 0;
      const n = 4000;
      for (var i = 0; i < n; i++) {
        final out = service.rollBonus(rolls, rng: rng);
        coins += out.where((s) => s.id.id == ItemId.COINS).length;
        keys += out.where((s) => s.id.id == ItemId.GOBLIN_QUEEN_KEY).length;
      }

      expect(coins, n); // guaranteed
      expect(keys / n, closeTo(0.25, 0.05));
    });

    test('empty rolls are skipped', () {
      final out = service.rollBonus(<DropRoll>[DropRoll(entries: const [])]);
      expect(out, isEmpty);
    });
  });

  group('goblin key drop', () {
    test('goblin has a 5% bonus roll for the Goblin Queen key', () {
      final def = EntityId.GOBLIN.definition as CombatEntityDefinition;

      // main drop is unchanged (coins)
      expect(def.itemDrops.single.id, ItemId.COINS);

      // exactly one bonus roll, 5%, yielding the key
      expect(def.bonusDrops, hasLength(1));
      expect(def.bonusDrops.single.chance, 0.05);
      expect(def.bonusDrops.single.entries.single.id, ItemId.GOBLIN_QUEEN_KEY);
    });
  });

  group('Goblin Queen boss', () {
    final service = WeightedDropTableService();

    test('is a stat-check combat boss', () {
      final def = EntityId.GOBLIN_QUEEN.definition as CombatEntityDefinition;
      expect(def.entityType, SkillId.ATTACK);
      expect(def.hitpoints, greaterThan(100));
    });

    test('every kill yields a guaranteed unique plus bulk coins', () {
      final def = EntityId.GOBLIN_QUEEN.definition as CombatEntityDefinition;
      final rng = Random(7);

      const uniques = {ItemId.GOBLIN_CROWN, ItemId.GOBLIN_SCEPTER};
      for (var i = 0; i < 200; i++) {
        final drops = [
          service.roll(def.weightedDropTable, rng: rng),
          ...service.rollBonus(def.bonusDrops, rng: rng),
        ];
        final ids = drops.map((s) => s.id.id).toSet();
        // guaranteed one of the uniques
        expect(ids.intersection(uniques), isNotEmpty);
        // guaranteed bulk coin stack
        final coinStack = drops.firstWhere((s) => s.id.id == ItemId.COINS);
        expect(coinStack.count, 500);
      }
    });
  });

  group('dungeon definitions', () {
    test('the lair is a keyed, one-shot landmark', () {
      final d = DungeonId.GOBLIN_QUEEN_LAIR.definition;
      expect(d.type, DungeonType.LANDMARK);
      expect(d.isKeyed, isTrue);
      expect(d.keyItemId, ItemId.GOBLIN_QUEEN_KEY);
      expect(d.repeatableEntries, isFalse);
      expect(DungeonId.landmarks, contains(DungeonId.GOBLIN_QUEEN_LAIR));
    });

    test('entries are ordered and the boss is the last member of the last', () {
      final d = DungeonId.GOBLIN_QUEEN_LAIR.definition;
      expect(d.entries, isNotEmpty);
      for (final entry in d.entries) {
        expect(entry.entities, isNotEmpty);
      }
      expect(d.entries.last.entities.last.entityId, EntityId.GOBLIN_QUEEN);
    });

    test('every entry is named and holds something', () {
      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        final d = id.definition;
        expect(d.entries, isNotEmpty, reason: '${id.name} has no cards');
        for (final entry in d.entries) {
          expect(
            entry.name,
            isNotEmpty,
            reason: '${id.name} has an unnamed card',
          );
          expect(entry.entities, isNotEmpty, reason: '${entry.name} is empty');
        }
      }
    });

    test('every member is a depleting encounter entity', () {
      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        for (final entry in id.definition.entries) {
          for (final ref in entry.entities) {
            final def = ref.entityId.definition;
            // the kill path casts the definition to an encounter definition
            // without a guard, and a card that never depletes never clears
            expect(
              def,
              isA<EncounterEntityDefinition>(),
              reason: '${ref.entityId} in ${id.name}/${entry.name}',
            );
            expect(
              def,
              isNot(isA<FishingEntityDefinition>()),
              reason: '${ref.entityId} never depletes',
            );
            expect(ref.count, greaterThan(0));
          }
        }
      }
    });
  });
}
