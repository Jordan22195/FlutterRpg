import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/data/buff_data.dart';
import 'package:rpg/data/offline_progress_data.dart';
import 'package:rpg/data/skill_category.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';
import 'gathering_tools.dart';

/// Runs the same stretch of play twice - once through the live frame loop,
/// once as an offline settle - so the two can be held up against each other.
///
/// The live side is the real [ActionTimingSystem.frameUpdate], fed synthetic
/// frames inside [fakeAsync] so everything that rides on a timer moves with
/// the simulated clock: the action's completion microtask, the respawn delay,
/// the once-a-second buff sweep and auto-drink, and the idle heartbeat. What
/// cannot be faked is [DateTime.now], which buffs are stamped against - so
/// instead of moving the clock forward, every frame moves the buffs back by
/// the same amount. Relative to now, that is the same thing.
///
/// The one live mechanism the harness has to stand in for is the enemy's
/// swing: [EncounterController.onActionTimingFrame] times it off the wall
/// clock, so the harness swings for it on the simulated one, by the same
/// rules (swing, die at zero, otherwise auto-eat).

/// What a stretch of play came to, measured the same way for both sides.
class PlayOutcome {
  /// Actions the bound action actually performed.
  final int actions;

  /// Xp banked per skill over the stretch, all sources.
  final Map<SkillId, double> xp;

  /// The share of [xp] the live frame loop pays by the second rather than by
  /// the action - the boost skill and stamina while boosted, recovery while
  /// it has something to restore, and the idle heartbeat's recovery once the
  /// loop has stopped. An offline settle pays the same off the stamina bar
  /// segment by segment; [actionXp] is what is left of [xp] without it.
  final Map<SkillId, double> frameXp;

  /// Net change in the bag, per item.
  final Map<ItemId, int> items;

  final double stamina;
  final double maxStamina;
  final int hitpoints;
  final bool running;
  final bool died;

  /// How far into the stretch the player died, when they did.
  final Duration? diedAfter;

  /// Seconds left on every global buff when the stretch ended.
  final Map<ItemId, double> globalBuffsLeft;

  /// Seconds left on every zone buff (fire) when the stretch ended.
  final Map<EntityId, double> zoneBuffsLeft;

  /// How long the offline settle says it covered; null for a live run.
  final Duration? reportedTimeAway;

  /// Where the player's clock stands against the instant the stretch ended:
  /// zero means the settle consumed the gap exactly.
  final Duration? clockDrift;

  /// The settle's report, whether or not it was big enough to show.
  final OfflineProgressReport? report;

  PlayOutcome({
    required this.actions,
    required this.xp,
    required this.frameXp,
    this.frameXpPaid = true,
    required this.items,
    required this.stamina,
    required this.maxStamina,
    required this.hitpoints,
    required this.running,
    required this.died,
    this.diedAfter,
    required this.globalBuffsLeft,
    required this.zoneBuffsLeft,
    this.reportedTimeAway,
    this.clockDrift,
    this.report,
  });

  /// [xp] less what the frame loop paid by the second. Rounding in the
  /// harness's mirror of the frame loop can leave a hair of a frame-xp skill
  /// behind; anything under half a point is that and not an action's xp.
  Map<SkillId, double> get actionXp => {
    for (final e in xp.entries)
      e.key: e.value - (frameXpPaid ? (frameXp[e.key] ?? 0) : 0),
  }..removeWhere((_, v) => v.abs() < 0.5);

  /// Whether [frameXp] is still in [xp], or was taken back as it landed.
  final bool frameXpPaid;

  @override
  String toString() =>
      'actions=$actions stamina=${stamina.toStringAsFixed(2)}/'
      '${maxStamina.toStringAsFixed(0)} hp=$hitpoints running=$running '
      'died=$died\n  actionXp=${_fmt(actionXp)}\n  frameXp=${_fmt(frameXp)}'
      '\n  items=$items\n  diedAfter=$diedAfter buffs=$globalBuffsLeft '
      'fires=$zoneBuffsLeft';

  static String _fmt(Map<SkillId, double> m) =>
      '{${m.entries.map((e) => '${e.key.name}: ${e.value.toStringAsFixed(1)}').join(', ')}}';
}

GameSession buildPlaySession() {
  final factory = GameSessionFactory();
  final catalogs = factory.catalog1();
  return factory.create(
    save: withGatheringTools(factory.newGame(catalogs)),
    catalogs: catalogs,
    vsync: const TestVSync(),
  );
}

class _Before {
  final Map<SkillId, double> xp;
  final Map<ItemId, int> items;
  _Before(GameSession s)
    : xp = {
        for (final e in s.saveGameData.playerData.skillData.entries)
          e.key: e.value.xp,
      },
      items = Map.of(s.saveGameData.inventoryData.itemMap);
}

