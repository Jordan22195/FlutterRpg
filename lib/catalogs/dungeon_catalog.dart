import 'package:flutter/widgets.dart';

import 'entity_catalog.dart';
import 'item_catalog.dart';
import '../data/skill_data.dart';

enum DungeonId {
  NULL,
  GOBLIN_QUEEN_LAIR,
  SPIDER_DEN,
  GOBLIN_CAMP,
  DEV_TRANSIENT_DUNGEON,
}

/// How a dungeon is reached, and what leaving it costs. A dungeon is a list
/// of cards worked through in order; a run lives only while you stay in the
/// dungeon, and every type resets its run on leave.
/// - [TRANSIENT]: discovered while exploring; free; cards are one-shot.
///   Leaving consumes the entrance — the dungeon is gone from the zone.
/// - [ZONE]: a permanent entrance inside a zone; free; cards are
///   repeatable, so a cleared card can be re-tapped to farm it.
/// - [LANDMARK]: shown on the world map; the first card costs a key; cards
///   are one-shot. Leaving spends the run, so re-entry costs another key.
enum DungeonType { TRANSIENT, ZONE, LANDMARK }

/// One member of a card's queue: [count] copies of [entityId] worked back
/// to back. A card's boss is simply its final member.
class DungeonEntityRef {
  final EntityId entityId;
  final int count;

  const DungeonEntityRef(this.entityId, {this.count = 1});
}

/// One card in the dungeon list: an ordered queue of entities. Clearing
/// every member clears the card.
///
/// [requiresPrevious] gates the card behind the one above it, which is the
/// default march-down-the-floors behaviour. Set it false for a card that
/// sits beside the critical path — an ore vein you may mine or walk past.
class DungeonEntry {
  final String name;
  final List<DungeonEntityRef> entities;
  final bool requiresPrevious;

  const DungeonEntry({
    required this.name,
    required this.entities,
    this.requiresPrevious = true,
  });
}

class DungeonDefinition {
  final DungeonId id;
  final String name;
  final String iconAsset;
  final DungeonType type;

  /// Landmark dungeons consume this item to start the first card. NULL for
  /// free-entry (transient/zone) dungeons.
  final ItemId keyItemId;

  /// Optional soft/hard level gate, mirroring the zone gate convention.
  /// NULL/0 means no explicit requirement.
  final SkillId requiredSkill;
  final int requiredLevel;

  final List<DungeonEntry> entries;

  const DungeonDefinition({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.type,
    required this.entries,
    this.keyItemId = ItemId.NULL,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
  });

  /// Whether the first card requires (and consumes) a key.
  bool get isKeyed => keyItemId != ItemId.NULL;

  /// Whether a cleared card can be re-tapped to fight it again. Only the
  /// permanent zone dungeons farm; keyed and transient runs are one-shot.
  bool get repeatableEntries => type == DungeonType.ZONE;
}

class DungeonCatalog {
  final _defs = <DungeonId, DungeonDefinition>{
    // Landmark dungeon: the first card costs a Goblin Queen Key (5% goblin
    // drop), cards are one-shot, and leaving ends the run. Fight down
    // through goblin warrens to the Goblin Queen in her chamber.
    DungeonId.GOBLIN_QUEEN_LAIR: const DungeonDefinition(
      id: DungeonId.GOBLIN_QUEEN_LAIR,
      name: "Goblin Queen's Lair",
      iconAsset: "assets/images/dungeons/goblin_queen_lair.png",
      type: DungeonType.LANDMARK,
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

    DungeonId.GOBLIN_CAMP: const DungeonDefinition(
      id: DungeonId.GOBLIN_CAMP,
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
        DungeonEntry(
          name: "Campfire",
          entities: [DungeonEntityRef(EntityId.FIREPIT)],
        ),
      ],
    ),

    // Zone dungeon: a permanent entrance inside the forest. Free, and its
    // cards are repeatable — clear down to the Broodmother, then re-tap her
    // card to farm the Spider Silk Necklace. The iron seam is off the
    // critical path: mine it or walk past it.
    DungeonId.SPIDER_DEN: const DungeonDefinition(
      id: DungeonId.SPIDER_DEN,
      name: "Spider Den",
      iconAsset: "assets/images/dungeons/spider_den.png",
      type: DungeonType.ZONE,
      entries: [
        DungeonEntry(
          name: "Webbed Thicket",
          entities: [
            DungeonEntityRef(EntityId.GIANT_SPIDER, count: 10),
            DungeonEntityRef(EntityId.GOBLIN, count: 10),
            DungeonEntityRef(EntityId.BIG_RED, count: 15),
            DungeonEntityRef(EntityId.GEM_VEIN, count: 10),
            DungeonEntityRef(EntityId.COW, count: 15),
          ],
        ),
        DungeonEntry(
          name: "Collapsed Seam",
          entities: [DungeonEntityRef(EntityId.IRON, count: 8)],
          requiresPrevious: false,
        ),
        DungeonEntry(
          name: "Deep Nest",
          entities: [DungeonEntityRef(EntityId.GIANT_SPIDER, count: 5)],
        ),
        DungeonEntry(
          name: "Broodmother's Lair",
          entities: [
            DungeonEntityRef(EntityId.GIANT_SPIDER, count: 2),
            DungeonEntityRef(EntityId.SPIDER_BROODMOTHER),
          ],
        ),
      ],
    ),

    // Dev content. Exists to exercise the transient leave path (the
    // entrance is consumed on leave) and, in one place, every card feature:
    // a multi-member queue, a skippable non-combat card, a card repeating
    // an EntityId used earlier in the list, and a boss.
    DungeonId.DEV_TRANSIENT_DUNGEON: const DungeonDefinition(
      id: DungeonId.DEV_TRANSIENT_DUNGEON,
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
  };

  DungeonDefinition? getDefinitionFor(DungeonId id) => _defs[id];

  List<DungeonDefinition> get all => _defs.values.toList();

  /// Landmark dungeons, for placement on the world map.
  List<DungeonDefinition> get landmarks =>
      _defs.values.where((d) => d.type == DungeonType.LANDMARK).toList();

  // takes dynamic (not DungeonId) so the shared EnumImageProviderLookup,
  // which invokes resolvers through a Function(Enum) signature, can call it
  // without a covariance TypeError — matching EntityCatalog/SkillController
  String iconAssetFor(dynamic objectId) => _defs[objectId]?.iconAsset ?? "";

  ImageProvider? imageProviderFor(dynamic objectId) {
    final asset = iconAssetFor(objectId);
    return asset.isEmpty ? null : AssetImage(asset);
  }
}
