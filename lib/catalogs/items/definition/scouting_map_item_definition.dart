import 'package:rpg/catalogs/items/definition/item_definition.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';

/// A map that, used from the bag, discovers a zone's entities for the
/// player: [discoveries] finds' worth, rolled as the zone's own table
/// would roll them at the player's Exploration level, with none of the
/// exploring.
///
/// It names no zone itself. A definition is const and a zone's table holds
/// shop shelves that hold these maps, so a zone reference here would be a
/// const cycle; [ScoutingMaps] is where an id is matched to its zone.
class ScoutingMapItemDefinition extends ItemDefinition {
  /// How many finds one map rolls.
  static const int discoveries = 500;

  const ScoutingMapItemDefinition({
    required super.name,
    required super.value,
    super.description,
    super.iconAsset,
    super.quality,
  });

  @override
  ScoutingMapItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
  }) {
    return ScoutingMapItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
    );
  }
}

/// Which zone each scouting map reveals.
class ScoutingMaps {
  ScoutingMaps._();

  static final Map<ItemId, ZoneId> _zones = {
    ItemId.SCOUTING_MAP_SOUTHWOOD_FOREST: ZoneId.SOUTHWOOD_FOREST,
    ItemId.SCOUTING_MAP_DARKWOOD_FOREST: ZoneId.DARKWOOD_FOREST,
    ItemId.SCOUTING_MAP_FOREST_MINE: ZoneId.FOREST_MINE,
    ItemId.SCOUTING_MAP_TUTORIAL_FARM: ZoneId.TUTORIAL_FARM,
    ItemId.SCOUTING_MAP_SWAMP: ZoneId.SWAMP,
    ItemId.SCOUTING_MAP_MAPLEWATER_LAKE: ZoneId.MAPLEWATER_LAKE,
  };

  /// Whether [id] is a scouting map.
  static bool isMap(ItemId id) => id.definition is ScoutingMapItemDefinition;

  /// The zone [id] reveals; null when it is not a map.
  static ZoneId? zoneFor(ItemId id) => _zones[id];
}
