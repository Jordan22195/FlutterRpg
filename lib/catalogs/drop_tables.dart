/// Reusable weighted drop tables.
///
/// These are top-level and `const` on purpose. A catalog definition is
/// `const`, and a const expression cannot read a field off an object, so a
/// shared table has to be something a const list literal can splice —
/// `itemDrops: [...gemDropTable, oreEntry]` — rather than something looked
/// up through an id. A whole table can also be handed over as-is, either as
/// the main drop or wrapped in a [DropRoll] that fires some of the time:
///
/// ```dart
/// itemDrops: gemDropTable,
/// bonusDrops: [DropRoll(chance: 0.02, entries: herbDropTable)],
/// ```
///
/// A table is a list of [ItemDropType], and both the main table and a
/// [DropRoll] are lists of exactly that — so the same table drops into
/// either, and rolls for the drop, quality and all, whichever it is used
/// as.
///
/// A table can also sit *inside* another table as a single weighted line,
/// by way of [NestedDrop]. Landing on it yields exactly one pick from it,
/// and the reference may stamp a quality on everything that comes out — so
/// one shared table serves every rarity variant of a monster instead of
/// each variant hand-writing the same lines at its own rarity:
///
/// ```dart
/// itemDrops: [
///   NestedDrop(cookedFishDropTable, weight: 2),
///   NestedDrop(ironToolsDropTable, weight: 1, rarity: Rarity.RARE),
///   ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 5),
/// ],
/// ```
///
/// Every entry leaves `unlockLevel` at 0. Only callers
/// that run `WeightedDropTableService.availableAt` before rolling honour it —
/// today that is exploration alone — and entity drop rolls ignore it outright,
/// so a level-tagged table would quietly do nothing in `bonusDrops`. Weight
/// carries the tiering instead.
library;

import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Every gem. The four colored gems are the core stats rather than tiers of
/// one ladder, so they drop evenly; diamond and dragonstone, the combat
/// pair, are rare; onyx, the xp gem, is rarest of all.
const List<ItemDropType> gemDropTable = [
  ItemDropType(id: ItemId.TOPAZ, weight: 1),
  ItemDropType(id: ItemId.SAPPHIRE, weight: 1),
  ItemDropType(id: ItemId.EMERALD, weight: 1),
  ItemDropType(id: ItemId.RUBY, weight: 1),
  ItemDropType(id: ItemId.DIAMOND, weight: 0.15),
  ItemDropType(id: ItemId.DRAGONSTONE, weight: 0.15),
  ItemDropType(id: ItemId.ONYX, weight: 0.03),
];

/// Every herb, in herbalism-level order, weight decaying about a quarter per
/// step down the ladder. Guam takes roughly a fifth of all rolls and Torstol
/// well under one percent, so a table roll reads as "a herb, probably a cheap
/// one" wherever it is used.
const List<ItemDropType> herbDropTable = [
  ItemDropType(id: ItemId.GUAM_LEAF, weight: 1),
  ItemDropType(id: ItemId.MARRENTILL, weight: 0.8),
  ItemDropType(id: ItemId.TARROMIN, weight: 0.65),
  ItemDropType(id: ItemId.HARRALANDER, weight: 0.5),
  ItemDropType(id: ItemId.MIRECAP, weight: 0.44),
  ItemDropType(id: ItemId.RANARR_WEED, weight: 0.38),
  ItemDropType(id: ItemId.TOADFLAX, weight: 0.3),
  ItemDropType(id: ItemId.IRIT_LEAF, weight: 0.22),
  ItemDropType(id: ItemId.AVANTOE, weight: 0.16),
  ItemDropType(id: ItemId.KWUARM, weight: 0.12),
  ItemDropType(id: ItemId.SNAPDRAGON, weight: 0.09),
  ItemDropType(id: ItemId.CADANTINE, weight: 0.065),
  ItemDropType(id: ItemId.LANTADYME, weight: 0.05),
  ItemDropType(id: ItemId.DWARF_WEED, weight: 0.035),
  ItemDropType(id: ItemId.TORSTOL, weight: 0.025),
];

/// The three cooked river fish, evenly weighted. A nested reference to this
/// reads as "a cooked fish" wherever it is used, without the caller caring
/// which one.
const List<ItemDropType> cookedFishDropTable = [
  ItemDropType(id: ItemId.COOKED_CARP, weight: 1),
  ItemDropType(id: ItemId.COOKED_MINNOW, weight: 1),
  ItemDropType(id: ItemId.COOKED_BLUEGILL, weight: 1),
];

