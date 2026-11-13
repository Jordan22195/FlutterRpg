import 'dart:async';
import 'package:flutter/material.dart';

/// Displays a simple countdown (expirationTime - now) with a clock icon.
///
/// This widget manages its own 1Hz tick so it can update the display without
/// requiring a Provider above it.
class CountdownTimer extends StatefulWidget {
  CountdownTimer({
    super.key,
    required this.expirationTime,
    this.size = 16,
    this.showIcon = true,
    this.clock = false,
  });

  /// The time at which the countdown ends.
  final DateTime expirationTime;
  double size;

  /// Drop the clock icon and show the remaining time alone. For corners too
  /// narrow to spare the width — an item tile has a count badge in the
  /// other one, and the two must not run into each other.
  final bool showIcon;

  /// Read as a running clock, "mm:ss", instead of the coarse unit. For a
  /// timer the player watches tick, like a fire burning down.
  final bool clock;

  /// "07:05": whole minutes and seconds left, rounded up so the clock reads
  /// 00:00 only once the time is actually out.
  static String formatClock(Duration remaining) {
    if (remaining.inMilliseconds <= 0) return '00:00';
    final total = (remaining.inMilliseconds / 1000).ceil();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(total ~/ 60)}:${two(total % 60)}';
  }

  /// "2h" / "6m" / "45s" - the coarse unit, the way the timer itself
  /// reads. Shared so a stretch of time that is not counting down yet can
  /// be written the same way beside one that is.
  static String formatDuration(Duration remaining) {
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
    final remainingText = widget.clock
        ? CountdownTimer.formatClock(remaining)
        : CountdownTimer.formatDuration(remaining);
    double size = widget.size;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showIcon) ...[
          Icon(Icons.schedule, size: size),
          SizedBox(width: 6),
        ],
        Text(
          remainingText,
          // even-width digits, so a ticking clock doesn't jitter the chip
          style: TextStyle(
            fontSize: size * 0.8,
            fontFeatures: widget.clock
                ? const [FontFeature.tabularFigures()]
                : null,
          ),
        ),
      ],
    );
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
