import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
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

  /// The gear this dungeon is farmed for, in the order its banner shows
  /// them: each boss's pieces floor by floor, any its trash carry, then the
  /// chest's own. Kept by hand beside the drop tables
  /// (design/DUNGEON_LOOT_GUIDE.md); catalog_integrity_test checks the two
  /// agree.
  final List<ItemId> uniques;

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
    this.uniques = const [],
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

  /// The rarities [id] drops at anywhere in this dungeon — off any of its
  /// monsters or out of its chest — lowest first. What a unique can be
  /// collected at, read from the drop tables so the two never disagree.
  List<Rarity> dropRaritiesOf(ItemId id) =>
      (_dropRarities[this] ??= _readDropRarities())[id] ?? const [];

  static final _dropRarities = Expando<Map<ItemId, List<Rarity>>>();

  Map<ItemId, List<Rarity>> _readDropRarities() {
    final found = <ItemId, Set<Rarity>>{};
    void take(Iterable<ItemDropType> lines) {
      for (final line in lines) {
        (found[line.id] ??= {}).add(line.rarity);
      }
    }

    for (final entry in entries) {
      for (final ref in entry.entities) {
        final def = ref.entityId.definition;
        if (def is! EncounterEntityDefinition) continue;
        take(def.itemDrops.flattened);
        for (final roll in def.bonusDrops) {
          take(roll.entries.flattened);
        }
      }
    }
    for (final roll in chestRolls) {
      take(roll.entries.flattened);
    }
    return {
      for (final MapEntry(key: id, value: rarities) in found.entries)
        id: rarities.toList()..sort((a, b) => a.index.compareTo(b.index)),
    };
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
    List<ItemId>? uniques,
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
      uniques: uniques ?? this.uniques,
    );
  }
}