/// The iron tool set, evenly weighted. Written at COMMON: a nested
/// reference stamps the quality it wants on top, so this one table serves
/// every rarity variant of the monsters that drop it.
const List<ItemDropType> ironToolsDropTable = [
  ItemDropType(id: ItemId.IRON_DAGGER, weight: 1),
  ItemDropType(id: ItemId.IRON_AXE, weight: 1),
  ItemDropType(id: ItemId.IRON_PICKAXE, weight: 1),
  ItemDropType(id: ItemId.IRON_SICKLE, weight: 1),
];

/// The small iron pieces — the extremities, not the body slots, so this
/// stays a lesser drop than a chest or legs would be.
const List<ItemDropType> ironMinorArmorDropTable = [
  ItemDropType(id: ItemId.IRON_HELMET, weight: 1),
  ItemDropType(id: ItemId.IRON_GLOVES, weight: 1),
  ItemDropType(id: ItemId.IRON_BOOTS, weight: 1),
];

/// The medium leather extremities, the way [ironMinorArmorDropTable] is the
/// iron ones: the goblins wear both. The body pieces are the trading post's.
const List<ItemDropType> mediumLeatherMinorArmorDropTable = [
  ItemDropType(id: ItemId.MEDIUM_LEATHER_COIF, weight: 1),
  ItemDropType(id: ItemId.MEDIUM_LEATHER_GLOVES, weight: 1),
  ItemDropType(id: ItemId.MEDIUM_LEATHER_BOOTS, weight: 1),
];

/// What a goblin carries besides its leather and its lunch, the same at
/// every rarity: a little iron bar, oak and guam leaf as the steady lines,
/// the low gems rarely, and iron daggers rarer still — mostly plain, now and
/// then a better one. The quality is fixed here, not the variant's.
const List<ItemDropType> goblinSupplyDrops = [
  ItemDropType(id: ItemId.IRON_BAR, lowCount: 1, highCount: 2, weight: 1),
  ItemDropType(id: ItemId.OAK_LOGS, lowCount: 1, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.GUAM_LEAF, lowCount: 1, highCount: 2, weight: 1),
  ItemDropType(id: ItemId.TOPAZ, weight: 0.3),
  ItemDropType(id: ItemId.SAPPHIRE, weight: 0.1),
  ItemDropType(id: ItemId.IRON_DAGGER, rarity: Rarity.COMMON, weight: 0.3),
  ItemDropType(id: ItemId.IRON_DAGGER, rarity: Rarity.UNCOMMON, weight: 0.15),
  ItemDropType(id: ItemId.IRON_DAGGER, rarity: Rarity.RARE, weight: 0.05),
];

/// The Wolf Den set's minor slots, evenly, at uncommon: a den boss rolls one
/// of these on a rare chance. The majors are the den chest's. The Cave Bear
/// and the Den Alpha Wolf each roll their own cut of it, below.
const List<ItemDropType> wolfDenMinorArmorDropTable = [
  ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_CLOAK, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_GLOVES, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_BOOTS, rarity: Rarity.UNCOMMON, weight: 1),
];

/// What the Cave Bear rolls on its rare chance: the set without the boots,
/// and the bear hide bracers in their place.
const List<ItemDropType> caveBearArmorDropTable = [
  ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_CLOAK, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_GLOVES, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(
    id: ItemId.BEAR_HIDE_BRACERS,
    rarity: Rarity.UNCOMMON,
    weight: 1,
  ),
];

/// What the Den Alpha Wolf rolls on its rare chance: the set without the
/// gloves, and the wolf hide bracers in their place.
const List<ItemDropType> denAlphaArmorDropTable = [
  ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_CLOAK, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_BOOTS, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(
    id: ItemId.WOLF_HIDE_BRACERS,
    rarity: Rarity.UNCOMMON,
    weight: 1,
  ),
];

/// The whole Wolf Den set at rare, evenly: a long shot from the den's end
/// chest, over and above its common majors.
const List<ItemDropType> wolfDenRareSetDropTable = [
  ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.RARE, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_CLOAK, rarity: Rarity.RARE, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_GLOVES, rarity: Rarity.RARE, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_BOOTS, rarity: Rarity.RARE, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_CHESTGUARD, rarity: Rarity.RARE, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_LEGGUARDS, rarity: Rarity.RARE, weight: 1),
];

