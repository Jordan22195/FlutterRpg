import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/systems/birds_nest_system.dart';
import 'package:rpg/systems/fire_tending_system.dart';

// Reagent fires. The wood sets a fire's power, the reagent picks the stat,
// a campfire or bonfire gives nothing until tended, and the buffs end with
// the fire. Logs are the grind: tending by hand pays a little xp, and the
// auto-tend and Keep fire fed switches pay none.
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
        ].map((id) => def(id).power),
        [5, 8, 13],
      );
      expect(
        [
          ItemId.BONFIRE,
          ItemId.OAK_BONFIRE,
          ItemId.WILLOW_BONFIRE,
        ].map((id) => def(id).power),
        [8, 13, 21],
      );
    });

    test('a bonfire is a rung stronger but eats reagents faster', () {
      expect(
        def(ItemId.BONFIRE).power,
        greaterThan(def(ItemId.BASIC_CAMPFIRE).power),
      );
      expect(
        def(ItemId.BONFIRE).reagentBurn,
        lessThan(def(ItemId.BASIC_CAMPFIRE).reagentBurn),
      );
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

      fire.tend(SkillId.STRENGTH, now);
      fire.tend(SkillId.STRENGTH, now);
      expect(fire.reagentExpirations[SkillId.STRENGTH], now.add(burn * 2));

      // the reagents outlast the 5-minute fire, but stop counting with it
      final afterFire = fire.expirationTime.add(const Duration(seconds: 1));
      expect(
        fire.reagentExpirations[SkillId.STRENGTH]!.isAfter(afterFire),
        isTrue,
      );
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

    test('every stat can be tended by Firemaking 13', () {
      final stats = {
        for (final id in FireTendingSystem.reagents)
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
      for (final id in FireTendingSystem.reagents) {
        expect(
          FireTendingSystem.reagentDefinition(id)!.levelRequirement,
          lessThanOrEqualTo(13),
        );
      }
    });

    test('a cookfire cannot be tended, and a reagent waits on its level', () {
      final session = buildSession();
      final save = session.saveGameData;
      save.inventoryData.itemMap[ItemId.OAK_SAP] = 5;
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      setFiremaking(session, 10);
      save.playerData.currentEntityViewId = EntityId.FIREPIT;

      light(session, ItemId.COOKFIRE);
      expect(session.fireController.blockFor(ItemId.ACORN), TendBlock.cookfire);

      light(session, ItemId.BASIC_CAMPFIRE);
      expect(session.fireController.blockFor(ItemId.ACORN), TendBlock.none);
      expect(session.fireController.blockFor(ItemId.OAK_SAP), TendBlock.level);
      session.dispose();
    });

    test('throwing one by hand pays its level in xp; auto-tend pays none', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.ACORN] = 5;
      save.inventoryData.itemMap[ItemId.DRY_TWIGS] = 5;
      save.playerData.currentEntityViewId = EntityId.FIREPIT;
      light(session, ItemId.BASIC_CAMPFIRE);
      final skill = save.playerData.skillData[SkillId.FIREMAKING]!;

      final before = skill.xp;
      expect(session.fireController.tend(ItemId.ACORN), isTrue);
      expect(skill.xp - before, FireTendingSystem.tendXp(ItemId.ACORN));
      expect(save.inventoryData.itemMap[ItemId.ACORN], 4);

      save.playerData.autoTendReagents.add(ItemId.DRY_TWIGS);
      final beforeAuto = skill.xp;
      expect(
        session.fireTendingSystem.autoTend(save.playerData, save.inventoryData),
        isTrue,
      );
      expect(save.inventoryData.itemMap[ItemId.DRY_TWIGS], 4);
      expect(skill.xp, beforeAuto);
      session.dispose();
    });

    test('Keep fire fed lays the same logs on before the fire goes out', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.LOGS] = 5;
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
      fire.tend(SkillId.STRENGTH, now, count: 3);
      final out = fire.expirationTime;

      // off: the fire is left to burn out
      session.fireTendingSystem.autoTend(
        save.playerData,
        save.inventoryData,
        at: out,
      );
      expect(save.inventoryData.itemMap[ItemId.LOGS], 5);

      save.playerData.keepFireFed = true;
      session.fireTendingSystem.autoTend(
        save.playerData,
        save.inventoryData,
        at: out,
      );
      expect(save.inventoryData.itemMap[ItemId.LOGS] ?? 0, 0);
      expect(fire.expirationTime, out.add(fire.definition.duration));
      // and its reagent is still burning past where the fire would have died
      expect(
        totals(
          session,
          at: out.add(const Duration(minutes: 1)),
        )[SkillId.STRENGTH],
        fire.power,
      );
      session.dispose();
    });

    test('a reagent running out is a cut an offline settle stops on', () {
      final session = buildSession();
      final now = DateTime.now();
      final fire = light(session, ItemId.BASIC_CAMPFIRE, at: now);
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

    test('auto-tend keeps a reagent up across an offline gap', () {
      final session = buildSession();
      final save = session.saveGameData;
      setFiremaking(session, 20);
      save.inventoryData.itemMap[ItemId.LOGS] = 5000;
      save.inventoryData.itemMap[ItemId.ACORN] = 20;
      save.playerData.autoTendReagents.add(ItemId.ACORN);
      expect(
        session.craftingController.startCraftingActionFor(
          'basic_campfire',
          EntityId.FIREPIT,
        ),
        isTrue,
      );

      final now = DateTime.now();
      save.playerData.lastActionTime = now.subtract(
        const Duration(minutes: 10),
      );
      session.offlineProgressSystem.settle(
        save.playerData,
        save.actionTimingData,
        now: now,
      );

      // ten minutes at one acorn per campfire burn
      final burn = def(ItemId.BASIC_CAMPFIRE).reagentBurn;
      final owed = (const Duration(minutes: 10).inSeconds / burn.inSeconds)
          .ceil();
      final spent = 20 - (save.inventoryData.itemMap[ItemId.ACORN] ?? 0);
      expect(spent, inInclusiveRange(owed, owed + 1));
      expect(
        totals(session, at: now)[SkillId.STRENGTH],
        def(ItemId.BASIC_CAMPFIRE).power,
      );
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
      }, containsAll(FireTendingSystem.reagents));
      expect(shed(EntityId.TREE), contains(ItemId.SMALL_BIRDS_NEST));
      expect(shed(EntityId.WILLOW_TREE), contains(ItemId.WOVEN_BIRDS_NEST));
      expect(shed(EntityId.BOG_TREE), contains(ItemId.WOVEN_BIRDS_NEST));
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
      ];
      for (final (chance, _) in ladder) {
        expect(chance, greaterThanOrEqualTo(0.9));
      }
      expect(ladder.map((r) => r.$2), [1, 2, 3]);
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
