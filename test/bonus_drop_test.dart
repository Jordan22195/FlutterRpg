import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// A layered bonus roll rolls a *drop*, the same as the main table does.
///
/// It used to roll bare item ids, which meant equipment from a bonus roll
/// arrived as a stackable count in the item map instead of as its own
/// instance, and could not carry a rolled quality at all. That is what
/// forced RARE_PITCHFORK into existence.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void maxOutCombat(GameSession session) {
    final save = session.saveGameData;
    for (final skill in [
      SkillId.ATTACK,
      SkillId.STRENGTH,
      SkillId.DEFENCE,
      SkillId.HITPOINTS,
    ]) {
      final data = save.playerData.skillData[skill]!;
      data.xp = data.xpTable[data.xpTable.length - 1];
    }
  }

  group('the roll itself', () {
    test('comes back as a drop, carrying its quality', () {
      final rolled = WeightedDropTableService().rollBonus([
        DropRoll(
          entries: [ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.RARE)],
        ),
      ], rng: Random(1));

      final drop = rolled.single;
      expect(drop.id, isA<ItemDropType>());
      expect(drop.id.id, ItemId.PITCHFORK);
      expect(drop.id.rarity, Rarity.RARE);
    });

    test('a stack range on the drop is honoured', () {
      final service = WeightedDropTableService();
      final rng = Random(4);
      for (var i = 0; i < 200; i++) {
        final drop = service.rollBonus([
          DropRoll(
            entries: [
              ItemDropType(id: ItemId.COINS, lowCount: 3, highCount: 10),
            ],
          ),
        ], rng: rng).single;
        expect(drop.count, inInclusiveRange(3, 10));
      }
    });
  });

  group('what a bonus-rolled kill pays out', () {
    test('a bonus roll is independent of the main pick', () {
      // the common scarecrow's pitchfork is a 5% roll layered on top of the
      // main table, not a line competing inside it. That is the whole
      // difference: the other three drops keep a full third each, and the
      // pitchfork still arrives as equipment rather than a count.
      final session = buildSession();
      final save = session.saveGameData;
      maxOutCombat(session);

      final scarecrow = EntityId.ROTWOOD_SCARECROW.build() as CombatEntity;
      scarecrow.count = 100000;
      session.encounterService.setEncounterEntity(
        save.encounterData,
        scarecrow,
      );

      final rng = Random(9);
      for (var i = 0; i < 6000; i++) {
        session.encounterSystem.executePlayerAction(
          playerState: save.playerData,
          encounter: save.encounterData,
          worldState: save.worldData,
          playerInventory: save.inventoryData,
          instantRespawn: true,
          rng: rng,
        );
      }

      final kills = 100000 - scarecrow.count;
      expect(kills, greaterThan(500), reason: 'too few kills to measure rates');

      // the main table is three equal lines, undiluted by the pitchfork
      final logs = save.inventoryData.itemMap[ItemId.LOGS] ?? 0;
      final ore = save.inventoryData.itemMap[ItemId.IRON_ORE] ?? 0;
      // logs roll 1-4 and ore 1-2, so compare stacks-per-kill against the
      // average stack rather than against the raw count
      expect(logs / kills, closeTo(1 / 3 * 2.5, 0.25));
      expect(ore / kills, closeTo(1 / 3 * 1.5, 0.15));

      // and the layered roll fires at its own rate, on top of all that
      final pitchforks = save.inventoryData.equipment
          .where((item) => item.id == ItemId.PITCHFORK)
          .fold<int>(0, (sum, item) => sum + item.count);
      expect(pitchforks / kills, closeTo(0.05, 0.02));
      expect(save.inventoryData.itemMap[ItemId.PITCHFORK], isNull);

      // and exactly, off the definition: three main lines at a clean third
      // each, plus one layered roll. As a main-table line the pitchfork
      // would make four rows of 31.6% - the dilution this undid.
      final details = session.worldController.entityDetails(scarecrow);
      final main = details.drops.where((d) => !d.bonus).toList();
      expect(
        main,
        hasLength(3),
        reason: 'the pitchfork is competing for the main pick',
      );
      for (final row in main) {
        expect(row.chance, closeTo(1 / 3, 1e-9), reason: row.name);
      }
      final layered = details.drops.singleWhere((d) => d.bonus);
      expect(layered.itemId, ItemId.PITCHFORK);
      expect(layered.chance, closeTo(0.05, 1e-9));

      session.dispose();
    });

    test('a bonus roll pays the quality its drop names', () {
      // the rare scarecrow's pitchfork is back on a bonus roll, and the
      // roll carries Rarity.RARE - which is what retired RARE_PITCHFORK
      final session = buildSession();
      final save = session.saveGameData;
      maxOutCombat(session);

      final scarecrow = EntityId.ROTWOOD_SCARECROW_1.build() as CombatEntity;
      scarecrow.count = 100000;
      session.encounterService.setEncounterEntity(
        save.encounterData,
        scarecrow,
      );

      final rng = Random(6);
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

      final pitchforks = save.inventoryData.equipment
          .where((item) => item.id == ItemId.PITCHFORK)
          .toList();

      expect(pitchforks, isNotEmpty);
      expect(pitchforks.map((p) => p.quality), everyElement(Rarity.RARE));
      expect(save.inventoryData.itemMap[ItemId.PITCHFORK], isNull);

      session.dispose();
    });

    test('non-equipment bonus drops still stack in the item map', () {
      // the mining gem tables are the regression guard on the payout split:
      // a gem is not equipment, so it must keep behaving exactly as before
      final session = buildSession();
      final save = session.saveGameData;
      final data = save.playerData.skillData[SkillId.MINING]!;
      data.xp = data.xpTable[data.xpTable.length - 1];

      final vein = EntityId.COAL_VEIN.build() as EncounterEntity;
      vein.count = 100000;
      session.encounterService.setEncounterEntity(save.encounterData, vein);

      final rng = Random(8);
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

      final gems = [
        ItemId.TOPAZ,
        ItemId.SAPPHIRE,
        ItemId.EMERALD,
        ItemId.RUBY,
        ItemId.DIAMOND,
      ].where((id) => (save.inventoryData.itemMap[id] ?? 0) > 0);

      expect(gems, isNotEmpty, reason: 'the 50% gem roll never landed');
      expect(save.inventoryData.equipment, isEmpty);

      session.dispose();
    });
  });

  test('the drop table reports a rarity for both kinds of row', () {
    final session = buildSession();

    // a main-table line that lists one item at two qualities
    final mudlurk = session.worldController.entityDetails(
      EntityId.MUDLURC_WARRIOR.build() as EncounterEntity,
    );
    final daggers = mudlurk.drops
        .where((d) => d.itemId == ItemId.FISHBONE_DAGGER)
        .toList();
    expect(daggers, hasLength(2));
    expect(
      daggers.map((d) => d.rarity),
      containsAll([Rarity.COMMON, Rarity.UNCOMMON]),
      reason: 'two qualities of one item read as duplicate rows without this',
    );

    // and a bonus-roll line
    final scarecrow = session.worldController.entityDetails(
      EntityId.ROTWOOD_SCARECROW_1.build() as EncounterEntity,
    );
    final pitchfork = scarecrow.drops.singleWhere(
      (d) => d.itemId == ItemId.PITCHFORK,
    );
    expect(pitchfork.bonus, isTrue);
    expect(pitchfork.rarity, Rarity.RARE);
    expect(pitchfork.chance, closeTo(0.50, 1e-9));

    session.dispose();
  });
}
