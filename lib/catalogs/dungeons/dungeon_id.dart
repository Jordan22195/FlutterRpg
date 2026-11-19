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
      uniques: [
        ItemId.GOBLIN_CROWN,
        ItemId.GOBLIN_SCEPTER,
        ItemId.QUEENS_TRAIN,
      ],
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
      uniques: [
        ItemId.WEBBED_CLOAK,
        ItemId.WEBBED_BRACERS,
        ItemId.VENOMFANG_RING,
        ItemId.SPIDER_SILK_NECKLACE,
        ItemId.BROODMOTHERS_MANTLE,
        ItemId.BROODSILK_LEGGINGS,
      ],
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
            ItemDropType(id: ItemId.DUSKTHORN, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.THICK_ICHOR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.THICK_VENOM, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.THICK_FEATHER, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.THICK_FANG, lowCount: 20, highCount: 80),
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
      uniques: [
        ItemId.CHICKEN_CHARM,
        ItemId.MOOD_RING,
        ItemId.PITCHFORK,
        ItemId.WOOD_SHIELD,
        ItemId.FARMHAND_GLOVES,
      ],
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
      // what the den is farmed for: each boss's two pieces, floor by
      // floor, the two its trash carry, then the chest's own
      uniques: [
        ItemId.BEAR_HIDE_BRACERS,
        ItemId.WOLF_DEN_HELM,
        ItemId.WOLF_HIDE_BRACERS,
        ItemId.WOLF_DEN_BOOTS,
        ItemId.REDCAP_RING,
        ItemId.WOLF_DEN_GLOVES,
        ItemId.WOLF_DEN_CLOAK,
        ItemId.WOLF_HIDE_BELT,
        ItemId.WOLF_DEN_CHESTGUARD,
        ItemId.WOLF_DEN_LEGGUARDS,
      ],
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
            ItemDropType(id: ItemId.MEADOWSWEET, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.BRAMBLEWORT, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.REEDMINT, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.STURDY_FANG, lowCount: 20, highCount: 80),
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
      uniques: [
        ItemId.CROAKERS_CHARM,
        ItemId.SNAPJAW_SHELL,
        ItemId.RIVERCANE_MANTLE,
      ],
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
            ItemDropType(id: ItemId.STURDY_VENOM, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.LILY_PAD, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COOKED_PIKE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.COOKED_SALMON, lowCount: 20, highCount: 80),
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
            ItemDropType(id: ItemId.STURDY_SHELL, lowCount: 5, highCount: 13),
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
      uniques: [
        ItemId.CROWQUILL_BRACERS,
        ItemId.OOZE_SLICK_BELT,
        ItemId.MURKJAW_PAULDRONS,
        ItemId.MURKHIDE_CUIRASS,
      ],
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
            ItemDropType(id: ItemId.THICK_VENOM, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.THICK_ICHOR, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.THICK_SHELL, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.THICK_FEATHER, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MURKJAW_HIDE, lowCount: 20, highCount: 80),
          ],
        ),
        // the zone's rare reagent, kept to a handful
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.THICK_FANG, lowCount: 5, highCount: 13),
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
      uniques: [
        ItemId.MUDCLAW_GRIPS,
        ItemId.WALLOWHIDE_TREADS,
        ItemId.MUDMAW_JAWBLADE,
        ItemId.SILTSCALE_COIF,
      ],
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
            ItemDropType(id: ItemId.THICK_SHELL, lowCount: 20, highCount: 80),
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
            ItemDropType(id: ItemId.THICK_VENOM, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.PEAT_CLOD, lowCount: 5, highCount: 13),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.THICK_SHELL, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.THICK_HORN, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.THICK_FANG, lowCount: 5, highCount: 13),
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
      uniques: [
        ItemId.WARLORDS_CLEAVER,
        ItemId.WARLORDS_WARHELM,
        ItemId.ALPHAS_FANG,
        ItemId.ALPHAS_MANTLE,
        ItemId.STORMCALLERS_SCEPTER,
        ItemId.GALEWRAP_GAUNTLETS,
        ItemId.STORMHIDE_LEGS,
      ],
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
            ItemDropType(id: ItemId.SALTWORT, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.BLUESTEM, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HEAVY_HORN, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.HEAVY_VENOM, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.VENOM_GLAND, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HEAVY_HORN, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.HEAVY_ICHOR, lowCount: 20, highCount: 80),
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
            ItemDropType(id: ItemId.HEAVY_FANG, lowCount: 5, highCount: 13),
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
      uniques: [
        ItemId.GRAVEKEEPERS_GREATCOAT,
        ItemId.GRAVEKEEPERS_KEYRING,
        ItemId.SHROUDREAVER,
        ItemId.WEEPING_ROSARY,
        ItemId.ABBOTS_GRIMOIRE,
        ItemId.OSSUARY_PAULDRONS,
        ItemId.RELIQUARY_GAUNTLETS,
      ],
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
            ItemDropType(id: ItemId.HEAVY_ICHOR, lowCount: 20, highCount: 80),
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
        // the chest's exclusive at the band's two rarities, and the bosses'
        // trims at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.RELIQUARY_GAUNTLETS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.RELIQUARY_GAUNTLETS, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.GRAVEKEEPERS_KEYRING, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.WEEPING_ROSARY, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.OSSUARY_PAULDRONS, rarity: Rarity.EPIC),
          ],
        ),
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
            DungeonEntityRef(EntityId.THE_SHROUDED_WRAITH, count: 1),
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
  // The played-out mine under Copperdust Flats' mesas, at Tempest Reach's
  // tier: the flats' level-55 snakes and the mine's packrats and bats at
  // the top, level-89 crawlers and stone golems in the deep works, a
  // level-89 boss at the end of each of the first three floors and the
  // level-144 Lode Golem at the bottom. No men in it; the miners are long
  // gone. Twenty-five fights a card.
  OLD_SORROW_MINE(
    DungeonDefinition(
      name: "Old Sorrow Mine",
      iconAsset: "assets/images/dungeons/old_sorrow_mine.png",
      uniques: [
        ItemId.PACKRATS_TRINKET,
        ItemId.DUSKWING_CUFFS,
        ItemId.BORERS_MANDIBLE,
        ItemId.BORERS_SHELL_PAULDRONS,
        ItemId.LODESTONE_MAUL,
        ItemId.HEART_OF_THE_LODE,
        ItemId.PROSPECTORS_DUSTER,
        ItemId.MOTHER_LODE_NUGGET,
      ],
      type: DungeonType.ZONE,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.GOLD_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.GOLD_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.MITHRIL_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HEAVY_FEATHER, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.HEAVY_FANG, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HEAVY_VENOM, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.VENOM_GLAND, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.COAL, lowCount: 20, highCount: 80),
          ],
        ),
        // the flats' gem reagent, kept to a handful
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CRYSTAL_GEODE, lowCount: 5, highCount: 13),
          ],
        ),
        // the chest's two exclusives at the band's two rarities, and three
        // of the bosses' trims at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.PROSPECTORS_DUSTER, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.MOTHER_LODE_NUGGET, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.PROSPECTORS_DUSTER, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.MOTHER_LODE_NUGGET, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.PACKRATS_TRINKET, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.DUSKWING_CUFFS, rarity: Rarity.EPIC),
            ItemDropType(
              id: ItemId.BORERS_SHELL_PAULDRONS,
              rarity: Rarity.EPIC,
            ),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Headframe",
          entities: [
            DungeonEntityRef(EntityId.RATTLESNAKE, count: 8),
            DungeonEntityRef(EntityId.GIANT_PACKRAT, count: 16),
            DungeonEntityRef(EntityId.PACKRAT_KING, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Collapsed Drift",
          entities: [
            DungeonEntityRef(EntityId.TUNNEL_BAT, count: 14),
            DungeonEntityRef(EntityId.ROCK_CRAWLER, count: 10),
            DungeonEntityRef(EntityId.DUSKWING_MATRIARCH, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Stamp Mill",
          entities: [
            DungeonEntityRef(EntityId.MINE_GOLEM, count: 12),
            DungeonEntityRef(EntityId.ROCK_CRAWLER, count: 8),
            DungeonEntityRef(EntityId.DUST_DEVIL, count: 4),
            DungeonEntityRef(EntityId.THE_BORER, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Mother Lode",
          entities: [
            DungeonEntityRef(EntityId.GEM_CRAWLER, count: 12),
            DungeonEntityRef(EntityId.MINE_GOLEM, count: 12),
            DungeonEntityRef(EntityId.LODE_GOLEM, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Redwall Bluffs' dungeon: a climb up the cliff face from the gorge floor
  // to the rim, a level-233 boss on every floor and no human monsters. The
  // first two floors' trash stands at 144, the last two at 233. Six uniques
  // off the bosses and two in the chest (design/DUNGEON_LOOT_GUIDE.md)
  REDWALL_EYRIE(
    DungeonDefinition(
      name: "The Redwall Eyrie",
      iconAsset: "assets/images/dungeons/redwall_eyrie.png",
      uniques: [
        ItemId.BASILISK_FANG,
        ItemId.GAZEGLASS_RING,
        ItemId.LEDGEWALKER_GREAVES,
        ItemId.CHIMERAS_HORN,
        ItemId.REDWINGS_TALON,
        ItemId.REDWINGS_CREST,
        ItemId.EYRIE_WINDCLOAK,
        ItemId.REDWALL_CUIRASS,
      ],
      type: DungeonType.ZONE,
      chestRolls: [
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
            ItemDropType(id: ItemId.ANCIENT_VENOM, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.VENOM_GLAND, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(
              id: ItemId.ANCIENT_FEATHER,
              lowCount: 20,
              highCount: 80,
            ),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.CRYSTAL_GEODE, lowCount: 5, highCount: 13),
          ],
        ),
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.EYRIE_WINDCLOAK, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.REDWALL_CUIRASS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.EYRIE_WINDCLOAK, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.REDWALL_CUIRASS, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.GAZEGLASS_RING, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.LEDGEWALKER_GREAVES, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.REDWINGS_CREST, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Gorge Floor",
          entities: [
            DungeonEntityRef(EntityId.BASILISK, count: 14),
            DungeonEntityRef(EntityId.GIANT_SCORPION, count: 8),
            DungeonEntityRef(EntityId.OLD_STONEGAZE, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Hanging Ledges",
          entities: [
            DungeonEntityRef(EntityId.CLIFF_CHIMERA, count: 12),
            DungeonEntityRef(EntityId.MINOTAUR, count: 10),
            DungeonEntityRef(EntityId.LEDGE_WARDEN, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Wind-Cut Arches",
          entities: [
            DungeonEntityRef(EntityId.CLIFF_CHIMERA, count: 8),
            DungeonEntityRef(EntityId.EARTH_ELEMENTAL, count: 8),
            DungeonEntityRef(EntityId.OGRE, count: 6),
            DungeonEntityRef(EntityId.ARCH_CHIMERA, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Eyrie",
          entities: [
            DungeonEntityRef(EntityId.GRIFFIN, count: 12),
            DungeonEntityRef(EntityId.ROC_FLEDGLING, count: 8),
            DungeonEntityRef(EntityId.REDWING_MATRIARCH, count: 1),
          ],
        ),
      ],
    ),
  ),
  // Saltwind Coast's dungeon: the coast's L34-89 monsters from the
  // tidepools down to the deep, and a level-89 boss at the end of each
  // card, so the dungeon tops out where the coast does. Twenty-five fights
  // a card. Tempest Reach's sibling, piece for piece: a weapon and a trim
  // off each of the first two bosses, a weapon and a major off the last.
  BRINEDEEP_CAVES(
    DungeonDefinition(
      name: "Brinedeep Caves",
      iconAsset: "assets/images/dungeons/brinedeep_caves.png",
      uniques: [
        ItemId.BRINECRUSHER_CLAW,
        ItemId.BRINECLAW_BRACERS,
        ItemId.TIDECALLERS_SCEPTER,
        ItemId.SALTSCALE_SANDALS,
        ItemId.LEVIATHANS_FANG,
        ItemId.LEVIATHAN_GIRDLE,
        ItemId.PEARLSCALE_CUIRASS,
      ],
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
            ItemDropType(id: ItemId.SERPENT_SCALE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.HEAVY_SHELL, lowCount: 20, highCount: 80),
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
            ItemDropType(id: ItemId.HEAVY_SHELL, lowCount: 5, highCount: 13),
            ItemDropType(id: ItemId.AMBERGRIS, lowCount: 5, highCount: 13),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.HEAVY_FANG, lowCount: 5, highCount: 13),
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
      uniques: [
        ItemId.TROLLHIDE_TREADS,
        ItemId.TOLLKEEPERS_BELT,
        ItemId.SENTINELS_BULWARK,
        ItemId.SENTINELS_GORGET,
        ItemId.DRAKEFANG_GREATSWORD,
        ItemId.WYRMCREST_RING,
        ItemId.ARCHWARDENS_HELM,
      ],
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
        // the chest's exclusive at the band's two rarities, and two of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.ARCHWARDENS_HELM, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.ARCHWARDENS_HELM, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.TROLLHIDE_TREADS, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.SENTINELS_BULWARK, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Hollow Arch",
          entities: [
            DungeonEntityRef(EntityId.TROLL, count: 16),
            DungeonEntityRef(EntityId.MINOTAUR, count: 8),
            DungeonEntityRef(EntityId.BRIDGE_TROLL, count: 1),
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
      uniques: [
        ItemId.CINDERFANG,
        ItemId.WYVERNWING_CLOAK,
        ItemId.SLAGPLATE_BRACERS,
        ItemId.SLAGPLATE_PAULDRONS,
        ItemId.RIDGEHEART_GAUNTLETS,
        ItemId.ASHWEAVE_HAUBERK,
        ItemId.EMBERGLASS_PENDANT,
      ],
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
        // the chest's exclusives at the band's two rarities, and two of the
        // bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.ASHWEAVE_HAUBERK, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.EMBERGLASS_PENDANT, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.ASHWEAVE_HAUBERK, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.EMBERGLASS_PENDANT, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.WYVERNWING_CLOAK, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.SLAGPLATE_PAULDRONS, rarity: Rarity.EPIC),
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
  // Ironroot Hills' dungeon: the hills' own beasts, trolls, elementals and
  // giants, and a level-233 boss at the end of each card. The third tier-6
  // dungeon, standing on slots and leads Spinehold and the Ashen Vaults leave
  // open.
  GAUNT_TOR(
    DungeonDefinition(
      name: "Gaunt Tor",
      iconAsset: "assets/images/dungeons/gaunt_tor.png",
      uniques: [
        ItemId.THUNDERHORN_HELM,
        ItemId.CAIRNSTONE_GREAVES,
        ItemId.CAIRNWARDENS_SIGNET,
        ItemId.HILL_KINGS_CUDGEL,
        ItemId.GIANTBONE_GIRDLE,
        ItemId.IRONROOT_CUIRASS,
        ItemId.RAMHIDE_MANTLE,
      ],
      type: DungeonType.ZONE,
      chestRolls: [
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
            ItemDropType(id: ItemId.COAL, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.GOLD_ORE, lowCount: 20, highCount: 80),
            ItemDropType(id: ItemId.ANIMAL_PELT, lowCount: 20, highCount: 80),
          ],
        ),
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 2000, highCount: 8000),
          ],
        ),
        // the chest's exclusives at the band's two rarities, and three of
        // the bosses' pieces at their top rarity, never above
        // (design/DUNGEON_LOOT_GUIDE.md)
        DropRoll(
          chance: 0.25,
          entries: [
            ItemDropType(id: ItemId.IRONROOT_CUIRASS, rarity: Rarity.RARE),
            ItemDropType(id: ItemId.RAMHIDE_MANTLE, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.06,
          entries: [
            ItemDropType(id: ItemId.IRONROOT_CUIRASS, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.RAMHIDE_MANTLE, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.THUNDERHORN_HELM, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.CAIRNSTONE_GREAVES, rarity: Rarity.EPIC),
            ItemDropType(id: ItemId.GIANTBONE_GIRDLE, rarity: Rarity.EPIC),
          ],
        ),
      ],
      entries: [
        DungeonEntry(
          name: "The Switchbacks",
          entities: [
            DungeonEntityRef(EntityId.ROCK_RAM, count: 12),
            DungeonEntityRef(EntityId.TROLL, count: 10),
            DungeonEntityRef(EntityId.THUNDERHORN, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Cairn Hollow",
          entities: [
            DungeonEntityRef(EntityId.TROLL, count: 12),
            DungeonEntityRef(EntityId.EARTH_ELEMENTAL_UNCOMMON, count: 12),
            DungeonEntityRef(EntityId.THE_CAIRNWARDEN, count: 1),
          ],
        ),

        DungeonEntry(
          name: "The Giants' Hall",
          entities: [
            DungeonEntityRef(EntityId.TROLL, count: 8),
            DungeonEntityRef(EntityId.HILL_GIANT, count: 12),
            DungeonEntityRef(EntityId.THE_HILL_KING, count: 1),
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
      uniques: [
        ItemId.SERGEANTS_SHIV,
        ItemId.WARBAND_BELT,
        ItemId.CAMP_BANNER_CLOAK,
      ],
      type: DungeonType.TRANSIENT,
      chestRolls: [
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.IRON_BAR, lowCount: 5, highCount: 15),
            ItemDropType(id: ItemId.OAK_LOGS, lowCount: 10, highCount: 30),
            ItemDropType(id: ItemId.MEADOWSWEET, lowCount: 5, highCount: 15),
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
