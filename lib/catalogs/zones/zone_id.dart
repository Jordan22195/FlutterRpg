import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/zones/definition/zone_definition.dart';
import 'package:rpg/catalogs/zones/map_node_type.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/theme/zone_palette.dart';

// ignore_for_file: constant_identifier_names

/// Every zone in the game, and its definition.
///
/// Ordered by exploration level ascending, with dev/test zones last.
///
/// Definitions are `const`. Call `definition.copyWith(...)` for a variant
/// template; the runtime [Zone] (which carries discovered entities and other
/// per-save state) is built by the session, not from here.
///
/// The enum *value names* are the save format, so they must never be renamed.
enum ZoneId {
  // ── ZONES · exploration level ascending ─────────────────────────
  TUTORIAL_FARM(
    ZoneDefinition(
      name: "Southglen Meadow",
      iconAsset: "assets/images/zones/farm.png",
      palette: ZonePalette.meadow,
      explorationLevel: 1,
      xpPerExplore: 3,

      permanentEntities: [
        EntityId.TRANQUIL_POND,
        EntityId.ANVIL,
        EntityId.FIREPIT,
        EntityId.FARMER,
        EntityId.GRAINERY_ENTRANCE,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TREE,
          weight: 1,
          unlockLevel: 1,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.CHICKEN,
          weight: 1,
          unlockLevel: 2,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.COW,
          weight: 1,
          unlockLevel: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.FIELD_RAT,
          weight: 1,
          unlockLevel: 1,
        ),

        WeightedDropTableEntry<EntityId>(
          id: EntityId.ROTWOOD_SCARECROW,
          weight: 1,
          unlockLevel: 4,
        ),
      ],
      discoverableItems: [WeightedDropTableEntry(id: ItemId.NULL, weight: 1)],
    ),
  ),
  SOUTHWOOD_FOREST(
    ZoneDefinition(
      iconAsset: 'assets/images/zones/forest.png',
      palette: ZonePalette.forest,
      explorationLevel: 5,
      xpPerExplore: 5,

      name: "Southwood Forest",
      permanentEntities: [
        EntityId.CREEK,
        EntityId.FIREPIT,
        EntityId.WOLF_DEN_ENTRANCE,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.OAK_TREE,
          weight: .5,
          unlockLevel: 7,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GOBLIN,
          weight: 1,
          unlockLevel: 10,
        ),

        WeightedDropTableEntry<EntityId>(
          id: EntityId.FOREST_WOLF,
          weight: 1,
          unlockLevel: 12,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.BEAR,
          weight: 1,
          unlockLevel: 13,
        ),

        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: .5),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GOBLIN_CAMP,
          weight: .01,
          unlockLevel: 5,
        ),
        // herb geography: the low herbs grow here once you can spot them,
        // which is what makes Herbalism reachable through Exploration
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GUAM,
          weight: 1,
          count: 3,
          unlockLevel: 6,
        ),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.NULL,
          count: 1,
          highCount: 5,
          weight: .15,
          unlockLevel: 8,
        ),
      ],
    ),
  ),
  SOUTH_HAVEN(
    ZoneDefinition(
      iconAsset: 'assets/images/zones/south_haven.png',
      palette: ZonePalette.southHaven,
      type: MapNodeType.TOWN,
      explorationLevel: 1,

      name: "South Haven",
      permanentEntities: [
        EntityId.ANVIL,
        EntityId.FIREPIT,
        EntityId.TRADING_POST,
        EntityId.MINING_SHOP,
        EntityId.ALCHEMY_STATION,
      ],
      discoverableEntities: [],
    ),
  ),
  // The three west-coast zones off Southwood Forest, each a band of the
  // monster ladder: Reedwater Vale 13–34, Mudmouth Delta 21–55, Saltwind
  // Coast 34–89. Monsters only so far: no gathering or stations yet.
  REEDWATER_VALE(
    ZoneDefinition(
      name: "Reedwater Vale",
      iconAsset: "assets/images/zones/reedwater_vale.png",
      palette: ZonePalette.reedwater,
      explorationLevel: 10,
      xpPerExplore: 5,
      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RIVER_TOAD,
          weight: 1.5,
          unlockLevel: 10,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WATER_STRIDER,
          weight: 1.5,
          unlockLevel: 10,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MUDLURC_FISHER,
          weight: 1,
          unlockLevel: 11,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SNAPPING_TURTLE,
          weight: .6,
          unlockLevel: 12,
        ),
      ],
    ),
  ),
  MUDMOUTH_DELTA(
    ZoneDefinition(
      name: "Mudmouth Delta",
      iconAsset: "assets/images/zones/mudmouth_delta.png",
      palette: ZonePalette.mudmouth,
      explorationLevel: 15,
      xpPerExplore: 7,
      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MUD_CRAB,
          weight: 1.5,
          unlockLevel: 15,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MIRE_HIPPO,
          weight: 1,
          unlockLevel: 16,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.CROCODILE,
          weight: .5,
          unlockLevel: 17,
        ),
      ],
    ),
  ),
  SALTWIND_COAST(
    ZoneDefinition(
      name: "Saltwind Coast",
      iconAsset: "assets/images/zones/saltwind_coast.png",
      palette: ZonePalette.saltwind,
      explorationLevel: 20,
      xpPerExplore: 9,
      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SHORE_CRAB,
          weight: 1.5,
          unlockLevel: 20,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.NAGA,
          weight: 1,
          unlockLevel: 21,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TIDAL_ELEMENTAL,
          weight: 1,
          unlockLevel: 22,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SEA_SERPENT,
          weight: .3,
          unlockLevel: 23,
        ),
      ],
    ),
  ),
  DARKWOOD_FOREST(
    ZoneDefinition(
      name: "Darkwood Forest",
      iconAsset: 'assets/images/zones/darkwood_forest.png',
      palette: ZonePalette.darkwood,
      explorationLevel: 20,
      xpPerExplore: 10,

      // The Spider Den moved here from Southwood: the den's own cards run to
      // the Broodmother at level 55, which never sat comfortably behind a
      // level-5 zone's front door.
      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.SPIDER_DEN_ENTRANCE,
        EntityId.RIVER,
      ],
      discoverableEntities: [
        // tier 3 gathering: willow for woodcutting, coal for mining. The
        // gold vein is the mine's, not the darkwood's.
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WILLOW_TREE,
          weight: 1.5,
          unlockLevel: 20,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 1),
        // the mine's bats roost in the dark canopy too
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GIANT_BAT,
          weight: 1.5,
          unlockLevel: 20,
        ),
        // the spiders that spill out of the den
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GIANT_SPIDER,
          weight: 1,
          unlockLevel: 20,
        ),
        // the high herbs grow in the deep woods, the way the low ones grow
        // in Southwood — the next rung of the same Herbalism ladder
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HARRALANDER,
          weight: .6,
          count: 2,
          unlockLevel: 21,
        ),

        WeightedDropTableEntry<EntityId>(
          id: EntityId.SKELETON,
          weight: 1,
          unlockLevel: 23,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ZOMBIE,
          weight: 1,
          unlockLevel: 24,
        ),
        // the dead forest's deepest haunt; gated well past the skeleton and
        // zombie it lurks behind
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WRAITH,
          weight: 0.5,
          unlockLevel: 30,
        ),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.WILLOW_LOGS,
          count: 1,
          highCount: 4,
          weight: .15,
          unlockLevel: 24,
        ),
      ],
    ),
  ),
  // The wet ground east of the town: mudlurcs, slimes and crows at the
  // front door, oozes and fungal monsters further in, the rare Murkjaw
  // past that, and a moss golem the zone gates well past its own door.
  // Each monster here has its own art. The swamp is also the source of the
  // super potions: mirecap, the marsh's reagents, and the Murkjaw's fang.
  SWAMP(
    ZoneDefinition(
      name: "Blackmire Swamp",
      iconAsset: 'assets/images/zones/swamp.png',
      palette: ZonePalette.swamp,
      explorationLevel: 25,
      xpPerExplore: 12,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.DROWNED_FEN_ENTRANCE,
        EntityId.MURKY_MARSH,
      ],
      discoverableEntities: [
        // willow's side-grade, for woodcutting
        WeightedDropTableEntry<EntityId>(
          id: EntityId.BOG_TREE,
          weight: 1.5,
          unlockLevel: 25,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MUDLURC,
          weight: 1.5,
          unlockLevel: 25,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SLIME,
          weight: 1.5,
          unlockLevel: 25,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.CARRION_CROW,
          weight: 1.5,
          unlockLevel: 25,
        ),
        // the super potions' herb, the next rung past darkwood's harralander
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MIRECAP,
          weight: .6,
          count: 3,
          unlockLevel: 25,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.FUNGAL_MONSTER,
          weight: 1.5,
          unlockLevel: 26,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.OOZE,
          weight: 1,
          unlockLevel: 27,
        ),
        // the reason to come: the only source of the murkjaw fang
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MURKJAW,
          weight: .3,
          unlockLevel: 28,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MOSS_GOLEM,
          weight: .3,
          unlockLevel: 29,
        ),
      ],
    ),
  ),
  // The still water past the swamp's far edge: a small lake ringed by
  // maples, and the ranarr that grows in their shade.
  MAPLEWATER_LAKE(
    ZoneDefinition(
      name: "Maplewater Lake",
      type: MapNodeType.SKILLING,
      iconAsset: 'assets/images/zones/maplewater_lake.png',
      palette: ZonePalette.maplewater,
      explorationLevel: 30,
      xpPerExplore: 13,

      permanentEntities: [EntityId.FIREPIT, EntityId.DEEP_POND],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MAPLE_TREE,
          weight: 1.5,
          unlockLevel: 30,
        ),
        // the lower trees, rarer finds than the maples they grow among
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TREE,
          weight: .4,
          unlockLevel: 30,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.OAK_TREE,
          weight: .4,
          unlockLevel: 30,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WILLOW_TREE,
          weight: .4,
          unlockLevel: 30,
        ),
        // the low herbs, uncommon this far from the farms
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GUAM,
          weight: .8,
          count: 3,
          unlockLevel: 30,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HARRALANDER,
          weight: .8,
          count: 3,
          unlockLevel: 30,
        ),
        // the fourth herb tier
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RANARR,
          weight: .6,
          count: 3,
          unlockLevel: 30,
        ),
      ],
    ),
  ),
  // A skilling grove up the hill from Maplewater Lake: yews older than
  // the village, and nothing that fights back. Woodcutting only, with a
  // firepit to burn what is cut.
  YEW_GROVE(
    ZoneDefinition(
      name: "Old Yew Grove",
      type: MapNodeType.SKILLING,
      iconAsset: 'assets/images/zones/yew_grove.png',
      palette: ZonePalette.forest,
      requiredSkill: SkillId.WOODCUTTING,
      requiredLevel: 40,
      explorationLevel: 40,
      xpPerExplore: 15,

      permanentEntities: [EntityId.FIREPIT],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.YEW_TREE,
          weight: 1.5,
          unlockLevel: 40,
        ),
        // the lake's maples creep up the slope
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MAPLE_TREE,
          weight: .5,
          unlockLevel: 40,
        ),
      ],
    ),
  ),
  // Deeper in past the yews, where the light goes strange: the magic
  // trees. The top of the woodcutting ladder, and nothing that fights.
  MAGIC_GROVE(
    ZoneDefinition(
      name: "Witchlight Grove",
      type: MapNodeType.SKILLING,
      iconAsset: 'assets/images/zones/witchlight_grove.png',
      palette: ZonePalette.forest,
      requiredSkill: SkillId.WOODCUTTING,
      requiredLevel: 55,
      explorationLevel: 55,
      xpPerExplore: 22,

      permanentEntities: [EntityId.FIREPIT],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MAGIC_TREE,
          weight: 1.5,
          unlockLevel: 55,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.YEW_TREE,
          weight: .5,
          unlockLevel: 55,
        ),
      ],
    ),
  ),
  // The fishing village on the lake's shore. Nothing to find by exploring;
  // it is where the lake's catch is bought and sold, and where the fishing
  // rods up to mithril and the logs up to maple are sold.
  MAPLEWATER_VILLAGE(
    ZoneDefinition(
      name: "Maplewater Village",
      iconAsset: 'assets/images/zones/maplewater_village.png',
      palette: ZonePalette.maplewater,
      type: MapNodeType.TOWN,
      explorationLevel: 30,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.MAPLEWATER_TRADING_POST,
        EntityId.FISHING_SHOP,
        EntityId.LUMBER_MILL,
      ],
      discoverableEntities: [],
    ),
  ),
  FOREST_MINE(
    ZoneDefinition(
      name: "Forest Mine",
      type: MapNodeType.SKILLING,
      iconAsset: 'assets/images/zones/mine.png',
      palette: ZonePalette.mine,
      requiredSkill: SkillId.MINING,
      requiredLevel: 5,
      explorationLevel: 15,
      xpPerExplore: 8,

      permanentEntities: [],
      discoverableEntities: [
        // the veins by rarity: copper the bulk of the rock, iron behind it,
        // coal uncommon and gold rare. The depths below carry the rest
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 3),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 2),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GIANT_SPIDER,
          weight: 1,
          unlockLevel: 18,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: .8),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOLD_VEIN, weight: .25),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GEM_VEIN,
          weight: .08,
          unlockLevel: 19,
        ),
      ],
      discoverableItems: [
        // a lost miner's purse, kept off the ore/gem axis so it doesn't
        // pre-empt either vein
        WeightedDropTableEntry(
          id: ItemId.COINS,
          count: 5,
          highCount: 50,
          weight: .12,
          unlockLevel: 18,
        ),
        WeightedDropTableEntry(
          id: ItemId.SOUL_SHARD,
          weight: .01,
          unlockLevel: 30,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    ),
  ),
  // The second level of the Forest Mine, down the shaft from the first.
  // A skilling zone: no monsters, only rock. Coal is the bulk of it, then
  // iron, gold and the first mithril this side of the prairie, with gems
  // the rarest seam.
  FOREST_MINE_DEPTHS(
    ZoneDefinition(
      name: "Forest Mine Depths",
      type: MapNodeType.SKILLING,
      iconAsset: 'assets/images/zones/forest_mine_depths.png',
      palette: ZonePalette.mine,
      requiredSkill: SkillId.MINING,
      requiredLevel: 20,
      explorationLevel: 25,
      xpPerExplore: 10,

      permanentEntities: [],
      discoverableEntities: [
        // in decreasing rarity: coal, iron, gold, mithril, gems
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 2),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 1.5),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOLD_VEIN, weight: .8),
        WeightedDropTableEntry<EntityId>(id: EntityId.MITHRIL_VEIN, weight: .4),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GEM_VEIN,
          weight: .15,
          unlockLevel: 30,
        ),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.COINS,
          count: 20,
          highCount: 120,
          weight: .12,
          unlockLevel: 25,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    ),
  ),
  CHALLENGING_MOUNTAIN(
    ZoneDefinition(
      name: "The Mountain",
      iconAsset: "assets/images/zones/the_mountain.png",
      explorationLevel: 30,
      xpPerExplore: 120,

      permanentEntities: [],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TREE,
          weight: 2,
          unlockLevel: 30,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GOBLIN,
          weight: 1,
          unlockLevel: 33,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
      ],
    ),
  ),
  // Out of the forest and onto the plains: rolling grass, long sight lines
  // and weather you can watch coming for an hour. A mid-level zone — its
  // monsters stand at 55 and 89 and its dungeon's bosses at 144 — with no
  // trees to cut. The only place mithril is mined and the first adamantite,
  // and the source of the greater potions: bluestem and the prairie's
  // reagents. The enum keeps its old FOOTHILLS name; it is the save format.
  FOOTHILLS(
    ZoneDefinition(
      name: "Stormgrass Prairie",
      iconAsset: 'assets/images/zones/stormgrass_prairie.png',
      palette: ZonePalette.prairie,
      explorationLevel: 35,
      xpPerExplore: 15,

      permanentEntities: [EntityId.FIREPIT, EntityId.TEMPEST_REACH_ENTRANCE],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RATTLESNAKE,
          weight: 1.5,
          unlockLevel: 35,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ORC,
          weight: 1.5,
          unlockLevel: 35,
        ),
        // the utility potions' grass
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SWEETGRASS,
          weight: .6,
          count: 3,
          unlockLevel: 35,
        ),
        // tier 4 mining, the rung above the darkwood's coal. A vein opens
        // at the level its ore smelts at, not inside the zone's range
        WeightedDropTableEntry<EntityId>(id: EntityId.MITHRIL_VEIN, weight: 1),
        // the greater potions' herb, the next rung past the swamp's mirecap
        WeightedDropTableEntry<EntityId>(
          id: EntityId.BLUESTEM,
          weight: .6,
          count: 3,
          unlockLevel: 36,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SABERTOOTH,
          weight: 1,
          unlockLevel: 37,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.CENTAUR,
          weight: 1,
          unlockLevel: 37,
        ),
        // the first magic thing in the game, well past the zone's door
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DUST_DEVIL,
          weight: .6,
          unlockLevel: 38,
        ),
        // tier 5 mining, and rare; opens where adamant smelts
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ADAMANTITE_VEIN,
          weight: .3,
        ),
      ],
    ),
  ),
  // South of the prairie the grass burns off into high desert: red-brown
  // hardpan, copper-coloured dust, mesas on the skyline and adobe ruins in
  // the washes. The prairie's equal — exploration 35, monsters at 55 and 89
  // — and the giant scorpion's home at last. Gold and gems in the rock.
  COPPERDUST_FLATS(
    ZoneDefinition(
      name: "Copperdust Flats",
      iconAsset: 'assets/images/zones/copperdust_flats.png',
      palette: ZonePalette.copperdust,
      explorationLevel: 35,
      xpPerExplore: 15,

      permanentEntities: [EntityId.FIREPIT],
      discoverableEntities: [
        // level 55: the prairie's snake, at home in the heat
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RATTLESNAKE,
          weight: 1.5,
          unlockLevel: 35,
        ),
        // level 89, the desert animal that never belonged in the bog
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GIANT_SCORPION,
          weight: 1.5,
          unlockLevel: 36,
        ),
        // the prairie's whirlwinds blow south over the flats too
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DUST_DEVIL,
          weight: .8,
          unlockLevel: 38,
        ),
        // the flats' mining: gold in the washes, gems in the mesa rock
        WeightedDropTableEntry<EntityId>(id: EntityId.GOLD_VEIN, weight: 1),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GEM_VEIN,
          weight: .2,
          unlockLevel: 37,
        ),
      ],
    ),
  ),
  // South of the darkwood the trees give out into a deep, fog-filled
  // hollow of leaning headstones, and an abandoned monastery at the bottom
  // of it. Stormgrass Prairie's equal — exploration 35, the dead at 55 and
  // 89 — and nothing to gather: the hollow is for fighting, and the Haunted
  // Ruins hold its level-144 bosses.
  MISTGRAVE_HOLLOW(
    ZoneDefinition(
      name: "Mistgrave Hollow",
      iconAsset: 'assets/images/zones/mistgrave_hollow.png',
      palette: ZonePalette.mistgrave,
      explorationLevel: 35,
      xpPerExplore: 15,

      permanentEntities: [EntityId.FIREPIT, EntityId.HAUNTED_RUINS_ENTRANCE],
      discoverableEntities: [
        // level 55, the darkwood's dead come further south
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RESTLESS_SKELETON,
          weight: 1.5,
          unlockLevel: 35,
        ),
        // level 55
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ZOMBIE,
          weight: 1.5,
          unlockLevel: 35,
        ),
        // level 89
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GRAVE_GHOUL,
          weight: 1,
          unlockLevel: 37,
        ),
        // level 89
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WAILING_BANSHEE,
          weight: 1,
          unlockLevel: 37,
        ),
        // level 89, rare and deep in the fog
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MIST_WRAITH,
          weight: .6,
          unlockLevel: 38,
        ),
      ],
    ),
  ),
  // The city at the foot of the hills, where the prairie road meets the
  // first rise of the range: just outside Ironroot Hills to the west.
  // Nothing to find by exploring; it is where jewelcrafting is done, the
  // way South Haven is where alchemy is, and it keeps every other skilling
  // table too, so a city is somewhere the whole craft can be done at once.
  IRON_GATE_CITY(
    ZoneDefinition(
      name: "Iron Gate City",
      iconAsset: 'assets/images/zones/iron_gate_city.png',
      palette: ZonePalette.ironGateCity,
      type: MapNodeType.TOWN,
      explorationLevel: 35,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.ANVIL,
        EntityId.ENCHANTING_BENCH,
        EntityId.JEWELCRAFTING_BENCH,
        EntityId.ALCHEMY_STATION,
      ],
      discoverableEntities: [],
    ),
  ),
  // East of the prairie the grass gives out against the front range: iron-red
  // rock, scrub and switchbacks climbing toward the peaks. The rung above
  // Stormgrass — its monsters run 55 to 233 — and the home the old foothills
  // roster was waiting on. Coal and adamantite in the rock, so it is where
  // the prairie's mithril meets the next tier.
  IRONROOT_HILLS(
    ZoneDefinition(
      name: "Ironroot Hills",
      iconAsset: 'assets/images/zones/ironroot_hills.png',
      palette: ZonePalette.ironroot,
      explorationLevel: 50,
      xpPerExplore: 20,

      permanentEntities: [EntityId.FIREPIT],
      discoverableEntities: [
        // level 55, the hills' welcome: the prairie's top end, flying
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HARPY,
          weight: 1.5,
          unlockLevel: 50,
        ),
        // level 89
        WeightedDropTableEntry<EntityId>(
          id: EntityId.IMP,
          weight: 1.5,
          unlockLevel: 50,
        ),
        // the steel tier's fuel, back above ground
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 1),
        // level 144, under the bridges and in the passes
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TROLL,
          weight: 1,
          unlockLevel: 52,
        ),
        // level 233, rare and well past the door
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HILL_GIANT,
          weight: .5,
          unlockLevel: 55,
        ),
        // tier 5 mining: rare on the prairie, a proper seam here. Opens
        // where adamant smelts, the same gate the prairie's vein uses
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ADAMANTITE_VEIN,
          weight: .8,
        ),
      ],
    ),
  ),
  // The mine under Ironroot Hills, sunk into the iron-red rock off the
  // switchbacks. A skilling zone with no monsters: coal and mithril in the
  // walls, adamantite deeper in, and the first runite anywhere, rare.
  IRONROOT_MINE(
    ZoneDefinition(
      name: "Ironroot Mine",
      type: MapNodeType.SKILLING,
      iconAsset: 'assets/images/zones/ironroot_mine.png',
      palette: ZonePalette.mine,
      requiredSkill: SkillId.MINING,
      requiredLevel: 40,
      explorationLevel: 50,
      xpPerExplore: 20,

      permanentEntities: [],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 1.5),
        WeightedDropTableEntry<EntityId>(id: EntityId.MITHRIL_VEIN, weight: 1),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ADAMANTITE_VEIN,
          weight: .6,
        ),
        // tier 6, rare; opens where rune smelts
        WeightedDropTableEntry<EntityId>(id: EntityId.RUNITE_VEIN, weight: .15),
      ],
      discoverableItems: [
        WeightedDropTableEntry(
          id: ItemId.COINS,
          count: 50,
          highCount: 300,
          weight: .12,
          unlockLevel: 50,
        ),
        WeightedDropTableEntry(id: ItemId.NULL, weight: 1),
      ],
    ),
  ),
  // East of the flats the desert breaks into layered red cliffs: sheer walls,
  // ledges, wind-cut arches and a river far below. One tier above the flats
  // — exploration 50, monsters at 144 and a rare 233 — with things that
  // perch, things that stare, and griffins nesting on the rim.
  REDWALL_BLUFFS(
    ZoneDefinition(
      name: "Redwall Bluffs",
      iconAsset: 'assets/images/zones/redwall_bluffs.png',
      palette: ZonePalette.redwall,
      explorationLevel: 50,
      xpPerExplore: 20,

      permanentEntities: [EntityId.FIREPIT],
      discoverableEntities: [
        // level 89, up from the flats below
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GIANT_SCORPION,
          weight: 1,
          unlockLevel: 50,
        ),
        // level 144: stone that perches on the ledges until it doesn't
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GARGOYLE,
          weight: 1.5,
          unlockLevel: 50,
        ),
        // level 144, in the shade at the cliff foot
        WeightedDropTableEntry<EntityId>(
          id: EntityId.BASILISK,
          weight: 1,
          unlockLevel: 52,
        ),
        // level 233, rare and nesting on the rim
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GRIFFIN,
          weight: .5,
          unlockLevel: 55,
        ),
        // tier 5 mining in the exposed cliff faces
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ADAMANTITE_VEIN,
          weight: .6,
        ),
      ],
    ),
  ),
  // ── THE MOUNTAINS · exploration 70 ──────────────────────────────
  // Past the hills and the bluffs the land climbs into two ranges, joined
  // by the pass town of Saddlegate. Their monsters run 144 to 233; the
  // rung above, 377, is held only by the bosses of each range's dungeon.
  //
  // North-east of Ironroot Hills: grey granite and a long rocky spine,
  // with the snowline above. Runite in the rock, the first proper seam
  // outside the Ironroot Mine. The way up to the Frostcrown Peaks.
  GREYSPINE_MOUNTAIN(
    ZoneDefinition(
      name: "Greyspine Mountain",
      iconAsset: 'assets/images/zones/greyspine_mountain.png',
      palette: ZonePalette.greyspine,
      explorationLevel: 70,
      xpPerExplore: 28,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.SPINEHOLD_CAVERNS_ENTRANCE,
      ],
      discoverableEntities: [
        // level 144, the hills' trolls followed up the passes
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TROLL,
          weight: 1.5,
          unlockLevel: 70,
        ),
        // level 144
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MINOTAUR,
          weight: 1.5,
          unlockLevel: 70,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 1),
        // level 233
        WeightedDropTableEntry<EntityId>(
          id: EntityId.OGRE,
          weight: 1,
          unlockLevel: 72,
        ),
        // level 233, rare and well past the door
        WeightedDropTableEntry<EntityId>(
          id: EntityId.STONE_GOLEM,
          weight: .5,
          unlockLevel: 75,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ADAMANTITE_VEIN,
          weight: .6,
        ),
        // tier 6; opens where rune smelts
        WeightedDropTableEntry<EntityId>(id: EntityId.RUNITE_VEIN, weight: .8),
      ],
    ),
  ),
  // South-east of Redwall Bluffs: ridges grey with fallen ash, cracked dark
  // rock and steam vents with fire in their throats. The way up to the
  // Moltenspire Peaks.
  ASHRIDGE_MOUNTAINS(
    ZoneDefinition(
      name: "Ashridge Mountains",
      iconAsset: 'assets/images/zones/ashridge_mountains.png',
      palette: ZonePalette.ashridge,
      explorationLevel: 70,
      xpPerExplore: 28,

      permanentEntities: [EntityId.FIREPIT, EntityId.ASHEN_VAULTS_ENTRANCE],
      discoverableEntities: [
        // level 144, the bluffs' stone come further east
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GARGOYLE,
          weight: 1.5,
          unlockLevel: 70,
        ),
        // level 144
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DARK_WIZARD,
          weight: 1.5,
          unlockLevel: 70,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.COAL_VEIN, weight: 1),
        // level 233
        WeightedDropTableEntry<EntityId>(
          id: EntityId.EARTH_ELEMENTAL,
          weight: 1,
          unlockLevel: 72,
        ),
        // level 233, out of the vents
        WeightedDropTableEntry<EntityId>(
          id: EntityId.FIRE_ELEMENTAL,
          weight: .5,
          unlockLevel: 75,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.MITHRIL_VEIN, weight: .6),
        WeightedDropTableEntry<EntityId>(id: EntityId.RUNITE_VEIN, weight: .8),
      ],
    ),
  ),
  // The town in the saddle between the two ranges, where the road from
  // Greyspine meets the road from the Ashridge, and the path up to the
  // Stormcrown Peaks begins. Nothing to find by exploring; it keeps every
  // crafting table, the way Iron Gate City does.
  SADDLEGATE(
    ZoneDefinition(
      name: "Saddlegate",
      iconAsset: 'assets/images/zones/saddlegate.png',
      palette: ZonePalette.saddlegate,
      type: MapNodeType.TOWN,
      explorationLevel: 70,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.ANVIL,
        EntityId.ENCHANTING_BENCH,
        EntityId.ALCHEMY_STATION,
      ],
      discoverableEntities: [],
    ),
  ),
  // ── THE PEAKS · exploration 90 ──────────────────────────────────
  // Above the ranges, three summits. Their monsters run 233 to 377; the
  // rung above, 610, is held only by the bosses of each peak's dungeon.
  // Dragonite in the rock of all three, richest under Moltenspire.
  //
  // Above Greyspine: ice spires, wind-blown snow, frozen falls.
  FROSTCROWN_PEAKS(
    ZoneDefinition(
      name: "Frostcrown Peaks",
      iconAsset: 'assets/images/zones/frostcrown_peaks.png',
      palette: ZonePalette.frostcrown,
      explorationLevel: 90,
      xpPerExplore: 35,

      permanentEntities: [EntityId.FIREPIT, EntityId.HOARFROST_HOLLOW_ENTRANCE],
      discoverableEntities: [
        // level 233, the mountain's ogres gone up into the snow
        WeightedDropTableEntry<EntityId>(
          id: EntityId.OGRE,
          weight: 1.5,
          unlockLevel: 90,
        ),
        // level 233, the meltwater given a will
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WATER_ELEMENTAL,
          weight: 1.5,
          unlockLevel: 90,
        ),
        // level 377
        WeightedDropTableEntry<EntityId>(
          id: EntityId.YETI,
          weight: 1,
          unlockLevel: 92,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.RUNITE_VEIN, weight: .6),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DRAGONITE_VEIN,
          weight: .3,
        ),
      ],
    ),
  ),
  // Above Saddlegate: summits wrapped in storm cloud, lightning on the rock.
  STORMCROWN_PEAKS(
    ZoneDefinition(
      name: "Stormcrown Peaks",
      iconAsset: 'assets/images/zones/stormcrown_peaks.png',
      palette: ZonePalette.stormcrown,
      explorationLevel: 90,
      xpPerExplore: 35,

      permanentEntities: [EntityId.FIREPIT, EntityId.THUNDERHALL_ENTRANCE],
      discoverableEntities: [
        // level 233, up from the bluffs' rim
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GRIFFIN,
          weight: 1.5,
          unlockLevel: 90,
        ),
        // level 377
        WeightedDropTableEntry<EntityId>(
          id: EntityId.ROC,
          weight: 1,
          unlockLevel: 92,
        ),
        // level 377, rare
        WeightedDropTableEntry<EntityId>(
          id: EntityId.WYVERN,
          weight: .5,
          unlockLevel: 95,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.RUNITE_VEIN, weight: .6),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DRAGONITE_VEIN,
          weight: .3,
        ),
      ],
    ),
  ),
  // Above the Ashridge: spires of black rock over rivers of lava.
  MOLTENSPIRE_PEAKS(
    ZoneDefinition(
      name: "Moltenspire Peaks",
      iconAsset: 'assets/images/zones/moltenspire_peaks.png',
      palette: ZonePalette.moltenspire,
      explorationLevel: 90,
      xpPerExplore: 35,

      permanentEntities: [EntityId.FIREPIT, EntityId.THE_CALDERA_ENTRANCE],
      discoverableEntities: [
        // level 233
        WeightedDropTableEntry<EntityId>(
          id: EntityId.FIRE_ELEMENTAL,
          weight: 1.5,
          unlockLevel: 90,
        ),
        // level 377
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DRAKE,
          weight: 1,
          unlockLevel: 92,
        ),
        // level 377, rare
        WeightedDropTableEntry<EntityId>(
          id: EntityId.IRON_GOLEM,
          weight: .5,
          unlockLevel: 95,
        ),
        WeightedDropTableEntry<EntityId>(id: EntityId.RUNITE_VEIN, weight: .6),
        // the proper dragonite seam
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DRAGONITE_VEIN,
          weight: .8,
        ),
      ],
    ),
  ),
  // ── DEV ZONES · outside the travel graph, free to enter ─────────
  DEV_FOREST(
    ZoneDefinition(
      name: "Dev Forest",
      iconAsset: 'assets/images/zones/forest.png',
      palette: ZonePalette.forest,
      xpPerExplore: 10,

      permanentEntities: [
        EntityId.FIREPIT,
        EntityId.ANVIL,
        EntityId.ENCHANTING_BENCH,
        EntityId.JEWELCRAFTING_BENCH,
        EntityId.ALCHEMY_STATION,
        EntityId.CREEK,
        EntityId.DEEP_POND,
        EntityId.RIVER,
        EntityId.LAKE,
        EntityId.OCEAN,
        EntityId.TRADING_POST,
        EntityId.WANDERING_MERCHANT,
        EntityId.DEV_SHOP,
      ],
      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(id: EntityId.TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.OAK_TREE, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.CHICKEN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.GOBLIN, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.COPPER, weight: 1),
        WeightedDropTableEntry<EntityId>(id: EntityId.IRON, weight: 1),
        // every herb, each found as a patch of 3 picks. herbs live only
        // here until real zones get herb geography
        WeightedDropTableEntry<EntityId>(
          id: EntityId.GUAM,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.MARRENTILL,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TARROMIN,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.HARRALANDER,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.RANARR,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TOADFLAX,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.IRIT,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.AVANTOE,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.KWUARM,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.SNAPDRAGON,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.CADANTINE,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.LANTADYME,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DWARF_WEED,
          weight: 1,
          count: 3,
        ),
        WeightedDropTableEntry<EntityId>(
          id: EntityId.TORSTOL,
          weight: 1,
          count: 3,
        ),
      ],
    ),
  ),
  DEV_DUNGEON_TESTING(
    ZoneDefinition(
      name: "Dev Dungeons",
      iconAsset: 'assets/images/zones/forest.png',
      xpPerExplore: 10,

      permanentEntities: [EntityId.SPIDER_DEN_ENTRANCE],

      discoverableEntities: [
        WeightedDropTableEntry<EntityId>(
          id: EntityId.DEV_DUNGEON_ENTRANCE,
          weight: 10,
        ),
      ],
    ),
  ),
  // ── SENTINEL ────────────────────────────────────────────────────
  NULL(
    ZoneDefinition(
      name: "Nowhere",
      iconAsset: "",
      permanentEntities: [],
      discoverableEntities: [],
    ),
  );

  const ZoneId(this.definition);

  /// The design-time template for this zone. Never mutate it.
  final ZoneDefinition definition;

  String get iconAsset => definition.iconAsset;

  /// Ids that were renamed, keyed by the name a save written before the
  /// rename still holds. Every save writes a world entry for every zone, so
  /// a zone rename orphans every save that has ever run the game — even an
  /// uncommitted one, if a build of it was played. A rename is only safe
  /// with its old name here; every save decode goes through [byName].
  static const Map<String, ZoneId> renamed = {'GLIMMERFORD': IRON_GATE_CITY};

  static final Map<String, ZoneId> _byName = values.asNameMap();

  /// The zone a saved [name] refers to, following [renamed]; null when it
  /// names nothing, so a retired zone can be dropped rather than thrown on.
  static ZoneId? byName(String name) => _byName[name] ?? renamed[name];
}
