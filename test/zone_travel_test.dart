import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zone_catalog.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('travel costs sum along the zone path', () {
    final catalog = ZoneCatalog();

    expect(catalog.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.STARTING_FOREST), 5);
    expect(catalog.travelCost(ZoneId.STARTING_FOREST, ZoneId.FOREST_MINE), 1);
    // farm > forest > mine
    expect(catalog.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE), 6);
    // dev forest is always free, both directions
    expect(catalog.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.DEV_FOREST), 0);
    expect(catalog.travelCost(ZoneId.DEV_FOREST, ZoneId.FOREST_MINE), 0);
    // staying put is free
    expect(catalog.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.TUTORIAL_FARM), 0);
  });

  test('traveling drains stamina and enforces level requirements', () {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = factory.newGame(catalogs);
    final session = factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
    final world = session.worldController;
    final player = save.playerData;

    expect(player.currentZoneId, ZoneId.TUTORIAL_FARM);
    expect(player.stamina, 10);

    // mine requires mining 5: blocked, and nothing is charged
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isFalse);
    expect(world.travelToZone(ZoneId.FOREST_MINE), isFalse);
    expect(player.stamina, 10);

    // farm -> forest costs 5
    expect(world.travelToZone(ZoneId.STARTING_FOREST), isTrue);
    expect(player.currentZoneId, ZoneId.STARTING_FOREST);
    expect(player.stamina, 5);

    // with mining 5, forest -> mine costs 1
    final mining = player.skillData[SkillId.MINING]!;
    mining.xp = mining.xpTable[5];
    expect(world.travelToZone(ZoneId.FOREST_MINE), isTrue);
    expect(player.stamina, 4);

    // mine -> farm costs 6; only 4 stamina left, so travel is refused
    expect(world.travelToZone(ZoneId.TUTORIAL_FARM), isFalse);
    expect(player.currentZoneId, ZoneId.FOREST_MINE);
    expect(player.stamina, 4);

    // dev forest is free from anywhere
    expect(world.travelToZone(ZoneId.DEV_FOREST), isTrue);
    expect(player.stamina, 4);

    session.dispose();
  });
}
