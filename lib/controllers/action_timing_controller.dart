import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/services/equipment_service.dart';
import 'package:rpg/services/player_data_service.dart';
import '../data/bound_action.dart';
import '../data/offline_progress_data.dart';
import '../data/skill_data.dart';
import '../services/offline_progress_service.dart';

// primary button sets the on fire function and max interval in the controller.
// the primary button triggers startIfNeeded which starts the ticker.
// all the speed controls are done in _onTick which triggers every frame.
//
// start with max interval
// min interval is calculated based on maxInterval / maxSpeedMuitipier
// current SpeedMultiplier = currentSpeedPercent * (maxSpeedMuitipier - 1) + 1
// current interval = maxInterval / current speed miltiplier

//
//  Action Timing Data
//
class ActionTimingData {
  ActionTimingData();
  FutureOr<void> Function(int) onFire = (_) {};

  /// The unboosted action interval. Not a constant: it is refreshed every
  /// frame from the item equipped for [actionSkill] and the speed stat, so
  /// swapping gear mid-action is felt immediately.
  Duration maxInterval = ActionTimingService.defaultMaxInterval;

  /// What the bound action trains, which is how the equipped item driving
  /// the interval is found. Null for actions performed with no item at all.
  SkillId? actionSkill;

  bool boostingSpeed = true;

  double accelPerSecond =
      0.5; // how quickly speed bar fills when button is held
  double decelPerSecond =
      .75; // how quickly speed bar empties when button is released

  // the boost ceiling; refreshed from the speed stat every frame.
  double maxBoostMultiplier = 2.0;

  bool boostLocked =
      false; // speed will not change (unless out of stamina) when this is true.

  bool running = false;
  bool buttonHeld = false;
  bool actionInFlight = false;

  // what the running action is, shown as an icon tile in the top status bar.
  // activityCount is a getter so the badge stays live as the entity count
  // or craftable count changes while the action runs.
  Enum? activityIconId;
  int Function()? activityCount;

  double percentOfMaxBoost = 0.0; // 0 to 1 percentage of maximum speed.
  double actionProgressPercentComplete =
      0.0; // 0 to 1 percentage of action progress

  Duration lastElapsed = Duration.zero;

  /// What [onFire] is, in a form a save can hold. Set alongside the closure
  /// in [ActionTimingController.bindOnFireFunction] and cleared with it in
  /// [ActionTimingService.stop], so it always describes the bound action.
  BoundAction? boundAction;

  Map<String, dynamic> toJson() {
    return {
      'maxInterval': maxInterval.inMicroseconds,
      'actionSkill': actionSkill?.name,
      'boostingSpeed': boostingSpeed,
      'maxBoostMultiplier': maxBoostMultiplier,
      'boostLocked': boostLocked,
      'running': running,
      'percentOfMaxBoost': percentOfMaxBoost,
      'actionProgressPercentComplete': actionProgressPercentComplete,
      'boundAction': boundAction?.toJson(),
    };
  }

  /// Tolerant by design: a malformed key falls back to its default rather
  /// than failing the save load. Nothing here is worth losing a game over -
  /// the worst case is the player reopens idle and presses the button again.
  ///
  /// [onFire], [activityIconId] and [activityCount] are absent because they
  /// are references; the resume path rebinds them. [buttonHeld],
  /// [actionInFlight] and [lastElapsed] are absent because they are
  /// frame-transient: no finger is down at launch, and a fresh Ticker
  /// restarts its elapsed clock from zero, which [ActionTimingSystem
  /// .frameUpdate] reads as its first-frame sentinel.
  factory ActionTimingData.fromJson(Map<String, dynamic> json) {
    final state = ActionTimingData();

    final rawInterval = json['maxInterval'];
    if (rawInterval is int) {
      state.maxInterval = Duration(microseconds: rawInterval);
    }

    final rawSkill = json['actionSkill'];
    if (rawSkill is String) {
      state.actionSkill = SkillId.values.asNameMap()[rawSkill];
    }

    final rawMaxBoost = json['maxBoostMultiplier'];
    if (rawMaxBoost is num) {
      state.maxBoostMultiplier = rawMaxBoost.toDouble();
    }

    final rawPercent = json['percentOfMaxBoost'];
    if (rawPercent is num) {
      state.percentOfMaxBoost = rawPercent.toDouble().clamp(0.0, 1.0);
    }

    final rawProgress = json['actionProgressPercentComplete'];
    if (rawProgress is num) {
      state.actionProgressPercentComplete = rawProgress.toDouble().clamp(
        0.0,
        1.0,
      );
    }

    if (json['boostingSpeed'] is bool) {
      state.boostingSpeed = json['boostingSpeed'] as bool;
    }
    state.boostLocked = json['boostLocked'] == true;
    state.running = json['running'] == true;

    final rawBound = json['boundAction'];
    if (rawBound is Map<String, dynamic>) {
      state.boundAction = BoundAction.fromJson(rawBound);
    }

    return state;
  }
}

