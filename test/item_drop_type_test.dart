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

/// A stand-in monster: the drop table is what is under test, so the tier
/// and the shape of the fight are held constant.
const testArchetype = CombatArchetype(
  iconAsset: '',
  fibLevel: 0,
  combatType: CombatType.CLOTH_DPS,
  attackInterval: 1,
);

// An entity's drop table is written as ItemDropType, which is a weighted
// entry in its own right. Both the main table and a layered bonus roll are
// lists of exactly that, and both roll for the drop rather than for a bare
// id - which is what carries a drop's quality through to the loot.
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
        testArchetype,
        name: 'Test',
        itemDrops: drops,
      );

      final table = def.weightedDropTable;

      expect(table.map((e) => e.id), drops);
      expect(table.map((e) => e.count), [2, 1]);
      expect(table.map((e) => e.highCount), [5, 0]);
      expect(table.map((e) => e.weight), [3, 1]);
    });

    test('rolls the drop itself, quality and all', () {
      const def = CombatEntityDefinition(
        testArchetype,
        name: 'Test',
        itemDrops: [
          ItemDropType(id: ItemId.FISHBONE_DAGGER, rarity: Rarity.UNCOMMON),
        ],
      );

      final rolled = WeightedDropTableService().roll(def.weightedDropTable);

      expect(rolled.id.id, ItemId.FISHBONE_DAGGER);
      expect(rolled.id.rarity, Rarity.UNCOMMON);
    });

    test('keeps one item at two qualities as two drops', () {
      const def = CombatEntityDefinition(
        testArchetype,
        name: 'Test',
        itemDrops: [
          ItemDropType(id: ItemId.FISHBONE_DAGGER, weight: 1),
          ItemDropType(id: ItemId.FISHBONE_DAGGER, rarity: Rarity.UNCOMMON),
        ],
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

  test('a shared table drops into a bonus roll and rolls for the drop', () {
    // the same const table serves both uses. through a bonus roll it comes
    // back as an ItemDropType, so the quality rides along - a plain item id
    // is exactly what used to leave bonus-rolled equipment unqualified.
    final rolled = WeightedDropTableService().rollBonus([
      DropRoll(entries: gemDropTable),
    ], rng: Random(1));

    final drop = rolled.single;
    expect(drop.id, isA<ItemDropType>());
    expect(gemDropTable, contains(drop.id));
    expect(drop.id.rarity, Rarity.COMMON);
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

      // the run is about what a kill drops, not about how long it takes, so
      // the player is levelled far past the mudlurk instead of the mudlurk
      // being weakened - its stats belong to its definition
      for (final skill in [
        SkillId.ATTACK,
        SkillId.STRENGTH,
        SkillId.DEFENCE,
        SkillId.HITPOINTS,
      ]) {
        final data = save.playerData.skillData[skill]!;
        data.xp = data.xpTable[data.xpTable.length - 1];
      }

      final mudlurkEntity = EntityId.MUDLURC_WARRIOR.build() as CombatEntity;
      mudlurkEntity.count = 100000;
      session.encounterService.setEncounterEntity(
        save.encounterData,
        mudlurkEntity,
      );

      // enough swings for ~600 kills: a mudlurk is a level 55 fight even
      // for a maxed player, so the actions a kill costs are real
      final rng = Random(3);
      for (var i = 0; i < 10000; i++) {
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
