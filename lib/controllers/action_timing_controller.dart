import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/services/player_data_service.dart';
import '../data/skill_data.dart';

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
  FutureOr<void> Function() onFire = () {};
  Duration maxInterval = Duration(seconds: 1);

  double accelPerSecond =
      0.25; // how quickly speed bar fills when button is held
  double decelPerSecond =
      .5; // how quickly speed bar empties when button is released

  // the boost ceiling; refreshed from the speed stat every frame.
  // min action interval = max action interval / maxSpeedMultiplier
  double maxSpeedMultiplier = 2.0;

  bool speedLocked =
      false; // speed will not change (unless out of stamina) when this is true.

  bool running = false;
  bool buttonHeld = false;
  bool actionInFlight = false;

  // what the running action is, shown as an icon tile in the top status bar.
  // activityCount is a getter so the badge stays live as the entity count
  // or craftable count changes while the action runs.
  Enum? activityIconId;
  int Function()? activityCount;

  double speedPercent = 0.0; // 0 to 1 percentage of maximum speed.
  double actionProgress = 0.0; // 0 to 1 percentage of action progress

  Duration lastElapsed = Duration.zero;
}

//
//  Action Timing Controller
//

class ActionTimingController extends ChangeNotifier {
  // internal state
  final TickerProvider _vsync;
  late Ticker ticker;
  final ActionTimingData _actionTimingState = ActionTimingData();

  // data
  final PlayerData _playerState;

  // services
  final ActionTimingService _actionTimingService;

  //systems
  final ActionSpeedSystem _actionSpeedSystem;

  ActionTimingController({
    required TickerProvider vsync,

    required ActionTimingService actionTimingService,
    required PlayerData playerState,
    required ActionSpeedSystem actionSpeedSystem,
  }) : _actionTimingService = actionTimingService,
       _playerState = playerState,
       _vsync = vsync,
       _actionSpeedSystem = actionSpeedSystem {
    ticker = _vsync.createTicker(_onTick);
  }

  @override
  void dispose() {
    ticker.dispose();
    super.dispose();
  }

  bool getActionSpeedLockState() {
    return _actionTimingState.speedLocked;
  }

  double get percentMaxSpeed => _actionTimingState.speedPercent;

  double get actionProgress => _actionTimingState.actionProgress;

