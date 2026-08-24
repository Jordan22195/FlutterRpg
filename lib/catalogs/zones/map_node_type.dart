import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

/// What a place on the world map *is*, as opposed to what reaching it costs.
///
/// This is the map token's whole vocabulary: one glyph per type, so a player
/// can tell a town from a hunting ground from a boss lair at a glance without
/// reading a single label.
///
/// Distinct from [DungeonType], which describes how a dungeon is entered and
/// what leaving it costs. A dungeon can be a LANDMARK (keyed entry) and a
/// BOSS_LAIR (what it looks like) at the same time.
enum MapNodeType {
  /// Explore, fight, gather. The default for a zone.
  WILDERNESS(Icons.forest, 'WILDERNESS'),

  /// Shops and services; nothing to find by exploring.
  SETTLEMENT(Icons.holiday_village, 'SETTLEMENT'),

  /// A run of encounter cards.
  DUNGEON(Icons.door_front_door, 'DUNGEON'),

  /// A one-off encounter at the end of a run.
  BOSS_LAIR(Icons.local_fire_department, 'BOSS LAIR');

  const MapNodeType(this.glyph, this.label);

  /// The silhouette drawn inside the map token.
  final IconData glyph;

  /// The type name as the detail pane states it.
  final String label;
}
