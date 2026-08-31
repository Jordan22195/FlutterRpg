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
/// bonusDrops: [DropRoll<ItemId>(chance: 0.02, entries: herbDropTable)],
/// ```
///
/// A table is a list of [ItemDropType], which is itself a weighted drop
/// table entry — so the same table serves as an entity's main `itemDrops`
/// (where it rolls for the drop, quality and all) and as the entries of a
/// [DropRoll] (where it rolls for a plain item id).
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
