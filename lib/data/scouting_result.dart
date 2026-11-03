import '../catalogs/entities/entities.dart';
import '../catalogs/zones/zones.dart';
import 'ObjectStack.dart';

/// What using a scouting map uncovered: the zone it covered and every
/// entity it turned up, merged by entity.
class ScoutingResult {
  final ZoneId zone;
  final List<ObjectStack<EntityId>> entities;

  const ScoutingResult({required this.zone, required this.entities});

  /// Nothing in the zone was there to be found.
  bool get isEmpty => entities.isEmpty;
}
