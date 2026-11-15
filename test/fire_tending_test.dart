import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/systems/birds_nest_system.dart';
import 'package:rpg/systems/fire_tending_system.dart';

// Reagent fires. The wood sets a fire's power, the reagent picks the stat,
// a campfire or bonfire gives nothing until tended, and the buffs end with
// the fire. Logs are the grind: a reagent recipe, run off the action button,
// pays a little xp on top.
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

  void setFiremaking(GameSession session, int level) {
    final skill =
        session.saveGameData.playerData.skillData[SkillId.FIREMAKING]!;
    skill.xp = skill.xpTable[level];
  }

  FireItem light(GameSession session, ItemId fire, {DateTime? at}) {
    final save = session.saveGameData;
    session.firemakingSystem.lightOrExtend(
      fire,
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
      at: at,
    );
    return session.firemakingSystem.activeFire(
      EntityId.FIREPIT,
      save.playerData.currentZoneId,
      save.playerData.buffData,
      at: at,
    )!;
  }

  Map<SkillId, int> totals(GameSession session, {DateTime? at}) =>
      session.buffService.getBuffedStatTotal(
        session.saveGameData.playerData.buffData,
        session.saveGameData.playerData.currentZoneId,
        at: at,
      );

  FireItemDefinition def(ItemId id) => id.definition as FireItemDefinition;

  // the waters' reagents come up on a fishing line and buff the skills,
  // higher up the ladder; the woodcutting seven are the combat stats
  const waterReagents = {
    ItemId.CATTAIL_FLUFF,
    ItemId.DRIED_REEDS,
    ItemId.RIVER_DRIFTWOOD,
    ItemId.PEAT_CLOD,
    ItemId.DRIED_RUSHES,
    ItemId.BONE_CORAL,
    ItemId.AMBERGRIS,
  };
  final woodReagents = FireTendingSystem.reagents
      .where((id) => !waterReagents.contains(id))
      .toList();

  group('the fire ladder', () {
    const fib = {1, 2, 3, 5, 8, 13, 21, 34, 55, 89};

    test('every buff number is a Fibonacci rung', () {
      for (final id in ItemId.values) {
        final d = id.definition;
        if (d is! FireItemDefinition) continue;
        expect(fib, contains(d.duration.inMinutes), reason: id.name);
        expect(fib, contains(d.reagentBurn.inMinutes), reason: id.name);
        for (final v in d.skillBonus.values) {
          expect(fib, contains(v), reason: id.name);
        }
        if (d.tendable) expect(fib, contains(d.power), reason: id.name);
      }
    });

    test('campfire and bonfire powers climb the wood tiers', () {
      expect(
        [
          ItemId.BASIC_CAMPFIRE,
          ItemId.OAK_CAMPFIRE,
          ItemId.WILLOW_CAMPFIRE,
          ItemId.MAPLE_CAMPFIRE,
          ItemId.YEW_CAMPFIRE,
          ItemId.MAGIC_CAMPFIRE,
        ].map((id) => def(id).power),
        [5, 8, 13, 21, 34, 55],
      );
      expect(
        [
          ItemId.BONFIRE,
          ItemId.OAK_BONFIRE,
          ItemId.WILLOW_BONFIRE,
          ItemId.MAPLE_BONFIRE,
          ItemId.YEW_BONFIRE,
          ItemId.MAGIC_BONFIRE,
        ].map((id) => def(id).power),
        [5, 8, 13, 21, 34, 55],
      );
    });

    test('a bonfire starts at its campfire, stokes two rungs past it, and '
        'eats kindling faster', () {
      for (final (campfire, bonfire) in [
        (ItemId.BASIC_CAMPFIRE, ItemId.BONFIRE),
        (ItemId.OAK_CAMPFIRE, ItemId.OAK_BONFIRE),
        (ItemId.WILLOW_CAMPFIRE, ItemId.WILLOW_BONFIRE),
        (ItemId.BOG_CAMPFIRE, ItemId.BOG_BONFIRE),
        (ItemId.MAPLE_CAMPFIRE, ItemId.MAPLE_BONFIRE),
        (ItemId.YEW_CAMPFIRE, ItemId.YEW_BONFIRE),
        (ItemId.MAGIC_CAMPFIRE, ItemId.MAGIC_BONFIRE),
      ]) {
        expect(def(bonfire).power, def(campfire).power, reason: bonfire.name);
        expect(def(bonfire).stokes, isTrue, reason: bonfire.name);
        expect(def(campfire).stokes, isFalse, reason: campfire.name);
        expect(
          (bonfire.build() as FireItem).ceiling,
          FireItem.stepped(def(campfire).power, 2),
          reason: bonfire.name,
        );
        expect(
          def(bonfire).reagentBurn,
          lessThan(def(campfire).reagentBurn),
          reason: bonfire.name,
        );
      }
      expect((ItemId.BONFIRE.build() as FireItem).ceiling, 13);
    });

    test('bog is willow one rung weaker and one rung longer', () {
      for (final (willow, bog) in [
        (ItemId.WILLOW_CAMPFIRE, ItemId.BOG_CAMPFIRE),
        (ItemId.WILLOW_BONFIRE, ItemId.BOG_BONFIRE),
      ]) {
        expect(def(bog).power, lessThan(def(willow).power));
        expect(def(bog).duration, greaterThan(def(willow).duration));
      }
      expect(
        def(ItemId.BOG_COOKFIRE).duration,
        greaterThan(def(ItemId.WILLOW_COOKFIRE).duration),
      );
    });
  });

  group('tending', () {
    test('a campfire gives nothing until a reagent goes on', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      expect(totals(session, at: now), isEmpty);

      fire.tend(SkillId.STRENGTH, now);
      expect(totals(session, at: now)[SkillId.STRENGTH], fire.power);
      session.dispose();
    });

    test('a second reagent extends the first; a buff ends with the fire', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      final burn = fire.definition.reagentBurn;

      // three 5 minute lays: room for two 5 minute reagents and a part
      session.firemakingSystem.lightOrExtend(
        ItemId.BASIC_CAMPFIRE,
        EntityId.FIREPIT,
        session.saveGameData.playerData.currentZoneId,
        session.saveGameData.playerData.buffData,
        count: 2,
        at: now,
      );
      fire.expirationTime = fire.expirationTime.subtract(
        const Duration(minutes: 2),
      );
      fire.tend(SkillId.STRENGTH, now);
      fire.tend(SkillId.STRENGTH, now);
      expect(fire.reagentExpirations[SkillId.STRENGTH], now.add(burn * 2));

      // a third would outlast the fire, so it stops at the fire's end
      fire.tend(SkillId.STRENGTH, now);
      expect(fire.reagentExpirations[SkillId.STRENGTH], fire.expirationTime);

      // and the buff stops with the fire
      final afterFire = fire.expirationTime.add(const Duration(seconds: 1));
      expect(totals(session, at: afterFire), isEmpty);
      session.dispose();
    });

    test('different reagents run side by side', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.OAK_BONFIRE, at: now);
      fire.tend(SkillId.STRENGTH, now);
      fire.tend(SkillId.DEFENCE, now);
      expect(totals(session, at: now), {
        SkillId.STRENGTH: fire.power,
        SkillId.DEFENCE: fire.power,
      });
      session.dispose();
    });

    test('every combat stat can be tended by Firemaking 13', () {
      final stats = {
        for (final id in woodReagents)
          FireTendingSystem.reagentDefinition(id)!.stat,
      };
      expect(stats, {
        SkillId.STAMINA,
        SkillId.DEFENCE,
        SkillId.RECOVERY,
        SkillId.STRENGTH,
        SkillId.ATTACK,
        SkillId.SPEED,
        SkillId.HITPOINTS,
      });
      for (final id in woodReagents) {
        expect(
          FireTendingSystem.reagentDefinition(id)!.levelRequirement,
          lessThanOrEqualTo(13),
        );
      }
    });

    test('each water reagent buffs a skill no other reagent does', () {
      final stats = [
        for (final id in FireTendingSystem.reagents)
          FireTendingSystem.reagentDefinition(id)!.stat,
      ];
      expect(stats.toSet(), hasLength(stats.length), reason: 'one per stat');
      for (final id in waterReagents) {
        final d = FireTendingSystem.reagentDefinition(id)!;
        expect(
          const {21, 34, 55, 89},
          contains(d.levelRequirement),
          reason: id.name,
        );
        expect(d.levelRequirement, greaterThan(13), reason: id.name);
        expect(FireTendingSystem.reagentFor(d.stat), id);
      }
    });

    test('a water reagent on a campfire buffs its skill', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      fire.tend(SkillId.FISHING, now);
      expect(totals(session, at: now)[SkillId.FISHING], fire.power);
      session.dispose();
    });

    test('a cookfire cannot be tended, and a reagent waits on its level', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.OAK_SAP] = 5;
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      setFiremaking(session, 10);
      save.playerData.currentEntityViewId = EntityId.FIREPIT;

      TendBlock block(ItemId reagent) => session.fireTendingSystem.blockFor(
        reagent,
        EntityId.FIREPIT,
        save.playerData.currentZoneId,
        save.playerData,
        save.inventoryData,
      );

      light(session, ItemId.COOKFIRE);
      expect(block(ItemId.ACORN), TendBlock.cookfire);

      light(session, ItemId.BASIC_CAMPFIRE);
      expect(block(ItemId.ACORN), TendBlock.none);
      expect(block(ItemId.OAK_SAP), TendBlock.level);
      session.dispose();
    });

    // runs one tick of [recipeId] at the firepit through the crafting path,
    // as the action button does
    void craft(GameSession session, String recipeId) {
      final save = session.saveGameData;
      save.craftingState.craftingEntityId = EntityId.FIREPIT;
      save.craftingState.activeRecipeId = recipeId;
      session.craftingSystem.craftActiveRecipe(
        save.craftingState,
        save.playerData,
        save.inventoryData,
        save.playerData.buffData,
        save.worldData,
      );
    }

    void pickFire(GameSession session, String recipeId) {
      session.saveGameData.craftingState.selectedRecipeByEntity[EntityId
          .FIREPIT] = {
        SkillId.FIREMAKING: recipeId,
      };
    }

    test('every reagent has a recipe, and the fire list leaves them out', () {
      final session = buildSession();
      final reagents = [
        for (final r in session.craftingController.availableReagentRecipes())
          r.tendReagent,
      ];
      expect(reagents.toSet(), FireTendingSystem.reagents.toSet());
      // in the order the stage shows their rings
      final stats = [
        for (final id in reagents)
          FireTendingSystem.reagentDefinition(id!)!.stat.index,
      ];
      expect(stats, [...stats]..sort());
      for (final r in session.craftingController.availableReagentRecipes()) {
        expect(r.skill, SkillId.FIREMAKING);
        expect(r.xp, FireTendingSystem.tendXp(r.tendReagent!));
      }
      expect(
        session.craftingController
            .availableRecipesFor(SkillId.FIREMAKING)
            .where((r) => r.tendReagent != null || r.isReagentMix),
        isEmpty,
      );
      session.dispose();
    });

    test('a reagent recipe throws one on and pays its level in xp', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      final skill = save.playerData.skillData[SkillId.FIREMAKING]!;

      final before = skill.xp;
      craft(session, 'tend_acorn');
      expect(skill.xp - before, FireTendingSystem.tendXp(ItemId.ACORN));
      expect(save.inventoryData.itemMap[ItemId.ACORN], 4);
      expect(fire.reagentActive(SkillId.STRENGTH, DateTime.now()), isTrue);
      session.dispose();
    });

    test('kindling never lights a cold pit', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      save.inventoryData.itemMap[ItemId.LOGS] = 5;
      pickFire(session, 'basic_campfire');

      craft(session, 'tend_acorn');
      // nothing spent and nothing lit: the fire has to be lit first
      expect(save.inventoryData.itemMap[ItemId.LOGS], 5);
      expect(save.inventoryData.itemMap[ItemId.ACORN], 5);
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

    test('kindling needs a campfire or bonfire already burning', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      save.inventoryData.itemMap[ItemId.LOGS] = 5;
      save.craftingState.craftingEntityId = EntityId.FIREPIT;
      bool canRun() => session.craftingSystem.recipeRequirementsMet(
        'tend_acorn',
        save.playerData,
        save.inventoryData,
        save.craftingState,
      );

      // a cookfire burning: nothing to throw it on
      pickFire(session, 'cookfire');
      light(session, ItemId.COOKFIRE);
      expect(canRun(), isFalse);

      // a campfire picked with the logs to light it is not enough
      pickFire(session, 'basic_campfire');
      expect(canRun(), isFalse);

      // one burning is
      light(session, ItemId.BASIC_CAMPFIRE);
      expect(canRun(), isTrue);
      session.dispose();
    });

    void pickMix(GameSession session, List<String> recipeIds) {
      session.saveGameData.craftingState.reagentMixByEntity[EntityId.FIREPIT] =
          [...recipeIds];
    }

    test('a kindling mix throws one of every picked reagent at once', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      save.inventoryData.itemMap[ItemId.TREE_BARK] = 5;
      save.inventoryData.itemMap[ItemId.DRY_TWIGS] = 5;
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      pickMix(session, ['tend_acorn', 'tend_tree_bark', 'tend_dry_twigs']);
      final skill = save.playerData.skillData[SkillId.FIREMAKING]!;
      final before = skill.xp;

      craft(session, reagentMixRecipeId);
      for (final id in [ItemId.ACORN, ItemId.TREE_BARK, ItemId.DRY_TWIGS]) {
        expect(save.inventoryData.itemMap[id], 4, reason: id.name);
      }
      for (final stat in [SkillId.STRENGTH, SkillId.DEFENCE, SkillId.STAMINA]) {
        expect(fire.reagentActive(stat, DateTime.now()), isTrue);
      }
      expect(
        skill.xp - before,
        FireTendingSystem.tendXp(ItemId.ACORN) +
            FireTendingSystem.tendXp(ItemId.TREE_BARK) +
            FireTendingSystem.tendXp(ItemId.DRY_TWIGS),
      );
      session.dispose();
    });

    test('a mix skips full rings and stops once every ring is full', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 10;
      save.inventoryData.itemMap[ItemId.TREE_BARK] = 10;
      save.playerData.currentEntityViewId = EntityId.FIREPIT;
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      pickMix(session, ['tend_acorn', 'tend_tree_bark']);
      // strength already full
      fire.tend(SkillId.STRENGTH, now, count: 10);

      final controller = session.craftingController;
      expect(
        controller.startCraftingActionFor(reagentMixRecipeId, EntityId.FIREPIT),
        isTrue,
      );
      controller.doCraftingAction(1);
      expect(save.inventoryData.itemMap[ItemId.ACORN], 10);
      expect(save.inventoryData.itemMap[ItemId.TREE_BARK], 9);
      // a 5 minute campfire holds one 5 minute bark: full, so it stopped
      expect(controller.mixFull(), isTrue);
      expect(session.actionTimingController.isRunning, isFalse);
      session.dispose();
    });

    test('a mix keeps picked reagents in stage order', () {
      final session = buildSession();
      save(GameSession s) => s.saveGameData;
      pickMix(session, ['tend_acorn', 'tend_dry_twigs', 'tend_tree_bark']);
      save(session).playerData.currentEntityViewId = EntityId.FIREPIT;
      final stats = [
        for (final r in session.craftingController.reagentMix())
          FireTendingSystem.reagentDefinition(r.tendReagent!)!.stat,
      ];
      // stamina, strength, defence: the order SkillId lists them
      expect(stats, [SkillId.STAMINA, SkillId.STRENGTH, SkillId.DEFENCE]);
      session.dispose();
    });

    test('a reagent buff stacks to at most the fire\'s end', () {
      final session = buildSession();
      final now = DateTime(2030, 1, 1, 12);
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);

      fire.tend(SkillId.STRENGTH, now, count: 100);
      expect(fire.reagentExpirations[SkillId.STRENGTH], fire.expirationTime);

      // more logs give it room: the next reagent extends past the old end
      final oldEnd = fire.expirationTime;
      session.firemakingSystem.lightOrExtend(
        ItemId.BASIC_CAMPFIRE,
        EntityId.FIREPIT,
        session.saveGameData.playerData.currentZoneId,
        session.saveGameData.playerData.buffData,
        at: now,
      );
      fire.tend(SkillId.STRENGTH, now);
      // a reagent outlasts a lay, so it runs to the new end
      expect(fire.expirationTime.isAfter(oldEnd), isTrue);
      expect(fire.reagentExpirations[SkillId.STRENGTH], fire.expirationTime);
      session.dispose();
    });

    test('a reagent ring reads its time left out of the fire\'s', () {
      final session = buildSession();
      final now = DateTime(2030, 1, 1, 12);
      final zone = session.saveGameData.playerData.currentZoneId;
      final buffs = session.saveGameData.playerData.buffData;
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      void addLogs() => session.firemakingSystem.lightOrExtend(
        ItemId.BASIC_CAMPFIRE,
        EntityId.FIREPIT,
        zone,
        buffs,
        at: now,
      );

      expect(fire.reagentFullness(SkillId.STRENGTH, now), 0);

      // a reagent as long as the fire fills its ring
      fire.tend(SkillId.STRENGTH, now);
      expect(fire.reagentFullness(SkillId.STRENGTH, now), closeTo(1, 1e-4));

      // the fire doubled: the ring halves until more reagents go on
      addLogs();
      expect(fire.reagentFullness(SkillId.STRENGTH, now), closeTo(0.5, 1e-4));
      fire.tend(SkillId.STRENGTH, now);
      expect(fire.reagentFullness(SkillId.STRENGTH, now), closeTo(1, 1e-4));

      // halfway through, both have burnt the same: still full
      final mid = now.add(const Duration(minutes: 1));
      expect(fire.reagentFullness(SkillId.STRENGTH, mid), closeTo(1, 1e-4));

      // and it empties with the fire
      expect(fire.reagentFullness(SkillId.STRENGTH, fire.expirationTime), 0);
      session.dispose();
    });

    test('a reagent running out is a cut an offline settle stops on', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      // enough lays that the fast tier outlasts the reagent
      session.firemakingSystem.lightOrExtend(
        ItemId.BASIC_CAMPFIRE,
        EntityId.FIREPIT,
        session.saveGameData.playerData.currentZoneId,
        session.saveGameData.playerData.buffData,
        count: 15,
        at: now,
      );
      fire.tend(SkillId.STRENGTH, now);
      expect(
        session.buffService.nextExpiration(
          session.saveGameData.playerData.buffData,
          session.saveGameData.playerData.currentZoneId,
          after: now,
        ),
        now.add(fire.definition.reagentBurn),
      );
      session.dispose();
    });

    test('reagent buffs survive a save and load', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      fire.tend(SkillId.ATTACK, now);
      final json = jsonDecode(
        jsonEncode(session.saveGameData.playerData.buffData.toJson()),
      );
      final back = BuffData.fromJson(json as Map<String, dynamic>);
      final restored =
          back.zoneBuffs[session
                  .saveGameData
                  .playerData
                  .currentZoneId]![EntityId.FIREPIT]
              as FireItem;
      expect(
        restored.reagentExpirations[SkillId.ATTACK],
        fire.reagentExpirations[SkillId.ATTACK],
      );
      session.dispose();
    });

    test('a full ring stops the reagent loop until more logs go on', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 10;
      save.inventoryData.itemMap[ItemId.LOGS] = 5;
      save.playerData.currentEntityViewId = EntityId.FIREPIT;
      pickFire(session, 'basic_campfire');
      light(session, ItemId.BASIC_CAMPFIRE);
      final controller = session.craftingController;
      final timing = session.actionTimingController;

      // a 5 minute campfire holds one 5 minute acorn: the tick that throws
      // it fills the ring and stops the loop
      expect(
        controller.startCraftingActionFor('tend_acorn', EntityId.FIREPIT),
        isTrue,
      );
      controller.doCraftingAction(1);
      expect(save.inventoryData.itemMap[ItemId.ACORN], 9);
      expect(controller.reagentFull('tend_acorn'), isTrue);
      expect(timing.isRunning, isFalse);

      // full, it won't start again
      expect(
        controller.startCraftingActionFor('tend_acorn', EntityId.FIREPIT),
        isFalse,
      );
      // a different reagent's ring is its own
      expect(controller.reagentFull('tend_tree_bark'), isFalse);

      // more logs make room for another
      save.craftingState.activeRecipeId = 'basic_campfire';
      craft(session, 'basic_campfire');
      expect(controller.reagentFull('tend_acorn'), isFalse);
      expect(
        controller.startCraftingActionFor('tend_acorn', EntityId.FIREPIT),
        isTrue,
      );
      timing.stop();
      session.dispose();
    });

    test('a batch throws on only what the fire has room for', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 10;
      final fire = light(session, ItemId.BASIC_CAMPFIRE);
      save.craftingState.craftingEntityId = EntityId.FIREPIT;
      save.craftingState.activeRecipeId = 'tend_acorn';

      final result = session.craftingSystem.craftActiveRecipe(
        save.craftingState,
        save.playerData,
        save.inventoryData,
        save.playerData.buffData,
        save.worldData,
        craftCount: 10,
        offline: true,
      );
      expect(result.actionsPerformed, 1);
      expect(save.inventoryData.itemMap[ItemId.ACORN], 9);
      expect(fire.reagentExpirations[SkillId.STRENGTH], fire.expirationTime);
      session.dispose();
    });

    test('a kindling mix keeps its buffs up across an offline gap', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 20;
      save.inventoryData.itemMap[ItemId.TREE_BARK] = 20;
      save.playerData.currentEntityViewId = EntityId.FIREPIT;
      // a long fire already burning, for the kindling to go on
      final now = DateTime.now();
      final start = now.subtract(const Duration(minutes: 10));
      session.firemakingSystem.lightOrExtend(
        ItemId.BASIC_CAMPFIRE,
        EntityId.FIREPIT,
        save.playerData.currentZoneId,
        save.playerData.buffData,
        count: 10,
        at: start,
      );
      pickMix(session, ['tend_acorn', 'tend_tree_bark']);
      expect(
        session.craftingController.startCraftingActionFor(
          reagentMixRecipeId,
          EntityId.FIREPIT,
        ),
        isTrue,
      );

      save.playerData.lastActionTime = start;
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      // both went on, and both buffs are still up
      expect(save.inventoryData.itemMap[ItemId.ACORN] ?? 0, lessThan(20));
      expect(save.inventoryData.itemMap[ItemId.TREE_BARK] ?? 0, lessThan(20));
      expect(totals(session, at: now)[SkillId.STRENGTH], 5);
      expect(totals(session, at: now)[SkillId.DEFENCE], 5);
      session.actionTimingController.stop();
      session.dispose();
    });
  });

  group('woodcutting and bird\'s nests', () {
    test('the first two trees shed every reagent between them', () {
      Set<ItemId> shed(EntityId tree) => {
        for (final roll
            in (tree.definition as EncounterEntityDefinition).bonusDrops)
          ...roll.entries.map((e) => e.id),
      };
      expect({
        ...shed(EntityId.TREE),
        ...shed(EntityId.OAK_TREE),
      }, containsAll(woodReagents));
      expect(shed(EntityId.TREE), contains(ItemId.SMALL_BIRDS_NEST));
      expect(shed(EntityId.WILLOW_TREE), contains(ItemId.WOVEN_BIRDS_NEST));
      expect(shed(EntityId.BOG_TREE), contains(ItemId.WOVEN_BIRDS_NEST));
      expect(shed(EntityId.MAPLE_TREE), contains(ItemId.STURDY_BIRDS_NEST));
      expect(shed(EntityId.YEW_TREE), contains(ItemId.GILDED_BIRDS_NEST));
      expect(shed(EntityId.MAGIC_TREE), contains(ItemId.ENCHANTED_BIRDS_NEST));
    });

    test('reagents come with nearly every log, more of them up the trees', () {
      // the reagent roll on each tree: its chance, and how many a roll pays
      (double, int) reagentRoll(EntityId tree) {
        final roll = (tree.definition as EncounterEntityDefinition).bonusDrops
            .firstWhere(
              (r) => r.entries.any((e) => FireTendingSystem.isReagent(e.id)),
            );
        final counts = roll.entries.map((e) => e.lowCount).toSet();
        expect(counts, hasLength(1), reason: '${tree.name} pays one amount');
        // a fixed amount, not a range: highCount is unset or the same
        for (final e in roll.entries) {
          expect(e.highCount, anyOf(0, e.lowCount), reason: tree.name);
        }
        return (roll.chance, counts.single);
      }

      final ladder = [
        reagentRoll(EntityId.TREE),
        reagentRoll(EntityId.OAK_TREE),
        reagentRoll(EntityId.WILLOW_TREE),
        reagentRoll(EntityId.MAPLE_TREE),
        reagentRoll(EntityId.YEW_TREE),
        reagentRoll(EntityId.MAGIC_TREE),
      ];
      for (final (chance, _) in ladder) {
        expect(chance, greaterThanOrEqualTo(0.9));
      }
      expect(ladder.map((r) => r.$2), [1, 2, 3, 5, 8, 13]);
      expect(reagentRoll(EntityId.BOG_TREE), reagentRoll(EntityId.WILLOW_TREE));
    });

    test(
      'a nest opens into reagents, and is the only way to woodcutter gear',
      () {
        final session = buildSession();
        final save = session.saveGameData;
        save.inventoryData.itemMap[ItemId.SMALL_BIRDS_NEST] = 200;

        final loot = session.inventoryController.openNests(
          ItemId.SMALL_BIRDS_NEST,
        );
        expect(save.inventoryData.itemMap[ItemId.SMALL_BIRDS_NEST] ?? 0, 0);
        final reagentsOut = loot
            .where((l) => FireTendingSystem.isReagent(l.id))
            .fold(0, (sum, l) => sum + l.count);
        expect(reagentsOut, 400, reason: 'two reagents a small nest');
        expect(
          loot.any(
            (l) => basicWoodcuttersGearDropTable.any((g) => g.id == l.id),
          ),
          isTrue,
          reason: '200 nests at 13% should turn up some basic gear',
        );

        // nests are the woodcutter's set's only source
        final shop = EntityId.TRADING_POST.definition as ShopEntityDefinition;
        for (final entry in shop.shopStockPool) {
          final d = entry.itemId.definition;
          if (d is SkillingGearDefinition) {
            expect(d.skill, isNot(SkillId.WOODCUTTING));
          }
        }
        expect(BirdsNestSystem.isNest(ItemId.WOVEN_BIRDS_NEST), isTrue);
        session.dispose();
      },
    );
  });
}