/// The Wolf Den set's major slots, evenly, and the wolf hide belt: the den
/// chest's rare pick.
const List<ItemDropType> wolfDenMajorArmorDropTable = [
  ItemDropType(id: ItemId.WOLF_DEN_CHESTGUARD, weight: 1),
  ItemDropType(id: ItemId.WOLF_DEN_LEGGUARDS, weight: 1),
  ItemDropType(id: ItemId.WOLF_HIDE_BELT, weight: 1),
];

const List<ItemDropType> ironMajorArmorDropTable = [
  ItemDropType(id: ItemId.IRON_CHESTPLATE, weight: 1),
  ItemDropType(id: ItemId.IRON_LEGS, weight: 1),
];

const List<ItemDropType> steelToolsDropTable = [
  ItemDropType(id: ItemId.STEEL_DAGGER, weight: 1),
  ItemDropType(id: ItemId.STEEL_AXE, weight: 1),
  ItemDropType(id: ItemId.STEEL_PICKAXE, weight: 1),
  ItemDropType(id: ItemId.STEEL_SICKLE, weight: 1),
];

/// The small iron pieces — the extremities, not the body slots, so this
/// stays a lesser drop than a chest or legs would be.
const List<ItemDropType> steelMinorArmorDropTable = [
  ItemDropType(id: ItemId.STEEL_HELMET, weight: 1),
  ItemDropType(id: ItemId.STEEL_GLOVES, weight: 1),
  ItemDropType(id: ItemId.STEEL_BOOTS, weight: 1),
];

const List<ItemDropType> steelMajorArmorDropTable = [
  ItemDropType(id: ItemId.STEEL_CHESTPLATE, weight: 1),
  ItemDropType(id: ItemId.STEEL_LEGS, weight: 1),
];

/// What an orc raider carries off: the steel tools and the two heavy body
/// pieces. Steel is a tier under the prairie, so this is kit worth selling
/// or smelting rather than wearing.
const List<ItemDropType> orcSteelDropTable = [
  ...steelToolsDropTable,
  ...steelMajorArmorDropTable,
];

const List<ItemDropType> mithrilWeaponsDropTable = [
  ItemDropType(id: ItemId.MITHRIL_AXE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_PICKAXE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_SICKLE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_SHIELD, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_DAGGER, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_SWORD, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_GREATSWORD, weight: 1),
];

/// Every mithril armor piece, evenly.
const List<ItemDropType> mithrilArmorDropTable = [
  ItemDropType(id: ItemId.MITHRIL_HELMET, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_PAULDRONS, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_CHESTPLATE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_BELT, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_BRACERS, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_LEGS, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_BOOTS, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_GLOVES, weight: 1),
];

const List<ItemDropType> heavyLeatherDropTable = [
  ItemDropType(id: ItemId.HEAVY_LEATHER_BELT, weight: 1),
  ItemDropType(id: ItemId.HEAVY_LEATHER_BRACERS, weight: 1),
  ItemDropType(id: ItemId.HEAVY_LEATHER_CHEST, weight: 1),
  ItemDropType(id: ItemId.HEAVY_LEATHER_COIF, weight: 1),
  ItemDropType(id: ItemId.HEAVY_LEATHER_GLOVES, weight: 1),
  ItemDropType(id: ItemId.HEAVY_LEATHER_PANTS, weight: 1),
  ItemDropType(id: ItemId.HEAVY_LEATHER_SPAULDERS, weight: 1),
];

const List<ItemDropType> spiderDropTable = [
  ItemDropType(id: ItemId.SILK, lowCount: 1, highCount: 2),
  ItemDropType(id: ItemId.VENOM, lowCount: 1, highCount: 2),
];

/// The dark forest's dead leave the same two scraps behind, a skeleton as
/// much as a zombie: rotten flesh most of the time, grave moss now and then.
const List<ItemDropType> graveScrapDropTable = [
  ItemDropType(id: ItemId.ROTTEN_FLESH, lowCount: 1, highCount: 2, weight: 1),
  ItemDropType(id: ItemId.GRAVE_MOSS, lowCount: 1, highCount: 2, weight: 0.6),
];

/// What a zombie wears: pure-attack rags, one slot each.
const List<ItemDropType> tatteredClothDropTable = [
  ItemDropType(id: ItemId.TATTERED_HOOD, weight: 1),
  ItemDropType(id: ItemId.TATTERED_CLOAK, weight: 1),
  ItemDropType(id: ItemId.TATTERED_WRAPS, weight: 1),
  ItemDropType(id: ItemId.TATTERED_SHOES, weight: 1),
];

