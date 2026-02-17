import 'dart:async';
import 'package:flutter/material.dart';

/// Displays a simple countdown (expirationTime - now) with a clock icon.
///
/// This widget manages its own 1Hz tick so it can update the display without
/// requiring a Provider above it.
class CountdownTimer extends StatefulWidget {
  const CountdownTimer({super.key, required this.expirationTime});

  /// The time at which the countdown ends.
  final DateTime expirationTime;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late final Ticker _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Ticker(
      onTick: () {
        if (mounted) setState(() {});
      },
    );
    _ticker.start();
  }

  @override
  void didUpdateWidget(covariant CountdownTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the expiration time changes, force an immediate refresh.
    if (oldWidget.expirationTime != widget.expirationTime) {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = widget.expirationTime.difference(now);

    final remainingText = _formatRemaining(remaining);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.schedule, size: 16),
        const SizedBox(width: 6),
        Text(remainingText, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  static String _formatRemaining(Duration remaining) {
    if (remaining.isNegative || remaining.inMilliseconds <= 0) {
      return '0s';
    }

    // Show as mm:ss under 1 hour, otherwise hh:mm:ss.
    final totalSeconds = remaining.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    String two(int v) => v.toString().padLeft(2, '0');

    if (hours > 0) {
      return '${two(hours)}:${two(minutes)}:${two(seconds)}';
    }
    return '${two(minutes)}:${two(seconds)}';
  }
}

/// Lightweight 1Hz ticker without requiring vsync.
class Ticker {
  Ticker({required this.onTick});

  final VoidCallback onTick;
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => onTick());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
