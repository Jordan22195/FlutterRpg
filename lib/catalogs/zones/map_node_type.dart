import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

/// The outline a map token is cut to. Shape carries the type before colour
/// does, so the three kinds of place read apart even for a player who can't
/// tell the colours apart.
enum MapNodeFrame {
  /// Wilderness: a diamond, the old "danger here" marker.
  DIAMOND,

  /// Town: a heraldic shield, the biggest token on the map.
  SHIELD,

  /// Skilling: a plain round token.
  ROUND,
}

/// What a place on the world map *is*, as opposed to what reaching it costs.
///
/// The map draws three kinds of place, each with its own pixel token:
/// [WILDERNESS], [TOWN] and [SKILLING]. Dungeons and boss lairs are
/// landmarks rather than zones; on the map they wear the wilderness diamond
/// (they're where the fighting is), and keep their own name in the detail
/// pane.
///
/// Distinct from [DungeonType], which describes how a dungeon is entered and
/// what leaving it costs. A dungeon can be a LANDMARK (keyed entry) and a
/// BOSS_LAIR (what it looks like) at the same time.
enum MapNodeType {
  /// Explore, fight, gather. The default for a zone.
  WILDERNESS(
    Icons.forest,
    'WILDERNESS',
    MapNodeFrame.DIAMOND,
    Color(0xFFE86A44),
    Color(0xFF8F3420),
  ),

  /// Shops, crafting stations and quests; nothing to find by exploring.
  TOWN(
    Icons.holiday_village,
    'TOWN',
    MapNodeFrame.SHIELD,
    Color(0xFFF0C04A),
    Color(0xFF946B16),
  ),

  /// A gathering spot: a mine, a grove, a lake. Nothing (or next to nothing)
  /// that fights back.
  SKILLING(
    Icons.hardware,
    'SKILLING',
    MapNodeFrame.ROUND,
    Color(0xFF5EC2E6),
    Color(0xFF2B6F8C),
  ),

  /// A run of encounter cards.
  DUNGEON(
    Icons.door_front_door,
    'DUNGEON',
    MapNodeFrame.DIAMOND,
    Color(0xFFE86A44),
    Color(0xFF8F3420),
  ),

  /// A one-off encounter at the end of a run.
  BOSS_LAIR(
    Icons.local_fire_department,
    'BOSS LAIR',
    MapNodeFrame.DIAMOND,
    Color(0xFFE86A44),
    Color(0xFF8F3420),
  );

  const MapNodeType(
    this.glyph,
    this.label,
    this.frame,
    this.color,
    this.shade,
  );

  /// A Material stand-in for the type, for places outside the map that
  /// don't draw the pixel token (discovery tiles and the like).
  final IconData glyph;

  /// The type name as the detail pane states it.
  final String label;

  /// The outline of this type's map token.
  final MapNodeFrame frame;

  /// The token's rim, the filter button's bar and the type label's colour.
  final Color color;

  /// The darker band just inside the rim.
  final Color shade;

  /// Which of the map's three kinds of place this counts as, for the filter
  /// rail and the token art. Dungeons and lairs count as wilderness.
  MapNodeType get group => switch (this) {
    MapNodeType.TOWN => MapNodeType.TOWN,
    MapNodeType.SKILLING => MapNodeType.SKILLING,
    _ => MapNodeType.WILDERNESS,
  };

  /// The three kinds the map draws, in the order the filter rail lists them.
  static const List<MapNodeType> mapGroups = [WILDERNESS, TOWN, SKILLING];
}
