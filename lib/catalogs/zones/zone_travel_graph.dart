import 'package:rpg/catalogs/zones/zone_id.dart';

/// The world map as a weighted graph: how long moving on it takes.
///
/// This is the one genuinely behavioural half of the old `ZoneCatalog`: zone
/// *definitions* now hang off [ZoneId], but travel is a computation over the
/// edges between them, so it stays a service.
class ZoneTravelGraph {
  /// How long each road takes to walk, recorded per direction.
  static const Map<ZoneId, Map<ZoneId, TravelEdge>> _connections = {
    ZoneId.TUTORIAL_FARM: {
      ZoneId.SOUTHWOOD_FOREST: TravelEdge(time: Duration(milliseconds: 2500)),
    },
    ZoneId.SOUTHWOOD_FOREST: {
      ZoneId.TUTORIAL_FARM: TravelEdge(time: Duration(milliseconds: 2500)),
      ZoneId.SOUTH_HAVEN: TravelEdge(time: Duration(seconds: 5)),
    },
    ZoneId.SOUTH_HAVEN: {
      ZoneId.SOUTHWOOD_FOREST: TravelEdge(time: Duration(seconds: 5)),
      ZoneId.FOREST_MINE: TravelEdge(time: Duration(milliseconds: 500)),
      ZoneId.DARKWOOD_FOREST: TravelEdge(time: Duration(milliseconds: 7500)),
      ZoneId.SWAMP: TravelEdge(time: Duration(seconds: 10)),
    },
    ZoneId.FOREST_MINE: {
      ZoneId.SOUTH_HAVEN: TravelEdge(time: Duration(seconds: 5)),
    },
    ZoneId.DARKWOOD_FOREST: {
      ZoneId.SOUTH_HAVEN: TravelEdge(time: Duration(milliseconds: 7500)),
    },
    ZoneId.SWAMP: {
      ZoneId.SOUTH_HAVEN: TravelEdge(time: Duration(seconds: 10)),
      ZoneId.FOOTHILLS: TravelEdge(time: Duration(milliseconds: 12500)),
      ZoneId.MAPLEWATER_LAKE: TravelEdge(time: Duration(seconds: 10)),
    },
    ZoneId.MAPLEWATER_LAKE: {
      ZoneId.SWAMP: TravelEdge(time: Duration(seconds: 10)),
    },
    ZoneId.FOOTHILLS: {
      ZoneId.SWAMP: TravelEdge(time: Duration(milliseconds: 12500)),
      ZoneId.COPPERDUST_FLATS: TravelEdge(time: Duration(seconds: 10)),
      ZoneId.IRON_GATE_CITY: TravelEdge(time: Duration(milliseconds: 7500)),
    },
    ZoneId.IRON_GATE_CITY: {
      ZoneId.FOOTHILLS: TravelEdge(time: Duration(milliseconds: 7500)),
      // the city sits just outside the hills: a short walk out of town
      ZoneId.IRONROOT_HILLS: TravelEdge(time: Duration(milliseconds: 2500)),
    },
    ZoneId.IRONROOT_HILLS: {
      ZoneId.IRON_GATE_CITY: TravelEdge(time: Duration(milliseconds: 2500)),
    },
    ZoneId.COPPERDUST_FLATS: {
      ZoneId.FOOTHILLS: TravelEdge(time: Duration(seconds: 10)),
      ZoneId.REDWALL_BLUFFS: TravelEdge(time: Duration(milliseconds: 7500)),
    },
    ZoneId.REDWALL_BLUFFS: {
      ZoneId.COPPERDUST_FLATS: TravelEdge(time: Duration(milliseconds: 7500)),
    },
  };

  /// Unique travel edges (each bidirectional pair listed once), for
  /// drawing the path graph on the map.
  static List<(ZoneId, ZoneId)> travelEdges() {
    final seen = <String>{};
    final edges = <(ZoneId, ZoneId)>[];
    _connections.forEach((from, destinations) {
      for (final to in destinations.keys) {
        final key = ([from.index, to.index]..sort()).join('-');
        if (seen.add(key)) edges.add((from, to));
      }
    });
    return edges;
  }

