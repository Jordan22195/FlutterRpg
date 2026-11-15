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

/// What the maple sheds: all seven, five at a time.
const List<ItemDropType> mapleReagentDropTable = [
  ItemDropType(id: ItemId.DRY_TWIGS, lowCount: 5, highCount: 5, weight: 1),
  ItemDropType(id: ItemId.TREE_BARK, lowCount: 5, highCount: 5, weight: 1),
  ItemDropType(id: ItemId.PINE_RESIN, lowCount: 5, highCount: 5, weight: 1),
  ItemDropType(id: ItemId.ACORN, lowCount: 5, highCount: 5, weight: 1),
  ItemDropType(id: ItemId.OAK_GALL, lowCount: 5, highCount: 5, weight: 1),
  ItemDropType(id: ItemId.DRY_LEAVES, lowCount: 5, highCount: 5, weight: 1),
  ItemDropType(id: ItemId.OAK_SAP, lowCount: 5, highCount: 5, weight: 1),
];

/// What the yew sheds: all seven, eight at a time.
const List<ItemDropType> yewReagentDropTable = [
  ItemDropType(id: ItemId.DRY_TWIGS, lowCount: 8, highCount: 8, weight: 1),
  ItemDropType(id: ItemId.TREE_BARK, lowCount: 8, highCount: 8, weight: 1),
  ItemDropType(id: ItemId.PINE_RESIN, lowCount: 8, highCount: 8, weight: 1),
  ItemDropType(id: ItemId.ACORN, lowCount: 8, highCount: 8, weight: 1),
  ItemDropType(id: ItemId.OAK_GALL, lowCount: 8, highCount: 8, weight: 1),
  ItemDropType(id: ItemId.DRY_LEAVES, lowCount: 8, highCount: 8, weight: 1),
  ItemDropType(id: ItemId.OAK_SAP, lowCount: 8, highCount: 8, weight: 1),
];

