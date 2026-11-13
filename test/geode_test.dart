import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/systems/birds_nest_system.dart';

// Geodes: mining's bird's nests. A vein sheds a geode whose quality tracks
// the vein's tier, and the geode opens into a gem and, rarely, the Miner's
// set of the same tier.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final factory = GameSessionFactory();

  GameSession buildSession() {
    final catalogs = factory.catalog1();
    return factory.create(
      save: factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  const geodes = [
    ItemId.DULL_GEODE,
    ItemId.BANDED_GEODE,
    ItemId.CRYSTAL_GEODE,
    ItemId.PRISMATIC_GEODE,
    ItemId.RADIANT_GEODE,
  ];

  ItemId? geodeOf(EntityId vein) {
    for (final roll
        in (vein.definition as EncounterEntityDefinition).bonusDrops) {
      for (final e in roll.entries) {
        if (geodes.contains(e.id)) return e.id;
      }
    }
    return null;
  }

  test('geode quality rises with the difficulty of the vein', () {
    // veins by defence, ascending; the geode never gets worse as it climbs
    final veins =
        [
          for (final id in EntityId.values)
            if (id.definition is EncounterEntityDefinition &&
                (id.definition as EncounterEntityDefinition).entityType ==
                    SkillId.MINING &&
                geodeOf(id) != null)
              id,
        ]..sort(
          (a, b) => (a.definition as EncounterEntityDefinition).defence
              .compareTo((b.definition as EncounterEntityDefinition).defence),
        );
    expect(veins, hasLength(9));
    // veins of equal defence may differ (coal and gold); a harder vein never
    // sheds a worse geode than the easiest of the veins below it
    int defenceOf(EntityId v) =>
        (v.definition as EncounterEntityDefinition).defence;
    int tierOf(EntityId v) => geodes.indexOf(geodeOf(v)!);
    for (final v in veins) {
      final lower = veins.where((o) => defenceOf(o) < defenceOf(v));
      for (final o in lower) {
        expect(tierOf(v), greaterThanOrEqualTo(tierOf(o)), reason: v.name);
      }
    }
    // the user's map: dull / banded / crystal / prismatic / radiant
    expect(geodeOf(EntityId.IRON), ItemId.BANDED_GEODE);
    expect(geodeOf(EntityId.COAL_VEIN), ItemId.BANDED_GEODE);
    expect(geodeOf(EntityId.GOLD_VEIN), ItemId.CRYSTAL_GEODE);
    expect(geodeOf(EntityId.GEM_VEIN), ItemId.CRYSTAL_GEODE);
    expect(geodeOf(EntityId.MITHRIL_VEIN), ItemId.PRISMATIC_GEODE);
    expect(geodeOf(EntityId.ADAMANTITE_VEIN), ItemId.PRISMATIC_GEODE);
    expect(geodeOf(EntityId.RUNITE_VEIN), ItemId.RADIANT_GEODE);
    expect(geodeOf(EntityId.DRAGONITE_VEIN), ItemId.RADIANT_GEODE);
    expect(
      [for (final g in geodes) g.definition.quality],
      [
        Rarity.COMMON,
        Rarity.UNCOMMON,
        Rarity.RARE,
        Rarity.EPIC,
        Rarity.LEGENDARY,
      ],
    );
  });

  test('every geode is openable and holds its tier of miner gear', () {
    const gear = [
      basicMinersGearDropTable,
      noviceMinersGearDropTable,
      apprenticeMinersGearDropTable,
      advancedMinersGearDropTable,
      masterMinersGearDropTable,
    ];
    for (var i = 0; i < geodes.length; i++) {
      expect(BirdsNestSystem.isNest(geodes[i]), isTrue);
      final listed = {
        for (final r in geodeRolls[geodes[i]]!) ...r.entries.map((e) => e.id),
      };
      expect(listed, containsAll(gear[i].map((e) => e.id)));
    }
  });

  test('opening geodes pays gems and, over many, the matching gear', () {
    final session = buildSession();
    final save = session.saveGameData;
    save.inventoryData.itemMap[ItemId.DULL_GEODE] = 500;

    final loot = session.inventoryController.openNests(ItemId.DULL_GEODE);
    expect(save.inventoryData.itemMap[ItemId.DULL_GEODE] ?? 0, 0);
    final gems = loot
        .where((l) => {ItemId.TOPAZ, ItemId.SAPPHIRE}.contains(l.id))
        .fold(0, (sum, l) => sum + l.count);
    expect(gems, 500, reason: 'one gem a dull geode');
    expect(
      loot.any((l) => basicMinersGearDropTable.any((g) => g.id == l.id)),
      isTrue,
    );
    session.dispose();
  });
}
