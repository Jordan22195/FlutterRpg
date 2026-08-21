import '../catalogs/dungeons/dungeons.dart';

/// Which screen the player was looking at, serialized with the save so a
/// force-closed app reopens where it left off. Only the map tab's nested
/// navigator is tracked (the other tabs restore to their roots): the
/// named routes above the map root are stored bottom-to-top. The dungeon
/// screen's id and card index ride along because, unlike the entity
/// screens, they can't be re-derived from the player's currentEntityViewId.
///
/// [dungeonAutoAdvance] is a preference rather than a position: it survives
/// leaving the dungeon, which the run state deliberately does not.
class UiState {
  int tabIndex;
  List<String> mapRouteStack;
  DungeonId dungeonId;

  /// Card index the dungeon's encounter route was showing, or -1.
  int dungeonSlot;

  /// Clearing a card runs straight into the next one instead of dropping
  /// back to the dungeon list.
  bool dungeonAutoAdvance;

  UiState({
    this.tabIndex = 0,
    List<String>? mapRouteStack,
    this.dungeonId = DungeonId.NULL,
    this.dungeonSlot = -1,
    this.dungeonAutoAdvance = false,
  }) : mapRouteStack = mapRouteStack ?? [];

  Map<String, dynamic> toJson() {
    return {
      'tabIndex': tabIndex,
      'mapRouteStack': mapRouteStack,
      'dungeonId': dungeonId.name,
      'dungeonSlot': dungeonSlot,
      'dungeonAutoAdvance': dungeonAutoAdvance,
    };
  }

  // ui state is cosmetic: anything malformed falls back to defaults
  // (open on the map tab) rather than failing the whole save load
  factory UiState.fromJson(Map<String, dynamic> json) {
    final rawStack = json['mapRouteStack'];
    final rawDungeonId = json['dungeonId'];
    final rawSlot = json['dungeonSlot'];

    return UiState(
      tabIndex: json['tabIndex'] is int ? json['tabIndex'] as int : 0,
      mapRouteStack: rawStack is List
          ? rawStack.whereType<String>().toList()
          : null,
      dungeonId: rawDungeonId is String
          ? DungeonId.values.firstWhere(
              (d) => d.name == rawDungeonId,
              orElse: () => DungeonId.NULL,
            )
          : DungeonId.NULL,
      dungeonSlot: rawSlot is int ? rawSlot : -1,
      dungeonAutoAdvance: json['dungeonAutoAdvance'] == true,
    );
  }
}