//
//  Action Timing Controller
//

class ActionTimingController extends ChangeNotifier {
  // internal state
  final TickerProvider _vsync;
  late Ticker ticker;
  final ActionTimingData _actionTimingState;

  // data
  final PlayerData _playerState;

  final OfflineProgressData _offlineProgressData;

  // services
  final ActionTimingService _actionTimingService;
  final OfflineProgressService _offlineProgressService;

  //systems
  final ActionTimingSystem _actionSpeedSystem;

  ActionTimingController({
    required TickerProvider vsync,

    required ActionTimingService actionTimingService,
    required PlayerData playerState,
    required ActionTimingSystem actionSpeedSystem,
    required ActionTimingData actionTimingState,
    required OfflineProgressData offlineProgressData,
    required OfflineProgressService offlineProgressService,
  }) : _actionTimingService = actionTimingService,
       _playerState = playerState,
       _vsync = vsync,
       _actionSpeedSystem = actionSpeedSystem,
       _actionTimingState = actionTimingState,
       _offlineProgressData = offlineProgressData,
       _offlineProgressService = offlineProgressService {
    ticker = _vsync.createTicker(_onTick);
  }

  /// Bumped when an offline settle produces a report worth showing. The
  /// shell watches this counter rather than the report, so two identical
  /// settles still raise the popup twice.
  int get offlineReportSequence => _offlineProgressData.reportSequence;

  /// The report waiting to be shown, if any. Valid until [consumeOfflineReport].
  OfflineProgressReport? get pendingOfflineReport =>
      _offlineProgressData.pending;

  /// Called once the report has been shown to the player.
  void consumeOfflineReport() =>
      _offlineProgressService.consume(_offlineProgressData);

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  bool getActionSpeedLockState() {
    return _actionTimingState.boostLocked;
  }

  double get percentMaxSpeed => _actionTimingState.percentOfMaxBoost;

  double get actionProgress => _actionTimingState.actionProgressPercentComplete;

  /// The interval an action training [skill] would run at from a standing
  /// start. A screen showing a timer for an action that is *not* the one
  /// running asks for this rather than [getCurrentActionDuration], so an
  /// idle timer never reports another screen's live interval.
  Duration idleActionDurationFor(SkillId? skill) =>
      _actionSpeedSystem.intervalFor(skill, _playerState);

  Duration getCurrentActionDuration() {
    // the frame loop keeps the stored interval fresh while an action runs.
    // idle, nothing is ticking to refresh it - and stopping resets it to the
    // default - so it is computed live instead, or switching stance would
    // leave the status bar reading whatever the last action left behind.
    // the boost sits at 1x with nothing held, so the unboosted interval is
    // the whole answer here.
    if (!_actionTimingState.running) {
      return _actionSpeedSystem.currentMaxInterval(
        _actionTimingState,
        _playerState,
      );
    }
    return _actionTimingService.getCurrentActionDuration(_actionTimingState);
  }

  double getCurrentSpeedMultiplier() {
    return _actionTimingService.getCurrentSpeedMultiplier(_actionTimingState);
  }

  void lockActionSpeed() {
    _actionTimingService.setLockActionSpeed(true, _actionTimingState);
  }

  void unlockActionSpeed() {
    _actionTimingService.setLockActionSpeed(false, _actionTimingState);
  }

