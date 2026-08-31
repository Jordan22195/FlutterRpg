import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/services/crafting_service.dart';

// Fires are zone buffs owned by a firepit, not entities. These cover the
// three things that follow from that: a firepit holds one fire, firepits are
// independent of each other, and cooking is gated on the fire that is lit.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession() {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  // gives the player enough logs and firemaking to light anything
  void stockForFiremaking(GameSession session, {int level = 40}) {
    final save = session.saveGameData;
    final skill = save.playerData.skillData[SkillId.FIREMAKING]!;
    skill.xp = skill.xpTable[level];
    save.inventoryData.itemMap[ItemId.LOGS] = 200;
    save.inventoryData.itemMap[ItemId.OAK_LOGS] = 200;
  }

  // runs one craft of [recipeId] at [firepit] through the real crafting path
  void craftAt(GameSession session, String recipeId, EntityId firepit) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = firepit;
    save.craftingState.activeRecipeId = recipeId;
    session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
    );
  }

  test('lighting a fire buffs the firepit and adds no entity to the zone', () {
    final session = buildSession();
    final save = session.saveGameData;
    stockForFiremaking(session);

    final entitiesBefore = session.explorationService
        .getCurrentZoneEntities(save.playerData, save.worldData)
        .length;

    craftAt(session, 'cookfire', EntityId.FIREPIT);

    final fire = session.firemakingSystem.activeFire(
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    );

    expect(fire, isNotNull);
    expect(fire!.id, ItemId.COOKFIRE);
    expect(fire.canCook, isTrue);

    // no fire entity: the firepit is the only thing standing in the zone
    expect(
      session.explorationService
          .getCurrentZoneEntities(save.playerData, save.worldData)
          .length,
      entitiesBefore,
    );

    // and no fire lands in the inventory either
    expect(save.inventoryData.itemMap[ItemId.COOKFIRE] ?? 0, 0);

    session.dispose();
  });

  test('adding logs extends the fire; a different fire replaces it', () {
    final session = buildSession();
    final save = session.saveGameData;
    stockForFiremaking(session);

    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final firstExpiry = session.firemakingSystem
        .activeFire(
          EntityId.FIREPIT,
          save.playerData.currentZoneId,
          save.playerData.buffData,
        )!
        .expirationTime;

    // same fire again: the timer grows rather than restarting
    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final extended = session.firemakingSystem.activeFire(
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    )!;
    expect(extended.id, ItemId.COOKFIRE);
    expect(extended.expirationTime.isAfter(firstExpiry), isTrue);

    // a different fire takes the firepit over entirely
    craftAt(session, 'bonfire', EntityId.FIREPIT);
    final replaced = session.firemakingSystem.activeFire(
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    )!;
    expect(replaced.id, ItemId.BONFIRE);
    expect(
      save.playerData.buffData.zoneBuffs[save.playerData.currentZoneId]!.length,
      1,
    );

    session.dispose();
  });

  test('two firepits in a zone burn independently and their buffs sum', () {
    final session = buildSession();
    final save = session.saveGameData;
    stockForFiremaking(session);

    // ANVIL stands in for a second firepit: the model keys on the owning
    // entity id, so any two distinct ids are two independent fires
    craftAt(session, 'basic_campfire', EntityId.FIREPIT);
    craftAt(session, 'basic_campfire', EntityId.ANVIL);

    final zoneBuffs =
        save.playerData.buffData.zoneBuffs[save.playerData.currentZoneId]!;
    expect(zoneBuffs.keys, containsAll([EntityId.FIREPIT, EntityId.ANVIL]));

    final campfire = ItemId.BASIC_CAMPFIRE.build() as FireItem;
    final total = session.buffService.getBuffedStatTotal(
      save.playerData.buffData,
      save.playerData.currentZoneId,
    );
    // which stats a campfire grants is a balance choice; the claim here is
    // that two of them are worth double, whatever those stats are
    expect(campfire.skillBonus, isNotEmpty);
    for (final entry in campfire.skillBonus.entries) {
      expect(
        total[entry.key],
        entry.value * 2,
        reason: 'two campfires should double their ${entry.key.name} bonus',
      );
    }

    session.dispose();
  });

  test('cooking is gated on a cookfire burning at the station', () {
    final session = buildSession();
    final save = session.saveGameData;
    stockForFiremaking(session);
    save.inventoryData.itemMap[ItemId.MINNOW] = 20;
    save.craftingState.craftingEntityId = EntityId.FIREPIT;

    bool canCook() => session.craftingSystem.recipeRequirementsMet(
      'cook_minnow',
      save.playerData,
      save.inventoryData,
      save.craftingState,
    );

    // cold firepit
    expect(canCook(), isFalse);

    // a campfire burns but cannot cook
    craftAt(session, 'basic_campfire', EntityId.FIREPIT);
    expect(canCook(), isFalse);

    // a cookfire can
    craftAt(session, 'cookfire', EntityId.FIREPIT);
    expect(canCook(), isTrue);

    // and putting it out closes cooking again
    session.firemakingSystem.extinguish(
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    );
    expect(canCook(), isFalse);
    expect(
      session.firemakingSystem.activeFire(
        EntityId.FIREPIT,
        save.playerData.currentZoneId,
        save.playerData.buffData,
      ),
      isNull,
    );

    session.dispose();
  });

  test('a better cookfire burns less food', () {
    final craftingService = CraftingService();
    final cookfire = ItemId.COOKFIRE.build() as FireItem;
    final oakCookfire = ItemId.OAK_COOKFIRE.build() as FireItem;

    // the cooking bonus reaches burn chance through the buffed stat totals,
    // so a higher-tier fire is simply a higher effective cooking level
    final base = craftingService.calculateBurnChance(
      level: 1 + cookfire.skillBonus[SkillId.COOKING]!,
      difficultyScale: 1,
    );
    final oak = craftingService.calculateBurnChance(
      level: 1 + oakCookfire.skillBonus[SkillId.COOKING]!,
      difficultyScale: 1,
    );

    expect(oak, lessThan(base));
  });

  test('an expired fire is swept and its firepit goes cold', () {
    final session = buildSession();
    final save = session.saveGameData;
    stockForFiremaking(session);

    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final fire = save
        .playerData
        .buffData
        .zoneBuffs[save.playerData.currentZoneId]![EntityId.FIREPIT]!;
    fire.expirationTime = DateTime.now().subtract(const Duration(seconds: 1));

    session.buffService.removeExpiredZoneBuffs(save.playerData.buffData);

    expect(
      session.firemakingSystem.activeFire(
        EntityId.FIREPIT,
        save.playerData.currentZoneId,
        save.playerData.buffData,
      ),
      isNull,
    );

    session.dispose();
  });

  test('a fire survives a save round trip with its remaining time', () {
    final session = buildSession();
    final save = session.saveGameData;
    stockForFiremaking(session);
    craftAt(session, 'oak_cookfire', EntityId.FIREPIT);

    final before = session.firemakingSystem.activeFire(
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    )!;

    final restored = SaveGameData.fromJson(
      jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
    );

    final after = restored
        .playerData
        .buffData
        .zoneBuffs[restored.playerData.currentZoneId]![EntityId.FIREPIT]!;

    expect(after, isA<FireItem>());
    expect((after as FireItem).canCook, isTrue);
    expect(after.id, ItemId.OAK_COOKFIRE);
    expect(after.ownerEntityId, EntityId.FIREPIT);
    expect(after.expirationTime.difference(before.expirationTime).inSeconds, 0);

    session.dispose();
  });

  group('legacy saves', () {
    // the shape a save written before this change carries: a campfire entity
    // standing in the zone, a zone buff keyed by ItemId pointing at that
    // entity, and one flat recipe selection per station
    Map<String, dynamic> legacySave(GameSession session) {
      final raw =
          jsonDecode(jsonEncode(session.saveGameData.toJson()))
              as Map<String, dynamic>;
      final zoneId = session.saveGameData.playerData.currentZoneId;

      final zone = (raw['worldData']['zones'] as Map)[zoneId.name] as Map;
      (zone['discoveredEntities'] as List).add({
        'runtimeType': 'CampfireEntity',
        'id': 'BASIC_CAMPIRE',
        'name': 'Basic Campfire',
        'craftingSkill': 'COOKING',
        'expirationTime': DateTime.now()
            .add(const Duration(minutes: 1))
            .toIso8601String(),
      });

      raw['playerData']['buffData']['zoneBuffs'] = {
        zoneId.name: {
          'BASIC_CAMPFIRE': {
            'runtimeType': 'ZoneBuffItem',
            'id': 'BASIC_CAMPFIRE',
            'name': 'Basic Campfire',
            'value': 5,
            'count': 1,
            'skillBonus': {'HITPOINTS': 5},
            'durationMs': 60000,
            'expirationTime': DateTime.now()
                .add(const Duration(minutes: 1))
                .toIso8601String(),
            'zoneId': zoneId.name,
            'entityId': 'BASIC_CAMPIRE',
          },
        },
      };

      raw['craftingState']['selectedRecipeByEntity'] = {
        'ANVIL': 'smelt_copper_bar',
        'FIREPIT': 'basic_campfire',
        // a selection whose recipe no longer exists is dropped, not guessed
        'JEWELCRAFTING_BENCH': 'retired_recipe',
      };

      return raw;
    }

    test('load without throwing, re-homing the fire onto the firepit', () {
      final seed = buildSession();
      final raw = legacySave(seed);
      final zoneId = seed.saveGameData.playerData.currentZoneId;
      seed.dispose();

      final restored = SaveGameData.fromJson(raw);

      // the retired campfire entity is skipped rather than rejecting the save
      final zone = restored.worldData.zones[zoneId]!;
      expect(
        zone.discoveredEntities.where((e) => e.name == 'Basic Campfire'),
        isEmpty,
      );

      // and its buff now belongs to the firepit
      final buff =
          restored.playerData.buffData.zoneBuffs[zoneId]![EntityId.FIREPIT]!;
      expect(buff.id, ItemId.BASIC_CAMPFIRE);
      expect(buff.ownerEntityId, EntityId.FIREPIT);
    });

    test('flat recipe selections are filed under their recipe\'s skill', () {
      final seed = buildSession();
      final raw = legacySave(seed);
      seed.dispose();

      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final session = factory.create(
        save: SaveGameData.fromJson(raw),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );

      final selections =
          session.saveGameData.craftingState.selectedRecipeByEntity;
      expect(
        selections[EntityId.ANVIL]?[SkillId.BLACKSMITHING],
        'smelt_copper_bar',
      );
      expect(
        selections[EntityId.FIREPIT]?[SkillId.FIREMAKING],
        'basic_campfire',
      );
      expect(selections[EntityId.JEWELCRAFTING_BENCH], isNull);
      expect(session.saveGameData.craftingState.legacySelections, isEmpty);

      session.dispose();
    });
  });

  test('the sweep judges expiry at the instant it is given', () {
    final session = buildSession();
    final save = session.saveGameData;
    final buffData = save.playerData.buffData;
    stockForFiremaking(session);

    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final fire =
        buffData.zoneBuffs[save.playerData.currentZoneId]![EntityId.FIREPIT]!;
    final wentOut = fire.expirationTime;

    // a settle replays the gap segment by segment and sweeps at each
    // segment's own instant, so a fire is still there for the stretch it
    // was burning in
    session.buffService.removeExpiredZoneBuffs(
      buffData,
      at: wentOut.subtract(const Duration(seconds: 1)),
    );
    expect(
      session.buffService.getZoneBuff(
        buffData,
        save.playerData.currentZoneId,
        EntityId.FIREPIT,
      ),
      isNotNull,
    );

    // and gone from the instant it went out - inclusive, because a segment
    // ends exactly on the expiry it was cut at
    session.buffService.removeExpiredZoneBuffs(buffData, at: wentOut);
    expect(
      session.buffService.getZoneBuff(
        buffData,
        save.playerData.currentZoneId,
        EntityId.FIREPIT,
      ),
      isNull,
    );

    session.dispose();
  });

  test('a fire answers whether it was lit at a given instant', () {
    final session = buildSession();
    final save = session.saveGameData;
    final zone = save.playerData.currentZoneId;
    final buffData = save.playerData.buffData;
    stockForFiremaking(session);

    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final wentOut = session.firemakingSystem
        .activeFire(EntityId.FIREPIT, zone, buffData)!
        .expirationTime;

    final before = wentOut.subtract(const Duration(seconds: 1));
    final after = wentOut.add(const Duration(seconds: 1));

    expect(
      session.firemakingSystem.activeFire(
        EntityId.FIREPIT,
        zone,
        buffData,
        at: before,
      ),
      isNotNull,
    );
    expect(
      session.firemakingSystem.activeFire(
        EntityId.FIREPIT,
        zone,
        buffData,
        at: after,
      ),
      isNull,
    );
    expect(
      session.firemakingSystem.canCookAt(
        EntityId.FIREPIT,
        zone,
        buffData,
        at: before,
      ),
      isTrue,
    );
    expect(
      session.firemakingSystem.canCookAt(
        EntityId.FIREPIT,
        zone,
        buffData,
        at: after,
      ),
      isFalse,
    );

    // a firepit that never held a fire has no answer either way
    expect(
      session.firemakingSystem.canCookAt(
        EntityId.ANVIL,
        zone,
        buffData,
        at: before,
      ),
      isFalse,
    );

    session.dispose();
  });

  test('the next expiration is the earliest still to come, in this zone', () {
    final session = buildSession();
    final save = session.saveGameData;
    final zone = save.playerData.currentZoneId;
    final buffData = save.playerData.buffData;
    final start = DateTime.now();

    expect(
      session.buffService.nextExpiration(buffData, zone, after: start),
      isNull,
    );

    stockForFiremaking(session);
    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final cookfire = buffData.zoneBuffs[zone]![EntityId.FIREPIT]! as FireItem;
    cookfire.expirationTime = start.add(const Duration(minutes: 5));

    // a second fire in another zone is nothing to do with this one
    final elsewhere = ItemId.BONFIRE.build() as FireItem;
    elsewhere.expirationTime = start.add(const Duration(minutes: 1));
    session.buffService.setZoneBuff(
      elsewhere,
      buffData,
      ZoneId.values.firstWhere((z) => z != zone),
      EntityId.FIREPIT,
    );

    expect(
      session.buffService.nextExpiration(buffData, zone, after: start),
      cookfire.expirationTime,
    );
    // strictly after: asking from the instant it went out looks past it
    expect(
      session.buffService.nextExpiration(
        buffData,
        zone,
        after: cookfire.expirationTime,
      ),
      isNull,
    );

    session.dispose();
  });

  test('stat totals include a fire that was lit at the instant asked', () {
    final session = buildSession();
    final save = session.saveGameData;
    final zone = save.playerData.currentZoneId;
    final buffData = save.playerData.buffData;
    stockForFiremaking(session);

    final baseline =
        session.playerDataService.getStatTotals(
          save.playerData,
        )[SkillId.COOKING] ??
        0;

    craftAt(session, 'cookfire', EntityId.FIREPIT);
    final wentOut = session.firemakingSystem
        .activeFire(EntityId.FIREPIT, zone, buffData)!
        .expirationTime;
    final bonus = ItemId.COOKFIRE.build() as FireItem;

    // while it burns, the fire lends its cooking bonus
    expect(
      session.playerDataService.getStatTotals(save.playerData)[SkillId.COOKING],
      baseline + bonus.skillBonus[SkillId.COOKING]!,
    );

    // and it still does when a settle asks about an instant it was burning
    // at, hours after it went out
    expect(
      session.buffService.getBuffedStatTotal(
        buffData,
        zone,
        at: wentOut.subtract(const Duration(seconds: 1)),
      )[SkillId.COOKING],
      bonus.skillBonus[SkillId.COOKING],
    );
    expect(
      session.buffService.getBuffedStatTotal(
        buffData,
        zone,
        at: wentOut.add(const Duration(seconds: 1)),
      )[SkillId.COOKING],
      isNull,
    );

    // a buff in another zone never counts, whenever it is asked about
    expect(
      session.buffService.getBuffedStatTotal(
        buffData,
        ZoneId.values.firstWhere((z) => z != zone),
        at: wentOut.subtract(const Duration(seconds: 1)),
      ),
      isEmpty,
    );

    session.dispose();
  });
}
