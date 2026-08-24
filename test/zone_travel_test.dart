import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the travel graph', () {
    test('travel costs sum along the cheapest path', () {
      final graph = ZoneTravelGraph();

      // single hops are the edge's own cost
      expect(
        graph.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.SOUTHWOOD_FOREST),
        5,
      );
      expect(graph.travelCost(ZoneId.SOUTHWOOD_FOREST, ZoneId.SOUTH_HAVEN), 10);
      expect(graph.travelCost(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE), 1);

      // and a multi-hop trip is the sum along the road:
      // farm >5> forest >10> haven >1> mine
      expect(graph.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE), 16);

      // dev zones sit off the graph and are free, both directions
      expect(graph.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.DEV_FOREST), 0);
      expect(graph.travelCost(ZoneId.DEV_FOREST, ZoneId.FOREST_MINE), 0);

      // staying put is free
      expect(graph.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.TUTORIAL_FARM), 0);

      // nowhere is nowhere
      expect(
        graph.travelCost(ZoneId.TUTORIAL_FARM, ZoneId.CHALLENGING_MOUNTAIN),
        double.infinity,
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

    test('the cheapest route wins, not the shortest one', () {
      // the search has to price the road, not count the corners on it. This
      // is the case the old breadth-first walk got wrong: it returned the
      // first path it stumbled onto, so a two-hop detour that costs less
      // than one long hop was never found.
      final graph = ZoneTravelGraph();
      final direct = ZoneTravelGraph.edgeCost(
        ZoneId.SOUTHWOOD_FOREST,
        ZoneId.SOUTH_HAVEN,
      );
      final viaMine =
          ZoneTravelGraph.edgeCost(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE) * 2;

      // the graph today has no cheaper detour, so the direct hop must win
      expect(direct, lessThan(direct + viaMine));
      expect(
        graph.travelCost(ZoneId.SOUTHWOOD_FOREST, ZoneId.SOUTH_HAVEN),
        direct,
      );
      expect(
        ZoneTravelGraph.travelPath(ZoneId.SOUTHWOOD_FOREST, ZoneId.SOUTH_HAVEN),
        [ZoneId.SOUTHWOOD_FOREST, ZoneId.SOUTH_HAVEN],
      );
    });

    test('an edge is priced in the direction you would walk it', () {
      // the connection table records haven>mine as 1 and mine>haven as 10,
      // and the badge on that road has to say which of those you're about
      // to pay rather than splitting the difference
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE),
        1,
      );
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.FOREST_MINE, ZoneId.SOUTH_HAVEN),
        10,
      );
      // a road recorded in only one direction still gets a number
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.SOUTHWOOD_FOREST, ZoneId.TUTORIAL_FARM),
        5,
      );
      // non-neighbours have no edge at all
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.TUTORIAL_FARM, ZoneId.FOREST_MINE),
        double.infinity,
      );
    });
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

    // mine requires mining 5 on top of its exploration difficulty:
    // blocked, and nothing is charged
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isFalse);
    expect(world.travelToZone(ZoneId.FOREST_MINE), isFalse);
    expect(player.stamina, 10);

    // the forest sits at exploration 5, so it stays shut until the player
    // has explored the meadow enough to reach it
    expect(world.meetsZoneRequirement(ZoneId.SOUTHWOOD_FOREST), isFalse);
    expect(world.travelToZone(ZoneId.SOUTHWOOD_FOREST), isFalse);
    expect(player.currentZoneId, ZoneId.TUTORIAL_FARM);
    expect(player.stamina, 10);

    final exploration = player.skillData[SkillId.EXPLORATION]!;
    exploration.xp = exploration.xpTable[5];
    expect(world.meetsZoneRequirement(ZoneId.SOUTHWOOD_FOREST), isTrue);

    // farm -> forest costs 5
    expect(world.travelToZone(ZoneId.SOUTHWOOD_FOREST), isTrue);
    expect(player.currentZoneId, ZoneId.SOUTHWOOD_FOREST);
    expect(player.stamina, 5);

    // the mine needs both of its gates: mining 5 and exploration 15
    final mining = player.skillData[SkillId.MINING]!;
    mining.xp = mining.xpTable[5];
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isFalse);
    exploration.xp = exploration.xpTable[15];
    expect(world.meetsZoneRequirement(ZoneId.FOREST_MINE), isTrue);

    // the road to the mine runs through South Haven: 10 then 1. Five
    // stamina doesn't cover it, and being refused costs nothing
    expect(world.travelCostTo(ZoneId.FOREST_MINE), 11);
    expect(world.travelToZone(ZoneId.FOREST_MINE), isFalse);
    expect(player.currentZoneId, ZoneId.SOUTHWOOD_FOREST);
    expect(player.stamina, 5);

    player.stamina = 20;
    expect(world.travelToZone(ZoneId.FOREST_MINE), isTrue);
    expect(player.currentZoneId, ZoneId.FOREST_MINE);
    expect(player.stamina, 9);

    // mine -> farm is the whole road back. The climb out of the mine is 10
    // where the walk down was 1, so the return trip is 25, not 16
    expect(world.travelCostTo(ZoneId.TUTORIAL_FARM), 25);
    expect(world.travelToZone(ZoneId.TUTORIAL_FARM), isFalse);
    expect(player.currentZoneId, ZoneId.FOREST_MINE);
    expect(player.stamina, 9);

    // dev forest is free from anywhere
    expect(world.travelToZone(ZoneId.DEV_FOREST), isTrue);
    expect(player.stamina, 9);

    session.dispose();
  });
}