  /// Binds the action the loop fires. [actionSkill] is what the action
  /// trains; the item equipped for it sets how long each action takes.
  /// Leave it null for actions performed with no equipment.
  /// [boundAction] describes [function] in a form the save can hold, so the
  /// same action can be rebound after an app restart.
  void bindOnFireFunction(
    FutureOr<void> Function(int) function, {
    Enum? activityIconId,
    int Function()? activityCount,
    SkillId? actionSkill,
    BoundAction? boundAction,
  }) {
    _actionTimingState.onFire = function;
    _actionTimingState.actionSkill = actionSkill;
    _actionTimingState.activityIconId = activityIconId;
    _actionTimingState.activityCount = activityCount;
    _actionTimingState.boundAction = boundAction;
  }

  // icon id of the currently running activity; null when idle
  Enum? get activityIconId =>
      _actionTimingState.running ? _actionTimingState.activityIconId : null;

  // live count for the activity icon badge
  int get activityCount => _actionTimingState.activityCount?.call() ?? 0;

  // true when the loop is running with [function] bound as its action
  bool isRunningAction(FutureOr<void> Function(int) function) {
    return _actionTimingState.running && _actionTimingState.onFire == function;
  }

  /// True while the action loop is running (any action).
  bool get isRunning => _actionTimingState.running;

  /// True only once frames are actually arriving. A save restores [isRunning]
  /// before anything has been bound to fire, so that flag alone cannot tell a
  /// live loop from one still waiting to be resumed; the ticker can.
  bool get isTicking => ticker.isActive;

  /// True while the primary button is held down and boosting the speed.
  bool get isButtonHeld => _actionTimingState.buttonHeld;

  void start() {
    // time spent with the loop stopped is not time spent away: the player
    // was on another screen, not backgrounded mid-action. without this, the
    // first frame after a deliberate pause would pay out offline progress
    // for the whole gap.
    _playerState.lastActionTime = DateTime.now();
    _actionTimingService.start(_actionTimingState);
    ticker.start();
    notifyListeners();
  }

  void stop() {
    _actionTimingService.stop(_actionTimingState);
    ticker.stop();
    // the ticker is what feeds the multiplier back to the player, so stopping
    // mid-boost would otherwise leave the boosted stats inflated until the
    // next run
    _actionSpeedSystem.clearBoost(_playerState);
    notifyListeners();
  }

  void onPrimaryButtonPressed() {
    // set held flag
    _actionTimingService.setPrimaryButtonHeld(true, _actionTimingState);
  }

  void onPrimaryButtonReleased() {
    // reset held flag
    _actionTimingService.setPrimaryButtonHeld(false, _actionTimingState);
  }

  // increase speed percent based on acceleration values
  // icriment action progress based on time elapsed and current action interval
  // if action progress is 100% fire the action
  // drain stamina and apply xp based on speed mulitplier
  void _onTick(Duration elapsed) {
    _actionSpeedSystem.frameUpdate(elapsed, _actionTimingState, _playerState);
    notifyListeners();
  }
}

class ActionTimingSystem {
  final ActionTimingService _actionTimingService;
  final PlayerDataService _playerDataService;
  final EquipmentService _equipmentService;
  final OfflineProgressService _offlineProgressService;

  // the buffer offline actions report into. shared with the action
  // controllers, which record their results while it is open
  final OfflineProgressData _offlineProgressData;

  ActionTimingSystem({
    required ActionTimingService actionTimingService,
    required PlayerDataService playerDataService,
    required EquipmentService equipmentService,
    required OfflineProgressService offlineProgressService,
    required OfflineProgressData offlineProgressData,
  }) : _actionTimingService = actionTimingService,
       _playerDataService = playerDataService,
       _equipmentService = equipmentService,
       _offlineProgressService = offlineProgressService,
       _offlineProgressData = offlineProgressData;

  /// Drops the boost back to 1x, so nothing stays scaled while idle.
  void clearBoost(PlayerData playerState) {
    _playerDataService.setBoostMultiplier(1.0, playerState);
  }

  /// The unboosted interval the bound action would run at right now: the
  /// speed of the item equipped to perform it, cut by the speed stat while in
  /// the fast stance.
  ///
  /// [frameUpdate] writes this into [ActionTimingData.maxInterval] every frame
  /// while the loop runs. Idle, nothing writes it, so the status bar readout
  /// asks for it directly - the stance moves it, and a stance can be switched
  /// with the loop stopped.
  Duration currentMaxInterval(ActionTimingData state, PlayerData playerState) {
    return intervalFor(state.actionSkill, playerState);
  }

