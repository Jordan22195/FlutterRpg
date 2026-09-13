import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/bound_action.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

// Travelling runs on the same loop every other action runs on: a road has an
// interval, it can be held to boost, and what the player was looking at when
// they set off is what starts when they arrive.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  GameSession buildSession([SaveGameData? from]) {
    final factory = GameSessionFactory();
    final catalogs = factory.catalog1();
    final save = from ?? factory.newGame(catalogs);
    return factory.create(
      save: save,
      catalogs: catalogs,
      vsync: const TestVSync(),
    );
  }

  void setLevel(PlayerData player, SkillId skill, int level) {
    final data = player.skillData[skill]!;
    data.xp = data.xpTable[level];
  }

  /// Enough stamina to walk anywhere on the near roads, and enough
  /// exploration to be let in. Deliberately short of the swamp's gate — one
  /// of these tests needs a zone that stays shut.
  void fund(GameSession session) {
    final player = session.saveGameData.playerData;
    setLevel(player, SkillId.STAMINA, 20);
    setLevel(player, SkillId.EXPLORATION, 10);
    player.stamina = 200;
  }

  /// Simulates [seconds] of 60fps frames straight into the timing system,
  /// the way action_speed_test does — the ticker never runs headless.
  void run(GameSession session, {required double seconds}) {
    final state = session.saveGameData.actionTimingData;
    final player = session.saveGameData.playerData;
    var elapsed = state.lastElapsed;
    final frames = (seconds * 60).round();
    for (var i = 0; i <= frames; i++) {
      elapsed += const Duration(microseconds: 16667);
      session.actionTimingSystem.frameUpdate(elapsed, state, player);
    }
  }

  group('the roads have their own clock', () {
    test('a trip takes as long as its roads take, whatever they cost', () {
      final graph = ZoneTravelGraph();

      // single hops are the edge's own time
      expect(
        graph.travelTime(ZoneId.TUTORIAL_FARM, ZoneId.SOUTHWOOD_FOREST),
        const Duration(milliseconds: 2500),
      );
      expect(
        graph.travelTime(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE),
        const Duration(milliseconds: 500),
      );

      // and a multi-hop trip is the sum along the road the cost picks:
      // farm >2.5s> forest >5s> haven >10s> swamp >12.5s> foothills
      expect(
        graph.travelTime(ZoneId.TUTORIAL_FARM, ZoneId.FOOTHILLS),
        const Duration(seconds: 30),
      );

      // you are already there, and the dev zones are a step out of the world
      expect(
        graph.travelTime(ZoneId.SOUTH_HAVEN, ZoneId.SOUTH_HAVEN),
        Duration.zero,
      );
      expect(
        graph.travelTime(ZoneId.SOUTH_HAVEN, ZoneId.DEV_FOREST),
        Duration.zero,
      );

      // nowhere to walk is not a walk of no length
      expect(
        graph.travelTime(ZoneId.SOUTH_HAVEN, ZoneId.CHALLENGING_MOUNTAIN),
        Duration.zero,
      );
      expect(
        graph.travelCost(ZoneId.SOUTH_HAVEN, ZoneId.CHALLENGING_MOUNTAIN),
        double.infinity,
      );
    });

    test('what a road costs and how long it takes are two numbers', () {
      // Seeded proportionally, so today the two still track each other — the
      // point of this test is that they are separate facts on the edge and
      // can be moved apart. Retuning one of these expectations should leave
      // the other one passing untouched.
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE),
        1,
      );
      expect(
        ZoneTravelGraph.edgeTravelTime(ZoneId.SOUTH_HAVEN, ZoneId.FOREST_MINE),
        const Duration(milliseconds: 500),
      );

      // and both are read in the direction you are walking: the climb back
      // up out of the mine is its own road
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.FOREST_MINE, ZoneId.SOUTH_HAVEN),
        10,
      );
      expect(
        ZoneTravelGraph.edgeTravelTime(ZoneId.FOREST_MINE, ZoneId.SOUTH_HAVEN),
        const Duration(seconds: 5),
      );

      // no road at all: priced as unreachable, not as instant
      expect(
        ZoneTravelGraph.edgeCost(ZoneId.TUTORIAL_FARM, ZoneId.SWAMP),
        double.infinity,
      );
      expect(
        ZoneTravelGraph.edgeTravelTime(ZoneId.TUTORIAL_FARM, ZoneId.SWAMP),
        Duration.zero,
      );
    });
  });

  group('setting off', () {
    test('the fare is paid at the door, and you are still standing there', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;
      final player = session.saveGameData.playerData;
      final before = player.stamina;

      expect(world.startTravelTo(ZoneId.SOUTH_HAVEN), isTrue);

      // charged in full up front — the whole 15 for farm -> forest -> haven
      expect(player.stamina, before - 15);
      // and not one step of the way yet
      expect(world.currentZoneId, ZoneId.TUTORIAL_FARM);
      expect(world.isTravelling, isTrue);
      expect(world.travelTarget, ZoneId.SOUTH_HAVEN);

      session.dispose();
    });

    test('a road you cannot walk charges nothing', () {
      final session = buildSession();
      final world = session.worldController;
      final player = session.saveGameData.playerData;

      // a new save has 10 stamina, and South Haven is a 15 trip
      final before = player.stamina;
      expect(world.startTravelTo(ZoneId.SOUTH_HAVEN), isFalse);
      expect(player.stamina, before);
      expect(world.isTravelling, isFalse);

      // the swamp is locked behind exploration whatever the pool says
      fund(session);
      expect(world.startTravelTo(ZoneId.SWAMP), isFalse);
      expect(world.startTravelTo(ZoneId.CHALLENGING_MOUNTAIN), isFalse);
      expect(session.saveGameData.playerData.stamina, 200);

      // and you cannot set off for where you are already standing
      expect(world.startTravelTo(ZoneId.TUTORIAL_FARM), isFalse);

      session.dispose();
    });

    test('pressing again mid-trip boosts it rather than paying twice', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;

      world.startTravelTo(ZoneId.SOUTHWOOD_FOREST);
      final after = session.saveGameData.playerData.stamina;

      expect(world.startTravelTo(ZoneId.SOUTHWOOD_FOREST), isTrue);
      expect(session.saveGameData.playerData.stamina, after);
      expect(world.travelTarget, ZoneId.SOUTHWOOD_FOREST);

      session.dispose();
    });
  });

  group('walking it', () {
    test('the road sets the interval, and the speed stat cuts it', () {
      final session = buildSession();
      fund(session);
      final timing = session.actionTimingController;

      session.worldController.startTravelTo(ZoneId.SOUTHWOOD_FOREST);
      // one frame, so the loop has refreshed the interval from the binding
      run(session, seconds: 0.02);

      // 2.5s of road, cut by the speed stat's idle bonus. no item paces it:
      // this is the graph's number, not a weapon's.
      final idle = session.actionTimingSystem.intervalFor(
        null,
        session.saveGameData.playerData,
        intervalOverride: const Duration(milliseconds: 2500),
      );
      // the loop quotes whole milliseconds, so the comparison is made there
      expect(
        timing.getCurrentActionDuration().inMilliseconds,
        idle.inMilliseconds,
      );
      expect(idle, lessThan(const Duration(milliseconds: 2500)));

      session.dispose();
    });

    test('travel boosts on speed even out of a strength stance', () {
      final session = buildSession();
      fund(session);
      final player = session.saveGameData.playerData;
      final state = session.saveGameData.actionTimingData;
      player.stance = Stance.strong;

      session.worldController.startTravelTo(ZoneId.SOUTHWOOD_FOREST);
      // the road offers no stance, so setting off resets it
      expect(player.stance, Stance.fast);

      state.buttonHeld = true;
      run(session, seconds: 0.5);
      expect(state.boostingSpeed, isTrue);
      expect(state.percentOfMaxBoost, greaterThan(0));

      session.dispose();
    });

    test('a held boost gets you there sooner', () {
      final session = buildSession();
      fund(session);
      final state = session.saveGameData.actionTimingData;

      session.worldController.startTravelTo(ZoneId.SOUTH_HAVEN);
      run(session, seconds: 0.02);
      final unboosted = session.actionTimingController
          .getCurrentActionDuration();

      state.buttonHeld = true;
      run(session, seconds: 1.0);
      final boosted = session.actionTimingController.getCurrentActionDuration();

      expect(boosted, lessThan(unboosted));

      session.dispose();
    });
  });

  group('giving up on a trip', () {
    test('something else taking the loop hands the fare back', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;
      final player = session.saveGameData.playerData;

      world.startTravelTo(ZoneId.SOUTH_HAVEN);
      expect(player.stamina, 185);

      // the stop button, or any action started from another screen
      session.actionTimingController.stop();

      expect(player.stamina, 200);
      expect(world.isTravelling, isFalse);
      expect(world.travelTarget, isNull);
      expect(world.currentZoneId, ZoneId.TUTORIAL_FARM);

      session.dispose();
    });

    test('turning around part way is not charged twice', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;
      final player = session.saveGameData.playerData;

      world.startTravelTo(ZoneId.SOUTH_HAVEN);
      run(session, seconds: 1);
      expect(player.stamina, closeTo(185, 1));

      // changed their mind: the haven fare goes back, the forest one is paid
      expect(world.startTravelTo(ZoneId.SOUTHWOOD_FOREST), isTrue);
      expect(player.stamina, closeTo(195, 1));
      expect(world.travelTarget, ZoneId.SOUTHWOOD_FOREST);

      run(session, seconds: 4);
      expect(world.currentZoneId, ZoneId.SOUTHWOOD_FOREST);

      session.dispose();
    });
  });

  group('arriving', () {
    test('the walk ends once, and it ends where it was going', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;

      world.startTravelTo(ZoneId.SOUTHWOOD_FOREST);
      // well past the 2.5s road, so a second arrival would have fired by now
      run(session, seconds: 8);

      expect(world.currentZoneId, ZoneId.SOUTHWOOD_FOREST);
      expect(world.viewedZoneId, ZoneId.SOUTHWOOD_FOREST);
      expect(world.isTravelling, isFalse);
      expect(world.travelTarget, isNull);
      // nothing was waiting at the other end, so the loop is idle
      expect(session.actionTimingController.isRunning, isFalse);

      session.dispose();
    });

    test('nothing starts on arrival, even with the button held', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;
      final state = session.saveGameData.actionTimingData;

      world.startTravelTo(ZoneId.SOUTHWOOD_FOREST);

      // held the whole way, the way a finger on the travel button is, and
      // never lifted
      state.buttonHeld = true;
      run(session, seconds: 4);

      expect(world.currentZoneId, ZoneId.SOUTHWOOD_FOREST);
      // you are there, and that is all that happened. getting somewhere and
      // deciding what to do there are two decisions
      expect(session.actionTimingController.isRunning, isFalse);
      expect(
        session.actionTimingController.isRunningAction(world.doExplore),
        isFalse,
      );
      // and the boost the road built went with it, so the next press starts
      // from a standing start like any other
      expect(state.percentOfMaxBoost, 0.0);
      expect(state.buttonHeld, isFalse);
      expect(state.boostLocked, isFalse);

      session.dispose();
    });

    test('a locked boost does not carry an action out of the walk', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;
      final state = session.saveGameData.actionTimingData;

      world.startTravelTo(ZoneId.SOUTHWOOD_FOREST);
      // the latch is the one thing that outlives a finger coming off, so it
      // is the one worth checking does not outlive the road
      state.buttonHeld = true;
      state.boostLocked = true;
      run(session, seconds: 4);

      expect(world.currentZoneId, ZoneId.SOUTHWOOD_FOREST);
      expect(session.actionTimingController.isRunning, isFalse);
      expect(state.boostLocked, isFalse);

      session.dispose();
    });

    test('arriving hands the screens over to the new zone', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;

      world.startTravelTo(ZoneId.SOUTHWOOD_FOREST);
      run(session, seconds: 4);

      // and an explore started here now is this zone's, not the one the
      // player set off from
      world.startExplore();
      expect(
        session.saveGameData.actionTimingData.boundAction?.zoneId,
        ZoneId.SOUTHWOOD_FOREST,
      );

      session.dispose();
    });
  });

  group('a trip the player was not there for', () {
    test('a relaunch mid-walk refunds the fare and leaves you put', () {
      final before = buildSession();
      fund(before);
      before.worldController.startTravelTo(ZoneId.SOUTH_HAVEN);
      run(before, seconds: 0.5);

      // 200 less the 15 fare, plus whatever the half second recovered
      expect(before.saveGameData.playerData.stamina, closeTo(185, 1));
      expect(
        before.saveGameData.actionTimingData.boundAction?.kind,
        BoundActionKind.TRAVEL,
      );

      final raw = jsonDecode(jsonEncode(before.saveGameData.toJson()));
      before.dispose();

      final after = buildSession(
        SaveGameData.fromJson(Map<String, dynamic>.from(raw)),
      );
      after.resumeBoundAction();

      // the walk is given up: you are where you set off from, with the fare
      // back, and nothing running
      expect(after.worldController.currentZoneId, ZoneId.TUTORIAL_FARM);
      expect(after.saveGameData.playerData.stamina, 200);
      expect(after.actionTimingController.isRunning, isFalse);
      expect(after.worldController.isTravelling, isFalse);

      after.dispose();
    });
  });
}
