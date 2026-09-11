import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/dungeons/dungeon_type.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/dungeons/definition/dungeon_entry.dart';
import 'package:rpg/catalogs/dungeons/definition/dungeon_definition.dart';

// ignore_for_file: constant_identifier_names

/// Every dungeon in the game, and its definition.
///
/// Grouped by [DungeonType] — landmarks, then zone dungeons, then transient
/// ones — and within a group by required level. Dev content goes last.
///
/// A dungeon must never list its own entrance entity in [DungeonDefinition
/// .entries]: entity and dungeon definitions are `const` and reference each
/// other, and a cycle between two constants is a compile error.
///
/// The enum *value names* are the save format, so they must never be renamed.
enum DungeonId {
  // ── SENTINEL ────────────────────────────────────────────────────
  NULL(
    DungeonDefinition(
      name: "Nowhere",
      iconAsset: "",
      type: DungeonType.TRANSIENT,
      entries: [],
    ),
  ),
  // ── LANDMARKS · their own destination on the world map ──────────
  GOBLIN_QUEEN_LAIR(
    DungeonDefinition(
      name: "Goblin Queen's Lair",
      iconAsset: "assets/images/dungeons/goblin_queen_lair.png",
      type: DungeonType.LANDMARK,
      mapNodeType: MapNodeType.BOSS_LAIR,
      keyItemId: ItemId.GOBLIN_QUEEN_KEY,
      entries: [
        DungeonEntry(
          name: "Warren Entrance",
          entities: [DungeonEntityRef(EntityId.GOBLIN, count: 5)],
        ),
        DungeonEntry(
          name: "Deep Warren",
          entities: [
            DungeonEntityRef(EntityId.GOBLIN, count: 4),
            DungeonEntityRef(EntityId.GIANT_SPIDER, count: 2),
          ],
        ),
        DungeonEntry(
          name: "Queen's Chamber",
          entities: [
            DungeonEntityRef(EntityId.GOBLIN, count: 2),
            DungeonEntityRef(EntityId.GOBLIN_QUEEN),
          ],
        ),
      ],
    ),
  ),
  // ── ZONE DUNGEONS · a permanent entrance inside a zone ──────────
  SPIDER_DEN(
    DungeonDefinition(
      name: "Spider Den",
      iconAsset: "assets/images/dungeons/spider_den.png",
      type: DungeonType.ZONE,
      entries: [
        DungeonEntry(
          name: "Webbed Thicket",
          entities: [
            DungeonEntityRef(EntityId.GIANT_SPIDER, count: 10),
            DungeonEntityRef(EntityId.GIANT_SPIDER_UNCOMMON, count: 10),
            DungeonEntityRef(EntityId.ZOMBIE_UNCOMMON, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Broodmother's Lair",
          entities: [
            DungeonEntityRef(EntityId.GIANT_SPIDER_UNCOMMON, count: 15),
            DungeonEntityRef(EntityId.ZOMBIE_UNCOMMON, count: 6),
            DungeonEntityRef(EntityId.SPIDER_BROODMOTHER),
          ],
        ),
      ],
    ),
  ),
  GRAINERY(
    DungeonDefinition(
      name: "Grainery",
      iconAsset: "assets/images/dungeons/grainery.png",
      type: DungeonType.ZONE,
      entries: [
        DungeonEntry(
          name: "Feed Room",
          entities: [
            DungeonEntityRef(EntityId.FIELD_RAT, count: 5),
            DungeonEntityRef(EntityId.CHICKEN, count: 5),
            DungeonEntityRef(EntityId.BIG_RED, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Stalls",
          entities: [
            DungeonEntityRef(EntityId.COW, count: 10),
            DungeonEntityRef(EntityId.COW_UNCOMMON, count: 1),
          ],
        ),
        DungeonEntry(
          name: "Cellar",
          entities: [
            DungeonEntityRef(EntityId.ROTWOOD_SCARECROW, count: 10),
            DungeonEntityRef(EntityId.ROTWOOD_SCARECROW_UNCOMMON, count: 1),
          ],
        ),
      ],
    ),
  ),
  WOLF_DEN(
    DungeonDefinition(
      name: "Wolf Den",
      iconAsset: "assets/images/dungeons/wolf_den.png",
      type: DungeonType.ZONE,
      entries: [
        DungeonEntry(
          name: "Cave Entrance",
          entities: [
            DungeonEntityRef(EntityId.GOBLIN, count: 20),
            DungeonEntityRef(EntityId.GOBLIN_UNCOMMON, count: 10),
            DungeonEntityRef(EntityId.GOBLIN_RARE, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Deep Lair",
          entities: [
            DungeonEntityRef(EntityId.FOREST_WOLF, count: 20),
            DungeonEntityRef(EntityId.FOREST_WOLF_UNCOMMON, count: 10),
            DungeonEntityRef(EntityId.FOREST_WOLF_RARE, count: 10),
          ],
        ),
      ],
    ),
  ),
  // ── TRANSIENT · a discovered entrance, consumed on completion ───
  GOBLIN_CAMP(
    DungeonDefinition(
      name: "Goblin Camp",
      iconAsset: "assets/images/dungeons/goblin_camp.png",
      type: DungeonType.TRANSIENT,
      entries: [
        DungeonEntry(
          name: "Camp",
          entities: [
            DungeonEntityRef(EntityId.GOBLIN, count: 5),
            DungeonEntityRef(EntityId.GOBLIN_SCOUT, count: 3),
            DungeonEntityRef(EntityId.GOBLIN_SEARGENT, count: 1),
          ],
        ),
      ],
    ),
  ),
  // ── DEV ─────────────────────────────────────────────────────────
  DEV_TRANSIENT_DUNGEON(
    DungeonDefinition(
      name: "Dev Transient Dungeon",
      iconAsset: "assets/images/entities/spider_den.png",
      type: DungeonType.TRANSIENT,
      entries: [
        DungeonEntry(
          name: "Test Queue",
          entities: [
            DungeonEntityRef(EntityId.GOBLIN, count: 3),
            DungeonEntityRef(EntityId.GIANT_SPIDER),
          ],
        ),
        DungeonEntry(
          name: "Test Skippable Ore",
          entities: [DungeonEntityRef(EntityId.IRON, count: 10)],
          requiresPrevious: false,
        ),
        // deliberately the same EntityId as the first card: this is the
        // case that breaks resolving the live entity by id
        DungeonEntry(
          name: "Test Duplicate",
          entities: [DungeonEntityRef(EntityId.GOBLIN, count: 3)],
        ),
        DungeonEntry(
          name: "Test Boss",
          entities: [DungeonEntityRef(EntityId.SPIDER_BROODMOTHER)],
        ),
      ],
    ),
  );

  const DungeonId(this.definition);

  /// The design-time template for this dungeon. Never mutate it.
  final DungeonDefinition definition;

  /// False only for [NULL], the "no dungeon" sentinel. It carries an empty
  /// placeholder definition so [definition] can be non-nullable; nothing
  /// should treat it as a place you can enter.
  bool get isReal => this != NULL;

  String get iconAsset => definition.iconAsset;

  /// Icon lookup for [EnumImageProviderLookup], which keys on the id's Type
  /// and so hands back a `dynamic`.
  static ImageProvider? providerFor(dynamic id) {
    if (id is! DungeonId) return null;
    final asset = id.iconAsset;
    return asset.isEmpty ? null : AssetImage(asset);
  }

  /// The dungeons shown on the world map as their own destination, as
  /// opposed to those entered from inside a zone.
  static List<DungeonId> get landmarks => values
      .where((d) => d != NULL && d.definition.type == DungeonType.LANDMARK)
      .toList();
}
