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

/// Every gem, weighted so a roll lands on the low tiers most of the time.
/// The ladder is the one the Gem Vein entity already uses inline, which makes
/// this table a drop-in for it.
const List<ItemDropType> gemDropTable = [
  ItemDropType(id: ItemId.TOPAZ, weight: 1),
  ItemDropType(id: ItemId.SAPPHIRE, weight: 0.7),
  ItemDropType(id: ItemId.EMERALD, weight: 0.5),
  ItemDropType(id: ItemId.RUBY, weight: 0.3),
  ItemDropType(id: ItemId.DIAMOND, weight: 0.15),
  ItemDropType(id: ItemId.DRAGONSTONE, weight: 0.07),
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

const List<ItemDropType> mithrilWeaponsDropTable = [
  ItemDropType(id: ItemId.MITHRIL_AXE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_PICKAXE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_SICKLE, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_SHIELD, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_DAGGER, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_SWORD, weight: 1),
  ItemDropType(id: ItemId.MITHRIL_GREATSWORD, weight: 1),
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
