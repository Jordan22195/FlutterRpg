import 'package:flutter/material.dart';

import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// A dashed, transparent box saying a list has nothing in it yet ("No loot
/// this session"), so an empty tab still has a shape.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.height = 76,
  });

  final String message;
  final IconData? icon;
  final double height;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final style = HearthText.rowMeta.copyWith(
      fontSize: 14,
      color: palette.textMuted,
    );

    return CustomPaint(
      painter: _DashedBorderPainter(color: palette.borderStrong, radius: 16),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: palette.textMuted),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(message, textAlign: TextAlign.center, style: style),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  static const double _dash = 6;
  static const double _gap = 4;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.5),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dash + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
