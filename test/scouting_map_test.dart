import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/data/blacksmithing_recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

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

  int discovered(GameSession session, ZoneId zone) => session
      .saveGameData
      .worldData
      .zones[zone]!
      .discoveredEntities
      .whereType<EncounterEntity>()
      .fold<int>(0, (sum, e) => sum + e.count);

  test('a mining node unlocks at the level its ore is smelted at', () {
    int smeltLevel(ItemId ore) => blacksmithingRecipes
        .where((r) => r.inputs.containsKey(ore) && r.name.contains('Bar'))
        .map((r) => r.levelRequirement)
        .reduce((a, b) => a < b ? a : b);

    const veins = {
      EntityId.COPPER: ItemId.COPPER_ORE,
      EntityId.IRON: ItemId.IRON_ORE,
      EntityId.COAL_VEIN: ItemId.COAL,
      EntityId.GOLD_VEIN: ItemId.GOLD_ORE,
      EntityId.MITHRIL_VEIN: ItemId.MITHRIL_ORE,
    };
    for (final zone in ZoneId.values) {
      if (zone.name.startsWith('DEV')) continue;
      for (final entry in zone.definition.discoverableEntities) {
        final ore = veins[entry.id];
        if (ore == null) continue;
        expect(
          entry.unlockLevel,
          smeltLevel(ore),
          reason: '${entry.id.name} in ${zone.name}',
        );
      }
    }
  });

  test('equipment names carry no rarity, and a weapon has a dps', () {
    final dagger = ItemId.COPPER_DAGGER.build() as WeaponItem;
    dagger.quality = Rarity.RARE;
    expect(dagger.displayName, 'Copper Dagger');
    expect(
      dagger.damagePerSecond,
      closeTo(
        dagger.damage / (dagger.actionInterval.inMicroseconds / 1e6),
        1e-9,
      ),
    );
    expect(dagger.damagePerSecond, greaterThan(0));
  });

  test('scouting a zone discovers 500 finds in it, at the player level', () {
    final session = buildSession();
    final result = session.explorationSystem.scoutZone(
      zoneId: ZoneId.TUTORIAL_FARM,
      playerState: session.saveGameData.playerData,
      worldState: session.saveGameData.worldData,
    );
    expect(result, isNotNull);
    expect(result!.entities, isNotEmpty);
    expect(
      discovered(session, ZoneId.TUTORIAL_FARM),
      greaterThanOrEqualTo(500),
    );
    // only what level 1 has unlocked there
    final unlocked = ZoneId.TUTORIAL_FARM.definition.discoverableEntities
        .where((e) => e.unlockLevel <= 1)
        .map((e) => e.id)
        .toSet();
    expect(
      result.entities.map((e) => e.id).toSet(),
      unlocked.intersection(result.entities.map((e) => e.id).toSet()),
    );
    session.dispose();
  });

  const maps = {
    ItemId.SCOUTING_MAP_SOUTHWOOD_FOREST: ZoneId.SOUTHWOOD_FOREST,
    ItemId.SCOUTING_MAP_DARKWOOD_FOREST: ZoneId.DARKWOOD_FOREST,
    ItemId.SCOUTING_MAP_FOREST_MINE: ZoneId.FOREST_MINE,
  };

  test('each map is matched to its zone', () {
    for (final entry in maps.entries) {
      expect(ScoutingMaps.zoneFor(entry.key), entry.value);
    }
  });

  test('using a map spends it and discovers entities in its zone', () {
    final session = buildSession();
    final player = session.saveGameData.playerData;
    final skill = player.skillData[SkillId.EXPLORATION]!;
    skill.xp = skill.xpTable[60];
    final inventory = session.inventoryController;
    inventory.devSetItemCount(ItemId.SCOUTING_MAP_FOREST_MINE, 2);

    final result = inventory.useItem(ItemId.SCOUTING_MAP_FOREST_MINE);
    expect(result, isNotNull);
    expect(result!.zone, ZoneId.FOREST_MINE);
    expect(inventory.getItemCount(ItemId.SCOUTING_MAP_FOREST_MINE), 1);
    expect(discovered(session, ZoneId.FOREST_MINE), greaterThanOrEqualTo(500));
    session.dispose();
  });

  test('the trading post always shelves every map', () {
    final def = EntityId.TRADING_POST.definition as ShopEntityDefinition;
    for (final id in maps.keys) {
      final entry = def.shopStockPool.singleWhere((e) => e.itemId == id);
      expect(entry.alwaysStocked, isTrue, reason: id.name);
    }
  });

  testWidgets('the info dialog of a held map offers Use, then shows the haul', (
    tester,
  ) async {
    final session = buildSession();
    final skill =
        session.saveGameData.playerData.skillData[SkillId.EXPLORATION]!;
    skill.xp = skill.xpTable[60];
    session.inventoryController.devSetItemCount(
      ItemId.SCOUTING_MAP_FOREST_MINE,
      1,
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<InventoryController>.value(
        value: session.inventoryController,
        child: ChangeNotifierProvider.value(
          value: session.buffController,
          child: MaterialApp(
            home: Scaffold(
              body: ItemStackTile<ItemId>(
                size: 48,
                id: ItemId.SCOUTING_MAP_FOREST_MINE,
                count: 1,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ItemStackTile<ItemId>));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('item-use-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('item-use-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('scouting-total')), findsOneWidget);
    session.dispose();
  });

  test('skilling gear tiers are rarities that leave the stats alone', () {
    const expected = {
      SkillingGearTier.BASIC: Rarity.COMMON,
      SkillingGearTier.NOVICE: Rarity.UNCOMMON,
      SkillingGearTier.APPRENTICE: Rarity.RARE,
      SkillingGearTier.ADVANCED: Rarity.EPIC,
      SkillingGearTier.MASTER: Rarity.LEGENDARY,
    };
    var seen = 0;
    for (final id in ItemId.values) {
      final def = id.definition;
      if (def is! SkillingGearDefinition) continue;
      seen++;
      final piece = id.build() as EquipmentItem;
      expect(piece.quality, expected[def.tier], reason: id.name);
      // even rolled at a different rarity, the piece keeps its tier's
      piece.quality = Rarity.COMMON;
      expect(piece.quality, expected[def.tier], reason: id.name);
      expect(
        def.statsAt(Rarity.LEGENDARY),
        def.statsAt(Rarity.COMMON),
        reason: id.name,
      );
    }
    expect(seen, greaterThan(0));
  });
}
