import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

// An entity's drop table is written as ItemDropType, which is a weighted
// entry in its own right. It gets rolled two ways: for a plain item id (a
// bonus roll), and for the drop itself (the main table), which is what
// carries a drop's quality through to the loot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  EncounterEntityDefinition definitionOf(EntityId id) =>
      id.definition as EncounterEntityDefinition;

  group('the table a definition hands the roll service', () {
    test('mirrors the drops it was written with', () {
      const drops = [
        ItemDropType(id: ItemId.SCALE, lowCount: 2, highCount: 5, weight: 3),
        ItemDropType(id: ItemId.SALMON),
      ];
      const def = CombatEntityDefinition(
        name: 'Test',
        iconAsset: '',
        level: 1,
        combatType: CombatType.CLOTH_DPS,
        itemDrops: drops,
        attackInterval: 1,
      );

      final table = def.weightedDropTable;

      expect(table.map((e) => e.id), drops);
      expect(table.map((e) => e.count), [2, 1]);
      expect(table.map((e) => e.highCount), [5, 0]);
      expect(table.map((e) => e.weight), [3, 1]);
    });

    test('rolls the drop itself, quality and all', () {
      const def = CombatEntityDefinition(
        name: 'Test',
        iconAsset: '',
        level: 1,
        combatType: CombatType.CLOTH_DPS,
        itemDrops: [
          ItemDropType(id: ItemId.FISHBONE_DAGGER, rarity: Rarity.UNCOMMON),
        ],
        attackInterval: 1,
      );

      final rolled = WeightedDropTableService().roll(def.weightedDropTable);

      expect(rolled.id.id, ItemId.FISHBONE_DAGGER);
      expect(rolled.id.rarity, Rarity.UNCOMMON);
    });

    test('keeps one item at two qualities as two drops', () {
      const def = CombatEntityDefinition(
        name: 'Test',
        iconAsset: '',
        level: 1,
        combatType: CombatType.CLOTH_DPS,
        itemDrops: [
          ItemDropType(id: ItemId.FISHBONE_DAGGER, weight: 1),
          ItemDropType(id: ItemId.FISHBONE_DAGGER, rarity: Rarity.UNCOMMON),
        ],
        attackInterval: 1,
      );

      final rolled = WeightedDropTableService().rollMulitpleTimes(
        100,
        def.weightedDropTable,
        rng: Random(7),
      );

      expect(rolled, hasLength(2));
      expect(rolled.map((stack) => stack.id.rarity), [
        Rarity.COMMON,
        Rarity.UNCOMMON,
      ]);
    });
  });

  test('a shared table still rolls as plain item ids for a bonus roll', () {
    final rolled = WeightedDropTableService().roll(
      gemDropTable,
      rng: Random(1),
    );

    expect(rolled.id, isA<ItemId>());
    expect(gemDropTable.map((drop) => drop.id), contains(rolled.id));
  });

  group('what a kill pays out', () {
    // the catalog entity that lists a weapon in its own drop table, at two
    // qualities. it is the reason the main table rolls drops rather than ids.
    final mudlurk = definitionOf(EntityId.MUDLURC_WARRIOR);

    test('the catalog still lists a weapon drop at two qualities', () {
      final daggers = mudlurk.itemDrops
          .where((drop) => drop.id == ItemId.FISHBONE_DAGGER)
          .toList();

      expect(daggers.map((drop) => drop.rarity), [
        Rarity.COMMON,
        Rarity.UNCOMMON,
      ]);
    });

    test('equipment arrives as an instance carrying its rolled quality', () {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final session = factory.create(
        save: factory.newGame(catalogs),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
      final save = session.saveGameData;

      // a mudlurk that cannot fight back and dies to one hit, so the run is
      // about what it drops rather than how long it takes to kill
      session.encounterService.setEncounterEntity(
        save.encounterData,
        EncounterEntity(
          id: EntityId.MUDLURC_WARRIOR,
          name: 'Test Mudlurk',
          count: 100000,
          entityType: SkillId.ATTACK,
          defence: 0,
          hitpoints: 1,
        ),
      );

      final rng = Random(3);
      for (var i = 0; i < 600; i++) {
        session.encounterSystem.executePlayerAction(
          playerState: save.playerData,
          encounter: save.encounterData,
          worldState: save.worldData,
          playerInventory: save.inventoryData,
          instantRespawn: true,
          rng: rng,
        );
      }

      final daggers = save.inventoryData.equipment
          .where((item) => item.id == ItemId.FISHBONE_DAGGER)
          .toList();

      expect(
        daggers.map((item) => item.quality),
        containsAll([Rarity.COMMON, Rarity.UNCOMMON]),
        reason: 'both listed qualities should drop over 600 kills',
      );
      // an instance, never a count on the item map
      expect(save.inventoryData.itemMap[ItemId.FISHBONE_DAGGER], isNull);
      // the fish it drops are plain items, and still stack
      expect(save.inventoryData.itemMap[ItemId.SCALE], greaterThan(0));
    });
  });
}
