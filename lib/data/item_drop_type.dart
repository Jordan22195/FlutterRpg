import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// One line of a drop table: which item falls, how big a stack, how often,
/// and at what quality.
///
/// It is a [WeightedDropTableEntry] in its own right, so a table can be
/// rolled for plain item ids the way it always was — that is all a bonus
/// roll wants. It is also the thing the main table rolls *for*:
/// `EncounterEntityDefinition.weightedDropTable` keys its entries by the
/// drop itself, so [rarity] rides through the roll and reaches the loot
/// instead of being flattened back to an id.
class ItemDropType extends WeightedDropTableEntry<ItemId> {
  /// The quality the dropped item arrives at. Only equipment carries one,
  /// so a table can list the same piece twice at different qualities and
  /// weights — a common one often, a rare one rarely.
  final Rarity rarity;

  const ItemDropType({
    required ItemId id,
    this.rarity = Rarity.COMMON,
    int lowCount = 1,
    int highCount = 0,
    double weight = 1,
  }) : super(id: id, count: lowCount, highCount: highCount, weight: weight);

  /// The bottom of the stack range — [WeightedDropTableEntry.count] under
  /// the name the catalog writes it as.
  int get lowCount => count;

  @override
  ItemDropType copyWith({
    ItemId? id,
    Rarity? rarity,
    int? count,
    int? lowCount,
    int? highCount,
    int? unlockLevel,
    double? weight,
  }) {
    return ItemDropType(
      id: id ?? this.id,
      rarity: rarity ?? this.rarity,
      lowCount: lowCount ?? count ?? this.count,
      highCount: highCount ?? this.highCount,
      weight: weight ?? this.weight,
    );
  }

  /// Value identity, so a roll can aggregate stacks by what dropped: the
  /// same item at the same quality is the same drop, however many table
  /// lines produced it.
  @override
  bool operator ==(Object other) {
    return other is ItemDropType &&
        other.id == id &&
        other.rarity == rarity &&
        other.count == count &&
        other.highCount == highCount;
  }

  @override
  int get hashCode => Object.hash(id, rarity, count, highCount);
}

/// One line of a drop table that is a *reference to another table* rather
/// than an item of its own.
///
/// Rolling it yields exactly one pick from [table], so a shared table can
/// sit among ordinary lines as a single weighted entry:
///
/// ```dart
/// itemDrops: [
///   NestedDrop(cookedFishDropTable, weight: 2),
///   NestedDrop(ironToolsDropTable, weight: 1, rarity: Rarity.RARE),
///   ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 5),
/// ],
/// ```
///
/// It is an [ItemDropType], so a table holding one is still a plain
/// `List<ItemDropType>` and nothing downstream had to widen. The [id] it
/// inherits is [ItemId.NULL] and is never meant to be read: a reference is
/// resolved away by [WeightedDrops.flattened] before any roll or payout, and
/// `EncounterSystem._payOutDrops` asserts it never arrives.
///
/// Nesting is an entity-drop feature only. A zone's `discoverableItems` is a
/// `List<WeightedDropTableEntry<ItemId>>`, which one of these is assignable
/// to by subtyping but which has no flattening step — dropped in there it
/// would quietly read as exploration's "found nothing" filler.
class NestedDrop extends ItemDropType {
  /// The table this line stands in for.
  final List<ItemDropType> table;

  /// The quality forced onto everything that comes out of [table],
  /// overriding whatever each leaf declares for itself. Null leaves the
  /// leaves alone.
  ///
  /// This is what lets one shared table serve every rarity variant of a
  /// monster: the same `ironToolsDropTable` referenced at COMMON by the
  /// goblin and at RARE by the goblin warrior. An override applied further
  /// out wins over one applied further in, so the entity always has the
  /// last word on what its own drops are worth.
  final Rarity? rarityOverride;

  /// What to multiply the stack sizes out of [table] by. Null leaves them
  /// as written.
  ///
  /// It applies only to a leaf that declares a *range* — a `highCount`
  /// above its `lowCount`. Those are the bulk lines, the coins and ore and
  /// logs, where "the same drop but more of it" is what a tougher monster
  /// wants. A leaf with a fixed count is left alone on purpose: one iron
  /// dagger is the drop, and four of them is a different drop, not a
  /// bigger one.
  ///
  /// Unlike [rarityOverride], nested multipliers *compound* — a 2x
  /// reference to a table that itself holds a 3x reference pays 6x. A
  /// quality is a category, where the outermost word has to win; this is a
  /// scalar, and scalars multiply.
  final int? countMultiplier;

  const NestedDrop(
    this.table, {
    super.weight = 1,
    Rarity? rarity,
    this.countMultiplier,
  }) : rarityOverride = rarity,
       assert(
         countMultiplier == null || countMultiplier > 0,
         'a count multiplier of 0 would drop nothing at all',
       ),
       super(id: ItemId.NULL);

