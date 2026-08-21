import '../catalogs/items/items.dart';
import 'ObjectStack.dart';
import 'skill_data.dart';
import '../catalogs/entities/entities.dart';

class EncounterActionResult {
  Map<SkillId, double> xp = {};
  List<ObjectStack> items = [];

  /// What the action killed, by kind. Set on every path that takes an
  /// entity down - one at a time in normal play, a whole batch when an
  /// offline settle resolves many actions in one fire.
  List<ObjectStack<EntityId>> entitiesDefeated = [];

  /// Equipment produced by the action. Kept apart from [items] because an
  /// instance carries its own quality and never stacks.
  List<EquipmentItem> equipment = [];

  bool enemyDied = false;
  int damageDone = 0;

  /// How many actions this result accounts for. A batch settling time away
  /// reports what it actually did, which is not always the count it was
  /// handed: materials run out, a fire goes out, a node is stripped.
  int actionsPerformed = 0;
}

/// What one explore action turned up.
class ExploreResult {
  /// Entities discovered, in the order they were found.
  final List<ObjectStack<EntityId>> entities = [];

  /// Items found, already credited to the player and the zone tally.
  final List<ObjectStack<ItemId>> items = [];

  /// Exploration xp awarded. Only the first find is worth xp, so this is
  /// the xp of [entities].first and nothing else.
  double xp = 0;

  /// How many finds the action rolled — 1 plus whatever the player's
  /// exploration level over the zone earned.
  int findCount = 0;

  /// How many explores this result accounts for. A zone with nothing left to
  /// find reports none, however many the settle handed it.
  int actionsPerformed = 0;
}