/// The same rags at uncommon: what a wraith wears, a cut above a zombie's.
const List<ItemDropType> tatteredClothUncommonDropTable = [
  ItemDropType(id: ItemId.TATTERED_HOOD, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.TATTERED_CLOAK, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.TATTERED_WRAPS, rarity: Rarity.UNCOMMON, weight: 1),
  ItemDropType(id: ItemId.TATTERED_SHOES, rarity: Rarity.UNCOMMON, weight: 1),
];

/// The same table with every line stamped at [rarity].
///
/// Superseded by [NestedDrop]'s rarity override, which does this without
/// building a list — and unlike this, can be written in a const catalog
/// definition. Kept because it still works and takes nothing to keep.
///
/// A nested line is copied as a nested line with the rarity pushed into its
/// override. Rebuilding it as a plain [ItemDropType] the way the rest of the
/// loop does would quietly turn it into an [ItemId.NULL] leaf with the
/// sub-table gone.
List<ItemDropType> getScaledDropTable(
  List<ItemDropType> table,
  //int fibLevel,
  Rarity rarity,
) {
  List<ItemDropType> outTable = [];
  for (ItemDropType i in table) {
    if (i is NestedDrop) {
      outTable.add(
        NestedDrop(
          i.table,
          weight: i.weight,
          rarity: rarity,
          countMultiplier: i.countMultiplier,
        ),
      );
      continue;
    }
    final newItem = ItemDropType(
      id: i.id,
      rarity: rarity,
      lowCount: i.lowCount,
      highCount: i.highCount,
      weight: i.weight,
    );

    outTable.add(newItem);
  }
  return outTable;
}

// ── WOODCUTTING · FIRE REAGENTS AND BIRD'S NESTS ────────────────────

/// What a plain tree sheds besides its logs: the first three fire
/// reagents, one at a time. Reagents are a near-certain side drop - the
/// tree tier sets how many come with each log, not whether they come.
const List<ItemDropType> treeReagentDropTable = [
  ItemDropType(id: ItemId.DRY_TWIGS, weight: 1),
  ItemDropType(id: ItemId.TREE_BARK, weight: 1),
  ItemDropType(id: ItemId.PINE_RESIN, weight: 1),
];

/// What an oak sheds: the other four, two at a time, so the two trees
/// between them hold every stat a fire can be tended for.
const List<ItemDropType> oakReagentDropTable = [
  ItemDropType(id: ItemId.ACORN, lowCount: 2, highCount: 2, weight: 1),
  ItemDropType(id: ItemId.OAK_GALL, lowCount: 2, highCount: 2, weight: 1),
  ItemDropType(id: ItemId.DRY_LEAVES, lowCount: 2, highCount: 2, weight: 1),
  ItemDropType(id: ItemId.OAK_SAP, lowCount: 2, highCount: 2, weight: 1),
];

/// All seven, evenly, one at a time: what a bird's nest is lined with.
const List<ItemDropType> fireReagentDropTable = [
  ItemDropType(id: ItemId.DRY_TWIGS, weight: 1),
  ItemDropType(id: ItemId.TREE_BARK, weight: 1),
  ItemDropType(id: ItemId.PINE_RESIN, weight: 1),
  ItemDropType(id: ItemId.ACORN, weight: 1),
  ItemDropType(id: ItemId.OAK_GALL, weight: 1),
  ItemDropType(id: ItemId.DRY_LEAVES, weight: 1),
  ItemDropType(id: ItemId.OAK_SAP, weight: 1),
];

/// What the willow and its bog side-grade shed: all seven, three at a time.
const List<ItemDropType> willowReagentDropTable = [
  ItemDropType(id: ItemId.DRY_TWIGS, lowCount: 3, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.TREE_BARK, lowCount: 3, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.PINE_RESIN, lowCount: 3, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.ACORN, lowCount: 3, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.OAK_GALL, lowCount: 3, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.DRY_LEAVES, lowCount: 3, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.OAK_SAP, lowCount: 3, highCount: 3, weight: 1),
];

/// How often a log comes with its reagents: nearly always.
const double treeReagentChance = 0.9;

