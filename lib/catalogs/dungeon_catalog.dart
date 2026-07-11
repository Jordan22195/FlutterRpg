import 'package:flutter/widgets.dart';

import 'entity_catalog.dart';
import 'item_catalog.dart';
import '../data/skill_data.dart';

enum DungeonId {
  NULL,
  GOBLIN_QUEEN_LAIR,
}

/// How a dungeon is reached and how it behaves on entry/exit.
/// - [TRANSIENT]: stumbled on while exploring; free entry; one-shot (not
///   repeatable); a guaranteed reward on the boss; does not expire.
/// - [ZONE]: a permanent entity inside a zone; free entry; floors are
///   repeatable for targeted grinding.
/// - [LANDMARK]: shown on the world map; entry consumes a key; not
///   repeatable; high reward.
enum DungeonType { TRANSIENT, ZONE, LANDMARK }

/// One group of enemies within a floor: [count] copies of [entityId]
/// fought back to back. The dungeon's boss is simply the final pack of
/// the final floor.
class DungeonPack {
  final EntityId entityId;
  final int count;

  const DungeonPack(this.entityId, {this.count = 1});
}

/// An ordered set of packs. Clearing every pack clears the floor. In a
/// repeatable dungeon, clearing a floor unlocks the in-run loop/continue
/// choice for that floor.
class DungeonFloor {
  final String name;
  final List<DungeonPack> packs;

  const DungeonFloor({required this.name, required this.packs});
}

class DungeonDefinition {
  final DungeonId id;
  final String name;
  final String iconAsset;
  final DungeonType type;

  /// Landmark dungeons consume this item on entry. NULL for free-entry
  /// (transient/zone) dungeons.
  final ItemId keyItemId;

  /// When true, clearing a floor offers the in-run loop/continue choice.
  /// Zone dungeons are repeatable; transient and landmark are not.
  final bool repeatable;

  /// Optional soft/hard level gate, mirroring the zone gate convention.
  /// NULL/0 means no explicit requirement.
  final SkillId requiredSkill;
  final int requiredLevel;

  final List<DungeonFloor> floors;

  const DungeonDefinition({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.type,
    required this.floors,
    this.keyItemId = ItemId.NULL,
    this.repeatable = false,
    this.requiredSkill = SkillId.NULL,
    this.requiredLevel = 0,
  });

  /// The boss entity: the final pack of the final floor.
  EntityId get bossEntityId => floors.last.packs.last.entityId;

  /// Whether entry requires (and consumes) a key.
  bool get isKeyed => keyItemId != ItemId.NULL;
}

class DungeonCatalog {
  final _defs = <DungeonId, DungeonDefinition>{
    // Landmark dungeon: keyed by the Goblin Queen Key (5% goblin drop),
    // not repeatable, high reward. Fight down through goblin warrens to
    // the Goblin Queen in her chamber.
    DungeonId.GOBLIN_QUEEN_LAIR: const DungeonDefinition(
      id: DungeonId.GOBLIN_QUEEN_LAIR,
      name: "Goblin Queen's Lair",
      iconAsset: "assets/images/dungeons/goblin_queen_lair.png",
      type: DungeonType.LANDMARK,
      keyItemId: ItemId.GOBLIN_QUEEN_KEY,
      repeatable: false,
      floors: [
        DungeonFloor(
          name: "Warren Entrance",
          packs: [DungeonPack(EntityId.GOBLIN, count: 5)],
        ),
        DungeonFloor(
          name: "Deep Warren",
          packs: [
            DungeonPack(EntityId.GOBLIN, count: 4),
            DungeonPack(EntityId.GIANT_SPIDER, count: 2),
          ],
        ),
        DungeonFloor(
          name: "Queen's Chamber",
          packs: [
            DungeonPack(EntityId.GOBLIN, count: 2),
            DungeonPack(EntityId.GOBLIN_QUEEN),
          ],
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
