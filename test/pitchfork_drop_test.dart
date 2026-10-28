import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// A rare pitchfork is the ordinary pitchfork at [Rarity.RARE], not an item
/// of its own.
///
/// RARE_PITCHFORK existed only because a bonus roll could not carry a
/// quality. Now that a bonus roll rolls `ItemDropType` like the main table
/// does, it is retired: the rare scarecrow's 50% layered roll drops
/// PITCHFORK at RARE, and rarity multiplies its budget by 1.4.
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

  test('a rare pitchfork is 1.4x the ordinary one', () {
    final def = ItemId.PITCHFORK.definition as WeaponItemDefinition;
    final rare = ItemId.PITCHFORK.build() as EquipmentItem;
    rare.quality = Rarity.RARE;

    // a pitchfork is a damage weapon: the rarity scales what a swing deals
    // and there are no stats for it to scale
    expect(def.statWeights, isEmpty);
    expect(
      def.damageAt(Rarity.RARE) / def.damageAt(Rarity.COMMON),
      closeTo(1.4, 1e-9),
    );
    expect(rare.displayName, 'Rare Pitchfork');
  });

  test('the rare scarecrow drops it as a RARE instance, not a count', () {
    // through its 50% layered bonus roll, which pays a drop rather than a
    // bare id - so the quality reaches the instance
    final session = buildSession();
    final save = session.saveGameData;

    // levelled far past the scarecrow so the run is about what it drops
    for (final skill in [
      SkillId.ATTACK,
      SkillId.STRENGTH,
      SkillId.DEFENCE,
      SkillId.HITPOINTS,
    ]) {
      final data = save.playerData.skillData[skill]!;
      data.xp = data.xpTable[data.xpTable.length - 1];
    }

    final scarecrow = EntityId.ROTWOOD_SCARECROW_1.build() as CombatEntity;
    scarecrow.count = 100000;
    session.encounterService.setEncounterEntity(save.encounterData, scarecrow);

    final rng = Random(11);
    for (var i = 0; i < 4000; i++) {
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

    expect(pitchforks, isNotEmpty, reason: 'the rare drop never landed');
    expect(pitchforks.map((p) => p.quality), everyElement(Rarity.RARE));
    // an instance in the equipment list, never a count on the item map
    expect(save.inventoryData.itemMap[ItemId.PITCHFORK], isNull);

    session.dispose();
  });

  group('a retired id does not take the save with it', () {
    test('an unknown item id in the bag is skipped', () {
      // RARE_PITCHFORK is gone; a save written before it was retired still
      // has to load. A bare firstWhere threw StateError here, which the
      // bootstrap's FormatException fallback in main.dart never catches.
      final restored = InventoryData.fromJson(
        jsonDecode(
              jsonEncode({
                'items': {'COPPER_ORE': 4, 'RARE_PITCHFORK': 1},
                'equipment': [],
              }),
            )
            as Map<String, dynamic>,
      );

      expect(restored.itemMap[ItemId.COPPER_ORE], 4);
      expect(restored.itemMap.length, 1);
    });

    test('an unknown equipment instance in the bag is skipped', () {
      final restored = InventoryData.fromJson(
        jsonDecode(
              jsonEncode({
                'items': <String, int>{},
                'equipment': [
                  {
                    'runtimeType': 'WeaponItem',
                    'id': 'RARE_PITCHFORK',
                    'count': 1,
                    'quality': 'RARE',
                  },
                  {
                    'runtimeType': 'EquipmentItem',
                    'id': 'COPPER_HELMET',
                    'count': 1,
                    'quality': 'EPIC',
                  },
                ],
              }),
            )
            as Map<String, dynamic>,
      );

      expect(restored.equipment.single.id, ItemId.COPPER_HELMET);
      expect(restored.equipment.single.quality, Rarity.EPIC);
    });
  });
}
