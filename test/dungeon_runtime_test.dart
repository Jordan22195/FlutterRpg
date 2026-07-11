import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeon_catalog.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

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

  // crank combat skills so the player reliably kills and survives, making
  // a full clear deterministic enough to loop to completion
  void makePlayerStrong(GameSession session) {
    final skills = session.saveGameData.playerData.skillData;
    for (final id in [
      SkillId.ATTACK,
      SkillId.DEFENCE,
      SkillId.HITPOINTS,
    ]) {
      final s = skills[id]!;
      s.xp = s.xpTable[99];
    }
    session.saveGameData.playerData.hitpoints =
        session.playerDataService.getStatTotals(
          session.saveGameData.playerData,
        )[SkillId.HITPOINTS]!;
  }

  group('pure advancement', () {
    // a synthetic 2-floor, non-repeatable dungeon
    const nonRepeatable = DungeonDefinition(
      id: DungeonId.NULL,
      name: 't',
      iconAsset: '',
      type: DungeonType.LANDMARK,
      floors: [
        DungeonFloor(
          name: 'f0',
          packs: [DungeonPack(EntityId.GOBLIN), DungeonPack(EntityId.GOBLIN)],
        ),
        DungeonFloor(name: 'f1', packs: [DungeonPack(EntityId.GOBLIN_QUEEN)]),
      ],
    );
    const repeatable = DungeonDefinition(
      id: DungeonId.NULL,
      name: 't',
      iconAsset: '',
      type: DungeonType.ZONE,
      repeatable: true,
      floors: [
        DungeonFloor(name: 'f0', packs: [DungeonPack(EntityId.GOBLIN)]),
        DungeonFloor(name: 'f1', packs: [DungeonPack(EntityId.GOBLIN_QUEEN)]),
      ],
    );

    final system = buildSession().dungeonSystem;

    test('advances to the next pack within a floor', () {
      final adv = system.computeAdvance(nonRepeatable, 0, 0);
      expect(adv.floorIndex, 0);
      expect(adv.packIndex, 1);
      expect(adv.clearedFloor, isFalse);
    });

    test('clearing a non-final floor auto-continues to the next floor', () {
      final adv = system.computeAdvance(nonRepeatable, 0, 1);
      expect(adv.floorIndex, 1);
      expect(adv.packIndex, 0);
      expect(adv.clearedFloor, isTrue);
      expect(adv.complete, isFalse);
      expect(adv.awaitChoice, isFalse);
    });

    test('clearing the last floor completes a non-repeatable dungeon', () {
      final adv = system.computeAdvance(nonRepeatable, 1, 0);
      expect(adv.complete, isTrue);
      expect(adv.awaitChoice, isFalse);
    });

    test('clearing any floor of a repeatable dungeon pauses for a choice', () {
      final adv = system.computeAdvance(repeatable, 0, 0);
      expect(adv.awaitChoice, isTrue);
      expect(adv.clearedFloor, isTrue);
      expect(adv.complete, isFalse);
    });
  });

  group('Goblin Queen run (system loop)', () {
    test('needs a key; entry consumes it', () {
      final session = buildSession();
      final save = session.saveGameData;

      // no key yet
      expect(
        session.dungeonSystem.canEnter(
          run: save.dungeonRun,
          dungeonId: DungeonId.GOBLIN_QUEEN_LAIR,
          playerState: save.playerData,
          playerInventory: save.inventoryData,
        ),
        isFalse,
      );

      session.inventoryService.setItemCount(
        save.inventoryData,
        ItemId.GOBLIN_QUEEN_KEY,
        1,
      );

      final entered = session.dungeonSystem.enterDungeon(
        run: save.dungeonRun,
        dungeonId: DungeonId.GOBLIN_QUEEN_LAIR,
        playerState: save.playerData,
        playerInventory: save.inventoryData,
      );
      expect(entered, isTrue);
      expect(save.dungeonRun.active, isTrue);
      // key spent
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.GOBLIN_QUEEN_KEY,
        ),
        0,
      );

      session.dispose();
    });

    test('clearing all floors completes the run with the boss reward', () {
      final session = buildSession();
      final save = session.saveGameData;
      makePlayerStrong(session);

      session.inventoryService.setItemCount(
        save.inventoryData,
        ItemId.GOBLIN_QUEEN_KEY,
        1,
      );
      session.dungeonSystem.enterDungeon(
        run: save.dungeonRun,
        dungeonId: DungeonId.GOBLIN_QUEEN_LAIR,
        playerState: save.playerData,
        playerInventory: save.inventoryData,
      );

      // drive combat ticks until the run resolves
      var ticks = 0;
      while (save.dungeonRun.active && ticks < 20000) {
        session.dungeonSystem.executeDungeonAction(
          run: save.dungeonRun,
          playerState: save.playerData,
          playerInventory: save.inventoryData,
        );
        ticks++;
      }

      expect(save.dungeonRun.active, isFalse, reason: 'run should complete');
      expect(save.dungeonRun.awaitingFloorChoice, isFalse);

      // boss guaranteed one unique + 500 bulk coins landed in inventory
      final crown = session.inventoryService.getItemCount(
        save.inventoryData,
        ItemId.GOBLIN_CROWN,
      );
      final scepter = session.inventoryService.getItemCount(
        save.inventoryData,
        ItemId.GOBLIN_SCEPTER,
      );
      expect(crown + scepter, greaterThanOrEqualTo(1));
      expect(
        session.inventoryService.getItemCount(save.inventoryData, ItemId.COINS),
        greaterThanOrEqualTo(500),
      );

      session.dispose();
    });
  });

  test('an in-progress run survives a save round-trip', () {
    final session = buildSession();
    final save = session.saveGameData;
    makePlayerStrong(session);

    session.inventoryService.setItemCount(
      save.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
    session.dungeonSystem.enterDungeon(
      run: save.dungeonRun,
      dungeonId: DungeonId.GOBLIN_QUEEN_LAIR,
      playerState: save.playerData,
      playerInventory: save.inventoryData,
    );
    // one hit so the live enemy has partial hp to preserve
    session.dungeonSystem.executeDungeonAction(
      run: save.dungeonRun,
      playerState: save.playerData,
      playerInventory: save.inventoryData,
    );

    final restored = SaveGameData.fromJson(save.toJson());
    expect(restored.dungeonRun.active, isTrue);
    expect(restored.dungeonRun.dungeonId, DungeonId.GOBLIN_QUEEN_LAIR);
    expect(restored.dungeonRun.floorIndex, save.dungeonRun.floorIndex);
    expect(restored.dungeonRun.packIndex, save.dungeonRun.packIndex);
    expect(
      restored.dungeonRun.fight.entity?.hitpoints,
      save.dungeonRun.fight.entity?.hitpoints,
    );

    session.dispose();
  });

  group('auto-eat', () {
    test('eats when hp is low and food is equipped, not when healthy', () {
      final session = buildSession();
      final save = session.saveGameData;

      // give the player cooked chicken and equip it as food
      session.inventoryService.setItemCount(
        save.inventoryData,
        ItemId.COOKED_CHICKEN,
        5,
      );
      save.playerData.equipmentData.equipedFood = ItemId.COOKED_CHICKEN;

      final maxHp =
          session.playerDataService.getStatTotals(save.playerData)[SkillId
              .HITPOINTS]!;

      // healthy: no eating
      save.playerData.hitpoints = maxHp;
      expect(
        session.dungeonSystem.autoEat(
          playerState: save.playerData,
          playerInventory: save.inventoryData,
        ),
        isFalse,
      );
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.COOKED_CHICKEN,
        ),
        5,
      );

      // low: eats one and heals
      save.playerData.hitpoints = 1;
      expect(
        session.dungeonSystem.autoEat(
          playerState: save.playerData,
          playerInventory: save.inventoryData,
        ),
        isTrue,
      );
      expect(save.playerData.hitpoints, greaterThan(1));
      expect(
        session.inventoryService.getItemCount(
          save.inventoryData,
          ItemId.COOKED_CHICKEN,
        ),
        4,
      );

      session.dispose();
    });
  });

  test('leaving ends the run', () {
    final session = buildSession();
    final save = session.saveGameData;
    session.inventoryService.setItemCount(
      save.inventoryData,
      ItemId.GOBLIN_QUEEN_KEY,
      1,
    );
    session.dungeonSystem.enterDungeon(
      run: save.dungeonRun,
      dungeonId: DungeonId.GOBLIN_QUEEN_LAIR,
      playerState: save.playerData,
      playerInventory: save.inventoryData,
    );
    expect(save.dungeonRun.active, isTrue);

    session.dungeonSystem.leaveDungeon(save.dungeonRun);
    expect(save.dungeonRun.active, isFalse);
    expect(save.dungeonRun.fight.entity, isNull);

    session.dispose();
  });
}
