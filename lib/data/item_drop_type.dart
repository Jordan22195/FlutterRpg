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
