import 'package:rpg/catalogs/zones/zone_id.dart';

/// The world map as a weighted graph, and the stamina cost of moving on it.
///
/// This is the one genuinely behavioural half of the old `ZoneCatalog`: zone
/// *definitions* now hang off [ZoneId], but travel is a computation over the
/// edges between them, so it stays a service.
class ZoneTravelGraph {
  // travel edges with stamina costs; the world map is a path/tree.
  // farm <-5-> forest <-1-> mine
  static const Map<ZoneId, Map<ZoneId, double>> _connections = {
    ZoneId.TUTORIAL_FARM: {ZoneId.SOUTHWOOD_FOREST: 5},
    ZoneId.SOUTHWOOD_FOREST: {ZoneId.TUTORIAL_FARM: 5, ZoneId.SOUTH_HAVEN: 10},
    ZoneId.SOUTH_HAVEN: {ZoneId.SOUTHWOOD_FOREST: 10, ZoneId.FOREST_MINE: 1},
    ZoneId.FOREST_MINE: {ZoneId.SOUTH_HAVEN: 10},
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

  /// Zones outside the travel graph, reachable from anywhere at no cost.
  static const Set<ZoneId> _devZones = {
    ZoneId.DEV_FOREST,
    ZoneId.DEV_DUNGEON_TESTING,
  };

  /// Total stamina cost to travel from [from] to [to], summing the edge
  /// costs along the path. The dev zones are always free to enter and
  /// leave. Returns [double.infinity] when no path exists.
  double travelCost(ZoneId from, ZoneId to) {
    if (from == to) return 0;
    if (_devZones.contains(from) || _devZones.contains(to)) return 0;

    final visited = <ZoneId>{from};
    final queue = <(ZoneId, double)>[(from, 0)];
    while (queue.isNotEmpty) {
      final (zone, costSoFar) = queue.removeAt(0);
      for (final edge in (_connections[zone] ?? const {}).entries) {
        if (!visited.add(edge.key)) continue;
        final total = costSoFar + edge.value;
        if (edge.key == to) return total;
        queue.add((edge.key, total));
      }
    }
    return double.infinity;
  }
}
