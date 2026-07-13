import '../catalogs/dungeon_catalog.dart';

/// Which screen the player was looking at, serialized with the save so a
/// force-closed app reopens where it left off. Only the map tab's nested
/// navigator is tracked (the other tabs restore to their roots): the
/// named routes above the map root are stored bottom-to-top. The dungeon
/// screen's id rides along because, unlike the entity screens, it can't
/// be re-derived from the player's currentEntityViewId.
class UiState {
  int tabIndex;
  List<String> mapRouteStack;
  DungeonId dungeonId;

  UiState({
    this.tabIndex = 0,
    List<String>? mapRouteStack,
    this.dungeonId = DungeonId.NULL,
  }) : mapRouteStack = mapRouteStack ?? [];

  Map<String, dynamic> toJson() {
    return {
      'tabIndex': tabIndex,
      'mapRouteStack': mapRouteStack,
      'dungeonId': dungeonId.name,
    };
  }

  // ui state is cosmetic: anything malformed falls back to defaults
  // (open on the map tab) rather than failing the whole save load
  factory UiState.fromJson(Map<String, dynamic> json) {
    final rawStack = json['mapRouteStack'];
    final rawDungeonId = json['dungeonId'];

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
    );
  }
}