  /// The unboosted interval an action training [actionSkill] would run at
  /// from a standing start, with whatever is equipped to perform it.
  ///
  /// Asked for by name rather than off the running action's state, so a
  /// screen that is not the one acting can show what starting *there* would
  /// cost instead of echoing the interval some other screen's action is
  /// currently running at.
  Duration intervalFor(SkillId? actionSkill, PlayerData playerState) {
    final stats = _playerDataService.getStatTotals(playerState);
    return _actionTimingService.maxIntervalFor(
      equippedInterval: actionSkill == null
          ? null
          : _equipmentService.actionIntervalFor(
              actionSkill,
              playerState.equipmentData,
            ),
      speedStance:
          _playerDataService.getBoostSkill(playerState) == SkillId.SPEED,
      speedStat: stats[SkillId.SPEED] ?? 1,
    );
  }

  /// [stats] and [speedStance] are passed in because the frame loop has
  /// already worked both out by the time it needs the interval.
  Duration _maxIntervalFor(
    ActionTimingData state,
    PlayerData playerState,
    Map<SkillId, int> stats,
    bool speedStance,
  ) {
    final actionSkill = state.actionSkill;
    return _actionTimingService.maxIntervalFor(
      equippedInterval: actionSkill == null
          ? null
          : _equipmentService.actionIntervalFor(
              actionSkill,
              playerState.equipmentData,
            ),
      speedStance: speedStance,
      speedStat: stats[SkillId.SPEED] ?? 1,
    );
  }

  /// Settles the time the app spent backgrounded while an action was
  /// running: the actions that would have fired, and the stamina that would
  /// have drained or recovered.
  ///
  /// A locked boost keeps running while away, but only for as long as the
  /// stamina it burns lasts - so the window splits into a boosted stretch at
  /// the boosted interval, then whatever is left at the unboosted one. The
  /// two stretches fire separately, each with its own action count.
  ///
  /// [now] defaults to the wall clock and exists so tests can hand over a
  /// fixed instant instead of sleeping.
  void offlineProgressUpdate(
    PlayerData playerState,
    ActionTimingData actionTimingState, {
    DateTime? now,
  }) {
    // get elapsed time
    final at = now ?? DateTime.now();
    double secondsOfBoost = 0;
    final timeOffline = at.difference(playerState.lastActionTime);
    final timeOfflineInSeconds = timeOffline.inMicroseconds / 1e6;
    if (timeOfflineInSeconds <= 0) return;

    // open the buffer: everything the actions below produce is collected
    // into one report rather than passing silently into the player's data
    _offlineProgressService.begin(
      _offlineProgressData,
      timeOffline,
      playerState,
    );

    // get action interval duration. read in microseconds: a boosted
    // interval is routinely under a second, and truncating it to whole
    // seconds would divide by zero.
    final actionInterval =
        _actionTimingService
            .getCurrentActionDuration(actionTimingState)
            .inMicroseconds /
        1e6;

    //  if boost was locked,
    if (actionTimingState.boostLocked) {
      //    calculate duration of boost
      final boostMulitplier = _actionTimingService.getCurrentSpeedMultiplier(
        actionTimingState,
      );
      final drainPerSecond =
          ActionTimingService.staminaDrainPerBoost * (boostMulitplier - 1);

      // a boost that costs nothing (multiplier of exactly 1) never runs out,
      // so it covers the whole window rather than dividing by zero
      secondsOfBoost = drainPerSecond <= 0
          ? timeOfflineInSeconds
          : playerState.stamina / drainPerSecond;

      // the boost cannot outlast the time actually spent away
      if (secondsOfBoost > timeOfflineInSeconds) {
        secondsOfBoost = timeOfflineInSeconds;
      }

      // do stamina drain
      _playerDataService.changeStamina(
        -1 * secondsOfBoost * drainPerSecond,
        playerState,
      );
      // apply stamina xp

      // calculate number of actions boosted
      int numberOfBoostedActions = actionInterval <= 0
          ? 0
          : (secondsOfBoost / actionInterval).floor();
      // do boosted actions
      _offlineProgressService.recordActions(
        _offlineProgressData,
        numberOfBoostedActions,
      );
      _actionTimingService.fireOffline(
        actionTimingState,
        numberOfBoostedActions,
      );
    } else {
      // if boost was not locked, caculate stamina recovery
      final recoveryPerSecond = _playerDataService.staminaRecoveryPerSecond(
        playerState,
      );
      _playerDataService.changeStamina(
        timeOfflineInSeconds * recoveryPerSecond,
        playerState,
      );
      // apply recovery xp
    }

    // calculate number of actions unboosted
    final unboostedInterval =
        actionTimingState.maxInterval.inMicroseconds / 1e6;
    double secondsUnboosted = timeOfflineInSeconds - secondsOfBoost;
    int numberUnboostedActions = unboostedInterval <= 0
        ? 0
        : (secondsUnboosted / unboostedInterval).floor();
    _offlineProgressService.recordActions(
      _offlineProgressData,
      numberUnboostedActions,
    );
    _actionTimingService.fireOffline(actionTimingState, numberUnboostedActions);

    playerState.lastActionTime = at;

    // closes the buffer and promotes the report for the ui. safe here
    // because every bound action runs synchronously: fireOffline wraps the
    // call in a Future.sync, so an action that ever went async would settle
    // after this and report nothing.
    _offlineProgressService.finish(_offlineProgressData, playerState);
  }

