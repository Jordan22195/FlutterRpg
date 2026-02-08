import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

class MomentumLoopController extends ChangeNotifier {
  MomentumLoopController({
    required TickerProvider vsync,
    required this.onFire,
    this.maxInterval = const Duration(seconds: 2),
    this.minInterval = const Duration(seconds: 1),
    this.accelPerSecond = 0.5,
    this.decelPerSecond = 0.6,
    this.autocontinueThreshold = 0.25,
  }) {
    _ticker = vsync.createTicker(_onTick);
  }

  FutureOr<void> Function() onFire;

  Duration maxInterval;
  Duration minInterval;

  double accelPerSecond;
  double decelPerSecond;
  final double autocontinueThreshold;

  late Ticker _ticker;

  bool _holding = false;
  bool _running = false;
  bool _actionInFlight = false;

  double _momentum = 0.0; // 0..1
  double _progress = 0.0; // 0..1

  Duration _lastElapsed = Duration.zero;

  // Public read-only state
  bool get isHolding => _holding;
  bool get isRunning => _running;

  double get speed => _momentum; // momentum/speed bar
  double get actionProgress => _progress; // action bar

  Duration get currentInterval => _lerpInterval(_momentum);
  void rebindVsync(TickerProvider vsync) {
    print("MomentumLoopController: rebindVsync called");
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
    _progress = 0.0;
    _momentum = 0.0;
    _lastElapsed = Duration.zero;
    if (notify) notifyListeners();
  }

  void _startIfNeeded() {
    if (_running) return;
    _running = true;
    if (_momentum == 0.0) _momentum = 0.08; // nudge for responsiveness
    _lastElapsed = Duration.zero;
    _ticker.start();
  }

  Duration _lerpInterval(double t) {
    final maxMs = maxInterval.inMilliseconds.toDouble();
    final minMs = minInterval.inMilliseconds.toDouble();
    final ms = maxMs + (minMs - maxMs) * t;
    return Duration(
      milliseconds: ms.round().clamp(
        minInterval.inMilliseconds,
        maxInterval.inMilliseconds,
      ),
    );
  }

  void _onTick(Duration elapsed) {
    final dt = (_lastElapsed == Duration.zero)
        ? 0.0
        : (elapsed - _lastElapsed).inMicroseconds / 1e6;
    _lastElapsed = elapsed;

    if (dt <= 0) return;

    // momentum update
    if (_holding) {
      _momentum = (_momentum + accelPerSecond * dt).clamp(0.0, 1.0);
    } else {
      _momentum = (_momentum - decelPerSecond * dt).clamp(0.0, 1.0);
    }

    final shouldAutoContinue = _momentum >= autocontinueThreshold;

    // if not holding and no momentum, stop at cycle boundary
    if (!_holding && !shouldAutoContinue && _progress <= 0.0001) {
      stopNow();
      return;
    }

    // progress advance based on interval
    final intervalSec = currentInterval.inMicroseconds / 1e6;
    _progress += dt / intervalSec;

    if (_progress >= 1.0) {
      _progress = _progress % 1.0;
      _tryFire();
    }

    notifyListeners();
  }

  void _tryFire() {
    if (_actionInFlight) return;
    _actionInFlight = true;
    print(
      this.hashCode.toString() +
          ": firing action with momentum ${_momentum.toStringAsFixed(2)}",
    );
    Future.sync(onFire).whenComplete(() => _actionInFlight = false);
  }

  @override
  void dispose() {
    print("MomentumLoopController: dispose called");
    _ticker.dispose();
    super.dispose();
  }
}
