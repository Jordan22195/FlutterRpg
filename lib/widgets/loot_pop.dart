import 'package:flutter/material.dart';

/// Scales and fades a freshly won loot tile in, with a little overshoot,
/// a beat after the one before it. Every loot reveal — a chest opening, a
/// boss's drops on the floor summary — brings its tiles in on this one
/// timing, so a haul reads the same wherever it lands.
class LootPop extends StatelessWidget {
  const LootPop({
    super.key,
    required this.child,
    required this.order,
    this.animate = true,
  });

  final Widget child;

  /// Place in the reveal; each tile starts [step] after the one before.
  final int order;

  /// False shows [child] as it is, for a tile that was already there.
  final bool animate;

  /// How long one tile takes to pop in.
  static const Duration pop = Duration(milliseconds: 480);

  /// The beat between one tile starting and the next.
  static const Duration step = Duration(milliseconds: 180);

  /// Past this many tiles the rest come in together, so a big haul doesn't
  /// trickle on.
  static const int maxStaggered = 12;

  /// When the tile at [order] starts.
  static Duration delayFor(int order) => step * order.clamp(0, maxStaggered);

  @override
  Widget build(BuildContext context) {
    if (!animate) return child;
    final delay = delayFor(order);
    final total = pop + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      builder: (context, t, child) {
        final local =
            ((t * total.inMilliseconds - delay.inMilliseconds) /
                    pop.inMilliseconds)
                .clamp(0.0, 1.0);
        return Opacity(
          opacity: Curves.easeOut.transform(local),
          child: Transform.scale(
            scale: Curves.easeOutBack.transform(local),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
