import 'dart:async';
import 'package:flutter/material.dart';

/// Displays a simple countdown (expirationTime - now) with a clock icon.
///
/// This widget manages its own 1Hz tick so it can update the display without
/// requiring a Provider above it.
class CountdownTimer extends StatefulWidget {
  CountdownTimer({super.key, required this.expirationTime, this.size = 16});

  /// The time at which the countdown ends.
  final DateTime expirationTime;
  double size;

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
    double size = widget.size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule, size: size),
        SizedBox(width: 6),
        Text(remainingText, style: TextStyle(fontSize: size * 0.8)),
      ],
    );
  }

  static String _formatRemaining(Duration remaining) {
    if (remaining.isNegative || remaining.inMilliseconds <= 0) {
      return '0s';
    }

    if (remaining.isNegative) {
      return "0s";
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    final seconds = remaining.inSeconds % 60;

    if (hours > 0) {
      return "${hours}h";
    } else if (minutes > 0) {
      return "${minutes}m";
    } else {
      return "${seconds}s";
    }
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
