import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';

/// An entity an encounter runs against — a resource node, a fishing spot,
/// or something that fights back.
///
/// [count] (how many are standing here) and current [hitpoints] (how hurt
/// the one in front of the player is) are the only genuine per-instance
/// state. The stats are read off the definition.
class EncounterEntity extends Entity {
  int count;
  int _hitpoints;

  EncounterEntity({required super.id, this.count = 1, int? hitpoints})
    : _hitpoints = hitpoints ?? _maxHitPointsOf(id);

  @override
  EncounterEntityDefinition get definition =>
      id.definition as EncounterEntityDefinition;

  SkillId get entityType => definition.entityType;
  int get defence => definition.defence;
  int get maxHitPoints => definition.hitpoints;

  /// Current hp, clamped to the definition's maximum on both read and
  /// write. The clamp is what absorbs a tuning change: an entity saved at
  /// 40/40 whose definition is later cut to 25 comes back at 25/25 rather
  /// than overflowing its own bar, and it needs no migration to do it.
  int get hitpoints => _hitpoints.clamp(0, maxHitPoints);
  set hitpoints(int value) => _hitpoints = value.clamp(0, maxHitPoints);

  // an initializer cannot reach an instance getter, so the default has to
  // come off the definition directly
  static int _maxHitPointsOf(EntityId id) =>
      (id.definition as EncounterEntityDefinition).hitpoints;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['count'] = count;
    json['hitpoints'] = hitpoints;
    return json;
  }

  /// Overlays the saved runtime state onto a freshly built instance. Both
  /// fields are optional: a save that predates them, or an entity the
  /// catalog only just gained, comes back whole and at full health.
  void readEncounterStateFromJson(Map<String, dynamic> json) {
    final rawCount = json['count'];
    if (rawCount is int) {
      count = rawCount;
    }

    // a half-killed entity has to come back half-killed, or closing the app
    // mid-fight heals it
    final rawHitpoints = json['hitpoints'];
    if (rawHitpoints is int) {
      hitpoints = rawHitpoints;
    }
  }
}
