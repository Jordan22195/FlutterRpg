import '../controllers/action_timing_controller.dart';
import '../data/offline_progress_data.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../services/buff_service.dart';
import '../services/offline_progress_service.dart';
import '../services/player_data_service.dart';
import '../services/skill_service.dart';

/// Settles the time the app spent backgrounded while an action was running.
///
/// The window is not paid out in one lump. It is replayed as a series of
/// segments, each one running to the next moment the game state changes:
/// a buff burning out, a locked boost running out of stamina, a level-up.
/// Inside a segment nothing that matters moves, so one batched fire of the
/// bound action is worth exactly what the loop would have done live.
///
///     while (time left && the loop is still running)
///       read the state
///       cut the segment at the next threshold
///       fire one batch of actions
///       spend the time, sweep what expired, measure the rate
///
/// Materials running out and entities running dry are not predicted: the
/// action controllers already stop the loop when their requirements fail,
/// so the loop reads that as its own stop condition. Whatever time is left
/// when it stops is idle, and recovers stamina.
class OfflineProgressSystem {
  final ActionTimingService _actionTimingService;
  final ActionTimingSystem _actionTimingSystem;
  final PlayerDataService _playerDataService;
  final SkillService _skillService;
  final BuffService _buffService;
  final OfflineProgressService _offlineProgressService;

  // the buffer offline actions report into. shared with the action
  // controllers, which record their results while it is open - which is
  // also how this loop learns what each segment actually did
  final OfflineProgressData _offlineProgressData;

  OfflineProgressSystem({
    required ActionTimingService actionTimingService,
    required ActionTimingSystem actionTimingSystem,
    required PlayerDataService playerDataService,
    required SkillService skillService,
    required BuffService buffService,
    required OfflineProgressService offlineProgressService,
    required OfflineProgressData offlineProgressData,
  }) : _actionTimingService = actionTimingService,
       _actionTimingSystem = actionTimingSystem,
       _playerDataService = playerDataService,
       _skillService = skillService,
       _buffService = buffService,
       _offlineProgressService = offlineProgressService,
       _offlineProgressData = offlineProgressData;

  /// A settle is owed once the loop is running and frames have not arrived
  /// for longer than the offline threshold; it is in progress while the
  /// replay runs.
  ///
  /// The buff sweep stands down for both ([BuffController]), so a fire that
  /// burnt out while the app was away is still in the map when the replay
  /// reaches the segment it was burning in. The replay sweeps it itself, at
  /// the instant it actually went out.
  bool settlePending(PlayerData playerState, ActionTimingData timingState) {
    if (_offlineProgressData.processing) return true;
    if (!timingState.running) return false;
    return DateTime.now().difference(playerState.lastActionTime) >=
        ActionTimingService.offlineThreshold;
  }

