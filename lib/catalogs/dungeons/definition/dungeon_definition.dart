import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/dungeons/dungeon_type.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/dungeons/definition/dungeon_entry.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

class DungeonDefinition {
  final String name;
  final String iconAsset;
  final DungeonType type;

  /// What this dungeon looks like on the world map, for the landmarks that
  /// get their own token there. Orthogonal to [type]: [DungeonType] is how
  /// you get in and what leaving costs, this is what the place is.
  final MapNodeType mapNodeType;

  /// Landmark dungeons consume this item the first time the first floor is
  /// started. NULL for free-entry (transient/zone) dungeons.
  final ItemId keyItemId;

  /// Optional soft/hard level gate, mirroring the zone gate convention.
  /// NULL/0 means no explicit requirement.
  final SkillId requiredSkill;
  final int requiredLevel;

  final List<DungeonEntry> entries;

  /// What the full-clear chest rolls, each roll on its own chance. Empty
  /// lets DungeonSystem build a stand-in from the floors' bosses.
  final List<DropRoll> chestRolls;

  const DungeonDefinition({
    required this.name,
    required this.iconAsset,
    required this.type,
    required this.entries,
    this.mapNodeType = MapNodeType.DUNGEON,
    this.keyItemId = ItemId.NULL,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
    this.chestRolls = const [],
  });

  /// Whether the first floor requires (and consumes) a key. Charged once,
  /// ever — after that the dungeon is open for good.
  bool get isKeyed => keyItemId != ItemId.NULL;

  /// Whether floor [index] is on the critical path: the first floor, and
  /// every floor chained behind another. A floor with `requiresPrevious:
  /// false` sits beside the path, and a full clear walks past it.
  bool isMainFloor(int index) =>
      index == 0 ||
      (index > 0 && index < entries.length && entries[index].requiresPrevious);

  /// The critical path's floors, top to bottom.
  List<int> get mainFloors => [
    for (int i = 0; i < entries.length; i++)
      if (isMainFloor(i)) i,
  ];

  /// The main floor below [index], or null when [index] is the last.
  int? nextMainFloor(int index) {
    for (int i = index + 1; i < entries.length; i++) {
      if (isMainFloor(i)) return i;
    }
    return null;
  }

  /// The main floor above [index] — the one a chained floor waits on — or
  /// null when [index] is the first.
  int? previousMainFloor(int index) {
    for (int i = index - 1; i >= 0; i--) {
      if (isMainFloor(i)) return i;
    }
    return null;
  }

  /// A variant of this definition. Definitions are `const` and shared, so a
  /// caller needing a tweaked dungeon builds a new value here.
  DungeonDefinition copyWith({
    String? name,
    String? iconAsset,
    DungeonType? type,
    MapNodeType? mapNodeType,
    List<DungeonEntry>? entries,
    ItemId? keyItemId,
    SkillId? requiredSkill,
    int? requiredLevel,
    List<DropRoll>? chestRolls,
  }) {
    return DungeonDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      type: type ?? this.type,
      mapNodeType: mapNodeType ?? this.mapNodeType,
      entries: entries ?? this.entries,
      keyItemId: keyItemId ?? this.keyItemId,
      requiredSkill: requiredSkill ?? this.requiredSkill,
      requiredLevel: requiredLevel ?? this.requiredLevel,
      chestRolls: chestRolls ?? this.chestRolls,
    );
  }
}