  // the momentum loop, once per frame:
  // - the speed stat sets the boost ceiling
  // - holding the button accelerates toward the ceiling
  // - boosting drains stamina faster the harder the boost, and a locked
  //   boost drains exactly as a held one does
  // - the recovery stat restores stamina, but only once nothing is holding
  //   the boost up: neither a finger on the button nor the speed lock
  // - draining to empty breaks the lock, so the boost falls off rather than
  //   snapping back as soon as stamina trickles in
  void frameUpdate(
    Duration elapsed,
    ActionTimingData actionTimingState,
    PlayerData playerState,
  ) {
    final dt = (actionTimingState.lastElapsed == Duration.zero)
        ? 0.0
        : (elapsed - actionTimingState.lastElapsed).inMicroseconds / 1e6;
    actionTimingState.lastElapsed = elapsed;

    // check if we have been offline
    final sinceLastAction = DateTime.now().difference(
      playerState.lastActionTime,
    );
    if (actionTimingState.running &&
        sinceLastAction >= ActionTimingService.offlineThreshold &&
        dt > 0) {
      offlineProgressUpdate(playerState, actionTimingState);
      return;
    }
    // return if no time has passed. this sits above the stamp because the
    // first frame of a run always has a dt of zero: stamping there would
    // move lastActionTime forward before the offline check above ever gets
    // a frame it can act on, swallowing the whole gap on resume.
    if (dt <= 0) return;
    playerState.lastActionTime = DateTime.now();

    // refresh the boost ceiling from whichever stat the stance runs on
    final stats = _playerDataService.getStatTotals(playerState);
    final boostSkill = _playerDataService.getBoostSkill(playerState);
    actionTimingState.boostingSpeed = boostSkill == SkillId.SPEED;
    actionTimingState.maxBoostMultiplier = actionTimingState.boostingSpeed
        ? _actionTimingService.maxSpeedBoostForStat(stats[SkillId.SPEED] ?? 1)
        : _actionTimingService.maxStrengthBoostForStat(
            stats[SkillId.STRENGTH] ?? 1,
          );

    // and the interval itself from what is equipped to swing. refreshed
    // per frame rather than at bind time, so swapping to a faster axe is
    // felt without restarting the action
    actionTimingState.maxInterval = _maxIntervalFor(
      actionTimingState,
      playerState,
      stats,
      actionTimingState.boostingSpeed,
    );

    _actionTimingService.accelerateActionBoostValue(
      dt,
      actionTimingState,
      playerState,
    );
    // icriment action progress based on time elapsed and current action interval
    _actionTimingService.udpateActionProgress(dt, actionTimingState);

    // if action progress is > 100% try and fire the action and roll over the
    // progress percentage.
    if (actionTimingState.actionProgressPercentComplete >= 1.0) {
      actionTimingState.actionProgressPercentComplete =
          actionTimingState.actionProgressPercentComplete % 1.0;
      _actionTimingService.tryFire(actionTimingState, playerState, 1);
    }

    // calculate stamina drain and xp gains
    final boostMulitplier = _actionTimingService.getCurrentSpeedMultiplier(
      actionTimingState,
    );
    _playerDataService.setBoostMultiplier(boostMulitplier, playerState);

    // stamina flow: drain scales with how boosted you are; recovery is a
    // steady rate from the recovery stat. the net is applied clamped to
    // [0, max stamina]
    final drainPerSecond =
        ActionTimingService.staminaDrainPerBoost * (boostMulitplier - 1);
    final recoveryPerSecond = _playerDataService.staminaRecoveryPerSecond(
      playerState,
    );
    final wasBelowMax =
        playerState.stamina < _playerDataService.getMaxStamina(playerState);

    // only recover if the button is not held
    if (actionTimingState.buttonHeld == false &&
        actionTimingState.boostLocked == false) {
      _playerDataService.changeStamina((recoveryPerSecond) * dt, playerState);
      if (wasBelowMax && recoveryPerSecond > 0) {
        _playerDataService.applyXp(playerState, {
          SkillId.RECOVERY: recoveryPerSecond * dt,
        });
      }
    } else {
      _playerDataService.changeStamina(-1 * drainPerSecond * dt, playerState);
    }
    // xp: the stance's boost skill trains while boosting, stamina trains
    // while draining, recovery trains while it has something to restore
    if (boostMulitplier > 1) {
      _playerDataService.applyXp(playerState, {
        boostSkill: boostMulitplier * 1 * dt,
        SkillId.STAMINA: 1 * dt,
      });
    }
  }
}

