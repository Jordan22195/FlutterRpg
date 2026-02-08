import 'dart:async';

class IntervalRunner {
  Timer? _timer;

  void start(Duration interval, void Function() action) {
    _timer ??= Timer.periodic(interval, (_) => action());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
