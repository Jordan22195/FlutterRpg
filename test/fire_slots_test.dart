import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/crafting_state.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/systems/fire_tending_system.dart';

// Fire slots. A zone with a firepit holds several fire slots; how many burn
// at once is the firemaker's level, the same cap in every zone. A fire
// carries one kindling, and fires on the same stat don't stack.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final factory = GameSessionFactory();

  GameSession buildSession({SaveGameData? save}) {
    final catalogs = factory.catalog1();
    return factory.create(
      save: save ?? factory.newGame(catalogs),
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void setFiremaking(GameSession session, int level) {
    final skill =
        session.saveGameData.playerData.skillData[SkillId.FIREMAKING]!;
    skill.xp = skill.xpTable[level];
  }

  // one craft of [recipeId] at [slot] through the real crafting path
  void craftAt(GameSession session, String recipeId, EntityId slot) {
    final save = session.saveGameData;
    save.craftingState.craftingEntityId = slot;
    save.craftingState.activeRecipeId = recipeId;
    session.craftingSystem.craftActiveRecipe(
      save.craftingState,
      save.playerData,
      save.inventoryData,
      save.playerData.buffData,
      save.worldData,
    );
  }

  FireItem? fireIn(GameSession session, EntityId slot) {
    final save = session.saveGameData;
    return session.firemakingSystem.activeFire(
      slot,
      save.playerData.currentZoneId,
      save.playerData.buffData,
    );
  }

  group('the cap', () {
    test('rises along the Fibonacci ladder, the same in every zone', () {
      expect(FireSlots.capFor(1), 1);
      expect(FireSlots.capFor(12), 1);
      expect(FireSlots.capFor(13), 2);
      expect(FireSlots.capFor(34), 3);
      expect(FireSlots.capFor(55), 4);
      expect(FireSlots.capFor(89), 5);
      expect(FireSlots.capFor(99), 5);
      expect(FireSlots.nextCapLevel(1), 13);
      expect(FireSlots.nextCapLevel(34), 55);
      expect(FireSlots.nextCapLevel(89), isNull);
    });

    test('a cold slot past the cap lights nothing and spends nothing', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 5);
      save.inventoryData.itemMap[ItemId.LOGS] = 50;

      craftAt(session, 'cookfire', EntityId.FIREPIT);
      expect(fireIn(session, EntityId.FIREPIT), isNotNull);
      final logs = save.inventoryData.itemMap[ItemId.LOGS];

      // level 5 holds one fire, and a cookfire counts
      craftAt(session, 'cookfire', EntityId.FIREPIT_2);
      expect(fireIn(session, EntityId.FIREPIT_2), isNull);
      expect(save.inventoryData.itemMap[ItemId.LOGS], logs);
      expect(
        session.craftingSystem.recipeRequirementsMet(
          'cookfire',
          save.playerData,
          save.inventoryData,
          save.craftingState,
        ),
        isFalse,
      );

      // the fire already burning still takes more logs
      craftAt(session, 'cookfire', EntityId.FIREPIT);
      expect(save.inventoryData.itemMap[ItemId.LOGS], lessThan(logs!));

      // at 13 there is room for a second
      setFiremaking(session, 13);
      craftAt(session, 'cookfire', EntityId.FIREPIT_2);
      expect(fireIn(session, EntityId.FIREPIT_2), isNotNull);
      session.dispose();
    });

    test('a new fire goes in the first cold slot', () {
      final session = buildSession();
      final save = session.saveGameData;
      final zone = save.playerData.currentZoneId;
      final buffs = save.playerData.buffData;
      setFiremaking(session, 34);
      save.inventoryData.itemMap[ItemId.LOGS] = 50;

      expect(
        session.firemakingSystem.freeSlot(zone, buffs, 3),
        EntityId.FIREPIT,
      );
      craftAt(session, 'cookfire', EntityId.FIREPIT);
      expect(
        session.firemakingSystem.freeSlot(zone, buffs, 3),
        EntityId.FIREPIT_2,
      );
      craftAt(session, 'cookfire', EntityId.FIREPIT_3);
      expect(
        session.firemakingSystem.freeSlot(zone, buffs, 3),
        EntityId.FIREPIT_2,
      );
      craftAt(session, 'cookfire', EntityId.FIREPIT_2);
      expect(session.firemakingSystem.freeSlot(zone, buffs, 3), isNull);
      session.dispose();
    });
  });

  group('slots in the world', () {
    test('a zone with a firepit holds every slot; one without holds none', () {
      final session = buildSession();
      final zones = session.saveGameData.worldData.zones;
      final withPit = ZoneId.values.firstWhere(
        (z) =>
            z != ZoneId.NULL &&
            z.definition.permanentEntities.contains(EntityId.FIREPIT),
      );
      expect(
        zones[withPit]!.permanentEntities.map((e) => e.id),
        containsAll(FireSlots.slots),
      );
      for (final zone in zones.values) {
        final ids = zone.permanentEntities.map((e) => e.id).toSet();
        final slots = ids.where(FireSlots.isFireSlot).length;
        expect(slots, anyOf(0, FireSlots.slots.length), reason: zone.id.name);
      }
      session.dispose();
    });

    test('a save from before slots gains them on load, its fire kept', () {
      final first = buildSession();
      final save = first.saveGameData;
      setFiremaking(first, 13);
      save.inventoryData.itemMap[ItemId.LOGS] = 50;
      craftAt(first, 'cookfire', EntityId.FIREPIT);
      final zone = save.playerData.currentZoneId;
      // the save as it was: only the one firepit in each zone
      for (final z in save.worldData.zones.values) {
        z.permanentEntities.removeWhere(
          (e) => FireSlots.isFireSlot(e.id) && e.id != EntityId.FIREPIT,
        );
      }
      final json = jsonDecode(jsonEncode(save.toJson()));
      first.dispose();

      final loaded = buildSession(save: SaveGameData.fromJson(json));
      expect(
        loaded.saveGameData.worldData.zones[zone]!.permanentEntities.map(
          (e) => e.id,
        ),
        containsAll(FireSlots.slots),
      );
      expect(fireIn(loaded, EntityId.FIREPIT)?.id, ItemId.COOKFIRE);
      loaded.dispose();
    });
  });

  group('fires on the same stat', () {
    test('only the strongest counts; different stats both apply', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 34);
      save.inventoryData.itemMap[ItemId.LOGS] = 50;
      save.inventoryData.itemMap[ItemId.OAK_LOGS] = 50;
      craftAt(session, 'basic_campfire', EntityId.FIREPIT);
      craftAt(session, 'oak_campfire', EntityId.FIREPIT_2);
      craftAt(session, 'basic_campfire', EntityId.FIREPIT_3);
      final now = DateTime.now();
      fireIn(session, EntityId.FIREPIT)!.tend(SkillId.STRENGTH, now);
      final oak = fireIn(session, EntityId.FIREPIT_2)!;
      oak.tend(SkillId.STRENGTH, now);
      fireIn(session, EntityId.FIREPIT_3)!.tend(SkillId.DEFENCE, now);

      final totals = session.buffService.getBuffedStatTotal(
        save.playerData.buffData,
        save.playerData.currentZoneId,
      );
      final basic =
          (ItemId.BASIC_CAMPFIRE.definition as FireItemDefinition).power;
      expect(oak.power, greaterThan(basic));
      expect(totals[SkillId.STRENGTH], oak.power);
      expect(totals[SkillId.DEFENCE], basic);
      session.dispose();
    });
  });

  group('one kindling per fire', () {
    test('a fire takes more of its kindling but never a second', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.LOGS] = 50;
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      save.inventoryData.itemMap[ItemId.TREE_BARK] = 5;
      final zone = save.playerData.currentZoneId;
      // a long campfire, with room for several
      session.firemakingSystem.lightOrExtend(
        ItemId.BASIC_CAMPFIRE,
        EntityId.FIREPIT,
        zone,
        save.playerData.buffData,
        count: 5,
      );
      TendBlock block(ItemId reagent, {DateTime? at}) =>
          session.fireTendingSystem.blockFor(
            reagent,
            EntityId.FIREPIT,
            zone,
            save.playerData,
            save.inventoryData,
            at: at,
          );

      expect(block(ItemId.ACORN), TendBlock.none);
      expect(block(ItemId.TREE_BARK), TendBlock.none);
      session.fireTendingSystem.tend(
        ItemId.ACORN,
        EntityId.FIREPIT,
        zone,
        save.playerData,
        save.inventoryData,
      );

      // strength burns on it now: more acorns, but no bark
      expect(block(ItemId.ACORN), TendBlock.none);
      expect(block(ItemId.TREE_BARK), TendBlock.otherKindling);
      expect(
        session.fireTendingSystem.tend(
          ItemId.TREE_BARK,
          EntityId.FIREPIT,
          zone,
          save.playerData,
          save.inventoryData,
        ),
        0,
      );
      expect(save.inventoryData.itemMap[ItemId.TREE_BARK], 5);

      // once the acorn's buff runs out the fire takes a new kindling
      final fire = fireIn(session, EntityId.FIREPIT)!;
      final after = fire.reagentExpirations[SkillId.STRENGTH]!.add(
        const Duration(seconds: 1),
      );
      expect(after.isBefore(fire.expirationTime), isTrue);
      expect(block(ItemId.TREE_BARK, at: after), TendBlock.none);
      session.dispose();
    });

    test('a save that picked several kindlings keeps the first', () {
      final state = CraftingState.fromJson({
        'activeRecipeId': '',
        'craftedItems': CraftingState().craftedItems.toJson(),
        'craftingEntityId': EntityId.FIREPIT.name,
        'reagentMixByEntity': {
          EntityId.FIREPIT.name: [
            'tend_acorn',
            'tend_tree_bark',
            'tend_dry_twigs',
          ],
        },
      });
      expect(state.reagentMixByEntity[EntityId.FIREPIT], ['tend_acorn']);
    });
  });
}
