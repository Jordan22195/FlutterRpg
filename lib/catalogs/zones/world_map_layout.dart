import 'dart:ui' show Offset, Size;

import 'package:rpg/catalogs/dungeons/dungeon_id.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';

/// Where each place sits on the world map, and what kind of place it is.
///
/// Positions are the map's own coordinate space, not screen pixels: the map
/// canvas lays this out at [kWorldMapSize] and then pans and zooms it, so a
/// node keeps its neighbours whatever the window is doing.
///
/// Spacing is a layout decision, not a scale: a 30-stamina hop is not drawn
/// three times as long as a 10-stamina one. Costs vary far too widely for
/// that to stay on screen. What the layout does owe you is room — every pair
/// of centres here is at least [kMinNodeSpacing] apart, so a token plus its
/// two-line label never lands on a neighbour.
const Size kWorldMapSize = Size(1320, 760);

/// Floor on centre-to-centre distance between any two nodes.
const double kMinNodeSpacing = 100;

/// A single place on the world map. Zones are travelled to and cost stamina;
/// landmarks are entered directly and are not on the travel graph.
sealed class MapNode {
  const MapNode(this.center);

  /// Centre of the node's token, in map space.
  final Offset center;

  String get name;
  MapNodeType get type;

  /// Stable identity for keys and selection, drawn from the enum name so it
  /// survives a relayout.
  String get key;
}

class ZoneNode extends MapNode {
  const ZoneNode(this.id, super.center);

  final ZoneId id;

  @override
  String get name => id.definition.name;

  @override
  MapNodeType get type => id.definition.type;

  @override
  String get key => 'map-node-${id.name}';
}

class LandmarkNode extends MapNode {
  const LandmarkNode(this.id, super.center);

  final DungeonId id;

  @override
  String get name => id.definition.name;

  @override
  MapNodeType get type => id.definition.mapNodeType;

  @override
  String get key => 'map-node-${id.name}';
}

/// Every node drawn on the world map, laid out roughly geographically:
/// the meadow in the north, the road running south through the forest to
/// South Haven, which forks below the town — south-west into the darkwood and on down to the hollow below it,
/// south-east down to the mine and its depths below — with the swamp on the wet ground east of
/// the town and the prairie rolling out beyond it to Iron Gate City,
/// at the foot of Ironroot Hills in the far east with the Ironroot Mine below them to the south-east, the fishing village on the lake's north-east shore with the yew and
/// magic groves up the slope north of the lake, the desert flats south of
/// the prairie with the bluffs beyond them, the two mountain ranges east
/// of the hills and the bluffs with Saddlegate in the pass between them
/// and the three peaks beyond (frost north, storm above the pass, lava
/// south), the goblin warren off to
/// the east of the road, and the dev zones parked well clear of the real
/// map.
const List<MapNode> kWorldMapNodes = [
  ZoneNode(ZoneId.TUTORIAL_FARM, Offset(200, 140)),
  LandmarkNode(DungeonId.GOBLIN_QUEEN_LAIR, Offset(320, 250)),
  ZoneNode(ZoneId.SOUTHWOOD_FOREST, Offset(150, 300)),
  ZoneNode(ZoneId.SOUTH_HAVEN, Offset(230, 460)),
  ZoneNode(ZoneId.DARKWOOD_FOREST, Offset(150, 620)),
  ZoneNode(ZoneId.MISTGRAVE_HOLLOW, Offset(240, 710)),
  ZoneNode(ZoneId.FOREST_MINE, Offset(390, 570)),
  ZoneNode(ZoneId.FOREST_MINE_DEPTHS, Offset(420, 690)),
  ZoneNode(ZoneId.SWAMP, Offset(430, 400)),
  ZoneNode(ZoneId.MAPLEWATER_LAKE, Offset(520, 330)),
  ZoneNode(ZoneId.MAPLEWATER_VILLAGE, Offset(620, 250)),
  ZoneNode(ZoneId.YEW_GROVE, Offset(480, 190)),
  ZoneNode(ZoneId.MAGIC_GROVE, Offset(560, 90)),
  ZoneNode(ZoneId.FOOTHILLS, Offset(620, 480)),
  ZoneNode(ZoneId.IRON_GATE_CITY, Offset(740, 500)),
  ZoneNode(ZoneId.IRONROOT_HILLS, Offset(860, 440)),
  ZoneNode(ZoneId.IRONROOT_MINE, Offset(900, 570)),
  ZoneNode(ZoneId.COPPERDUST_FLATS, Offset(620, 640)),
  ZoneNode(ZoneId.REDWALL_BLUFFS, Offset(780, 670)),
  ZoneNode(ZoneId.GREYSPINE_MOUNTAIN, Offset(1000, 330)),
  ZoneNode(ZoneId.SADDLEGATE, Offset(1040, 500)),
  ZoneNode(ZoneId.ASHRIDGE_MOUNTAINS, Offset(980, 680)),
  ZoneNode(ZoneId.FROSTCROWN_PEAKS, Offset(1180, 250)),
  ZoneNode(ZoneId.STORMCROWN_PEAKS, Offset(1220, 460)),
  ZoneNode(ZoneId.MOLTENSPIRE_PEAKS, Offset(1180, 680)),
  ZoneNode(ZoneId.DEV_FOREST, Offset(820, 140)),
  ZoneNode(ZoneId.DEV_DUNGEON_TESTING, Offset(820, 250)),
];

/// Map-space centre of [zone]'s token, or null when it isn't laid out.
Offset? zoneNodeCenter(ZoneId zone) {
  for (final node in kWorldMapNodes) {
    if (node is ZoneNode && node.id == zone) return node.center;
  }
  return null;
}