class ActionTimingService {
  /// Stamina drained per second per point of boost (speed above 1x).
  static const double staminaDrainPerBoost = 2.0;

  /// How long a gap between frames has to be before it is treated as time
  /// spent away rather than a slow frame. Frames stop arriving when the app
  /// is backgrounded, so a gap this size means the loop was not running.
  static const Duration offlineThreshold = Duration(seconds: 1);

  /// How long an action takes with nothing equipped to perform it —
  /// bare-handed gathering, and everything done at a bench.
  static const Duration defaultMaxInterval = Duration(seconds: 3);

  /// Fraction of the action interval one point of the speed stat removes,
  /// and only in the fast stance: the strong stance trades that speed for
  /// the strength boost instead.
  static const double speedIntervalReductionPerPoint = 0.01;

  /// The floor that reduction can reach, as a fraction of the equipped
  /// item's own interval. Without it a speed stat of 100 would take the
  /// interval to zero and fire the action every frame.
  static const double minIntervalFraction = 0.15;

  /// The unboosted interval for an action: the speed of the item equipped
  /// to perform it, cut by the speed stat while in the fast stance.
  ///
  /// This is the ceiling the momentum boost then works down from — holding
  /// the button divides this further, so speed pays twice in the fast
  /// stance: once here and again through the boost ceiling.
  Duration maxIntervalFor({
    required Duration? equippedInterval,
    required bool speedStance,
    required int speedStat,
  }) {
    final base = equippedInterval ?? defaultMaxInterval;
    if (!speedStance) return base;

    final factor = (1 - speedIntervalReductionPerPoint * speedStat).clamp(
      minIntervalFraction,
      1.0,
    );
    return Duration(microseconds: (base.inMicroseconds * factor).round());
  }

  /// The boost ceiling granted by the speed stat.
  double maxSpeedBoostForStat(int speedStat) {
    return 1.0 + 0.05 * speedStat;
  }

  /// The boost ceiling granted by the strength stat.
  double maxStrengthBoostForStat(int strengthStat) {
    return 1.0 + 0.1 * strengthStat;
  }

