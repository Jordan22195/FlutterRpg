import 'package:rpg/catalogs/entities/entities.dart';

/// One member of a card's queue: [count] copies of [entityId] worked back
/// to back. A card's boss is simply its final member.
class DungeonEntityRef {
  final EntityId entityId;
  final int count;

  const DungeonEntityRef(this.entityId, {this.count = 1});
}

/// One card in the dungeon list: an ordered queue of entities. Clearing
/// every member clears the card.
///
/// [requiresPrevious] gates the card behind the one above it, which is the
/// default march-down-the-floors behaviour. Set it false for a card that
/// sits beside the critical path — an ore vein you may mine or walk past.
class DungeonEntry {
  final String name;
  final List<DungeonEntityRef> entities;
  final bool requiresPrevious;

  const DungeonEntry({
    required this.name,
    required this.entities,
    this.requiresPrevious = true,
  });
}
