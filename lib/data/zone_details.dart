import '../catalogs/zone_catalog.dart';

/// One row of a zone's discovery list: something an explore can turn up,
/// and what it takes to be able to turn it up. Covers both the entity and
/// the item table, so the zone detail screen renders them the same way.
class ZoneDiscovery {
  /// Display name of the entity or item.
  final String name;

  /// Icon path, or empty when the catalog has no art for it.
  final String iconAsset;

  /// Exploration level this discovery becomes available at; 0 means it is
  /// part of the zone's baseline.
  final int unlockLevel;

  /// Whether the player's exploration level currently reaches it.
  final bool locked;

  /// Share of the unlocked table this discovery accounts for (0..1). Zero
  /// while locked, since a locked entry contributes no weight.
  final double chance;

  /// Exploration xp for turning this up as an explore's first find. Zero
  /// for item finds, which grant no exploration xp.
  final double xp;

  /// Smallest and largest stack an entry yields, mirroring
  /// [EntityDropChance] so the same "1-10" formatting applies.
  final int minCount;
  final int maxCount;

  const ZoneDiscovery({
    required this.name,
    required this.iconAsset,
    required this.unlockLevel,
    required this.locked,
    required this.chance,
    required this.xp,
    required this.minCount,
    required this.maxCount,
  });

  bool get hasCountRange => maxCount > minCount;
}

/// Snapshot of everything the zone detail screen shows: the zone's gates,
/// the player's standing in it, and every discovery it holds — unlocked or
/// not. Built by [ExplorationSystem.buildZoneDetails].
class ZoneDetails {
  final ZoneDefinition zone;

  /// The player's Exploration level, gear and buffs included, matching the
  /// level the gates themselves are checked against.
  final int explorationLevel;

  /// Average things one explore turns up here right now. 1.00 at the
  /// zone's own level, climbing without a ceiling from there.
  final double findsPerExplore;

  /// Entities an explore can turn up, baseline entries first and then in
  /// unlock order.
  final List<ZoneDiscovery> entities;

  /// Items an explore can turn up, same ordering. The drop table's "found
  /// nothing" entry is left out.
  final List<ZoneDiscovery> items;

  const ZoneDetails({
    required this.zone,
    required this.explorationLevel,
    required this.findsPerExplore,
    required this.entities,
    required this.items,
  });

  /// Exploration levels this zone sits at; its baseline difficulty.
  int get zoneLevel => zone.explorationLevel;

  /// How far the player has outlevelled the zone. 0 at parity.
  int get levelsAboveZone {
    final over = explorationLevel - zoneLevel;
    return over < 0 ? 0 : over;
  }

  bool get hasDiscoveries => entities.isNotEmpty || items.isNotEmpty;

  /// Discoveries still ahead of the player, across both tables — what
  /// levelling Exploration here still has to offer.
  int get lockedCount =>
      entities.where((d) => d.locked).length +
      items.where((d) => d.locked).length;
}
