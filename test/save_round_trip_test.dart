import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/auto_eat_rule.dart';
import 'package:rpg/data/bound_action.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/catalogs/items/items.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('a whole save through the real load path', () {
    // SaveGameData.fromJson is only half of loading: GameSessionFactory.create
    // runs the migrations on top of it, and some state is deliberately left
    // to that step rather than carried in the file. Round-tripping the json
    // alone therefore proves nothing about what the player gets back — these
    // go through create(), the way a relaunch does.
    /// Writes [save] out, reads it back and runs the load migrations over
    /// it, the way a relaunch does. [tamper] edits the decoded json first,
    /// to stand in for a file an older content pack wrote.
    GameSession reload(
      SaveGameData save,
      GameCatalogBundle catalogs, {
      Map<String, dynamic> Function(Map<String, dynamic>)? tamper,
    }) {
      var decoded =
          jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
      if (tamper != null) decoded = tamper(decoded);
      return GameSessionFactory().create(
        save: SaveGameData.fromJson(decoded),
        catalogs: catalogs,
        vsync: const TestVSync(),
      );
    }

    test('SaveGameData survives a JSON round trip', () {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);

      save.uiState.tabIndex = 3;
      save.uiState.mapRouteStack = ['explore', 'shop'];
      save.uiState.dungeonId = DungeonId.GOBLIN_QUEEN_LAIR;

      final session = reload(save, catalogs);
      final restored = session.saveGameData;

      expect(restored.slotId, save.slotId);
      expect(restored.contentPackId, save.contentPackId);
      expect(restored.playerData.currentZoneId, save.playerData.currentZoneId);
      expect(restored.worldData.zones.keys, save.worldData.zones.keys);
      expect(
        restored.worldData.zones.values.map((z) => z.permanentEntities.length),
        save.worldData.zones.values.map((z) => z.permanentEntities.length),
      );
      expect(restored.uiState.tabIndex, save.uiState.tabIndex);
      expect(restored.uiState.mapRouteStack, save.uiState.mapRouteStack);
      expect(restored.uiState.dungeonId, save.uiState.dungeonId);

      session.dispose();
    });

    test('a zone\'s landmarks are rebuilt from the catalog, not the file', () {
      // the contract Zone.fromJson is written to: permanent entities are
      // content, not save state, so the file's copy is dropped on read and
      // the definition's list is what the player gets back. That is what
      // lets a firepit be added to a zone that shipped without one.
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);

      final zoneId = ZoneId.TUTORIAL_FARM;
      final defined = zoneId.definition.permanentEntities;
      expect(defined, isNotEmpty, reason: 'pick a zone with landmarks');

      // a save from an older content pack: this zone's landmarks are gone
      // from the file entirely, and it carries one the catalog never had
      final session = reload(
        save,
        catalogs,
        tamper: (json) {
          final zones = json['worldData']['zones'] as Map<String, dynamic>;
          (zones[zoneId.name] as Map<String, dynamic>)['permanentEntities'] =
              <dynamic>[];
          return json;
        },
      );
      final restored = session.saveGameData;

      final zone = restored.worldData.zones[zoneId]!;
      expect(
        zone.permanentEntities.map((e) => e.id).toSet(),
        defined.toSet(),
        reason: 'the load did not rebuild the zone\'s landmarks',
      );
      // and exactly once each — the rebuild must not double up on a save
      // that already listed them
      expect(zone.permanentEntities, hasLength(defined.length));

      session.dispose();
    });

    test('a landmark is never also a discovery', () {
      // older saves discovered entities that were later promoted to
      // permanent, leaving the same id in both lists. The permanent entry
      // wins and the discovered duplicate is dropped.
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);

      final zoneId = ZoneId.TUTORIAL_FARM;
      final landmark = zoneId.definition.permanentEntities.first;

      final session = reload(
        save,
        catalogs,
        tamper: (json) {
          final zones = json['worldData']['zones'] as Map<String, dynamic>;
          final zone = zones[zoneId.name] as Map<String, dynamic>;
          // the same landmarks, filed as discoveries the way an old save
          // that found them before they were promoted would have
          zone['discoveredEntities'] = [
            ...zone['permanentEntities'] as List,
          ];
          return json;
        },
      );
      final restored = session.saveGameData;

      final zone = restored.worldData.zones[zoneId]!;
      expect(zone.permanentEntities.map((e) => e.id), contains(landmark));
      expect(
        zone.discoveredEntities.map((e) => e.id),
        isNot(contains(landmark)),
        reason: 'the landmark is in both lists',
      );

      session.dispose();
    });

    test('a zone added since the save was written is built from scratch', () {
      final factory = GameSessionFactory();
      final catalogs = factory.catalog1();
      final save = factory.newGame(catalogs);

      final zoneId = ZoneId.DARKWOOD_FOREST;
      final session = reload(
        save,
        catalogs,
        tamper: (json) {
          final zones = json['worldData']['zones'] as Map<String, dynamic>;
          zones.remove(zoneId.name);
          return json;
        },
      );
      final restored = session.saveGameData;

      final zone = restored.worldData.zones[zoneId];
      expect(zone, isNotNull, reason: 'the missing zone was not backfilled');
      expect(
        zone!.permanentEntities.map((e) => e.id).toSet(),
        zoneId.definition.permanentEntities.toSet(),
      );
      expect(zone.discoveredEntities, isEmpty);

      session.dispose();
    });
  });

  group('action timing state', () {
    SaveGameData roundTrip(SaveGameData save) {
      return SaveGameData.fromJson(
        jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      );
    }

    test('a running action and its momentum survive a round trip', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());

      final timing = save.actionTimingData;
      timing.running = true;
      timing.boostLocked = true;
      timing.boostingSpeed = true;
      timing.percentOfMaxBoost = 0.6;
      timing.actionProgressPercentComplete = 0.25;
      timing.maxBoostMultiplier = 1.75;
      timing.maxInterval = const Duration(milliseconds: 2400);
      timing.actionSkill = SkillId.WOODCUTTING;
      timing.boundAction = const BoundAction.craft(
        zoneId: ZoneId.TUTORIAL_FARM,
        entityId: EntityId.ANVIL,
        recipeId: 'bronze_bar',
      );

      final restored = roundTrip(save).actionTimingData;

      expect(restored.running, isTrue);
      expect(restored.boostLocked, isTrue);
      expect(restored.boostingSpeed, isTrue);
      expect(restored.percentOfMaxBoost, closeTo(0.6, 1e-9));
      expect(restored.actionProgressPercentComplete, closeTo(0.25, 1e-9));
      expect(restored.maxBoostMultiplier, closeTo(1.75, 1e-9));
      expect(restored.maxInterval, const Duration(milliseconds: 2400));
      expect(restored.actionSkill, SkillId.WOODCUTTING);

      expect(restored.boundAction?.kind, BoundActionKind.CRAFT);
      expect(restored.boundAction?.zoneId, ZoneId.TUTORIAL_FARM);
      expect(restored.boundAction?.entityId, EntityId.ANVIL);
      expect(restored.boundAction?.recipeId, 'bronze_bar');
    });

    // these describe the live frame loop, not the run: no finger is on the
    // button at launch, and a fresh ticker restarts its own elapsed clock
    test('frame-transient fields come back clean', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());

      final timing = save.actionTimingData;
      timing.running = true;
      timing.buttonHeld = true;
      timing.actionInFlight = true;
      timing.lastElapsed = const Duration(seconds: 9);

      final restored = roundTrip(save).actionTimingData;

      expect(restored.buttonHeld, isFalse);
      expect(restored.actionInFlight, isFalse);
      expect(restored.lastElapsed, Duration.zero);
    });

    test('a save written before the loop was persisted loads idle', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());

      final json = save.toJson();
      json.remove('actionTimingData');
      final restored = SaveGameData.fromJson(json);

      expect(restored.actionTimingData.running, isFalse);
      expect(restored.actionTimingData.boundAction, isNull);
    });

    test('an unrecognized action kind loads idle rather than throwing', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      save.actionTimingData.running = true;
      save.actionTimingData.boundAction = const BoundAction.explore(
        zoneId: ZoneId.TUTORIAL_FARM,
      );

      final json = save.toJson();
      (json['actionTimingData'] as Map<String, dynamic>)['boundAction'] = {
        'kind': 'SOMETHING_RETIRED',
      };

      expect(SaveGameData.fromJson(json).actionTimingData.boundAction, isNull);
    });
  });

  group('the auto-drink potions', () {
    SaveGameData roundTrip(SaveGameData save) {
      return SaveGameData.fromJson(
        jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      );
    }

    test('the armed set survives a round trip', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      save.playerData.autoDrinkPotions.addAll([
        ItemId.MINOR_SPEED_POTION,
        ItemId.MINOR_ATTACK_POTION,
      ]);

      expect(roundTrip(save).playerData.autoDrinkPotions, {
        ItemId.MINOR_SPEED_POTION,
        ItemId.MINOR_ATTACK_POTION,
      });
    });

    test('a retired or malformed entry is skipped, not thrown on', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      final json =
          jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
      (json['playerData'] as Map)['autoDrinkPotions'] = [
        'MINOR_SPEED_POTION',
        'RETIRED_POTION',
        42,
      ];

      expect(SaveGameData.fromJson(json).playerData.autoDrinkPotions, {
        ItemId.MINOR_SPEED_POTION,
      });
    });

    test('a save written before the set existed loads nothing armed', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      final json =
          jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
      (json['playerData'] as Map).remove('autoDrinkPotions');

      expect(SaveGameData.fromJson(json).playerData.autoDrinkPotions, isEmpty);
    });
  });

  group('the auto-eat rule', () {
    SaveGameData roundTrip(SaveGameData save) {
      return SaveGameData.fromJson(
        jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>,
      );
    }

    test('a changed threshold survives a round trip', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      save.playerData.autoEatRule = const AutoEatRule(threshold: 0.4);

      expect(roundTrip(save).playerData.autoEatRule.threshold, 0.4);
    });

    test('a save written before the rule existed loads the standard one', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());
      final json =
          jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
      (json['playerData'] as Map).remove('autoEatRule');

      final restored = SaveGameData.fromJson(json);

      expect(
        restored.playerData.autoEatRule.threshold,
        AutoEatRule.standard.threshold,
      );
    });
  });
}
