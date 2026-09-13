import 'package:rpg/catalogs/zones/zone_id.dart';

/// The world map as a weighted graph: what moving on it costs, and how long
/// it takes.
///
/// This is the one genuinely behavioural half of the old `ZoneCatalog`: zone
/// *definitions* now hang off [ZoneId], but travel is a computation over the
/// edges between them, so it stays a service.
class ZoneTravelGraph {
  /// What one road costs to walk: the stamina it takes out of you, and how
  /// long it takes. Two independent numbers — a road can be long and easy or
  /// short and brutal — so neither is ever computed from the other. The times
  /// started life at half the stamina cost and are free to drift from there.
  static const Map<ZoneId, Map<ZoneId, TravelEdge>> _connections = {
    ZoneId.TUTORIAL_FARM: {
      ZoneId.SOUTHWOOD_FOREST: TravelEdge(
        stamina: 5,
        time: Duration(milliseconds: 2500),
      ),
    },
    ZoneId.SOUTHWOOD_FOREST: {
      ZoneId.TUTORIAL_FARM: TravelEdge(
        stamina: 5,
        time: Duration(milliseconds: 2500),
      ),
      ZoneId.SOUTH_HAVEN: TravelEdge(stamina: 10, time: Duration(seconds: 5)),
    },
    ZoneId.SOUTH_HAVEN: {
      ZoneId.SOUTHWOOD_FOREST: TravelEdge(
        stamina: 10,
        time: Duration(seconds: 5),
      ),
      ZoneId.FOREST_MINE: TravelEdge(
        stamina: 1,
        time: Duration(milliseconds: 500),
      ),
      ZoneId.DARKWOOD_FOREST: TravelEdge(
        stamina: 15,
        time: Duration(milliseconds: 7500),
      ),
      ZoneId.SWAMP: TravelEdge(stamina: 20, time: Duration(seconds: 10)),
    },
    ZoneId.FOREST_MINE: {
      ZoneId.SOUTH_HAVEN: TravelEdge(stamina: 10, time: Duration(seconds: 5)),
    },
    ZoneId.DARKWOOD_FOREST: {
      ZoneId.SOUTH_HAVEN: TravelEdge(
        stamina: 15,
        time: Duration(milliseconds: 7500),
      ),
    },
    ZoneId.SWAMP: {
      ZoneId.SOUTH_HAVEN: TravelEdge(stamina: 20, time: Duration(seconds: 10)),
      ZoneId.FOOTHILLS: TravelEdge(
        stamina: 25,
        time: Duration(milliseconds: 12500),
      ),
    },
    ZoneId.FOOTHILLS: {
      ZoneId.SWAMP: TravelEdge(
        stamina: 25,
        time: Duration(milliseconds: 12500),
      ),
    },
  };

  /// Unique travel edges (each bidirectional pair listed once), for
  /// drawing the path graph on the map.
  static List<(ZoneId, ZoneId, double)> travelEdges() {
    final seen = <String>{};
    final edges = <(ZoneId, ZoneId, double)>[];
    _connections.forEach((from, destinations) {
      destinations.forEach((to, edge) {
        final key = ([from.index, to.index]..sort()).join('-');
        if (seen.add(key)) {
          edges.add((from, to, edge.stamina));
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
    return _edge(from, to)?.stamina ?? double.infinity;
  }

  /// How long the single hop [from] -> [to] takes. Zero when the two aren't
  /// neighbours — every caller has already checked the road exists by
  /// pricing it, and a missing road is not a free one but no road at all.
  ///
  /// Directional with the same reverse fallback [edgeCost] uses, so a road
  /// recorded one way is never left untimed. Nothing here is derived from
  /// the stamina cost: the two are independent numbers on the edge.
  static Duration edgeTravelTime(ZoneId from, ZoneId to) {
    return _edge(from, to)?.time ?? Duration.zero;
  }

  /// The road between two neighbours, taken in the direction it is recorded
  /// and falling back to the reverse. Null when they aren't neighbours.
  static TravelEdge? _edge(ZoneId from, ZoneId to) {
    return _connections[from]?[to] ?? _connections[to]?[from];
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
        final total = currentCost + edge.value.stamina;
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
      total += _connections[path[i]]![path[i + 1]]!.stamina;
    }
    return total;
  }

  /// How long the trip from [from] to [to] takes, summing the time of each
  /// road along the route [travelCost] prices. The dev zones are entered and
  /// left instantly. Returns [Duration.zero] when no path exists.
  ///
  /// The route is chosen by stamina — [travelPath] is Dijkstra over cost —
  /// and the time is whatever that route happens to take. Now that the two
  /// numbers are independent, the cheapest road is not necessarily the
  /// quickest one, and this deliberately follows the cheapest.
  Duration travelTime(ZoneId from, ZoneId to) {
    if (from == to) return Duration.zero;
    if (isFreeZone(from) || isFreeZone(to)) return Duration.zero;

    final path = travelPath(from, to);
    if (path.length < 2) return Duration.zero;

    var total = Duration.zero;
    for (var i = 0; i < path.length - 1; i++) {
      total += _connections[path[i]]![path[i + 1]]!.time;
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

/// One road on the world map: what walking it takes out of you, and how long
/// it takes.
///
/// The two are recorded side by side rather than one being derived from the
/// other, because they are different facts about a road. The climb up from
/// the mine is expensive because it is steep, not because it is long.
class TravelEdge {
  const TravelEdge({required this.stamina, required this.time});

  /// Stamina spent walking this road, charged in full when the trip starts.
  final double stamina;

  /// How long walking it takes, before the speed stat and any boost cut it.
  final Duration time;
}
