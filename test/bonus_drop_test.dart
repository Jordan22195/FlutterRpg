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
      // a layered roll fires on its own chance, on top of whatever the main
      // table paid — it takes no share of the main pick. The rare
      // scarecrow is the entity with both halves; which item it layers and
      // at what chance is tuning, so all of it is read off the definition.
      const id = EntityId.ROTWOOD_SCARECROW_1;
      final def = id.definition as CombatEntityDefinition;

      final mainTable = def.itemDrops.flattened.toList();
      final totalWeight = mainTable.fold<double>(0, (sum, e) => sum + e.weight);
      final layered = def.bonusDrops.single;
      final layeredDrop = layered.entries.single;
      expect(
        mainTable.map((e) => e.id),
        isNot(contains(layeredDrop.id)),
        reason: 'the layered item is also competing inside the main table',
      );

      final session = buildSession();
      final save = session.saveGameData;
      maxOutCombat(session);

      final scarecrow = id.build() as CombatEntity;
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

      // every main line kept its full share: the layered roll diluted none
      // of them. A line rolls a stack, so compare items-per-kill against
      // the share times the average stack rather than against a raw count
      for (final drop in mainTable) {
        // equipment arrives as instances, counted below; these are stacks
        if (drop.id.definition is EquipmentItemDefinition) continue;
        final top = drop.highCount > drop.lowCount
            ? drop.highCount
            : drop.lowCount;
        final expected =
            (drop.weight / totalWeight) * (drop.lowCount + top) / 2;
        final got = (save.inventoryData.itemMap[drop.id] ?? 0) / kills;
        expect(
          got,
          closeTo(expected, expected * 0.2),
          reason: '${drop.id.name} is not paying its share of the table',
        );
      }

      // and the layered roll fired at its own rate, on top of all that
      final layeredCount = save.inventoryData.equipment
          .where((item) => item.id == layeredDrop.id)
          .fold<int>(0, (sum, item) => sum + item.count);
      expect(
        layeredCount / kills,
        closeTo(layered.chance, layered.chance * 0.15),
      );
      // equipment from a bonus roll is an instance, never a stacked count
      expect(save.inventoryData.itemMap[layeredDrop.id], isNull);

      // and exactly, off the definition: the main rows split the whole
      // table between them, and the layered row sits outside that split
      final details = session.worldController.entityDetails(scarecrow);
      final main = details.drops.where((d) => !d.bonus).toList();
      expect(main, hasLength(mainTable.length));
      expect(
        main.fold<double>(0, (sum, d) => sum + d.chance),
        closeTo(1.0, 1e-9),
        reason: 'the main table does not add up to one pick',
      );
      final bonusRow = details.drops.singleWhere((d) => d.bonus);
      expect(bonusRow.itemId, layeredDrop.id);
      expect(bonusRow.chance, closeTo(layered.chance, 1e-9));

      session.dispose();
    });

    test('an inline line competes for the pick, the way a bonus roll does '
        'not', () {
      // the contrast the test above is measured against. The common
      // scarecrow carries the same item as a main-table line instead, and
      // that costs every other line a share of the pick — which is the
      // whole reason the two payout paths are told apart.
      const id = EntityId.ROTWOOD_SCARECROW;
      final def = id.definition as CombatEntityDefinition;
      expect(def.bonusDrops, isEmpty);

      final session = buildSession();
      final details = session.worldController.entityDetails(
        id.build() as CombatEntity,
      );

      expect(details.drops.where((d) => d.bonus), isEmpty);
      final main = details.drops.toList();
      expect(main.length, def.itemDrops.flattened.length);
      expect(
        main.fold<double>(0, (sum, d) => sum + d.chance),
        closeTo(1.0, 1e-9),
      );
      // no line can hold a full share once another joins the table
      for (final row in main) {
        expect(row.chance, lessThan(1.0));
      }

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
