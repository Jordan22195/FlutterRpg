import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg/utilities/interval_runner.dart';

/// A button that fires once on tap, then keeps firing on an interval for as
/// long as it's held — long-pressing "Buy", "Sell" or "Drink" repeats the
/// action instead of one tap per item. Past [_accelerateAfter] the interval
/// drops to [_fastRepeatInterval], so clearing out a big stack doesn't mean
/// sitting through it one press at a time.
///
/// [onPressed] is expected to be a safe no-op once whatever it spends runs
/// out — coins, stock, or the stack itself — so this does not re-check
/// affordability between repeats. Pass null to disable the button outright.
class RepeatPressButton extends StatefulWidget {
  const RepeatPressButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  State<RepeatPressButton> createState() => _RepeatPressButtonState();
}

class _RepeatPressButtonState extends State<RepeatPressButton> {
  static const _repeatInterval = Duration(milliseconds: 120);
  static const _fastRepeatInterval = Duration(milliseconds: 15);
  static const _accelerateAfter = Duration(seconds: 1);

  final _repeat = IntervalRunner();
  Timer? _accelerateTimer;

  void _startRepeating() {
    // the long press already stood in for the first tap, so fire once
    // immediately rather than waiting a full interval for the first one
    widget.onPressed?.call();
    _repeat.start(_repeatInterval, () => widget.onPressed?.call());
    _accelerateTimer = Timer(_accelerateAfter, () {
      _repeat.stop();
      _repeat.start(_fastRepeatInterval, () => widget.onPressed?.call());
    });
  }

  void _stopRepeating() {
    _repeat.stop();
    _accelerateTimer?.cancel();
    _accelerateTimer = null;
  }

  @override
  void dispose() {
    _stopRepeating();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: widget.onPressed == null
          ? null
          : (_) => _startRepeating(),
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: TextButton(onPressed: widget.onPressed, child: Text(widget.label)),
    );
  }
}
