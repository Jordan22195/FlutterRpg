import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// One road on the world map: where it runs and how long the hop takes.
class MapEdge {
  const MapEdge({
    required this.from,
    required this.to,
    required this.time,
    this.onRoute = false,
  });

  /// The end nearer the player. The time badge is biased away from it, so
  /// the badge clears this node's label rather than landing on it.
  final Offset from;
  final Offset to;

  /// How long walking the hop takes, before the speed stat and any boost
  /// cut it. Walking is free, so time is all a road is labelled with.
  final Duration time;

  /// Part of the quickest way from where the player stands to the picked
  /// place. Route roads are drawn solid gold, so picking a node shows the
  /// way there before you read a word of the pane.
  final bool onRoute;

  @override
  bool operator ==(Object other) =>
      other is MapEdge &&
      other.from == from &&
      other.to == to &&
      other.time == time &&
      other.onRoute == onRoute;

  @override
  int get hashCode => Object.hash(from, to, time, onRoute);
}

/// Draws the travel graph in the map's pixel style: a dashed track per
/// road with the hop's travel time on a small square plate, and the route
/// to the picked place drawn solid in gold.
///
/// Every ordinary road is the same weight and colour. Time is stated once,
/// as a number, and never encoded a second time in the stroke.
class MapEdgePainter extends CustomPainter {
  const MapEdgePainter({
    required this.edges,
    required this.lineColor,
    required this.badgeFill,
    this.textColor = const Color(0xFFF1E4C3),
    this.routeColor = const Color(0xFFF0C04A),
    this.outlineColor = const Color(0xFF0A0806),
  });

  static const double _dash = 6;
  static const double _gap = 4;

  final List<MapEdge> edges;
  final Color lineColor;
  final Color badgeFill;
  final Color textColor;
  final Color routeColor;
  final Color outlineColor;

  @override
  void paint(Canvas canvas, Size size) {
    // ordinary roads under the route, so the gold line is never cut by a
    // dashed one crossing it
    for (final edge in edges.where((e) => !e.onRoute)) {
      _dashed(canvas, edge.from, edge.to);
    }
    for (final edge in edges.where((e) => e.onRoute)) {
      canvas.drawLine(
        edge.from,
        edge.to,
        Paint()
          ..color = outlineColor
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.square,
      );
      canvas.drawLine(
        edge.from,
        edge.to,
        Paint()
          ..color = routeColor
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.square,
      );
    }
  }

  void _dashed(Canvas canvas, Offset from, Offset to) {
    final length = (to - from).distance;
    if (length == 0) return;
    final dir = (to - from) / length;
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.butt
      ..isAntiAlias = false;
    for (var d = 0.0; d < length; d += _dash + _gap) {
      final end = (d + _dash).clamp(0.0, length);
      canvas.drawLine(from + dir * d, from + dir * end, paint);
    }
  }

  @override
  bool shouldRepaint(MapEdgePainter oldDelegate) {
    // the screen rebuilds this list every frame, so compare by value:
    // an identity check here would repaint on every tick forever
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.badgeFill != badgeFill ||
        oldDelegate.textColor != textColor ||
        oldDelegate.routeColor != routeColor ||
        !listEquals(oldDelegate.edges, edges);
  }
}
