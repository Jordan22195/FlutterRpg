import 'package:flutter/material.dart';

import '../theme/hearth_theme.dart';

/// Flashes [child] in the accent when an explore turns up what it shows.
///
/// [sequence] counts finds; the flash plays when it moves while [hit] is
/// true. A tile that is built because of the find (a discovery's first
/// appearance) has no earlier sequence to compare, so it flashes if the find
/// ([foundAt]) was just now. Coming back to the screen later does not.
class FindFlash extends StatefulWidget {
  const FindFlash({
    super.key,
    required this.sequence,
    required this.hit,
    required this.foundAt,
    required this.child,
  });

  final int sequence;
  final bool hit;
  final DateTime? foundAt;
  final Widget child;

  /// How long a find stays fresh enough to flash a tile built after it.
  static const Duration freshFor = Duration(milliseconds: 800);
  static const Duration duration = Duration(milliseconds: 700);

  @override
  State<FindFlash> createState() => _FindFlashState();
}

class _FindFlashState extends State<FindFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: FindFlash.duration,
  );

  @override
  void initState() {
    super.initState();
    final at = widget.foundAt;
    if (widget.hit &&
        at != null &&
        DateTime.now().difference(at) < FindFlash.freshFor) {
      _controller.forward(from: 0);
    }
  }

  @override
  void didUpdateWidget(FindFlash old) {
    super.didUpdateWidget(old);
    if (widget.hit && widget.sequence != old.sequence) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.palette.accent;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                final t = _controller.value;
                // up fast, then fade: a flash, not a pulse
                final alpha = t == 0 || t == 1
                    ? 0.0
                    : 0.45 * (1 - Curves.easeOut.transform(t));
                return DecoratedBox(
                  key: const ValueKey('find-flash'),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: alpha),
                    borderRadius: BorderRadius.circular(16),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
