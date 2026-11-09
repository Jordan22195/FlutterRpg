import '../catalogs/zones/zones.dart';

class WorldData {
  final Map<ZoneId, Zone> zones;

  WorldData({required this.zones});

  Map<String, dynamic> toJson() {
    return {
      'zones': zones.map(
        (zoneId, zone) => MapEntry(zoneId.name, zone.toJson()),
      ),
    };
  }

  factory WorldData.fromJson(Map<String, dynamic> json) {
    final rawZones = json['zones'];

    if (rawZones is! Map) {
      throw FormatException('Missing or invalid "zones". Expected object.');
    }

    final zones = <ZoneId, Zone>{};

    for (final entry in rawZones.entries) {
      final rawZoneId = entry.key;
      final rawZone = entry.value;

      if (rawZoneId is! String) {
        throw FormatException('Invalid zone id key. Expected String.');
      }

      if (rawZone is! Map<String, dynamic>) {
        throw FormatException('Invalid zone data for "$rawZoneId".');
      }

      // a zone the catalog no longer has is dropped, not thrown on: every
      // save carries an entry for every zone, so one retired or renamed-
      // without-an-alias zone would otherwise fail the whole load and the
      // bootstrap would start a new game over the player's save. a renamed
      // zone resolves through [ZoneId.renamed]; anything missing afterwards
      // is rebuilt from the catalog by GameSessionFactory.create
      final zoneId = ZoneId.byName(rawZoneId);
      if (zoneId == null) continue;

      final zone = Zone.fromJson({...rawZone, 'id': zoneId.name});
      zones[zoneId] = zone;
    }

    return WorldData(zones: zones);
  }
}
