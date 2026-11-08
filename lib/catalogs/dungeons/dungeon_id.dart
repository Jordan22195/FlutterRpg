import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/dungeons/dungeon_type.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/dungeons/definition/dungeon_entry.dart';
import 'package:rpg/catalogs/dungeons/definition/dungeon_definition.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

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
      // a bulk haul of everything the darkwood gives, a roll apiece, and the
      // bosses' pieces at rare on a long shot, the necklace at epic on a
      // longer one
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.WILLOW_LOGS, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.COAL, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.PIKE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.SALMON, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HARRALANDER, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.GRAVE_MOSS, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.SILK, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.VENOM, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.BAT_WING, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.BAT_FANG, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.ROTTEN_FLESH, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.WEBBED_CLOAK, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.VENOMFANG_RING, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.03,
          entries: [
            ItemDropType(id: ItemId.SPIDER_SILK_NECKLACE, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "Webbed Thicket",
          entities: [
            DungeonEntityRef(EntityId.GIANT_SPIDER_UNCOMMON, count: 12),
            DungeonEntityRef(EntityId.GIANT_BAT_UNCOMMON, count: 6),
            DungeonEntityRef(EntityId.THICKET_WEAVER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Cocoon Hollow",
          entities: [
            DungeonEntityRef(EntityId.GIANT_SPIDER_UNCOMMON, count: 10),
            DungeonEntityRef(EntityId.SKELETON_UNCOMMON, count: 8),
            DungeonEntityRef(EntityId.THICKET_ZOMBIE, count: 1),
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
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.LOGS, lowCount: 20, highCount: 50),
            ItemDropType(id: ItemId.COPPER_BAR, lowCount: 20, highCount: 50),

            ItemDropType(id: ItemId.IRON_ORE, lowCount: 20, highCount: 50),
            ItemDropType(id: ItemId.COPPER_ORE, lowCount: 20, highCount: 50),

            ItemDropType(
              id: ItemId.COOKED_CHICKEN,
              lowCount: 20,
              highCount: 50,
            ),
            ItemDropType(id: ItemId.COOKED_BEEF, lowCount: 20, highCount: 50),
            ItemDropType(id: ItemId.COPPER_SWORD, rarity: Rarity.UNCOMMON),
            ItemDropType(id: ItemId.COPPER_DAGGER, rarity: Rarity.UNCOMMON),
            ItemDropType(id: ItemId.COPPER_GREATSWORD, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
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
            DungeonEntityRef(EntityId.FIELD_RAT, count: 12),
            DungeonEntityRef(EntityId.COW, count: 10),
            DungeonEntityRef(EntityId.COW_BOSS, count: 1),
          ],
        ),
        DungeonEntry(
          name: "Cellar",
          entities: [
            DungeonEntityRef(EntityId.FIELD_RAT, count: 12),
            DungeonEntityRef(EntityId.ROTWOOD_SCARECROW, count: 8),
            DungeonEntityRef(EntityId.CHICKEN, count: 5),
            DungeonEntityRef(EntityId.ROTWOOD_SCARECROW_BOSS, count: 1),
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
      // a bulk haul of everything the forest gives, a roll apiece, and the
      // set's chest and legs on a rare chance, and now and then a rare
      // piece of any slot
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.LOGS, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.OAK_LOGS, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CRAYFISH, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.BLUEGILL, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.TROUT, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COOKED_CARP, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.COOKED_MINNOW, lowCount: 20, highCount: 80),
            ItemDropType(
              id: ItemId.COOKED_BLUEGILL,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.IRON_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.IRON_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.GUAM_LEAF, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MARRENTILL, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.TARROMIN, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.BEAR_CLAW, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.WOLF_CLAW, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.WOLF_PELT, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.BEAR_HIDE, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(chance: 0.1, entries: wolfDenMajorArmorDropTable),
        DropRoll(chance: 0.05, entries: wolfDenRareSetDropTable),
      ],
      entries: [
        DungeonEntry(
          name: "Cave Entrance",
          entities: [
            DungeonEntityRef(EntityId.GOBLIN_UNCOMMON, count: 15),
            DungeonEntityRef(EntityId.GOBLIN_RARE, count: 8),
            DungeonEntityRef(EntityId.CAVE_BEAR, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Deep Lair",
          entities: [
            DungeonEntityRef(EntityId.FOREST_WOLF_UNCOMMON, count: 10),
            DungeonEntityRef(EntityId.BEAR_UNCOMMON, count: 5),
            DungeonEntityRef(EntityId.DEN_ALPHA_WOLF, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Sunken Grotto",
          entities: [
            DungeonEntityRef(EntityId.GIANT_BAT, count: 5),
            DungeonEntityRef(EntityId.SLIME, count: 10),
            DungeonEntityRef(EntityId.GROTTO_FUNGAL_MONSTER, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Blackmire Swamp's dungeon: its mobs run L34-55 and its bosses
  // 55 / 55 / 89, twenty-five fights a card. Its
  // gear is the Spider Den's three pieces at the same strength, on the
  // wrist, waist and shoulder instead.
  DROWNED_FEN(
    DungeonDefinition(
      name: "Drowned Fen",
      iconAsset: "assets/images/dungeons/drowned_fen.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.BOG_LOGS, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.WILLOW_LOGS, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.BOG_EEL, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.CATFISH, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.MIRECAP, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.LEECH, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MARSH_FROG, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.SLIME_OOZE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.SLIME_CORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.SCALE, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CROW_QUILL, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.FEATHER, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MURKJAW_HIDE, lowCount: 20, highCount: 80),
          ],
        ),
        // the zone's rare reagent, kept to a handful
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.MURKJAW_FANG, lowCount: 5, highCount: 13),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.CROWQUILL_BRACERS, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.OOZE_SLICK_BELT, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.03,
          entries: [
            ItemDropType(id: ItemId.MURKJAW_PAULDRONS, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "Reedbank",
          entities: [
            DungeonEntityRef(EntityId.CARRION_CROW, count: 16),
            DungeonEntityRef(EntityId.MUDLURC, count: 8),
            DungeonEntityRef(EntityId.MURDER_KING, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Ooze Pits",
          entities: [
            DungeonEntityRef(EntityId.SLIME, count: 14),
            DungeonEntityRef(EntityId.OOZE, count: 10),
            DungeonEntityRef(EntityId.PRIMORDIAL_OOZE, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Murkjaw Nest",
          entities: [
            DungeonEntityRef(EntityId.MURKJAW, count: 12),
            DungeonEntityRef(EntityId.FUNGAL_MONSTER, count: 6),
            // the uncommon mudlurc, out of the swamp's discoveries since it
            // shares the common's art
            DungeonEntityRef(EntityId.MUDLURC_WARRIOR, count: 6),
            DungeonEntityRef(EntityId.MURKJAW_MATRIARCH, count: 1),
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
