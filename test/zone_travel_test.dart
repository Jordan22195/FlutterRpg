import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the travel graph', () {
    test('travel times sum along the quickest path', () {
      final graph = ZoneTravelGraph();

      // single hops are the road's own time
      expect(
        graph.travelTime(ZoneId.TUTORIAL_FARM, ZoneId.SOUTHWOOD_FOREST),
        const Duration(milliseconds: 2500),
      );
      expect(
        graph.travelTime(ZoneId.SOUTHWOOD_FOREST, ZoneId.SOUTH_HAVEN),
        const Duration(seconds: 5),
      );
      expect(
        graph.travelTime(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE),
        const Duration(milliseconds: 500),
      );

      // and a multi-hop trip is the sum along the road:
      // farm >2.5s> forest >5s> haven >0.5s> mine
      expect(
        graph.travelTime(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE),
        const Duration(seconds: 8),
      );

      // dev zones sit off the graph and are instant, both directions
      expect(
        graph.travelTime(ZoneId.TUTORIAL_FARM, ZoneId.DEV_FOREST),
        Duration.zero,
      );
      expect(
        graph.travelTime(ZoneId.DEV_FOREST, ZoneId.FOREST_MINE),
        Duration.zero,
      );

      // nowhere is nowhere
      expect(
        ZoneTravelGraph.isReachable(
          ZoneId.TUTORIAL_FARM,
          ZoneId.CHALLENGING_MOUNTAIN,
        ),
        isFalse,
      );
      expect(
        ZoneTravelGraph.isReachable(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE),
        isTrue,
      );
    });

    test('the path is the route actually walked, not just its length', () {
      expect(
        ZoneTravelGraph.travelPath(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE),
        [
          ZoneId.TUTORIAL_FARM,
          ZoneId.SOUTHWOOD_FOREST,
          ZoneId.SOUTH_HAVEN,
          ZoneId.FOREST_MINE,
        ],
      );
      expect(
        ZoneTravelGraph.travelHops(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE),
        3,
      );
      expect(
        ZoneTravelGraph.travelHops(
          ZoneId.TUTORIAL_FARM,
          ZoneId.SOUTHWOOD_FOREST,
        ),
        1,
      );
      // you are already there
      expect(
        ZoneTravelGraph.travelHops(ZoneId.TUTORIAL_FARM, ZoneId.TUTORIAL_FARM),
        0,
      );
      // unreachable reports as such rather than as zero hops
      expect(
        ZoneTravelGraph.travelHops(
          ZoneId.TUTORIAL_FARM,
          ZoneId.CHALLENGING_MOUNTAIN,
        ),
        -1,
      );
    });

    test('an edge is timed in the direction you would walk it', () {
      // the connection table records haven>mine as half a second and
      // mine>haven as five, and the badge on that road has to say which of
      // those you're about to walk rather than splitting the difference
      expect(
        ZoneTravelGraph.edgeTravelTime(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE),
        const Duration(milliseconds: 500),
      );
      expect(
        ZoneTravelGraph.edgeTravelTime(ZoneId.FOREST_MINE, ZoneId.SOUTH_HAVEN),
        const Duration(seconds: 5),
      );
      // non-neighbours have no edge at all
      expect(
        ZoneTravelGraph.edgeTravelTime(
          ZoneId.TUTORIAL_FARM,
          ZoneId.FOREST_MINE,
        ),
        Duration.zero,
      );
    });
  });

  test('traveling is free and enforces level requirements', () {
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

    // mine requires mining 5 on top of its exploration difficulty
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isFalse);
    expect(world.travelToZone(ZoneId.FOREST_MINE), isFalse);

    // the forest sits at exploration 5, so it stays shut until the player
    // has explored the meadow enough to reach it
    expect(world.meetsZoneRequirement(ZoneId.SOUTHWOOD_FOREST), isFalse);
    expect(world.travelToZone(ZoneId.SOUTHWOOD_FOREST), isFalse);
    expect(player.currentZoneId, ZoneId.TUTORIAL_FARM);

    final exploration = player.skillData[SkillId.EXPLORATION]!;
    exploration.xp = exploration.xpTable[5];
    expect(world.meetsZoneRequirement(ZoneId.SOUTHWOOD_FOREST), isTrue);

    // an empty tank stands in nobody's way: walking costs nothing
    player.stamina = 0;
    expect(world.travelToZone(ZoneId.SOUTHWOOD_FOREST), isTrue);
    expect(player.currentZoneId, ZoneId.SOUTHWOOD_FOREST);
    expect(player.stamina, 0);

    // the mine needs both of its gates: mining 5 and exploration 15
    final mining = player.skillData[SkillId.MINING]!;
    mining.xp = mining.xpTable[5];
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isFalse);
    exploration.xp = exploration.xpTable[15];
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isTrue);

    player.stamina = 20;
    expect(world.travelToZone(ZoneId.FOREST_MINE), isTrue);
    expect(player.currentZoneId, ZoneId.FOREST_MINE);
    expect(player.stamina, 20);

    // dev forest is reachable from anywhere
    expect(world.travelToZone(ZoneId.DEV_FOREST), isTrue);
    expect(player.stamina, 20);

    session.dispose();
  });
}
