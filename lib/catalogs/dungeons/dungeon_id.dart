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
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.RUNITE_BAR, lowCount: 10, highCount: 30),
            ItemDropType(
              id: ItemId.ADAMANTITE_BAR,
              lowCount: 20,
              highCount: 60,
            ),
          ],
        ),
        DropRoll(chance: 0.5, entries: gemDropTable),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.QUEENS_TRAIN, rarity: Rarity.RARE)],
        ),
        DropRoll(
          chance: 0.06,
          entries: [ItemDropType(id: ItemId.QUEENS_TRAIN, rarity: Rarity.EPIC)],
        ),
        DropRoll(
          chance: 0.17,
          entries: [ItemDropType(id: ItemId.GOBLIN_CROWN, rarity: Rarity.EPIC)],
        ),
      ],
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
      // Broodsilk Leggings, which only the chest gives
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
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.5,
          entries: [
            ItemDropType(
              id: ItemId.BROODSILK_LEGGINGS,
              rarity: Rarity.UNCOMMON,
            ),
          ],
        ),
        DropRoll(
          chance: 0.15,
          entries: [
            ItemDropType(id: ItemId.BROODSILK_LEGGINGS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.WEBBED_CLOAK, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.SPIDER_SILK_NECKLACE, rarity: Rarity.RARE),
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
          ],
        ),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.2,
          entries: [
            ItemDropType(id: ItemId.FARMHAND_GLOVES, rarity: Rarity.COMMON),
          ],
        ),
        DropRoll(
          chance: 0.05,
          entries: [
            ItemDropType(id: ItemId.FARMHAND_GLOVES, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.CHICKEN_CHARM, rarity: Rarity.UNCOMMON),
            ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.UNCOMMON),
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
      // set's chest and legs, which only the chest gives
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
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.5,
          entries: [
            ItemDropType(
              id: ItemId.WOLF_DEN_CHESTGUARD,
              rarity: Rarity.UNCOMMON,
            ),
            ItemDropType(
              id: ItemId.WOLF_DEN_LEGGUARDS,
              rarity: Rarity.UNCOMMON,
            ),
          ],
        ),
        DropRoll(
          chance: 0.15,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_CHESTGUARD, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.WOLF_DEN_LEGGUARDS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.WOLF_DEN_BOOTS, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.WOLF_DEN_GLOVES, rarity: Rarity.RARE),
          ],
        ),
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
            DungeonEntityRef(EntityId.GROTTO_BAT, count: 5),
            DungeonEntityRef(EntityId.GROTTO_SLIME, count: 10),
            DungeonEntityRef(EntityId.GROTTO_FUNGAL_MONSTER, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Reedwater Vale's dungeon: the vale's L13-34 monsters through its reed
  // channels, and a level-34 boss at the end of each of its two cards,
  // twenty-five fights a card. Its gear sits at the Wolf Den's tier, on the
  // neck, offhand and shoulders the den leaves bare.
  REEDMAZE(
    DungeonDefinition(
      name: "The Reedmaze",
      iconAsset: "assets/images/dungeons/reedmaze.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.TOAD_LEGS, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.TURTLE_MEAT, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.STRIDER_LEG, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.LILY_PAD, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.TOAD_WART, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COOKED_PIKE, lowCount: 20, highCount: 80),
            ItemDropType(
              id: ItemId.COOKED_SALMON,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.IRON_BAR, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.STEEL_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        // the vale's river reagents and the turtle's shell, kept to a
        // handful
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.FRESHWATER_MUSSEL,
              lowCount: 5,
              highCount: 13,
            ),
            ItemDropType(
              id: ItemId.RIVER_DRIFTWOOD,
              lowCount: 5,
              highCount: 13,
            ),
            ItemDropType(id: ItemId.TURTLE_SHELL, lowCount: 5, highCount: 13),
          ],
        ),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.5,
          entries: [
            ItemDropType(id: ItemId.RIVERCANE_MANTLE, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.15,
          entries: [
            ItemDropType(id: ItemId.RIVERCANE_MANTLE, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.CROAKERS_CHARM, rarity: Rarity.RARE),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Reedbeds",
          entities: [
            DungeonEntityRef(EntityId.RIVER_TOAD, count: 14),
            DungeonEntityRef(EntityId.WATER_STRIDER, count: 10),
            DungeonEntityRef(EntityId.OLD_CROAKER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Snapper's Pool",
          entities: [
            DungeonEntityRef(EntityId.MUDLURC_FISHER, count: 12),
            DungeonEntityRef(EntityId.SNAPPING_TURTLE, count: 12),
            DungeonEntityRef(EntityId.OLD_SNAPJAW, count: 1),
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
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.5,
          entries: [
            ItemDropType(id: ItemId.MURKHIDE_CUIRASS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.15,
          entries: [
            ItemDropType(id: ItemId.MURKHIDE_CUIRASS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.CROWQUILL_BRACERS, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.MURKJAW_PAULDRONS, rarity: Rarity.RARE),
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
  // Mudmouth Delta's dungeon: the delta's L21-55 monsters in its burrowed
  // banks, and bosses at 55, 55 and 89, twenty-five fights a card. The
  // third dungeon at the Spider Den's and Drowned Fen's tier: two trims off
  // the first two bosses and the tier's first unique weapon off the last,
  // on the hands, feet and sword hand the other two leave empty.
  SILT_WARRENS(
    DungeonDefinition(
      name: "The Silt Warrens",
      iconAsset: "assets/images/dungeons/silt_warrens.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CRAB_MEAT, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.HIPPO_RUMP, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HIPPO_HIDE, lowCount: 20, highCount: 80),
            ItemDropType(
              id: ItemId.CROCODILE_HIDE,
              lowCount: 20,
              highCount: 80,
            ),
            ItemDropType(id: ItemId.SCALE, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.COOKED_BOG_EEL,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.STEEL_BAR, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.COAL, lowCount: 20, highCount: 80),
          ],
        ),
        // the delta's marsh reagents, and its teeth and tusks, kept to a
        // handful
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.LEECH, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.MARSH_FROG, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.PEAT_CLOD, lowCount: 5, highCount: 13),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CRAB_CLAW, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.HIPPO_TUSK, lowCount: 5, highCount: 13),
            ItemDropType(
              id: ItemId.CROCODILE_TOOTH,
              lowCount: 5,
              highCount: 13,
            ),
          ],
        ),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.5,
          entries: [
            ItemDropType(id: ItemId.SILTSCALE_COIF, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.15,
          entries: [
            ItemDropType(id: ItemId.SILTSCALE_COIF, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.MUDCLAW_GRIPS, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.WALLOWHIDE_TREADS, rarity: Rarity.RARE),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Mudflats",
          entities: [
            DungeonEntityRef(EntityId.MUD_CRAB, count: 16),
            DungeonEntityRef(EntityId.MIRE_HIPPO, count: 8),
            DungeonEntityRef(EntityId.OLD_MUDCLAW, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Wallows",
          entities: [
            DungeonEntityRef(EntityId.MIRE_HIPPO, count: 14),
            DungeonEntityRef(EntityId.MUD_CRAB, count: 10),
            DungeonEntityRef(EntityId.WALLOW_BULL, count: 1),
          ],
        ),

        DungeonEntry(
          name: "Deathroll Channel",
          entities: [
            DungeonEntityRef(EntityId.CROCODILE, count: 12),
            DungeonEntityRef(EntityId.MIRE_HIPPO, count: 12),
            DungeonEntityRef(EntityId.MUDMAW, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Stormgrass Prairie's dungeon: its mobs run L55-89 and all three bosses
  // stand at 144, twenty-five fights a card. It runs from the orcs' camp
  // out through the predators' grass and into the storm itself, and its
  // gear sits a rung past the Drowned Fen's.
  TEMPEST_REACH(
    DungeonDefinition(
      name: "Tempest Reach",
      iconAsset: "assets/images/dungeons/tempest_reach.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.MITHRIL_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.SWEETGRASS, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.BLUESTEM, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.ORC_TUSK, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.SNAKESKIN, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.VENOM_GLAND, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CENTAUR_HOOF, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.WIND_MOTE, lowCount: 20, highCount: 80),
            ItemDropType(
              id: ItemId.BOWSTRING_SINEW,
              lowCount: 20,
              highCount: 80,
            ),
            ItemDropType(
              id: ItemId.SABERTOOTH_PELT,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        // the zone's rare reagent, kept to a handful
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.SABERTOOTH_FANG,
              lowCount: 5,
              highCount: 13,
            ),
          ],
        ),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.STORMHIDE_LEGS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.STORMHIDE_LEGS, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.WARLORDS_WARHELM, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.ALPHAS_MANTLE, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.GALEWRAP_GAUNTLETS, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "Raider's Camp",
          entities: [
            DungeonEntityRef(EntityId.ORC, count: 16),
            DungeonEntityRef(EntityId.RATTLESNAKE, count: 8),
            DungeonEntityRef(EntityId.ORC_WARLORD, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Matted Grass",
          entities: [
            DungeonEntityRef(EntityId.RATTLESNAKE, count: 10),
            DungeonEntityRef(EntityId.SABERTOOTH, count: 14),
            DungeonEntityRef(EntityId.SABERTOOTH_ALPHA, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Storm Front",
          entities: [
            DungeonEntityRef(EntityId.CENTAUR, count: 10),
            // the uncommon orc: the warband at 89, out of the prairie's
            // discoveries since it shares the common's art
            DungeonEntityRef(EntityId.ORC_UNCOMMON, count: 7),
            DungeonEntityRef(EntityId.DUST_DEVIL, count: 7),
            DungeonEntityRef(EntityId.TEMPEST, count: 1),
          ],
        ),
      ],
    ),
  ),
  // The abandoned monastery at the bottom of Mistgrave Hollow, at Tempest
  // Reach's tier: the hollow's 55-89 dead in its graveyard, nave and
  // ossuary, and a level-144 boss at the end of each.
  HAUNTED_RUINS(
    DungeonDefinition(
      name: "Haunted Ruins",
      iconAsset: "assets/images/dungeons/haunted_ruins.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.MITHRIL_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.ROTTEN_FLESH, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.GRAVE_MOSS, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.ENCHANTING_ESSENCE,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.ENCHANTING_RUNE,
              lowCount: 5,
              highCount: 13,
            ),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(
              id: ItemId.ENCHANTING_PRISM,
              lowCount: 1,
              highCount: 3,
            ),
          ],
        ),
        DropRoll(chance: 0.03, entries: [ItemDropType(id: ItemId.SOUL_SHARD)]),
      ],
      entries: [
        DungeonEntry(
          name: "The Graveyard Gate",
          entities: [
            DungeonEntityRef(EntityId.RESTLESS_SKELETON, count: 16),
            DungeonEntityRef(EntityId.ZOMBIE, count: 8),
            DungeonEntityRef(EntityId.THE_GRAVEKEEPER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Silent Nave",
          entities: [
            DungeonEntityRef(EntityId.WAILING_BANSHEE, count: 10),
            DungeonEntityRef(EntityId.GRAVE_GHOUL, count: 14),
            DungeonEntityRef(EntityId.THE_WEEPING_ABBESS, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Ossuary",
          entities: [
            DungeonEntityRef(EntityId.FALLEN_MONK, count: 10),
            DungeonEntityRef(EntityId.MIST_WRAITH, count: 7),
            DungeonEntityRef(EntityId.WAILING_BANSHEE, count: 7),
            DungeonEntityRef(EntityId.THE_UNDYING_ABBOT, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Saltwind Coast's dungeon: the coast's L34-89 monsters from the
  // tidepools down to the deep, and a level-144 boss at the end of each
  // card, twenty-five fights a card. Tempest Reach's sibling, piece for
  // piece: a weapon and a trim off each of the first two bosses, a weapon
  // and a major off the last.
  BRINEDEEP_CAVES(
    DungeonDefinition(
      name: "Brinedeep Caves",
      iconAsset: "assets/images/dungeons/brinedeep_caves.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.MITHRIL_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COOKED_TUNA, lowCount: 20, highCount: 80),
            ItemDropType(
              id: ItemId.COOKED_SWORDFISH,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.SERPENT_SCALE,
              lowCount: 20,
              highCount: 80,
            ),
            ItemDropType(id: ItemId.SCALE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.CRAB_CLAW, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.ENCHANTING_ESSENCE,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        // the sea's reagents and the serpent's fang, kept to a handful
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.SEA_KELP, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.AMBERGRIS, lowCount: 5, highCount: 13),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.SERPENT_FANG, lowCount: 5, highCount: 13),
          ],
        ),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.PEARLSCALE_CUIRASS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.PEARLSCALE_CUIRASS, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.BRINECLAW_BRACERS, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.SALTSCALE_SANDALS, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.LEVIATHAN_GIRDLE, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Tidepools",
          entities: [
            DungeonEntityRef(EntityId.SHORE_CRAB, count: 16),
            DungeonEntityRef(EntityId.NAGA, count: 8),
            DungeonEntityRef(EntityId.BRINECRUSHER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Drowned Shrine",
          entities: [
            DungeonEntityRef(EntityId.NAGA, count: 14),
            DungeonEntityRef(EntityId.TIDAL_ELEMENTAL, count: 10),
            DungeonEntityRef(EntityId.NAGA_TIDECALLER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Leviathan's Deep",
          entities: [
            DungeonEntityRef(EntityId.TIDAL_ELEMENTAL, count: 10),
            DungeonEntityRef(EntityId.SEA_SERPENT, count: 14),
            DungeonEntityRef(EntityId.LEVIATHAN, count: 1),
          ],
        ),
      ],
    ),
  ),
  // The caverns under Greyspine Mountain. Its rooms hold the mountain's
  // 144-233 monsters; each ends in a level-377 boss, the only ones in the
  // range.
  SPINEHOLD_CAVERNS(
    DungeonDefinition(
      name: "Spinehold Caverns",
      iconAsset: "assets/images/dungeons/spinehold_caverns.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.RUNEITE_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.RUNITE_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.ADAMANTITE_ORE,
              lowCount: 20,
              highCount: 80,
            ),
            ItemDropType(
              id: ItemId.ADAMANTITE_BAR,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 2000, highCount: 8000),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Troll Bridge",
          entities: [
            DungeonEntityRef(EntityId.TROLL, count: 16),
            DungeonEntityRef(EntityId.MINOTAUR, count: 8),
            DungeonEntityRef(EntityId.ELDER_ROC, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The High Gallery",
          entities: [
            DungeonEntityRef(EntityId.MINOTAUR, count: 10),
            DungeonEntityRef(EntityId.OGRE, count: 14),
            DungeonEntityRef(EntityId.STEEL_SENTINEL, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Drake's Roost",
          entities: [
            DungeonEntityRef(EntityId.OGRE, count: 10),
            DungeonEntityRef(EntityId.STONE_GOLEM, count: 14),
            DungeonEntityRef(EntityId.GREYSPINE_DRAKE, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Old vaults buried under the Ashridge's ash. The range's 144-233
  // monsters, and a level-377 boss at the end of each room.
  ASHEN_VAULTS(
    DungeonDefinition(
      name: "The Ashen Vaults",
      iconAsset: "assets/images/dungeons/ashen_vaults.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.RUNEITE_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.RUNITE_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.ADAMANTITE_ORE,
              lowCount: 20,
              highCount: 80,
            ),
            ItemDropType(
              id: ItemId.ADAMANTITE_BAR,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 2000, highCount: 8000),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Ash Drifts",
          entities: [
            DungeonEntityRef(EntityId.GARGOYLE, count: 16),
            DungeonEntityRef(EntityId.DARK_WIZARD, count: 8),
            DungeonEntityRef(EntityId.ASH_WYVERN, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Slag Halls",
          entities: [
            DungeonEntityRef(EntityId.DARK_WIZARD, count: 10),
            DungeonEntityRef(EntityId.EARTH_ELEMENTAL, count: 14),
            DungeonEntityRef(EntityId.SLAG_WARDEN, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Furnace Heart",
          entities: [
            DungeonEntityRef(EntityId.EARTH_ELEMENTAL, count: 10),
            DungeonEntityRef(EntityId.FIRE_ELEMENTAL, count: 14),
            DungeonEntityRef(EntityId.HEART_OF_THE_RIDGE, count: 1),
          ],
        ),
      ],
    ),
  ),
  // The glacier cave under Frostcrown. The peak's 233-377 monsters, and a
  // level-610 boss at the end of each room.
  HOARFROST_HOLLOW(
    DungeonDefinition(
      name: "Hoarfrost Hollow",
      iconAsset: "assets/images/dungeons/hoarfrost_hollow.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.RUNEITE_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.RUNITE_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.DRAGON_ORE, lowCount: 10, highCount: 40),
            ItemDropType(id: ItemId.DRAGON_BAR, lowCount: 10, highCount: 40),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 5000, highCount: 20000),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Ice Gate",
          entities: [
            DungeonEntityRef(EntityId.OGRE, count: 16),
            DungeonEntityRef(EntityId.WATER_ELEMENTAL, count: 8),
            DungeonEntityRef(EntityId.YETI_PATRIARCH, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Frozen Pillars",
          entities: [
            DungeonEntityRef(EntityId.WATER_ELEMENTAL, count: 12),
            DungeonEntityRef(EntityId.YETI, count: 12),
            DungeonEntityRef(EntityId.FROST_GIANT, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Wyrm's Throne",
          entities: [
            DungeonEntityRef(EntityId.YETI, count: 14),
            DungeonEntityRef(EntityId.OGRE, count: 10),
            DungeonEntityRef(EntityId.FROST_WYRM, count: 1),
          ],
        ),
      ],
    ),
  ),
  // A ruined hall on Stormcrown's summit. The peak's 233-377 monsters, and
  // a level-610 boss at the end of each room.
  THUNDERHALL(
    DungeonDefinition(
      name: "Thunderhall",
      iconAsset: "assets/images/dungeons/thunderhall.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.RUNEITE_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.RUNITE_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.DRAGON_ORE, lowCount: 10, highCount: 40),
            ItemDropType(id: ItemId.DRAGON_BAR, lowCount: 10, highCount: 40),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 5000, highCount: 20000),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Windswept Steps",
          entities: [
            DungeonEntityRef(EntityId.GRIFFIN, count: 16),
            DungeonEntityRef(EntityId.ROC, count: 8),
            DungeonEntityRef(EntityId.ROC_BROODMOTHER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Broken Colonnade",
          entities: [
            DungeonEntityRef(EntityId.ROC, count: 12),
            DungeonEntityRef(EntityId.WYVERN, count: 12),
            DungeonEntityRef(EntityId.THUNDERBIRD, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Giant's Throne",
          entities: [
            DungeonEntityRef(EntityId.WYVERN, count: 10),
            DungeonEntityRef(EntityId.GRIFFIN, count: 14),
            DungeonEntityRef(EntityId.STORM_GIANT, count: 1),
          ],
        ),
      ],
    ),
  ),
  // The crater at Moltenspire's heart. The peak's 233-377 monsters, and a
  // level-610 boss at the end of each room.
  THE_CALDERA(
    DungeonDefinition(
      name: "The Caldera",
      iconAsset: "assets/images/dungeons/the_caldera.png",
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.RUNEITE_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.RUNITE_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.DRAGON_ORE, lowCount: 10, highCount: 40),
            ItemDropType(id: ItemId.DRAGON_BAR, lowCount: 10, highCount: 40),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 5000, highCount: 20000),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Crater Rim",
          entities: [
            DungeonEntityRef(EntityId.FIRE_ELEMENTAL, count: 16),
            DungeonEntityRef(EntityId.DRAKE, count: 8),
            DungeonEntityRef(EntityId.CALDERA_LESSER_DEMON, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Obsidian Spires",
          entities: [
            DungeonEntityRef(EntityId.DRAKE, count: 12),
            DungeonEntityRef(EntityId.IRON_GOLEM, count: 12),
            DungeonEntityRef(EntityId.CALDERA_GREATER_DEMON, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Lava Lake",
          entities: [
            DungeonEntityRef(EntityId.IRON_GOLEM, count: 10),
            DungeonEntityRef(EntityId.FIRE_ELEMENTAL, count: 14),
            DungeonEntityRef(EntityId.CALDERA_DRAGON, count: 1),
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
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.IRON_BAR, lowCount: 5, highCount: 15),
            ItemDropType(id: ItemId.OAK_LOGS, lowCount: 10, highCount: 30),
            ItemDropType(id: ItemId.GUAM_LEAF, lowCount: 5, highCount: 15),
          ],
        ),
        // the chest's exclusive at the band's two rarities, and some of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.05,
          entries: [
            ItemDropType(id: ItemId.CAMP_BANNER_CLOAK, rarity: Rarity.COMMON),
          ],
        ),
        DropRoll(
          chance: 0.015,
          entries: [
            ItemDropType(id: ItemId.CAMP_BANNER_CLOAK, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.03,
          entries: [
            ItemDropType(id: ItemId.SERGEANTS_SHIV, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
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