Map<SkillId, double> _xpDelta(GameSession s, _Before before) {
  final out = <SkillId, double>{};
  for (final e in s.saveGameData.playerData.skillData.entries) {
    final d = e.value.xp - (before.xp[e.key] ?? 0);
    if (d.abs() > 1e-9) out[e.key] = d;
  }
  return out;
}

Map<ItemId, int> _itemDelta(GameSession s, _Before before) {
  final now = s.saveGameData.inventoryData.itemMap;
  final out = <ItemId, int>{};
  for (final id in {...now.keys, ...before.items.keys}) {
    final d = (now[id] ?? 0) - (before.items[id] ?? 0);
    if (d != 0) out[id] = d;
  }
  return out;
}

/// Moves every buff's clock back by [by] - the same, relative to now, as the
/// clock moving forward by it.
void ageBuffs(BuffData buffs, Duration by) {
  for (final buff in buffs.globalBuffs.values) {
    buff.expirationTime = buff.expirationTime.subtract(by);
  }
  for (final zone in buffs.zoneBuffs.values) {
    for (final buff in zone.values) {
      buff.expirationTime = buff.expirationTime.subtract(by);
    }
  }
}

Map<ItemId, double> _globalLeft(BuffData buffs, DateTime at) => {
  for (final e in buffs.globalBuffs.entries)
    if (e.value.expirationTime.isAfter(at))
      e.key: e.value.expirationTime.difference(at).inMicroseconds / 1e6,
};

Map<EntityId, double> _zoneLeft(BuffData buffs, DateTime at) => {
  for (final zone in buffs.zoneBuffs.values)
    for (final e in zone.entries)
      if (e.value.expirationTime.isAfter(at))
        e.key: e.value.expirationTime.difference(at).inMicroseconds / 1e6,
};

/// Counts the actions the bound action performs, however it is fired: a live
/// fire is one, an offline one is whatever the batch says it got through.
/// Wrapped around whatever is bound when the stretch starts, and re-wrapped
/// if the action rebinds itself (a dungeon card's hand-off does).
class _ActionCounter {
  int live = 0;
}

/// [setup] builds the scenario on a fresh session: levels, gear, buffs, the
/// bound action, the stance and boost. It runs on a fresh session for each
/// side, so it must be deterministic apart from the combat rolls.
typedef PlaySetup = void Function(GameSession session);

