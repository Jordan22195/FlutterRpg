import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'player_data_controller.dart';
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

class MomentumLoopController extends ChangeNotifier {
  MomentumLoopController({
    required TickerProvider vsync,
    required this.onFire,
    this.maxInterval = const Duration(seconds: 5),
    this.accelPerSecond = 0.25,
    this.decelPerSecond = 0.5,
  }) {
    _ticker = vsync.createTicker(_onTick);
  }

  FutureOr<void> Function() onFire;

  Duration maxInterval;

  double accelPerSecond;
  double decelPerSecond;

  late Ticker _ticker;
  bool speedLocked = false;

  bool _holding = false;
  bool _running = false;
  bool _actionInFlight = false;

  double _speedPercent = 0.0; // 0..1
  double _actionProgress = 0.0; // 0..1

  Duration _lastElapsed = Duration.zero;

  // Public read-only state
  bool get isHolding => _holding;
  bool get isRunning => _running;

  // updated in onTick
  double get percentMaxSpeed => _speedPercent; // momentum/speed bar
  double get actionProgress => _actionProgress; // action bar

  double get actionsPerSecond {
    final intervalSec = getCurrentActionDuration().inMicroseconds / 1e6;
    if (intervalSec == 0) return 0;
    return 1 / intervalSec;
  }

  /// Returns the current speed multiplier relative to the max interval.
  double getCurrentSpeedMultiplier() {
    return percentMaxSpeed * (getMaxSpeed() - 1) + 1;
  }

  void rebindVsync(TickerProvider vsync) {
    debugPrint("MomentumLoopController: rebindVsync called");
    final wasRunning = _running;

    // Stop old ticker
    _ticker.stop();
    _ticker.dispose();

    // Reset tick timing so dt doesn't explode
    _lastElapsed = Duration.zero;

    // Create new ticker bound to *current route’s* TickerMode
    _ticker = vsync.createTicker(_onTick);

    if (wasRunning) {
      _ticker.start();
    }

    notifyListeners();
  }

  void pressDown() {
    _holding = true;
    _startIfNeeded();
    notifyListeners();
  }

  void pressUp() {
    _holding = false;
    notifyListeners();
  }

  void cancel() {
    _holding = false;
    notifyListeners();
  }

  void stopNow() {
    _stopInternal(notify: true);
  }

  /// Stops the ticker and resets state WITHOUT notifying listeners.
  ///
  /// This is useful during widget disposal/unmount, where notifying can trigger
  /// AnimatedBuilder rebuilds while the framework is locked.
  void stopNowSilently() {
    _stopInternal(notify: false);
  }

  void _stopInternal({required bool notify}) {
    _ticker.stop();
    _running = false;
    _actionProgress = 0.0;
    _speedPercent = 0.0;
    _lastElapsed = Duration.zero;
    speedLocked = false;
    if (notify) notifyListeners();
  }

  void _startIfNeeded() {
    if (_running) return;
    _running = true;
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  double getMaxSpeed() {
    return 10.0;
    return 1 + (PlayerDataController.instance.getStatTotal(Skills.SPEED) * .1);
  }

  Duration getCurrentActionDuration() {
    final ms = maxInterval.inMilliseconds / getCurrentSpeedMultiplier();

    return Duration(milliseconds: ms.round());
  }

  // increase speed percent based on acceleration values
  // icriment action progress based on time elapsed and current action interval
  // if action progress is 100% fire the action
  // drain stamina and apply xp based on speed mulitplier
  void _onTick(Duration elapsed) {
    final dt = (_lastElapsed == Duration.zero)
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;

    if (dt <= 0) return;

    if (!speedLocked) {
      // momentum update
      if (_holding && PlayerDataController.instance.getStaminaPercent() > 0) {
        _speedPercent = (_speedPercent + accelPerSecond * dt).clamp(0.0, 1.0);
      } else {
        _speedPercent = (_speedPercent - decelPerSecond * dt).clamp(0.0, 1.0);
      }
    }

    // progress advance based on interval
    // icriment action progress based on time elapsed and current action interval
    final intervalSec = getCurrentActionDuration().inMicroseconds / 1e6;
    _actionProgress += dt / intervalSec;
    if (_actionProgress >= 1.0) {
      _actionProgress = _actionProgress % 1.0;
      _tryFire();
    }

    final speed = getCurrentSpeedMultiplier();
    final econLevel = PlayerDataController.instance.getStatTotal(
      Skills.ECONOMY,
    );
    final exploreLevel = PlayerDataController.instance.getStatTotal(
      Skills.EXPLORATION,
    );
    final sustainableSpeed = 1 + 0.05 * (econLevel - 1); // * (exploreLevel);

    double staminaCost = 0;
    if (speed > sustainableSpeed) {
      staminaCost = 1 * dt;
      // dt * k * (speed - sustainableSpeed);
    }
    PlayerDataController.instance.drainStamina(staminaCost.toDouble());
    if (speed > 1) {
      final staminaXp = dt * 10;
      SkillController.instance.addXp(Skills.STAMINA, staminaXp);
    }

    final speedXp = (speed - 1) * 100 * dt;
    SkillController.instance.addXp(Skills.SPEED, speedXp);

    if (staminaCost > 0) {
      final econXp = dt * 10.0;
      SkillController.instance.addXp(Skills.ECONOMY, econXp);
    }

    notifyListeners();
  }

  void _tryFire() {
    if (_actionInFlight) return;
    _actionInFlight = true;
    debugPrint(
      ": firing action with momentum ${_speedPercent.toStringAsFixed(2)} "
      "(${actionsPerSecond.toStringAsFixed(2)} actions/sec)",
    );
    Future.sync(onFire).whenComplete(() => _actionInFlight = false);
  }

  @override
  void dispose() {
    debugPrint("MomentumLoopController: dispose called");
    _ticker.dispose();
    super.dispose();
  }
}
