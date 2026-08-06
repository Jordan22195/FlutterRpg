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
    return _actionTimingState.boostLocked;
  }

  double get percentMaxSpeed => _actionTimingState.percentOfMaxBoost;

  double get actionProgress => _actionTimingState.actionProgressPercentComplete;

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

  /// True while the primary button is held down and boosting the speed.
  bool get isButtonHeld => _actionTimingState.buttonHeld;

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

    // return if no time has passed.
    if (dt <= 0) return;

    // refresh the boost ceiling from the speed stat
    final stats = _playerDataService.getStatTotals(playerState);
    final skillBoost = playerState.skillBoost;
    if (skillBoost == SkillId.SPEED) {
      actionTimingState.boostingSpeed = true;
    } else {
      actionTimingState.boostingSpeed = false;
    }
    actionTimingState.maxBoostMultiplier = actionTimingState.boostingSpeed
        ? _actionTimingService.maxSpeedBoostForStat(stats[SkillId.SPEED] ?? 1)
        : _actionTimingService.maxStrengthBoostForStat(
            stats[SkillId.STRENGTH] ?? 1,
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
      _actionTimingService.tryFire(actionTimingState);
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
    // xp: speed trains while boosting, stamina trains while draining,
    // recovery trains while it has something to restore
    if (boostMulitplier > 1) {
      _playerDataService.applyXp(playerState, {
        actionTimingState.boostingSpeed ? SkillId.SPEED : SkillId.STRENGTH:
            boostMulitplier * 1 * dt,
        SkillId.STAMINA: 1 * dt,
      });
    }
  }
}

class ActionTimingService {
  /// Stamina drained per second per point of boost (speed above 1x).
  static const double staminaDrainPerBoost = 2.0;

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

  void tryFire(ActionTimingData actionTimingState) {
    if (actionTimingState.actionInFlight) return;
    actionTimingState.actionInFlight = true;
    Future.sync(
      actionTimingState.onFire,
    ).whenComplete(() => actionTimingState.actionInFlight = false);
  }
}
