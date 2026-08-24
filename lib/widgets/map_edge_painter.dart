import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One road on the world map: where it runs, what the hop costs, and whether
/// the player can pay for it right now.
class MapEdge {
  const MapEdge({
    required this.from,
    required this.to,
    required this.cost,
    required this.affordable,
  });

  /// The end nearer the player. The cost badge is biased away from it, so
  /// the badge clears this node's label rather than landing on it.
  final Offset from;
  final Offset to;
  final double cost;

  /// Whether the player's stamina covers this hop *at this moment*. It is a
  /// fact about the player, not about the road, so it flips back as stamina
  /// recovers.
  final bool affordable;

  @override
  bool operator ==(Object other) =>
      other is MapEdge &&
      other.from == from &&
      other.to == to &&
      other.cost == cost &&
      other.affordable == affordable;

  @override
  int get hashCode => Object.hash(from, to, cost, affordable);
}

/// Draws the travel graph: one uniform line per road, with the hop's stamina
/// cost in a small pill along it.
///
/// Every road is drawn the same weight and the same colour. Cost is stated
/// once, as a number, and never encoded a second time in the stroke — the
/// only thing that changes an edge's appearance is the player not being able
/// to afford it, which turns the line and its badge red.
class MapEdgePainter extends CustomPainter {
  const MapEdgePainter({
    required this.edges,
    required this.lineColor,
    required this.badgeFill,
    required this.warningColor,
  });

  /// How far along the edge the badge sits, measured from the near end.
  /// Past the midpoint so it clears the near node's two-line label.
  static const double badgePosition = 0.62;

  static const double _badgeRadius = 10;

  final List<MapEdge> edges;
  final Color lineColor;
  final Color badgeFill;
  final Color warningColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final color = edge.affordable ? lineColor : warningColor;

      canvas.drawLine(
        edge.from,
        edge.to,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );

      final at = Offset.lerp(edge.from, edge.to, badgePosition)!;
      final text = TextPainter(
        text: TextSpan(
          text: edge.cost.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final width = (text.width + 12).clamp(_badgeRadius * 2, double.infinity);
      final pill = RRect.fromRectAndRadius(
        Rect.fromCenter(center: at, width: width, height: _badgeRadius * 2),
        const Radius.circular(_badgeRadius),
      );
      canvas.drawRRect(pill, Paint()..color = badgeFill);
      canvas.drawRRect(
        pill,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke,
      );
      text.paint(canvas, at - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(MapEdgePainter oldDelegate) {
    // the screen rebuilds this list every frame, so compare by value:
    // an identity check here would repaint on every tick forever
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.badgeFill != badgeFill ||
        oldDelegate.warningColor != warningColor ||
        !listEquals(oldDelegate.edges, edges);
  }
}
