import '../catalogs/zone_catalog.dart';

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

      final zoneId = ZoneId.values.firstWhere(
        (z) => z.name == rawZoneId,
        orElse: () => throw FormatException('Invalid ZoneId "$rawZoneId".'),
      );

      zones[zoneId] = Zone.fromJson(rawZone);
    }

    return WorldData(zones: zones);
  }
}