  /// How long the single hop [from] -> [to] takes. Zero when the two aren't
  /// neighbours — a missing road is not a free one but no road at all, and
  /// every caller has already checked the road exists.
  ///
  /// Directional on purpose. The times are recorded per direction and are
  /// not always symmetric — South Haven down to the mine is half a second,
  /// the climb back up is five — so the number a road is labelled with
  /// depends on which way you're about to walk it. Falls back to the reverse
  /// direction when only one is recorded, so a road is never left untimed.
  static Duration edgeTravelTime(ZoneId from, ZoneId to) {
    return _edge(from, to)?.time ?? Duration.zero;
  }

  /// The road between two neighbours, taken in the direction it is recorded
  /// and falling back to the reverse. Null when they aren't neighbours.
  static TravelEdge? _edge(ZoneId from, ZoneId to) {
    return _connections[from]?[to] ?? _connections[to]?[from];
  }

  /// Zones outside the travel graph, reachable from anywhere instantly.
  static const Set<ZoneId> _devZones = {
    ZoneId.DEV_FOREST,
    ZoneId.DEV_DUNGEON_TESTING,
  };

  /// Whether [zone] sits outside the travel graph and so is free to reach.
  static bool isFreeZone(ZoneId zone) => _devZones.contains(zone);

  /// The quickest route from [from] to [to], both ends included. A single
  /// element means you are already there; an empty list means unreachable.
  /// A dev zone is one free step from anywhere, so it resolves to `[from, to]`.
  ///
  /// Dijkstra rather than a breadth-first walk: the graph's roads take very
  /// different times (half a second vs five), so the route with the fewest
  /// hops is not always the quickest one.
  static List<ZoneId> travelPath(ZoneId from, ZoneId to) {
    if (from == to) return [from];
    if (isFreeZone(from) || isFreeZone(to)) return [from, to];

    final best = <ZoneId, int>{from: 0};
    final cameFrom = <ZoneId, ZoneId>{};
    final settled = <ZoneId>{};

    while (true) {
      // the graph is a handful of nodes, so a linear scan for the nearest
      // unsettled node is cheaper than maintaining a heap
      ZoneId? current;
      int? currentCost;
      best.forEach((zone, cost) {
        if (!settled.contains(zone) &&
            (currentCost == null || cost < currentCost!)) {
          current = zone;
          currentCost = cost;
        }
      });
      if (current == null) return const [];

      final zone = current!;
      if (zone == to) break;
      settled.add(zone);

      for (final edge in (_connections[zone] ?? const {}).entries) {
        final total = currentCost! + edge.value.time.inMicroseconds;
        final known = best[edge.key];
        if (known == null || total < known) {
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

  /// Whether there is any road at all from [from] to [to]. Being where you
  /// already are counts; the dev zones are reachable from everywhere.
  static bool isReachable(ZoneId from, ZoneId to) {
    return travelPath(from, to).isNotEmpty;
  }

  /// How long the trip from [from] to [to] takes, summing the time of each
  /// road along the quickest route. The dev zones are entered and left
  /// instantly. Returns [Duration.zero] when no path exists.
  ///
  /// Walking is free: the trip costs time, not stamina. Stamina only goes
  /// into a walk when the player boosts it, and that is charged by the
  /// boost as it runs, the same as for any other action.
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

  /// Hops between [from] and [to] along the quickest route; 0 when they are
  /// the same zone, -1 when unreachable.
  static int travelHops(ZoneId from, ZoneId to) {
    final path = travelPath(from, to);
    return path.isEmpty ? -1 : path.length - 1;
  }
}

/// One road on the world map: how long it takes to walk.
///
/// Walking a road costs nothing but the time. Stamina only goes into a walk
/// when the player boosts it, which the boost charges as it runs.
class TravelEdge {
  const TravelEdge({required this.time});

  /// How long walking it takes, before the speed stat and any boost cut it.
  final Duration time;
}
