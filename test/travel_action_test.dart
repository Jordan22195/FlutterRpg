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

  /// A full stamina pool to boost with, and enough exploration to be let
  /// in. Deliberately short of the swamp's gate — one
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
    test('a trip takes as long as its roads take', () {
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

      // and a multi-hop trip is the sum along the quickest road:
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
        ZoneTravelGraph.isReachable(
          ZoneId.SOUTH_HAVEN,
          ZoneId.CHALLENGING_MOUNTAIN,
        ),
        isFalse,
      );
    });
  });

  group('setting off', () {
    test('setting off is free, and you are still standing there', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;
      final player = session.saveGameData.playerData;
      final before = player.stamina;

      expect(world.startTravelTo(ZoneId.SOUTH_HAVEN), isTrue);

      // walking costs nothing: only a boost spends stamina
      expect(player.stamina, before);
      // and not one step of the way yet
      expect(world.currentZoneId, ZoneId.TUTORIAL_FARM);
      expect(world.isTravelling, isTrue);
      expect(world.travelTarget, ZoneId.SOUTH_HAVEN);

      session.dispose();
    });

    test('an empty tank still walks; only gates and roads refuse', () {
      final session = buildSession();
      final world = session.worldController;
      final player = session.saveGameData.playerData;

      player.stamina = 0;
      expect(world.startTravelTo(ZoneId.SOUTH_HAVEN), isTrue);
      expect(player.stamina, 0);
      expect(world.isTravelling, isTrue);
      world.cancelTravel();

      // the swamp is locked behind exploration whatever the pool says
      fund(session);
      expect(world.startTravelTo(ZoneId.SWAMP), isFalse);
      expect(world.startTravelTo(ZoneId.CHALLENGING_MOUNTAIN), isFalse);
      expect(session.saveGameData.playerData.stamina, 200);

      // and you cannot set off for where you are already standing
      expect(world.startTravelTo(ZoneId.TUTORIAL_FARM), isFalse);

      session.dispose();
    });

    test('pressing again mid-trip boosts it rather than setting off again', () {
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

    test('an unboosted walk spends no stamina, a boosted one does', () {
      final session = buildSession();
      fund(session);
      final player = session.saveGameData.playerData;
      final state = session.saveGameData.actionTimingData;

      // half the pool, so recovery has room to show if it were all there was
      player.stamina = 100;
      session.worldController.startTravelTo(ZoneId.SOUTH_HAVEN);
      run(session, seconds: 1.0);
      // walking hands-off: stamina only recovers
      expect(player.stamina, greaterThanOrEqualTo(100));

      final beforeBoost = player.stamina;
      state.buttonHeld = true;
      run(session, seconds: 1.0);
      expect(player.stamina, lessThan(beforeBoost));

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
    test('something else taking the loop lets go of the trip', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;

      world.startTravelTo(ZoneId.SOUTH_HAVEN);

      // the stop button, or any action started from another screen
      session.actionTimingController.stop();

      expect(world.isTravelling, isFalse);
      expect(world.travelTarget, isNull);
      expect(world.currentZoneId, ZoneId.TUTORIAL_FARM);

      session.dispose();
    });

    test('turning around part way heads for the new place', () {
      final session = buildSession();
      fund(session);
      final world = session.worldController;

      world.startTravelTo(ZoneId.SOUTH_HAVEN);
      run(session, seconds: 1);

      // changed their mind
      expect(world.startTravelTo(ZoneId.SOUTHWOOD_FOREST), isTrue);
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
    test('a relaunch mid-walk leaves you put', () {
      final before = buildSession();
      fund(before);
      before.worldController.startTravelTo(ZoneId.SOUTH_HAVEN);
      run(before, seconds: 0.5);

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

      // the walk is given up: you are where you set off from, and nothing
      // is running
      expect(after.worldController.currentZoneId, ZoneId.TUTORIAL_FARM);
      expect(after.actionTimingController.isRunning, isFalse);
      expect(after.worldController.isTravelling, isFalse);

      after.dispose();
    });
  });
}
