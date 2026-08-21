import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';

class Zone {
  final ZoneId id;
  final String name;
  final List<Entity> permanentEntities;
  final List<Entity> discoveredEntities;

  /// Items turned up by the current explore session in this zone. Mirrors
  /// the encounter screen's session drops: the finds also go to the player
  /// inventory, and this list is session-scoped rather than saved.
  final InventoryData discoveredItems;

  Zone({
    required this.id,
    required this.name,
    required this.discoveredEntities,
    required this.permanentEntities,
    InventoryData? discoveredItems,
  }) : discoveredItems = discoveredItems ?? InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'id': id.name,
      'name': name,
      'permanentEntities': permanentEntities.map((e) => e.toJson()).toList(),
      'discoveredEntities': discoveredEntities.map((e) => e.toJson()).toList(),
    };
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawPermanent = json['permanentEntities'];
    final rawDiscovered = json['discoveredEntities'];

    if (rawId is! String) {
      throw FormatException('Missing or invalid "id". Expected String.');
    }

    if (rawName is! String) {
      throw FormatException('Missing or invalid "name". Expected String.');
    }

    if (rawPermanent is! List) {
      throw FormatException(
        'Missing or invalid "permanentEntities". Expected list.',
      );
    }

    if (rawDiscovered is! List) {
      throw FormatException(
        'Missing or invalid "discoveredEntities". Expected list.',
      );
    }

    final zoneId = ZoneId.values.firstWhere(
      (z) => z.name == rawId,
      orElse: () => throw FormatException('Invalid ZoneId "\$rawId".'),
    );

    //final permanentEntities = rawPermanent.map((e) {
    //  if (e is! Map<String, dynamic>) {
    //    throw FormatException('Invalid permanent entity entry.');
    //  }
    //  return Entity.fromJson(e);
    // }).toList();

    // entities the current content no longer defines are skipped rather than
    // rejecting the whole save. that is what lets an entity be retired — the
    // campfires that became fire buffs, for instance — without a bespoke
    // migration for every removal.
    final discoveredEntities = <Entity>[];
    for (final e in rawDiscovered) {
      if (e is! Map<String, dynamic>) {
        throw FormatException('Invalid discovered entity entry.');
      }
      try {
        discoveredEntities.add(Entity.fromJson(e));
      } on FormatException {
        continue;
      }
    }

    // discoveredItems is explore-session state, so it isn't saved: a
    // reloaded zone starts with an empty find list
    return Zone(
      id: zoneId,
      name: rawName,
      permanentEntities: [],
      discoveredEntities: discoveredEntities,
    );
  }
}
