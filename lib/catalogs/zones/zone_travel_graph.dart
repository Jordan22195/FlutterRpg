import 'package:rpg/catalogs/zones/zone_id.dart';

/// The world map as a weighted graph, and the stamina cost of moving on it.
///
/// This is the one genuinely behavioural half of the old `ZoneCatalog`: zone
/// *definitions* now hang off [ZoneId], but travel is a computation over the
/// edges between them, so it stays a service.
class ZoneTravelGraph {
  // travel edges with stamina costs; the world map is a path/tree.
  // farm <-5-> forest <-10-> haven, and below the town the road forks:
  // haven <-15-> darkwood, haven -1-> mine (10 back up the hill)
  static const Map<ZoneId, Map<ZoneId, double>> _connections = {
    ZoneId.TUTORIAL_FARM: {ZoneId.SOUTHWOOD_FOREST: 5},
    ZoneId.SOUTHWOOD_FOREST: {ZoneId.TUTORIAL_FARM: 5, ZoneId.SOUTH_HAVEN: 10},
    ZoneId.SOUTH_HAVEN: {
      ZoneId.SOUTHWOOD_FOREST: 10,
      ZoneId.FOREST_MINE: 1,
      ZoneId.DARKWOOD_FOREST: 15,
    },
    ZoneId.FOREST_MINE: {ZoneId.SOUTH_HAVEN: 10},
    ZoneId.DARKWOOD_FOREST: {ZoneId.SOUTH_HAVEN: 15},
  };

  /// Unique travel edges (each bidirectional pair listed once), for
  /// drawing the path graph on the map.
  static List<(ZoneId, ZoneId, double)> travelEdges() {
    final seen = <String>{};
    final edges = <(ZoneId, ZoneId, double)>[];
    _connections.forEach((from, destinations) {
      destinations.forEach((to, cost) {
        final key = ([from.index, to.index]..sort()).join('-');
        if (seen.add(key)) {
          edges.add((from, to, cost));
        }
      });
    });
    return edges;
  }

  /// Stamina cost of walking the single hop [from] -> [to]. Returns
  /// [double.infinity] when the two aren't neighbours.
  ///
  /// Directional on purpose. The costs are recorded per direction and are
  /// not always symmetric — South Haven down to the mine is 1, the climb
  /// back up is 10 — so the number a road is labelled with depends on which
  /// way you're about to walk it. A badge that averaged the two, or took the
  /// cheaper, would lie to whoever is standing at the expensive end. Falls
  /// back to the reverse direction when only one is recorded, so a road is
  /// never left unlabelled.
  static double edgeCost(ZoneId from, ZoneId to) {
    final forward = _connections[from]?[to];
    if (forward != null) return forward;
    return _connections[to]?[from] ?? double.infinity;
  }

  /// Zones outside the travel graph, reachable from anywhere at no cost.
  static const Set<ZoneId> _devZones = {
    ZoneId.DEV_FOREST,
    ZoneId.DEV_DUNGEON_TESTING,
  };

  /// Whether [zone] sits outside the travel graph and so is free to reach.
  static bool isFreeZone(ZoneId zone) => _devZones.contains(zone);

  /// The cheapest route from [from] to [to], both ends included. A single
  /// element means you are already there; an empty list means unreachable.
  /// A dev zone is one free step from anywhere, so it resolves to `[from, to]`.
  ///
  /// Dijkstra rather than a breadth-first walk: the graph's edges have very
  /// different weights (1 vs 10 today), so the route with the fewest hops is
  /// not always the cheapest one, and travel charges by stamina, not by hops.
  static List<ZoneId> travelPath(ZoneId from, ZoneId to) {
    if (from == to) return [from];
    if (isFreeZone(from) || isFreeZone(to)) return [from, to];

    final best = <ZoneId, double>{from: 0};
    final cameFrom = <ZoneId, ZoneId>{};
    final settled = <ZoneId>{};

    while (true) {
      // the graph is a handful of nodes, so a linear scan for the nearest
      // unsettled node is cheaper than maintaining a heap
      ZoneId? current;
      var currentCost = double.infinity;
      best.forEach((zone, cost) {
        if (!settled.contains(zone) && cost < currentCost) {
          current = zone;
          currentCost = cost;
        }
      });
      if (current == null) return const [];

      final zone = current!;
      if (zone == to) break;
      settled.add(zone);

      for (final edge in (_connections[zone] ?? const {}).entries) {
        final total = currentCost + edge.value;
        if (total < (best[edge.key] ?? double.infinity)) {
          best[edge.key] = total;
          cameFrom[edge.key] = zone;
        }
      }
    }

    final path = <ZoneId>[to];
    var step = to;
    while (step != from) {
      step = cameFrom[step]!;
      path.insert(0, step);
    }
    return path;
  }

  /// Total stamina cost to travel from [from] to [to], summing the edge
  /// costs along the cheapest path. The dev zones are always free to enter
  /// and leave. Returns [double.infinity] when no path exists.
  double travelCost(ZoneId from, ZoneId to) {
    if (from == to) return 0;
    if (isFreeZone(from) || isFreeZone(to)) return 0;

    final path = travelPath(from, to);
    if (path.length < 2) return double.infinity;

    var total = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      total += _connections[path[i]]![path[i + 1]]!;
    }
    return total;
  }

  /// Hops between [from] and [to] along the cheapest route; 0 when they are
  /// the same zone, -1 when unreachable.
  static int travelHops(ZoneId from, ZoneId to) {
    final path = travelPath(from, to);
    return path.isEmpty ? -1 : path.length - 1;
  }
}