  /// Stays a [NestedDrop]. The inherited [ItemDropType.copyWith] hard-builds
  /// an `ItemDropType`, so without this a copy would silently come back as a
  /// leaf pointing at [ItemId.NULL] with the sub-table gone.
  ///
  /// A `rarity` passed here becomes the override, and wins over the one
  /// already held, matching the outermost-wins rule.
  @override
  NestedDrop copyWith({
    ItemId? id,
    Rarity? rarity,
    int? count,
    int? lowCount,
    int? highCount,
    int? unlockLevel,
    double? weight,
    List<ItemDropType>? table,
    int? countMultiplier,
  }) {
    return NestedDrop(
      table ?? this.table,
      weight: weight ?? this.weight,
      rarity: rarity ?? rarityOverride,
      countMultiplier: countMultiplier ?? this.countMultiplier,
    );
  }

  /// Identity by the table pointed at, not by the inherited fields — every
  /// reference carries the same [ItemId.NULL], count and rarity, so the
  /// inherited [ItemDropType.==] would call any two of them the same drop.
  @override
  bool operator ==(Object other) {
    return other is NestedDrop &&
        identical(other.table, table) &&
        other.rarityOverride == rarityOverride &&
        other.countMultiplier == countMultiplier &&
        other.weight == weight;
  }

  @override
  int get hashCode => Object.hash(
    identityHashCode(table),
    rarityOverride,
    countMultiplier,
    weight,
  );
}

/// A list of drops as a weighted table keyed by the drops themselves, so a
/// roll comes back knowing which quality it landed on rather than just
/// which item.
///
/// Built on read rather than stored: an entity definition and a [DropRoll]
/// are both const, so neither can hold a table it assembled in its own
/// constructor. Both of them go through here, so the wrap exists once.
///
/// This is also where a [NestedDrop] is resolved — every roll in the game
/// reaches its table through [weighted], so flattening here is the whole of
/// what nesting costs the roller.
extension WeightedDrops on List<ItemDropType> {
  /// Leaves only: every [NestedDrop] replaced by the entries of the table it
  /// points at, each scaled into the share the reference itself held.
  ///
  /// A reference of weight `W` over children summing to `C` gives each child
  /// `c` an effective weight of `W * c / C`. Those add back up to `W`, so
  /// this table's total is untouched and a child's odds come out at
  /// `W/total * c/C` — exactly the two-stage roll the reference describes,
  /// which is why nesting needs nothing from the roller itself.
  ///
  /// A table with no reference in it is handed back as-is. Callers only ever
  /// read the result (`WeightedDropTableService.rollMulitpleTimes` sorts its
  /// own copy), so there is no reason to build a duplicate for the common
  /// case.
  List<ItemDropType> get flattened => _flattened(null, 1, 0);

  /// [override] is the rarity handed down by an enclosing reference and
  /// [multiplier] the stack scaling handed down with it, both already folded
  /// together across however many references deep this is.
  ///
  /// [depth] is what stops a table built at runtime from pointing at itself.
  /// A const table cannot: a cycle between two const values does not compile.
  List<ItemDropType> _flattened(Rarity? override, int multiplier, int depth) {
    assert(
      depth <= _maxNestDepth,
      'drop table nested past $_maxNestDepth deep',
    );
    if (depth > _maxNestDepth) return const [];

    if (override == null &&
        multiplier == 1 &&
        !any((drop) => drop is NestedDrop)) {
      return this;
    }

    final out = <ItemDropType>[];
    for (final drop in this) {
      if (drop is! NestedDrop) {
        out.add(_asEnclosed(drop, override, multiplier));
        continue;
      }
      // scale against the flattened total, not the raw one: they agree in
      // arithmetic but not in floating point, and this is the one that
      // describes the entries actually being emitted
      final children = drop.table._flattened(
        // a quality is a category, so the outermost reference wins; a
        // multiplier is a scalar, so they compound
        override ?? drop.rarityOverride,
        multiplier * (drop.countMultiplier ?? 1),
        depth + 1,
      );
      final total = children.fold<double>(0, (sum, c) => sum + c.weight);
      // an empty or weightless table would divide to NaN here, and NaN
      // reaches the roller as a baffling "weight <= 0"
      if (total <= 0) continue;
      for (final child in children) {
        out.add(child.copyWith(weight: drop.weight * child.weight / total));
      }
    }
    return out;
  }

  List<WeightedDropTableEntry<ItemDropType>> get weighted => [
    for (final drop in flattened)
      WeightedDropTableEntry(
        id: drop,
        count: drop.lowCount,
        highCount: drop.highCount,
        weight: drop.weight,
      ),
  ];
}

/// One leaf as the reference enclosing it asks for: stamped with [override]
/// if it carries one, and its stack range scaled by [multiplier].
///
/// The scaling deliberately passes over a leaf with a fixed count. A range
/// is a bulk line — coins, ore, logs — where more of the same thing is what
/// a multiplier means. A fixed count is the drop itself, and multiplying a
/// dagger into four daggers would be inventing a different drop rather than
/// scaling this one.
ItemDropType _asEnclosed(ItemDropType leaf, Rarity? override, int multiplier) {
  final scale = multiplier != 1 && leaf.highCount > leaf.lowCount;
  if (override == null && !scale) return leaf;
  return leaf.copyWith(
    rarity: override,
    lowCount: scale ? leaf.lowCount * multiplier : null,
    highCount: scale ? leaf.highCount * multiplier : null,
  );
}

/// How deep [WeightedDrops.flattened] will follow references before it calls
/// the table malformed. Content never comes close; this is here because a
/// list built at runtime can be made to contain itself.
const int _maxNestDepth = 8;
