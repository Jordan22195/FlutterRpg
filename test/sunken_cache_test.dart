import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/definition/scouting_map_item_definition.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/systems/birds_nest_system.dart';

import 'support/gathering_tools.dart';

// Fishing loot: a cast can pull up junk instead of a fish, a catch now and
// then comes up with one of the water's own reagents, and rarely with the
// water's sunken cache, which opens like a geode into that water's
// reagents, its cooked fish, a fishing potion, a map of the zone it lies in
// and, rarely, the Fisher's set of its tier.
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

  final spots = [
    for (final id in EntityId.values)
      if (id.definition is FishingEntityDefinition) id,
  ];
  FishingEntityDefinition defOf(EntityId id) =>
      id.definition as FishingEntityDefinition;

  ItemId? cacheOf(EntityId spot) {
    for (final roll in defOf(spot).bonusDrops) {
      for (final e in roll.entries) {
        if (sunkenCacheRolls.containsKey(e.id)) return e.id;
      }
    }
    return null;
  }

  Set<ItemId> fishersSet() => {
    for (final id in ItemId.values)
      if (id.name.contains('_FISHERS_')) id,
  };

  test('every water has its own cache, better the harder the water', () {
    expect(spots, hasLength(7));
    final caches = [for (final s in spots) cacheOf(s)];
    expect(caches, everyElement(isNotNull));
    expect(caches.toSet(), hasLength(spots.length), reason: 'one per water');
    expect(caches.toSet(), sunkenCacheRolls.keys.toSet());

    int defence(EntityId s) => defOf(s).defence;
    for (final s in spots) {
      for (final o in spots.where((o) => defence(o) < defence(s))) {
        expect(
          cacheOf(s)!.definition.quality.index,
          greaterThanOrEqualTo(cacheOf(o)!.definition.quality.index),
          reason: '${s.name} over ${o.name}',
        );
      }
    }
  });

  test('every spot drags up junk in place of a catch', () {
    final junk = {for (final e in fishingJunkDropTable) e.id};
    for (final s in spots) {
      final main = defOf(s).itemDrops.flattened.map((e) => e.id).toSet();
      expect(main, containsAll(junk), reason: s.name);
      // junk is never level-gated: it comes up from the first cast
      for (final e in defOf(s).itemDrops.flattened) {
        if (junk.contains(e.id)) expect(e.unlockLevel, lessThanOrEqualTo(1));
      }
    }
  });

  test('every water reagent has a use: a potion or a fire', () {
    final alchemyInputs = {for (final r in alchemyRecipes) ...r.inputs.keys};
    for (final s in spots) {
      final reagents = {
        for (final roll in defOf(s).bonusDrops)
          for (final e in roll.entries)
            if (!sunkenCacheRolls.containsKey(e.id)) e.id,
      };
      expect(reagents, isNotEmpty, reason: s.name);
      expect(
        reagents.any((id) => id.definition is FireReagentDefinition),
        isTrue,
        reason: '${s.name} has no fire reagent',
      );
      for (final id in reagents) {
        expect(
          id.definition is FireReagentDefinition || alchemyInputs.contains(id),
          isTrue,
          reason: '${id.name} off ${s.name} has no use',
        );
      }
    }
  });

  test(
    'a cache holds its water\'s reagents, a potion and the Fisher\'s set',
    () {
      const gear = [
        basicFishersGearDropTable,
        noviceFishersGearDropTable,
        apprenticeFishersGearDropTable,
        advancedFishersGearDropTable,
        masterFishersGearDropTable,
      ];
      final tiers = <List<ItemDropType>>{};
      for (final s in spots) {
        final cache = cacheOf(s)!;
        expect(BirdsNestSystem.isNest(cache), isTrue);
        final listed = {
          for (final r in sunkenCacheRolls[cache]!)
            ...r.entries.map((e) => e.id),
        };
        final reagents = {
          for (final roll in defOf(s).bonusDrops)
            for (final e in roll.entries)
              if (e.id != cache) e.id,
        };
        expect(listed, containsAll(reagents), reason: s.name);
        expect(
          listed.any(
            (id) =>
                id.definition is BuffItemDefinition &&
                (id.definition as BuffItemDefinition).skillBonus.containsKey(
                  SkillId.FISHING,
                ),
          ),
          isTrue,
          reason: '${s.name} cache holds no fishing potion',
        );
        final set = gear.firstWhere(
          (g) => g.every((e) => listed.contains(e.id)),
          orElse: () => const [],
        );
        expect(set, isNotEmpty, reason: '${s.name} cache holds no Fisher tier');
        tiers.add(set);
      }
      expect(tiers, hasLength(gear.length), reason: 'every tier has a water');
    },
  );

  test('a cache\'s map is of the zone its water lies in', () {
    for (final s in spots) {
      final maps = {
        for (final r in sunkenCacheRolls[cacheOf(s)!]!)
          for (final e in r.entries)
            if (ScoutingMaps.isMap(e.id)) e.id,
      };
      final homes = [
        for (final z in ZoneId.values)
          if (!z.name.startsWith('DEV') &&
              z.definition.permanentEntities.contains(s))
            z,
      ];
      if (homes.isEmpty) {
        expect(maps, isEmpty, reason: '${s.name} lies in no zone yet');
        continue;
      }
      expect(maps, hasLength(1), reason: s.name);
      expect(homes, contains(ScoutingMaps.zoneFor(maps.single)));
    }
  });

  test('the Fisher\'s set comes only out of sunken caches', () {
    final set = fishersSet();
    expect(set, hasLength(30));
    for (final id in EntityId.values) {
      // the dev shop sells everything
      if (id.name.startsWith('DEV_')) continue;
      final def = id.definition;
      if (def is EncounterEntityDefinition) {
        final drops = {
          ...def.itemDrops.flattened.map((e) => e.id),
          for (final r in def.bonusDrops)
            ...r.entries.flattened.map((e) => e.id),
        };
        expect(drops.intersection(set), isEmpty, reason: id.name);
      }
      if (def is ShopEntityDefinition) {
        final stock = def.shopStockPool.map((e) => e.itemId).toSet();
        expect(stock.intersection(set), isEmpty, reason: id.name);
      }
    }
    final fromCaches = {
      for (final rolls in sunkenCacheRolls.values)
        for (final r in rolls) ...r.entries.map((e) => e.id),
    };
    expect(fromCaches, containsAll(set));
  });

  test('opening caches empties them and pays only what they hold', () {
    final session = buildSession();
    final save = session.saveGameData;
    save.inventoryData.itemMap[ItemId.POND_CACHE] = 500;

    final loot = session.inventoryController.openNests(ItemId.POND_CACHE);
    expect(save.inventoryData.itemMap[ItemId.POND_CACHE] ?? 0, 0);
    final listed = {
      for (final r in sunkenCacheRolls[ItemId.POND_CACHE]!)
        ...r.entries.map((e) => e.id),
    };
    expect(loot.map((l) => l.id).toSet().difference(listed), isEmpty);
    // two reagent rolls a cache, every time
    final reagents = loot
        .where((l) => pondReagentDropTable.any((e) => e.id == l.id))
        .fold(0, (sum, l) => sum + l.count);
    expect(reagents, 1000);
    // over five hundred, the long shots land
    expect(loot.any((l) => fishersSet().contains(l.id)), isTrue);
    expect(loot.any((l) => l.id == ItemId.SCOUTING_MAP_TUTORIAL_FARM), isTrue);
    session.dispose();
  });

  test('junk comes up in place of fish; reagents and caches beside them', () {
    final catalogs = factory.catalog1();
    final session = factory.create(
      save: withGatheringTools(factory.newGame(catalogs)),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final save = session.saveGameData;
    session.explorationService.addEntityToCurrentZone(
      EntityId.TRANQUIL_POND,
      1,
      save.playerData,
      save.worldData,
    );
    final entity =
        session.explorationService.getEntity(
              EntityId.TRANQUIL_POND,
              save.playerData.currentZoneId,
              save.worldData,
            )
            as EncounterEntity;
    session.encounterService.setEncounterEntity(save.encounterData, entity);

    final result = session.encounterSystem.executeFishingAction(
      playerState: save.playerData,
      encounter: save.encounterData,
      world: save.worldData,
      playerInventory: save.inventoryData,
      actionCount: 2000,
      offline: true,
    );
    final junk = {for (final e in fishingJunkDropTable) e.id};
    final items = {for (final s in result.items) s.id as ItemId: s.count};
    expect(items.keys.toSet().intersection(junk), isNotEmpty);
    for (final id in junk) {
      expect(id.definition.xpValue, 0, reason: id.name);
    }
    expect(items.keys, contains(ItemId.MINNOW));
    // the water's reagents come up beside the catches; xp is the fish's alone
    expect(
      items.keys.toSet().intersection({
        for (final e in pondReagentDropTable) e.id,
      }),
      isNotEmpty,
    );
    expect(
      result.xp[SkillId.FISHING],
      (items[ItemId.MINNOW] ?? 0) * ItemId.MINNOW.definition.xpValue,
    );
    session.dispose();
  });
}