/// The live side: [seconds] of the real frame loop at [fps].
///
/// [payFrameXp] off takes back the frame loop's per-second xp as it lands -
/// see [PlayOutcome.frameXp]. Without it a live run levels recovery and
/// stamina as it goes and the two sides drift apart on that alone.
PlayOutcome runLive(
  PlaySetup setup,
  double seconds, {
  double fps = 20,
  bool payFrameXp = true,
}) {
  late PlayOutcome outcome;
  fakeAsync((async) {
    final session = buildPlaySession();
    final save = session.saveGameData;
    final player = save.playerData;
    final timing = save.actionTimingData;
    setup(session);
    final before = _Before(session);
    final frameXp = <SkillId, double>{};
    // with [payFrameXp] off, every second's worth is taken straight back
    // off the skill it landed on, so the stretch levels on its action xp
    // alone - which is all an offline settle pays
    void addFrameXp(SkillId id, double v) {
      frameXp[id] = (frameXp[id] ?? 0) + v;
      if (!payFrameXp) player.skillData[id]!.xp -= v;
    }

    final counter = _ActionCounter();
    // set when an action killed the enemy: the next one stands up with its
    // swing timer at the top, as EncounterController does
    var enemyDied = false;
    var wrapped = timing.onFire;
    void wrap() {
      final inner = timing.onFire;
      timing.onFire = (count, {offline = false, at, span}) {
        counter.live += count;
        inner(count, offline: offline, at: at, span: span);
        final result = session.encounterController.latestActionResult;
        if (result.enemyDied || result.entitiesDefeated.isNotEmpty) {
          enemyDied = true;
        }
      };
      wrapped = timing.onFire;
    }

    wrap();

    final frame = Duration(microseconds: (1e6 / fps).round());
    final dt = frame.inMicroseconds / 1e6;
    final frames = (seconds / dt).round();
    var elapsed = const Duration(milliseconds: 1);
    // the first frame of a run is the dt=0 sentinel
    session.actionTimingSystem.frameUpdate(elapsed, timing, player);

    var sinceSwing = 0.0;
    var swinging = false;
    var died = false;
    Duration? diedAfter;
    final pds = session.playerDataService;
    final ats = ActionTimingService();

    for (var i = 0; i < frames; i++) {
      elapsed += frame;
      ageBuffs(player.buffData, frame);

      if (timing.running) {
        if (!identical(timing.onFire, wrapped)) wrap();

        // the frame loop's per-second xp, worked out from the same state it
        // reads: the boost after this frame's acceleration, recovery only
        // while nothing holds the boost up
        final maxBefore = pds.getMaxStamina(player);
        final belowMax = player.stamina < maxBefore;
        final away = session.actionTimingSystem.frameUpdate(
          elapsed,
          timing,
          player,
        );
        expect(away, isFalse, reason: 'a live frame must not read as a gap');
        final mult = ats.getCurrentSpeedMultiplier(timing);
        if (mult > 1) {
          addFrameXp(pds.getBoostSkill(player), mult * dt);
          addFrameXp(SkillId.STAMINA, dt);
        }
        if (!timing.buttonHeld && !timing.boostLocked) {
          final rate = pds.staminaRecoveryPerSecond(player);
          if (belowMax && rate > 0) addFrameXp(SkillId.RECOVERY, rate * dt);
        }

        // the enemy's swing, on the simulated clock - see the file header
        if (enemyDied) {
          swinging = false;
          enemyDied = false;
        }
        final entity = save.encounterData.entity;
        if (timing.running &&
            entity is CombatEntity &&
            entity.attackInterval > 0 &&
            !save.encounterData.respawning) {
          if (!swinging) {
            swinging = true;
            sinceSwing = 0;
          } else {
            sinceSwing += dt;
          }
          final interval = (entity.attackInterval * 1000).round() / 1000;
          if (sinceSwing + 1e-9 >= interval) {
            sinceSwing = 0;
            session.encounterSystem.executeEntityAttack(
              playerState: player,
              encounter: save.encounterData,
            );
            if (player.hitpoints <= 0) {
              died = true;
              diedAfter = frame * (i + 1);
              session.actionTimingController.stop();
              pds.heal(1, player);
            } else {
              session.encounterSystem.autoEat(
                playerState: player,
                playerInventory: save.inventoryData,
              );
            }
          }
        }
      } else {
        swinging = false;
        // the idle heartbeat's 10 recovery xp a tick, below
        if (player.stamina < pds.getMaxStamina(player) &&
            (i * dt).floor() != ((i + 1) * dt).floor()) {
          addFrameXp(SkillId.RECOVERY, 10);
        }
      }
      async.elapse(frame);
    }

    final at = DateTime.now();
    outcome = PlayOutcome(
      actions: counter.live,
      xp: _xpDelta(session, before),
      frameXp: frameXp,
      frameXpPaid: payFrameXp,
      items: _itemDelta(session, before),
      stamina: player.stamina,
      maxStamina: pds.getMaxStamina(player),
      hitpoints: player.hitpoints,
      running: timing.running,
      died: died,
      diedAfter: diedAfter,
      globalBuffsLeft: _globalLeft(player.buffData, at),
      zoneBuffsLeft: _zoneLeft(player.buffData, at),
    );
    session.actionTimingController.stop();
    session.dispose();
    async.flushTimers(flushPeriodicTimers: false);
  });
  return outcome;
}

/// The offline side: the same [setup], then [seconds] away settled in one
/// go. Anything [setup] lit or drank is moved to the start of the gap, which
/// is when the player did it.
PlayOutcome runOffline(PlaySetup setup, double seconds) {
  final session = buildPlaySession();
  final save = session.saveGameData;
  final player = save.playerData;
  final timing = save.actionTimingData;
  setup(session);
  final before = _Before(session);

  final gap = Duration(microseconds: (seconds * 1e6).round());
  final now = DateTime.now();
  ageBuffs(player.buffData, gap);
  player.lastActionTime = now.subtract(gap);
  session.offlineProgressSystem.settle(player, timing, now: now);
  // the settle's own buffer rather than the pending report: a gap under
  // [OfflineProgressService.reportThreshold] pays out but raises no dialog
  final report = session.offlineProgressData.report;

  final pds = session.playerDataService;
  final outcome = PlayOutcome(
    actions: report.actionCount,
    xp: _xpDelta(session, before),
    // the settle pays the core skills off the stamina bar, as the frame
    // loop does - the same share, measured the same way
    frameXp: {
      for (final e in report.xp.entries)
        if (kSkillsByCategory[SkillCategory.core]!.contains(e.key))
          e.key: e.value,
    },
    items: _itemDelta(session, before),
    stamina: player.stamina,
    maxStamina: pds.getMaxStamina(player, at: now),
    hitpoints: player.hitpoints,
    running: timing.running,
    died: report.died,
    diedAfter: report.diedAfter,
    globalBuffsLeft: _globalLeft(player.buffData, now),
    zoneBuffsLeft: _zoneLeft(player.buffData, now),
    reportedTimeAway: report.timeAway,
    clockDrift: player.lastActionTime.difference(now),
    report: report,
  );
  session.actionTimingController.stop();
  session.dispose();
  return outcome;
}