  /// Replays [PlayerData.lastActionTime] → [now] segment by segment.
  ///
  /// [now] defaults to the wall clock and exists so tests can hand over a
  /// fixed instant instead of sleeping.
  void settle(
    PlayerData playerState,
    ActionTimingData timingState, {
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final timeAway = at.difference(playerState.lastActionTime);
    var remaining = timeAway.inMicroseconds / 1e6;
    if (remaining <= 0) return;

    // open the buffer: everything the actions below produce is collected
    // into one report rather than passing silently into the player's data
    _offlineProgressService.begin(_offlineProgressData, timeAway);

    // xp per action for each skill the action trains, measured from the
    // segment before this one. empty until the first segment has run, which
    // is why that one is a single action: a probe cheap enough to pay for
    // itself in an accurate level-up threshold for everything after it.
    var xpPerAction = <SkillId, double>{};
    var probing = true;

    while (remaining > 0 && timingState.running) {
      // ---- read the state this segment runs at
      _refreshTiming(playerState, timingState);
      final intervalSeconds =
          _actionTimingService
              .getCurrentActionDuration(timingState)
              .inMicroseconds /
          1e6;
      if (intervalSeconds <= 0) break;

      // ---- cut the segment at the nearest threshold
      var segment = remaining;
      segment = _min(segment, _boostEndsIn(playerState, timingState));
      segment = _min(segment, _nextBuffExpiryIn(playerState));
      segment = _min(
        segment,
        _levelUpIn(playerState, xpPerAction, intervalSeconds),
      );
      if (probing) segment = _min(segment, intervalSeconds);
      if (segment <= 0) break;

      // ---- fire one batch, and remember what the report said before it so
      // the rate can be read back off it
      final actions = (segment / intervalSeconds).floor();
      final xpBefore = Map<SkillId, double>.from(
        _offlineProgressData.report.xp,
      );
      final actionsBefore = _offlineProgressData.report.actionCount;
      _actionTimingService.fireOffline(
        timingState,
        actions,
        at: playerState.lastActionTime,
        span: Duration(microseconds: (segment * 1e6).round()),
      );

      // ---- spend the time the segment cost. an action that stopped the
      // loop did not use the whole segment - its materials ran out, its
      // node was stripped, it was killed - and the rest of that stretch was
      // spent idle, so only the share it reported is charged. the actions a
      // batch reports are proportional to the time it consumed, which is
      // what makes this share meaningful.
      final performedThisSegment =
          _offlineProgressData.report.actionCount - actionsBefore;
      final spanUsed = (!timingState.running && actions > 0)
          ? segment * performedThisSegment / actions
          : segment;

      _applyStamina(playerState, timingState, spanUsed);
      playerState.lastActionTime = playerState.lastActionTime.add(
        Duration(microseconds: (spanUsed * 1e6).round()),
      );
      remaining -= spanUsed;

      // ---- expire what this segment outlived, at the moment it did
      _buffService.checkBuffExpriations(
        playerState.buffData,
        at: playerState.lastActionTime,
      );
      _buffService.removeExpiredZoneBuffs(
        playerState.buffData,
        at: playerState.lastActionTime,
      );

      // ---- what the batch paid per action, for the next threshold
      final performed = performedThisSegment;
      if (performed > 0) {
        xpPerAction = {
          for (final entry in _offlineProgressData.report.xp.entries)
            entry.key: (entry.value - (xpBefore[entry.key] ?? 0)) / performed,
        };
      }
      probing = false;
    }

    // the loop stopped short: the action's requirements failed and the
    // player spent the rest of the window idle, recovering
    if (remaining > 0) {
      // the loop stopped, so the rest of the gap is idle at whatever the
      // player's stats are by its end
      _playerDataService.changeStamina(
        remaining * _playerDataService.staminaRecoveryPerSecond(playerState),
        playerState,
      );
    }

    playerState.lastActionTime = at;

    // where in the gap the fight ended, for the report to tell the player
    if (_offlineProgressData.report.died) {
      _offlineProgressService.recordDeathTime(
        _offlineProgressData,
        timeAway - Duration(microseconds: (remaining * 1e6).round()),
      );
    }

    // closes the buffer and promotes the report for the ui. safe here
    // because every bound action runs synchronously: fireOffline wraps the
    // call in a Future.sync, so an action that ever went async would settle
    // after this and report nothing.
    _offlineProgressService.finish(_offlineProgressData);
  }

  /// The two things a segment's pace is read from, refreshed the same way
  /// [ActionTimingSystem.frameUpdate] refreshes them every frame. This is
  /// what a level-up buys: a faster interval for every segment after it.
  void _refreshTiming(PlayerData playerState, ActionTimingData timingState) {
    // running out of stamina breaks the lock outright, the same rule
    // [ActionTimingService.accelerateActionBoostValue] applies live. without
    // it a settle that starts on an empty locked boost would cut a segment
    // of zero and end there, leaving the rest of the gap unsettled.
    if (timingState.boostLocked && playerState.stamina <= 0) {
      _actionTimingService.setLockActionSpeed(false, timingState);
      timingState.percentOfMaxBoost = 0.0;
    }

    // every read is taken at the segment's own instant: a fire or potion
    // that was up for this stretch of the gap lends its stats to it, even
    // though it burnt out hours before the settle ran
    final at = playerState.lastActionTime;
    final stats = _playerDataService.getStatTotals(playerState, at: at);
    final boostSkill = _playerDataService.getBoostSkill(playerState);
    timingState.boostingSpeed = boostSkill == SkillId.SPEED;
    timingState.maxBoostMultiplier = timingState.boostingSpeed
        ? _actionTimingService.maxSpeedBoostForStat(stats[SkillId.SPEED] ?? 1)
        : _actionTimingService.maxStrengthBoostForStat(
            stats[SkillId.STRENGTH] ?? 1,
          );
    timingState.maxInterval = _actionTimingSystem.intervalFor(
      timingState.actionSkill,
      playerState,
      at: at,
    );
  }

  /// How long a locked boost can hold out, or null when nothing is burning
  /// stamina. A boost that costs nothing never runs out.
  double? _boostEndsIn(PlayerData playerState, ActionTimingData timingState) {
    if (!timingState.boostLocked) return null;
    final multiplier = _actionTimingService.getCurrentSpeedMultiplier(
      timingState,
    );
    final drainPerSecond =
        ActionTimingService.staminaDrainPerBoost * (multiplier - 1);
    if (drainPerSecond <= 0) return null;
    return playerState.stamina / drainPerSecond;
  }

  /// How long until the next buff runs out — a fire going cold is what stops
  /// a cooking loop, and every other buff moves the stats the action rolls
  /// against.
  double? _nextBuffExpiryIn(PlayerData playerState) {
    final next = _buffService.nextExpiration(
      playerState.buffData,
      playerState.currentZoneId,
      after: playerState.lastActionTime,
    );
    if (next == null) return null;
    return next.difference(playerState.lastActionTime).inMicroseconds / 1e6;
  }

  /// How long until the measured xp rate levels a skill up. Null until a
  /// segment has been measured, and for a rate that never gets there.
  double? _levelUpIn(
    PlayerData playerState,
    Map<SkillId, double> xpPerAction,
    double intervalSeconds,
  ) {
    double? soonest;
    for (final entry in xpPerAction.entries) {
      if (entry.value <= 0) continue;
      final skill = playerState.skillData[entry.key];
      if (skill == null) continue;
      final xpToGo = _skillService.xpToLevelUp(skill);
      if (xpToGo <= 0) continue;
      final seconds = (xpToGo / entry.value).ceil() * intervalSeconds;
      if (soonest == null || seconds < soonest) soonest = seconds;
    }
    return soonest;
  }

  /// The stamina one segment's worth of time moves, on the same rules the
  /// frame loop runs on: a held boost drains, anything else recovers.
  /// Draining to empty breaks the lock, so later segments run unboosted.
  void _applyStamina(
    PlayerData playerState,
    ActionTimingData timingState,
    double seconds,
  ) {
    final at = playerState.lastActionTime;
    if (!timingState.boostLocked) {
      _playerDataService.changeStamina(
        seconds *
            _playerDataService.staminaRecoveryPerSecond(playerState, at: at),
        playerState,
        at: at,
      );
      return;
    }

    final multiplier = _actionTimingService.getCurrentSpeedMultiplier(
      timingState,
    );
    final drainPerSecond =
        ActionTimingService.staminaDrainPerBoost * (multiplier - 1);
    _playerDataService.changeStamina(
      -seconds * drainPerSecond,
      playerState,
      at: at,
    );

    // spent once it cannot fund another microsecond. the exact-zero case is
    // not reachable by arithmetic - draining a boost window computed from
    // the stamina it costs leaves a float's worth behind either way - and a
    // residue that small would otherwise cut segments too short to hold a
    // single action, over and over.
    if (playerState.stamina < drainPerSecond * 1e-6) {
      _playerDataService.changeStamina(
        -playerState.stamina,
        playerState,
        at: at,
      );
      _actionTimingService.setLockActionSpeed(false, timingState);
      timingState.percentOfMaxBoost = 0.0;
    }
  }

  double _min(double value, double? threshold) {
    if (threshold == null) return value;
    return threshold < value ? threshold : value;
  }
}
