import 'encounter_data.dart';
import 'inventory_data.dart';
import '../catalogs/dungeon_catalog.dart';

/// Live state of an in-progress dungeon run. Serialized with the save so a
/// run survives app close (resume in place). A deliberate leave is what
/// resets it — not closing the app.
///
/// The current fight reuses [EncounterData] so the live enemy (with its
/// hp/count) serializes for free and the existing combat services operate
/// on it directly. [loot] accumulates every drop across the whole run for
/// the run summary.
class DungeonRun {
  bool active;
  DungeonId dungeonId;

  /// Position within the dungeon's floors.
  int floorIndex;
  int packIndex;

  /// Highest floor fully cleared this run (-1 = none). Drives the in-run
  /// loop/continue choice for repeatable dungeons.
  int maxClearedFloor;

  /// Paused at a floor boundary waiting for the player's loop/continue
  /// choice (repeatable dungeons only).
  bool awaitingFloorChoice;

  /// The current pack's live enemy and its per-fight drop log.
  EncounterData fight;

  /// Every drop collected across the run.
  InventoryData loot;

  DungeonRun({
    this.active = false,
    this.dungeonId = DungeonId.NULL,
    this.floorIndex = 0,
    this.packIndex = 0,
    this.maxClearedFloor = -1,
    this.awaitingFloorChoice = false,
    EncounterData? fight,
    InventoryData? loot,
  }) : fight = fight ?? EncounterData(),
       loot = loot ?? InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'active': active,
      'dungeonId': dungeonId.name,
      'floorIndex': floorIndex,
      'packIndex': packIndex,
      'maxClearedFloor': maxClearedFloor,
      'awaitingFloorChoice': awaitingFloorChoice,
      'fight': fight.toJson(),
      'loot': loot.toJson(),
    };
  }

  factory DungeonRun.fromJson(Map<String, dynamic> json) {
    final rawDungeonId = json['dungeonId'];
    final dungeonId = rawDungeonId is String
        ? DungeonId.values.firstWhere(
            (d) => d.name == rawDungeonId,
            orElse: () => DungeonId.NULL,
          )
        : DungeonId.NULL;

    final rawFight = json['fight'];
    final rawLoot = json['loot'];

    return DungeonRun(
      active: json['active'] == true,
      dungeonId: dungeonId,
      floorIndex: json['floorIndex'] is int ? json['floorIndex'] as int : 0,
      packIndex: json['packIndex'] is int ? json['packIndex'] as int : 0,
      maxClearedFloor: json['maxClearedFloor'] is int
          ? json['maxClearedFloor'] as int
          : -1,
      awaitingFloorChoice: json['awaitingFloorChoice'] == true,
      fight: rawFight is Map<String, dynamic>
          ? EncounterData.fromJson(rawFight)
          : EncounterData(),
      loot: rawLoot is Map<String, dynamic>
          ? InventoryData.fromJson(rawLoot)
          : InventoryData(itemMap: {}),
    );
  }
}