  Duration getCurrentActionDuration() {
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

  void bindOnFireFunction(
    FutureOr<void> Function() function, {
    Enum? activityIconId,
    int Function()? activityCount,
  }) {
    _actionTimingState.onFire = function;
    _actionTimingState.activityIconId = activityIconId;
    _actionTimingState.activityCount = activityCount;
  }

  // icon id of the currently running activity; null when idle
  Enum? get activityIconId =>
      _actionTimingState.running ? _actionTimingState.activityIconId : null;

  // live count for the activity icon badge
  int get activityCount => _actionTimingState.activityCount?.call() ?? 0;

  // true when the loop is running with [function] bound as its action
  bool isRunningAction(FutureOr<void> Function() function) {
    return _actionTimingState.running && _actionTimingState.onFire == function;
  }

  /// True while the action loop is running (any action).
  bool get isRunning => _actionTimingState.running;

  void start() {
    _actionTimingService.start(_actionTimingState);
    ticker.start();
    notifyListeners();
  }

  void stop() {
    _actionTimingService.stop(_actionTimingState);
    ticker.stop();
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

class ActionSpeedSystem {
  final ActionTimingService _actionTimingService;
  final PlayerDataService _playerDataService;

  ActionSpeedSystem({
    required ActionTimingService actionTimingService,
    required PlayerDataService playerDataService,
  }) : _actionTimingService = actionTimingService,
       _playerDataService = playerDataService;

  // the momentum loop, once per frame:
  // - the speed stat sets the boost ceiling
  // - holding the button accelerates toward the ceiling
  // - boosting drains stamina faster the harder the boost
  // - the recovery stat restores stamina at a steady rate, so a gentle
  //   boost whose drain matches recovery can be held indefinitely
  void frameUpdate(
    Duration elapsed,
    ActionTimingData actionTimingState,
    PlayerData playerState,
  ) {
    final dt = (actionTimingState.lastElapsed == Duration.zero)
        ? 0.0
        : (elapsed - actionTimingState.lastElapsed).inMicroseconds / 1e6;
    actionTimingState.lastElapsed = elapsed;

    // return if no time has passed.
    if (dt <= 0) return;

    // refresh the boost ceiling from the speed stat
    final stats = _playerDataService.getStatTotals(playerState);
    actionTimingState.maxSpeedMultiplier = _actionTimingService
        .maxSpeedForStat(stats[SkillId.SPEED] ?? 1);

    _actionTimingService.updateActionSpeed(dt, actionTimingState, playerState);

    // icriment action progress based on time elapsed and current action interval
    _actionTimingService.udpateActionProgress(dt, actionTimingState);

    // if action progress is > 100% try and fire the action and roll over the
    // progress percentage.
    if (actionTimingState.actionProgress >= 1.0) {
      actionTimingState.actionProgress = actionTimingState.actionProgress % 1.0;
      _actionTimingService.tryFire(actionTimingState);
    }

    final speed = _actionTimingService.getCurrentSpeedMultiplier(
      actionTimingState,
    );

    // stamina flow: drain scales with how boosted you are; recovery is a
    // steady rate from the recovery stat. the net is applied clamped to
    // [0, max stamina]
    final drainPerSecond =
        ActionTimingService.staminaDrainPerBoost * (speed - 1);
    final recoveryPerSecond = _playerDataService.staminaRecoveryPerSecond(
      playerState,
    );
    final wasBelowMax =
        playerState.stamina < _playerDataService.getMaxStamina(playerState);

    _playerDataService.changeStamina(
      (recoveryPerSecond - drainPerSecond) * dt,
      playerState,
    );

    // xp: speed trains while boosting, stamina trains while draining,
    // recovery trains while it has something to restore
    if (speed > 1) {
      _playerDataService.applyXp(playerState, {
        SkillId.SPEED: (speed - 1) * 100 * dt,
        SkillId.STAMINA: 10 * dt,
      });
    }

    if (wasBelowMax && recoveryPerSecond > 0) {
      _playerDataService.applyXp(playerState, {SkillId.RECOVERY: 10 * dt});
    }
  }
}

class ActionTimingService {
  /// Stamina drained per second per point of boost (speed above 1x).
  static const double staminaDrainPerBoost = 1.0;

  /// The boost ceiling granted by the speed stat.
  double maxSpeedForStat(int speedStat) {
    return 2.0 + 0.1 * speedStat;
  }

  void updateActionSpeed(
    double dt,
    ActionTimingData actionTimingState,
    PlayerData playerState,
  ) {
    final hasStamina = playerState.stamina > 0;

    // a locked speed holds steady, but running out of stamina always
    // forces the boost to fall off
    if (actionTimingState.speedLocked && hasStamina) {
      return;
    }

    // momentum update
    if (!actionTimingState.speedLocked &&
        actionTimingState.buttonHeld &&
        hasStamina) {
      actionTimingState.speedPercent =
          (actionTimingState.speedPercent +
                  actionTimingState.accelPerSecond * dt)
              .clamp(0.0, 1.0);
    } else {
      actionTimingState.speedPercent =
          (actionTimingState.speedPercent -
                  actionTimingState.decelPerSecond * dt)
              .clamp(0.0, 1.0);
    }
  }

  void setLockActionSpeed(bool locked, ActionTimingData actionTimingState) {
    actionTimingState.speedLocked = locked;
  }

  void setPrimaryButtonHeld(bool held, ActionTimingData state) {
    state.buttonHeld = held;
  }

  void udpateActionProgress(double dt, ActionTimingData actionTimingState) {
    final intervalSec =
        getCurrentActionDuration(actionTimingState).inMicroseconds / 1e6;
    actionTimingState.actionProgress += dt / intervalSec;
  }

  double actionsPerSecond(ActionTimingData actionTimingState) {
    final intervalSec =
        getCurrentActionDuration(actionTimingState).inMicroseconds / 1e6;
    if (intervalSec == 0) return 0;
    return 1 / intervalSec;
  }

  /// Returns the current speed multiplier relative to the max interval.
  double getCurrentSpeedMultiplier(ActionTimingData actionTimingState) {
    return actionTimingState.speedPercent *
            (actionTimingState.maxSpeedMultiplier - 1) +
        1;
  }

  void stop(ActionTimingData actionTimingState) {
    actionTimingState.running = false;
    actionTimingState.actionProgress = 0.0;
    actionTimingState.speedPercent = 0.0;
    actionTimingState.buttonHeld = false;
    actionTimingState.lastElapsed = Duration.zero;
    actionTimingState.speedLocked = false;
    actionTimingState.activityIconId = null;
    actionTimingState.activityCount = null;
  }

  void start(ActionTimingData actionTimingState) {
    if (actionTimingState.running) return;
    actionTimingState.running = true;
    actionTimingState.lastElapsed = Duration.zero;
  }

  Duration getCurrentActionDuration(ActionTimingData actionTimingState) {
    final ms =
        actionTimingState.maxInterval.inMilliseconds /
        getCurrentSpeedMultiplier(actionTimingState);

    return Duration(milliseconds: ms.round());
  }

  void tryFire(ActionTimingData actionTimingState) {
    if (actionTimingState.actionInFlight) return;
    actionTimingState.actionInFlight = true;
    Future.sync(
      actionTimingState.onFire,
    ).whenComplete(() => actionTimingState.actionInFlight = false);
  }
}
