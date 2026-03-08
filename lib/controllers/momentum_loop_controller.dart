import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:rpg/data/player_data.dart';
import '../services/player_data_service.dart';
import '../data/skill.dart';
import 'dart:math';

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
  Duration maxInterval = Duration(seconds: 5);

  double accelPerSecond =
      0.25; // how quickly speed bar fills when button is held
  double decelPerSecond =
      .5; // how quickly speed bar empties when button is released
  double maxSpeedMultiplier =
      1.0; // min action interval = max action interval / maxSpeedMulitplier

  bool speedLocked =
      false; // speed will not change (unless out of stamina) when this is true.

  bool running = false;
  bool buttonHeld = false;
  bool actionInFlight = false;

  double speedPercent = 0.0; // 0 to 1 percentage of maximum speed.
  double actionProgress = 0.0; // 0 to 1 percentage of action progress

  Duration lastElapsed = Duration.zero;
}

//
//  Action Timing Controller
//



class ActionTimingController {
  // internal state
  final TickerProvider _vsync;
  late Ticker ticker;
  ActionTimingData _actionTimingState = ActionTimingData();

  // data
  PlayerData _playerState;

  // services
  ActionTimingService _actionTimingService;

  ActionTimingController({
    required TickerProvider vsync,

    required ActionTimingService actionTimingService,
    required PlayerData playerState,
  }) : _actionTimingService = actionTimingService,
       _playerState = playerState,
       _vsync = vsync

       {
    ticker = _vsync.createTicker(_onTick);

       }


  void bindOnFireFunction(FutureOr<void> Function() function) {
    _actionTimingState.onFire = function;
  }

  void start() {
    _actionTimingService.start(_actionTimingState);
    ticker.start();


  }

  void stop(){
    _actionTimingService.stop(_actionTimingState);
    ticker.stop();
  }

  // increase speed percent based on acceleration values
  // icriment action progress based on time elapsed and current action interval
  // if action progress is 100% fire the action
  // drain stamina and apply xp based on speed mulitplier
  void _onTick(Duration elapsed) {
    final dt = (_actionTimingState.lastElapsed == Duration.zero)
        ? 0.0
        : (elapsed - _actionTimingState.lastElapsed).inMicroseconds / 1e6;
    _actionTimingState.lastElapsed = elapsed;

    // return if no time has passed.
    if (dt <= 0) return;

    _actionTimingService.updateActionSpeed(
      dt,
      _actionTimingState,
      _playerState,
    );

    // icriment action progress based on time elapsed and current action interval
    _actionTimingService.udpateActionProgress(dt, _actionTimingState);

    // if action progress is > 100% try and fire the action and roll over the
    // progress percentage.
    if (_actionTimingState.actionProgress >= 1.0) {
      _actionTimingState.actionProgress =
          _actionTimingState.actionProgress % 1.0;
      _actionTimingService.tryFire(_actionTimingState);
    }

    final speed = _actionTimingService.getCurrentSpeedMultiplier();
    // todo : put this calculation somwhere
    final sustainableSpeed =
        1; // 1 + 0.05 * (economyStatTotal - 1)* specific skill stat total
    double staminaCost = 0;
    if (speed > sustainableSpeed) {
      staminaCost = 1 * dt;
      // dt * k * (speed - sustainableSpeed);
    }

    // drain stamina
    //playerService.drainStamina(staminaCost.toDouble());

    // calculate speed, stamina, and economy xp

    if (speed > 1) {
      final staminaXp = dt * 10;
      SkillController.instance.addXp(SkillId.STAMINA, staminaXp);
    }

    final speedXp = (speed - 1) * 100 * dt;

    if (staminaCost > 0) {
      final econXp = dt * 10.0;
    }

    // todo skill services apply xp
  }
}

//
//  Action Timing Service
//

class ActionTimingService {
  void updateActionSpeed(
    double dt,
    ActionTimingData actionTimingState,
    PlayerData playerState,
  ) {
    if (!actionTimingState.speedLocked) {
      // momentum update
      if (actionTimingState.buttonHeld && playerState.stamina > 0) {
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
  }

  void udpateActionProgress(double dt, ActionTimingData actionTimingState) {
    final intervalSec = getCurrentActionDuration(actionTimingState).inMicroseconds / 1e6;
    actionTimingState.actionProgress += dt / intervalSec;
  }

  double get actionsPerSecond(ActionTimingData actionTimingState) {
    final intervalSec = getCurrentActionDuration(actionTimingState).inMicroseconds / 1e6;
    if (intervalSec == 0) return 0;
    return 1 / intervalSec;
  }

  /// Returns the current speed multiplier relative to the max interval.
  double getCurrentSpeedMultiplier(ActionTimingData actionTimingState) {
    return actionTimingState.speedPercent * (getMaxSpeed() - 1) + 1;
  }

  void stop(ActionTimingData actionTimingState) {
    actionTimingState.running = false;
    actionTimingState.actionProgress = 0.0;
    actionTimingState.speedPercent = 0.0;
    actionTimingState.lastElapsed = Duration.zero;
    actionTimingState.speedLocked = false;
  }

  void start(ActionTimingData actionTimingState) {
    if (actionTimingState.running) return;
    actionTimingState.running = true;
    actionTimingState.lastElapsed = Duration.zero;
  }

  double getMaxSpeed() {
    return 10.0;
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
    debugPrint(
      ": firing action with momentum ${actionTimingState.speedPercent.toStringAsFixed(2)} "
      "(${actionsPerSecond.toStringAsFixed(2)} actions/sec)",
    );
    Future.sync(
      actionTimingState.onFire,
    ).whenComplete(() => actionTimingState.actionInFlight = false);
  }
}