/// The basic Woodcutter's set, evenly: a small nest's long shot.
const List<ItemDropType> basicWoodcuttersGearDropTable = [
  ItemDropType(id: ItemId.BASIC_WOODCUTTERS_HAT),
  ItemDropType(id: ItemId.BASIC_WOODCUTTERS_TUNIC),
  ItemDropType(id: ItemId.BASIC_WOODCUTTERS_PANTS),
  ItemDropType(id: ItemId.BASIC_WOODCUTTERS_GLOVES),
  ItemDropType(id: ItemId.BASIC_WOODCUTTERS_BOOTS),
  ItemDropType(id: ItemId.BASIC_WOODCUTTERS_CLOAK),
];

/// The novice Woodcutter's set, evenly: a woven nest's long shot.
const List<ItemDropType> noviceWoodcuttersGearDropTable = [
  ItemDropType(id: ItemId.NOVICE_WOODCUTTERS_HAT),
  ItemDropType(id: ItemId.NOVICE_WOODCUTTERS_TUNIC),
  ItemDropType(id: ItemId.NOVICE_WOODCUTTERS_PANTS),
  ItemDropType(id: ItemId.NOVICE_WOODCUTTERS_GLOVES),
  ItemDropType(id: ItemId.NOVICE_WOODCUTTERS_BOOTS),
  ItemDropType(id: ItemId.NOVICE_WOODCUTTERS_CLOAK),
];

/// What opening one nest rolls: a lining of fire reagents (one roll per
/// reagent, Fibonacci by nest tier), a long shot at a piece of the
/// Woodcutter's set of the nest's tier, and a longer one at a gem. Nests are
/// the only source of Woodcutter's gear.
const Map<ItemId, List<DropRoll>> birdsNestRolls = {
  ItemId.SMALL_BIRDS_NEST: [
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(chance: 0.13, entries: basicWoodcuttersGearDropTable),
    DropRoll(chance: 0.01, entries: gemDropTable),
  ],
  ItemId.WOVEN_BIRDS_NEST: [
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(chance: 0.08, entries: noviceWoodcuttersGearDropTable),
    DropRoll(chance: 0.02, entries: gemDropTable),
  ],
};

// ── MINING · GEODES ──────────────────────────────────────────────────

/// The basic Miner's set, evenly.
const List<ItemDropType> basicMinersGearDropTable = [
  ItemDropType(id: ItemId.BASIC_MINERS_HAT),
  ItemDropType(id: ItemId.BASIC_MINERS_TUNIC),
  ItemDropType(id: ItemId.BASIC_MINERS_PANTS),
  ItemDropType(id: ItemId.BASIC_MINERS_GLOVES),
  ItemDropType(id: ItemId.BASIC_MINERS_BOOTS),
  ItemDropType(id: ItemId.BASIC_MINERS_CLOAK),
];

/// The novice Miner's set, evenly.
const List<ItemDropType> noviceMinersGearDropTable = [
  ItemDropType(id: ItemId.NOVICE_MINERS_HAT),
  ItemDropType(id: ItemId.NOVICE_MINERS_TUNIC),
  ItemDropType(id: ItemId.NOVICE_MINERS_PANTS),
  ItemDropType(id: ItemId.NOVICE_MINERS_GLOVES),
  ItemDropType(id: ItemId.NOVICE_MINERS_BOOTS),
  ItemDropType(id: ItemId.NOVICE_MINERS_CLOAK),
];

/// The apprentice Miner's set, evenly.
const List<ItemDropType> apprenticeMinersGearDropTable = [
  ItemDropType(id: ItemId.APPRENTICE_MINERS_HAT),
  ItemDropType(id: ItemId.APPRENTICE_MINERS_TUNIC),
  ItemDropType(id: ItemId.APPRENTICE_MINERS_PANTS),
  ItemDropType(id: ItemId.APPRENTICE_MINERS_GLOVES),
  ItemDropType(id: ItemId.APPRENTICE_MINERS_BOOTS),
  ItemDropType(id: ItemId.APPRENTICE_MINERS_CLOAK),
];

/// The advanced Miner's set, evenly.
const List<ItemDropType> advancedMinersGearDropTable = [
  ItemDropType(id: ItemId.ADVANCED_MINERS_HAT),
  ItemDropType(id: ItemId.ADVANCED_MINERS_TUNIC),
  ItemDropType(id: ItemId.ADVANCED_MINERS_PANTS),
  ItemDropType(id: ItemId.ADVANCED_MINERS_GLOVES),
  ItemDropType(id: ItemId.ADVANCED_MINERS_BOOTS),
  ItemDropType(id: ItemId.ADVANCED_MINERS_CLOAK),
];