  // increase or decrease boost based on if button is held or not
  // uses acceleration and deceleration values for the rate of change
  void accelerateActionBoostValue(
    double dt,
    ActionTimingData actionTimingState,
    PlayerData playerState,
  ) {
    final hasStamina = playerState.stamina > 0;

    // running out of stamina breaks the lock outright. there is nothing left
    // to hold the boost up with, so the lock is dropped rather than left
    // engaged to snap the speed back the moment stamina trickles in again.
    if (!hasStamina && actionTimingState.boostLocked) {
      setLockActionSpeed(false, actionTimingState);
    }

    // a locked speed holds steady
    if (actionTimingState.boostLocked) {
      return;
    }

    // momentum update
    if (actionTimingState.buttonHeld && hasStamina) {
      // calculate the current percentage of max boost (0 .. 1)
      // increase boost amount by accerlation amount if button is pressed
      actionTimingState.percentOfMaxBoost =
          (actionTimingState.percentOfMaxBoost +
                  actionTimingState.accelPerSecond * dt)
              .clamp(0.0, 1.0);
    } else {
      // decrease boost bar amount be deceleration amount if button is not held
      actionTimingState.percentOfMaxBoost =
          (actionTimingState.percentOfMaxBoost -
                  actionTimingState.decelPerSecond * dt)
              .clamp(0.0, 1.0);
    }
  }

  void setLockActionSpeed(bool locked, ActionTimingData actionTimingState) {
    actionTimingState.boostLocked = locked;
  }

  void setPrimaryButtonHeld(bool held, ActionTimingData state) {
    state.buttonHeld = held;
  }

  void udpateActionProgress(double dt, ActionTimingData actionTimingState) {
    final intervalSec =
        getCurrentActionDuration(actionTimingState).inMicroseconds / 1e6;
    actionTimingState.actionProgressPercentComplete += dt / intervalSec;
  }

  double actionsPerSecond(ActionTimingData actionTimingState) {
    final intervalSec =
        getCurrentActionDuration(actionTimingState).inMicroseconds / 1e6;
    if (intervalSec == 0) return 0;
    return 1 / intervalSec;
  }

  /// Returns the current speed multiplier relative to the max interval.
  double getCurrentSpeedMultiplier(ActionTimingData actionTimingState) {
    return actionTimingState.percentOfMaxBoost *
            (actionTimingState.maxBoostMultiplier - 1) +
        1;
  }

  void stop(ActionTimingData actionTimingState) {
    actionTimingState.running = false;
    actionTimingState.actionProgressPercentComplete = 0.0;
    actionTimingState.percentOfMaxBoost = 0.0;
    actionTimingState.buttonHeld = false;
    actionTimingState.lastElapsed = Duration.zero;
    actionTimingState.boostLocked = false;
    actionTimingState.activityIconId = null;
    actionTimingState.activityCount = null;
    actionTimingState.actionSkill = null;
    actionTimingState.boundAction = null;
    actionTimingState.maxInterval = defaultMaxInterval;
  }

  void start(ActionTimingData actionTimingState) {
    if (actionTimingState.running) return;
    actionTimingState.running = true;
    actionTimingState.lastElapsed = Duration.zero;
  }

  Duration getCurrentActionDuration(ActionTimingData actionTimingState) {
    final ms = actionTimingState.boostingSpeed
        ? actionTimingState.maxInterval.inMilliseconds /
              getCurrentSpeedMultiplier(actionTimingState)
        : actionTimingState.maxInterval.inMilliseconds;

    return Duration(milliseconds: ms.round());
  }

  void tryFire(
    ActionTimingData actionTimingState,
    PlayerData playerState,
    int count,
  ) {
    if (actionTimingState.actionInFlight) return;
    actionTimingState.actionInFlight = true;
    Future.sync(() => actionTimingState.onFire(count)).whenComplete(() {
      actionTimingState.actionInFlight = false;
      playerState.lastActionTime = DateTime.now();
    });
  }

  /// Fires the bound action for one settled stretch of offline progress.
  ///
  /// Unlike [tryFire] this does not gate on [ActionTimingData.actionInFlight]:
  /// the offline path fires its boosted and unboosted stretches back to back
  /// within a single frame, and the flag is only cleared in a microtask — so
  /// the guard would swallow the second stretch outright. The flag is still
  /// raised, so the per-frame [tryFire] stays gated behind an offline batch
  /// that is still running.
  ///
  /// [PlayerData.lastActionTime] is deliberately left alone: the offline
  /// window ends when the catch-up was calculated, not whenever an async
  /// action happens to settle, so [ActionTimingSystem.offlineProgressUpdate]
  /// owns it.
  void fireOffline(ActionTimingData actionTimingState, int count) {
    if (count <= 0) return;
    actionTimingState.actionInFlight = true;
    Future.sync(
      () => actionTimingState.onFire(count),
    ).whenComplete(() => actionTimingState.actionInFlight = false);
  }
}
