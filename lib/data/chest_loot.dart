import '../catalogs/items/items.dart';
import 'ObjectStack.dart';

/// What a chest paid of one item at one rarity. Equipment arrives at the
/// quality its drop line names, so two qualities of the same piece are two
/// lines; everything else carries the rarity its definition declares.
class ChestLoot extends ObjectStack<ItemId> {
  ChestLoot({required super.id, required super.count, required this.rarity});

  final Rarity rarity;
}