/// The master Miner's set, evenly.
const List<ItemDropType> masterMinersGearDropTable = [
  ItemDropType(id: ItemId.MASTER_MINERS_HAT),
  ItemDropType(id: ItemId.MASTER_MINERS_TUNIC),
  ItemDropType(id: ItemId.MASTER_MINERS_PANTS),
  ItemDropType(id: ItemId.MASTER_MINERS_GLOVES),
  ItemDropType(id: ItemId.MASTER_MINERS_BOOTS),
  ItemDropType(id: ItemId.MASTER_MINERS_CLOAK),
];

/// Gems by geode quality: the cheap colored four first, the combat pair
/// next, onyx last. Each tier shifts the weight toward the rarer stones.
const List<ItemDropType> dullGeodeGemTable = [
  ItemDropType(id: ItemId.TOPAZ, weight: 1),
  ItemDropType(id: ItemId.SAPPHIRE, weight: 1),
];

const List<ItemDropType> bandedGeodeGemTable = [
  ItemDropType(id: ItemId.TOPAZ, weight: 1),
  ItemDropType(id: ItemId.SAPPHIRE, weight: 1),
  ItemDropType(id: ItemId.EMERALD, weight: 1),
  ItemDropType(id: ItemId.RUBY, weight: 1),
];

const List<ItemDropType> crystalGeodeGemTable = [
  ItemDropType(id: ItemId.TOPAZ, weight: 1),
  ItemDropType(id: ItemId.SAPPHIRE, weight: 1),
  ItemDropType(id: ItemId.EMERALD, weight: 1),
  ItemDropType(id: ItemId.RUBY, weight: 1),
  ItemDropType(id: ItemId.DIAMOND, weight: 0.3),
  ItemDropType(id: ItemId.DRAGONSTONE, weight: 0.3),
];

const List<ItemDropType> prismaticGeodeGemTable = [
  ItemDropType(id: ItemId.EMERALD, weight: 1),
  ItemDropType(id: ItemId.RUBY, weight: 1),
  ItemDropType(id: ItemId.DIAMOND, weight: 0.6),
  ItemDropType(id: ItemId.DRAGONSTONE, weight: 0.6),
  ItemDropType(id: ItemId.ONYX, weight: 0.08),
];

const List<ItemDropType> radiantGeodeGemTable = [
  ItemDropType(id: ItemId.DIAMOND, weight: 1),
  ItemDropType(id: ItemId.DRAGONSTONE, weight: 1),
  ItemDropType(id: ItemId.ONYX, weight: 0.25),
];

/// What opening one geode rolls: a gem every time from a table that gets
/// richer with the geode's quality (and a second from the Prismatic up), and
/// a long shot at a piece of the Miner's set of the matching tier. The
/// quality tracks the vein it came from, so the better the node the better
/// the gear and the stones. Geodes are the only source of Miner's gear.
const Map<ItemId, List<DropRoll>> geodeRolls = {
  ItemId.DULL_GEODE: [
    DropRoll(entries: dullGeodeGemTable),
    DropRoll(chance: 0.10, entries: basicMinersGearDropTable),
  ],
  ItemId.BANDED_GEODE: [
    DropRoll(entries: bandedGeodeGemTable),
    DropRoll(chance: 0.08, entries: noviceMinersGearDropTable),
  ],
  ItemId.CRYSTAL_GEODE: [
    DropRoll(entries: crystalGeodeGemTable),
    DropRoll(chance: 0.06, entries: apprenticeMinersGearDropTable),
  ],
  ItemId.PRISMATIC_GEODE: [
    DropRoll(entries: prismaticGeodeGemTable),
    DropRoll(chance: 0.5, entries: prismaticGeodeGemTable),
    DropRoll(chance: 0.05, entries: advancedMinersGearDropTable),
  ],
  ItemId.RADIANT_GEODE: [
    DropRoll(entries: radiantGeodeGemTable),
    DropRoll(chance: 0.75, entries: radiantGeodeGemTable),
    DropRoll(chance: 0.04, entries: masterMinersGearDropTable),
  ],
};

/// Everything that opens from the bag like a chest: nests and geodes.
const Map<ItemId, List<DropRoll>> openableRolls = {
  ...birdsNestRolls,
  ...geodeRolls,
};