/// What the magic tree sheds: all seven, thirteen at a time.
const List<ItemDropType> magicReagentDropTable = [
  ItemDropType(id: ItemId.DRY_TWIGS, lowCount: 13, highCount: 13, weight: 1),
  ItemDropType(id: ItemId.TREE_BARK, lowCount: 13, highCount: 13, weight: 1),
  ItemDropType(id: ItemId.PINE_RESIN, lowCount: 13, highCount: 13, weight: 1),
  ItemDropType(id: ItemId.ACORN, lowCount: 13, highCount: 13, weight: 1),
  ItemDropType(id: ItemId.OAK_GALL, lowCount: 13, highCount: 13, weight: 1),
  ItemDropType(id: ItemId.DRY_LEAVES, lowCount: 13, highCount: 13, weight: 1),
  ItemDropType(id: ItemId.OAK_SAP, lowCount: 13, highCount: 13, weight: 1),
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

/// The apprentice Woodcutter's set, evenly: a sturdy nest's long shot.
const List<ItemDropType> apprenticeWoodcuttersGearDropTable = [
  ItemDropType(id: ItemId.APPRENTICE_WOODCUTTERS_HAT),
  ItemDropType(id: ItemId.APPRENTICE_WOODCUTTERS_TUNIC),
  ItemDropType(id: ItemId.APPRENTICE_WOODCUTTERS_PANTS),
  ItemDropType(id: ItemId.APPRENTICE_WOODCUTTERS_GLOVES),
  ItemDropType(id: ItemId.APPRENTICE_WOODCUTTERS_BOOTS),
  ItemDropType(id: ItemId.APPRENTICE_WOODCUTTERS_CLOAK),
];

/// The advanced Woodcutter's set, evenly: a gilded nest's long shot.
const List<ItemDropType> advancedWoodcuttersGearDropTable = [
  ItemDropType(id: ItemId.ADVANCED_WOODCUTTERS_HAT),
  ItemDropType(id: ItemId.ADVANCED_WOODCUTTERS_TUNIC),
  ItemDropType(id: ItemId.ADVANCED_WOODCUTTERS_PANTS),
  ItemDropType(id: ItemId.ADVANCED_WOODCUTTERS_GLOVES),
  ItemDropType(id: ItemId.ADVANCED_WOODCUTTERS_BOOTS),
  ItemDropType(id: ItemId.ADVANCED_WOODCUTTERS_CLOAK),
];

/// The master Woodcutter's set, evenly: a enchanted nest's long shot.
const List<ItemDropType> masterWoodcuttersGearDropTable = [
  ItemDropType(id: ItemId.MASTER_WOODCUTTERS_HAT),
  ItemDropType(id: ItemId.MASTER_WOODCUTTERS_TUNIC),
  ItemDropType(id: ItemId.MASTER_WOODCUTTERS_PANTS),
  ItemDropType(id: ItemId.MASTER_WOODCUTTERS_GLOVES),
  ItemDropType(id: ItemId.MASTER_WOODCUTTERS_BOOTS),
  ItemDropType(id: ItemId.MASTER_WOODCUTTERS_CLOAK),
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
  // up the trees the lining doubles along the ladder, the gear gets rarer
  // as it gets better, and the gem gets likelier
  ItemId.STURDY_BIRDS_NEST: [
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(chance: 0.05, entries: apprenticeWoodcuttersGearDropTable),
    DropRoll(chance: 0.03, entries: gemDropTable),
  ],
  ItemId.GILDED_BIRDS_NEST: [
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(chance: 0.03, entries: advancedWoodcuttersGearDropTable),
    DropRoll(chance: 0.05, entries: gemDropTable),
  ],
  ItemId.ENCHANTED_BIRDS_NEST: [
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(entries: fireReagentDropTable),
    DropRoll(chance: 0.02, entries: masterWoodcuttersGearDropTable),
    DropRoll(chance: 0.08, entries: gemDropTable),
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

// ── FISHING · JUNK, WATER REAGENTS AND SUNKEN CACHES ───────────────

/// What a line drags up instead of a fish. It sits in every fishing spot's
/// main table, so a junk cast is a cast with no catch and no fish xp.
const List<ItemDropType> fishingJunkDropTable = [
  ItemDropType(id: ItemId.OLD_BOOT, weight: 1),
  ItemDropType(id: ItemId.TIN_CAN, weight: 1),
  ItemDropType(id: ItemId.TANGLED_LINE, weight: 1),
  ItemDropType(id: ItemId.SODDEN_DRIFTWOOD, weight: 1),
];

/// How much of a fishing spot's main table is junk: a quarter of the
/// weight its top fish carries.
const double fishingJunkWeight = 0.25;

/// How often a catch comes up with one of the water's own reagents.
const double waterReagentChance = 0.15;

/// How often a catch comes up with the water's sunken cache: a geode's odds.
const double sunkenCacheChance = 0.02;

/// The basic Fisher's set, evenly.
const List<ItemDropType> basicFishersGearDropTable = [
  ItemDropType(id: ItemId.BASIC_FISHERS_HAT),
  ItemDropType(id: ItemId.BASIC_FISHERS_TUNIC),
  ItemDropType(id: ItemId.BASIC_FISHERS_PANTS),
  ItemDropType(id: ItemId.BASIC_FISHERS_GLOVES),
  ItemDropType(id: ItemId.BASIC_FISHERS_BOOTS),
  ItemDropType(id: ItemId.BASIC_FISHERS_CLOAK),
];

/// The novice Fisher's set, evenly.
const List<ItemDropType> noviceFishersGearDropTable = [
  ItemDropType(id: ItemId.NOVICE_FISHERS_HAT),
  ItemDropType(id: ItemId.NOVICE_FISHERS_TUNIC),
  ItemDropType(id: ItemId.NOVICE_FISHERS_PANTS),
  ItemDropType(id: ItemId.NOVICE_FISHERS_GLOVES),
  ItemDropType(id: ItemId.NOVICE_FISHERS_BOOTS),
  ItemDropType(id: ItemId.NOVICE_FISHERS_CLOAK),
];

/// The apprentice Fisher's set, evenly.
const List<ItemDropType> apprenticeFishersGearDropTable = [
  ItemDropType(id: ItemId.APPRENTICE_FISHERS_HAT),
  ItemDropType(id: ItemId.APPRENTICE_FISHERS_TUNIC),
  ItemDropType(id: ItemId.APPRENTICE_FISHERS_PANTS),
  ItemDropType(id: ItemId.APPRENTICE_FISHERS_GLOVES),
  ItemDropType(id: ItemId.APPRENTICE_FISHERS_BOOTS),
  ItemDropType(id: ItemId.APPRENTICE_FISHERS_CLOAK),
];

/// The advanced Fisher's set, evenly.
const List<ItemDropType> advancedFishersGearDropTable = [
  ItemDropType(id: ItemId.ADVANCED_FISHERS_HAT),
  ItemDropType(id: ItemId.ADVANCED_FISHERS_TUNIC),
  ItemDropType(id: ItemId.ADVANCED_FISHERS_PANTS),
  ItemDropType(id: ItemId.ADVANCED_FISHERS_GLOVES),
  ItemDropType(id: ItemId.ADVANCED_FISHERS_BOOTS),
  ItemDropType(id: ItemId.ADVANCED_FISHERS_CLOAK),
];

/// The master Fisher's set, evenly.
const List<ItemDropType> masterFishersGearDropTable = [
  ItemDropType(id: ItemId.MASTER_FISHERS_HAT),
  ItemDropType(id: ItemId.MASTER_FISHERS_TUNIC),
  ItemDropType(id: ItemId.MASTER_FISHERS_PANTS),
  ItemDropType(id: ItemId.MASTER_FISHERS_GLOVES),
  ItemDropType(id: ItemId.MASTER_FISHERS_BOOTS),
  ItemDropType(id: ItemId.MASTER_FISHERS_CLOAK),
];

/// Each water's own reagents, evenly: an alchemy reagent and a fire
/// reagent (the marsh's two alchemy reagents are its leech and frog). What
/// a catch sometimes comes up with, and what that water's cache is lined
/// with.
const List<ItemDropType> pondReagentDropTable = [
  ItemDropType(id: ItemId.LILY_PAD, weight: 1),
  ItemDropType(id: ItemId.CATTAIL_FLUFF, weight: 1),
];

const List<ItemDropType> creekReagentDropTable = [
  ItemDropType(id: ItemId.CREEK_MOSS, weight: 1),
  ItemDropType(id: ItemId.DRIED_REEDS, weight: 1),
];

const List<ItemDropType> riverReagentDropTable = [
  ItemDropType(id: ItemId.FRESHWATER_MUSSEL, weight: 1),
  ItemDropType(id: ItemId.RIVER_DRIFTWOOD, weight: 1),
];

const List<ItemDropType> marshReagentDropTable = [
  ItemDropType(id: ItemId.LEECH, weight: 1),
  ItemDropType(id: ItemId.MARSH_FROG, weight: 1),
  ItemDropType(id: ItemId.PEAT_CLOD, weight: 1),
];

const List<ItemDropType> smallLakeReagentDropTable = [
  ItemDropType(id: ItemId.DUCKWEED, weight: 1),
  ItemDropType(id: ItemId.DRIED_RUSHES, weight: 1),
];

const List<ItemDropType> lakeReagentDropTable = [
  ItemDropType(id: ItemId.LAKE_SPONGE, weight: 1),
  ItemDropType(id: ItemId.BONE_CORAL, weight: 1),
];

const List<ItemDropType> oceanReagentDropTable = [
  ItemDropType(id: ItemId.SEA_KELP, weight: 1),
  ItemDropType(id: ItemId.AMBERGRIS, weight: 1),
];

/// Each water's cooked fish, evenly, one to three at a time.
const List<ItemDropType> pondCookedFishDropTable = [
  ItemDropType(id: ItemId.COOKED_MINNOW, lowCount: 1, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.COOKED_CARP, lowCount: 1, highCount: 3, weight: 1),
];

const List<ItemDropType> creekCookedFishDropTable = [
  ItemDropType(
    id: ItemId.COOKED_CRAYFISH,
    lowCount: 1,
    highCount: 3,
    weight: 1,
  ),
  ItemDropType(
    id: ItemId.COOKED_BLUEGILL,
    lowCount: 1,
    highCount: 3,
    weight: 1,
  ),
  ItemDropType(id: ItemId.COOKED_TROUT, lowCount: 1, highCount: 3, weight: 1),
];

const List<ItemDropType> riverCookedFishDropTable = [
  ItemDropType(id: ItemId.COOKED_PIKE, lowCount: 1, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.COOKED_SALMON, lowCount: 1, highCount: 3, weight: 1),
];

const List<ItemDropType> marshCookedFishDropTable = [
  ItemDropType(id: ItemId.COOKED_BOG_EEL, lowCount: 1, highCount: 3, weight: 1),
];

const List<ItemDropType> smallLakeCookedFishDropTable = [
  ItemDropType(id: ItemId.COOKED_CATFISH, lowCount: 1, highCount: 3, weight: 1),
  ItemDropType(id: ItemId.COOKED_BASS, lowCount: 1, highCount: 3, weight: 1),
];

const List<ItemDropType> lakeCookedFishDropTable = [
  ItemDropType(
    id: ItemId.COOKED_WHITEFISH,
    lowCount: 1,
    highCount: 3,
    weight: 1,
  ),
  ItemDropType(
    id: ItemId.COOKED_STURGEON,
    lowCount: 1,
    highCount: 3,
    weight: 1,
  ),
];

const List<ItemDropType> oceanCookedFishDropTable = [
  ItemDropType(id: ItemId.COOKED_TUNA, lowCount: 1, highCount: 3, weight: 1),
  ItemDropType(
    id: ItemId.COOKED_SWORDFISH,
    lowCount: 1,
    highCount: 3,
    weight: 1,
  ),
  ItemDropType(id: ItemId.COOKED_SHARK, lowCount: 1, highCount: 3, weight: 1),
];

/// What opening one sunken cache rolls: a lining of the water's own
/// reagents (Fibonacci by the water's tier), a stack of its cooked fish,
/// a fair shot at a fishing potion, a scouting map of the zone the water
/// lies in (the lake and ocean have no zone yet, so no map), and a long shot
/// at a piece of the Fisher's set of the matching tier. Caches are the only
/// source of Fisher's gear.
const Map<ItemId, List<DropRoll>> sunkenCacheRolls = {
  ItemId.POND_CACHE: [
    DropRoll(entries: pondReagentDropTable),
    DropRoll(entries: pondReagentDropTable),
    DropRoll(entries: pondCookedFishDropTable),
    DropRoll(
      chance: 0.25,
      entries: [ItemDropType(id: ItemId.MINOR_FISHING_POTION)],
    ),
    DropRoll(
      chance: 0.05,
      entries: [ItemDropType(id: ItemId.SCOUTING_MAP_TUTORIAL_FARM)],
    ),
    DropRoll(chance: 0.13, entries: basicFishersGearDropTable),
  ],
  ItemId.CREEK_CACHE: [
    DropRoll(entries: creekReagentDropTable),
    DropRoll(entries: creekReagentDropTable),
    DropRoll(entries: creekCookedFishDropTable),
    DropRoll(
      chance: 0.25,
      entries: [ItemDropType(id: ItemId.MINOR_FISHING_POTION)],
    ),
    DropRoll(
      chance: 0.05,
      entries: [ItemDropType(id: ItemId.SCOUTING_MAP_SOUTHWOOD_FOREST)],
    ),
    DropRoll(chance: 0.13, entries: basicFishersGearDropTable),
  ],
  ItemId.RIVER_CACHE: [
    DropRoll(entries: riverReagentDropTable),
    DropRoll(entries: riverReagentDropTable),
    DropRoll(entries: riverReagentDropTable),
    DropRoll(entries: riverCookedFishDropTable),
    DropRoll(chance: 0.25, entries: [ItemDropType(id: ItemId.FISHING_POTION)]),
    DropRoll(
      chance: 0.05,
      entries: [ItemDropType(id: ItemId.SCOUTING_MAP_DARKWOOD_FOREST)],
    ),
    DropRoll(chance: 0.08, entries: noviceFishersGearDropTable),
  ],
  ItemId.MARSH_CACHE: [
    DropRoll(entries: marshReagentDropTable),
    DropRoll(entries: marshReagentDropTable),
    DropRoll(entries: marshReagentDropTable),
    DropRoll(entries: marshCookedFishDropTable),
    DropRoll(chance: 0.25, entries: [ItemDropType(id: ItemId.FISHING_POTION)]),
    DropRoll(
      chance: 0.05,
      entries: [ItemDropType(id: ItemId.SCOUTING_MAP_SWAMP)],
    ),
    DropRoll(chance: 0.08, entries: noviceFishersGearDropTable),
  ],
  ItemId.SMALL_LAKE_CACHE: [
    DropRoll(entries: smallLakeReagentDropTable),
    DropRoll(entries: smallLakeReagentDropTable),
    DropRoll(entries: smallLakeReagentDropTable),
    DropRoll(entries: smallLakeReagentDropTable),
    DropRoll(entries: smallLakeReagentDropTable),
    DropRoll(entries: smallLakeCookedFishDropTable),
    DropRoll(chance: 0.25, entries: [ItemDropType(id: ItemId.FISHING_POTION)]),
    DropRoll(
      chance: 0.05,
      entries: [ItemDropType(id: ItemId.SCOUTING_MAP_MAPLEWATER_LAKE)],
    ),
    DropRoll(chance: 0.06, entries: apprenticeFishersGearDropTable),
  ],
  ItemId.LAKE_CACHE: [
    DropRoll(entries: lakeReagentDropTable),
    DropRoll(entries: lakeReagentDropTable),
    DropRoll(entries: lakeReagentDropTable),
    DropRoll(entries: lakeReagentDropTable),
    DropRoll(entries: lakeReagentDropTable),
    DropRoll(entries: lakeCookedFishDropTable),
    DropRoll(
      chance: 0.25,
      entries: [ItemDropType(id: ItemId.SUPER_FISHING_POTION)],
    ),
    DropRoll(chance: 0.05, entries: advancedFishersGearDropTable),
  ],
  ItemId.OCEAN_CACHE: [
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanReagentDropTable),
    DropRoll(entries: oceanCookedFishDropTable),
    DropRoll(
      chance: 0.25,
      entries: [ItemDropType(id: ItemId.SUPER_FISHING_POTION)],
    ),
    DropRoll(chance: 0.04, entries: masterFishersGearDropTable),
  ],
};

/// Everything that opens from the bag like a chest: nests, geodes and
/// sunken caches.
const Map<ItemId, List<DropRoll>> openableRolls = {
  ...birdsNestRolls,
  ...geodeRolls,
  ...sunkenCacheRolls,
};
