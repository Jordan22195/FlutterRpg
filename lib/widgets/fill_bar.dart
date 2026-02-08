import 'package:flutter/material.dart';

class FillBar extends StatelessWidget {
  const FillBar({
    super.key,
    required this.value, // 0..1
    this.height = 6,
    this.borderRadius = 999,

    // Optional overrides
    this.backgroundColor,
    this.foregroundColor,
  });

  final double value;
  final double height;
  final double borderRadius;

  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;

    final bg = backgroundColor ?? scheme.onSurface.withOpacity(0.12);

    final fg = foregroundColor ?? scheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fillWidth = constraints.maxWidth * v;

            return Stack(
              children: [
                Positioned.fill(child: ColoredBox(color: bg)),
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: fillWidth,
                  child: ColoredBox(color: fg),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
