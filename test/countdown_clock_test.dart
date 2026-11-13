import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/widgets/countdown_timer.dart';

void main() {
  test('the clock format reads mm:ss, rounding up to the next second', () {
    String f(Duration d) => CountdownTimer.formatClock(d);
    expect(f(const Duration(hours: 1)), '60:00');
    expect(f(const Duration(minutes: 7, seconds: 5)), '07:05');
    expect(f(const Duration(seconds: 59, milliseconds: 1)), '01:00');
    expect(f(const Duration(milliseconds: 300)), '00:01');
    expect(f(Duration.zero), '00:00');
    expect(f(const Duration(seconds: -3)), '00:00');
  });
}
