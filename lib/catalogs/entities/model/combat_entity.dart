import 'package:rpg/catalogs/entities/definition/combat_entity_definition.dart';
import 'package:rpg/catalogs/entities/model/encounter_entity.dart';

/// An entity that fights back. Adds no state of its own — what makes it a
/// combat entity is its definition, and attack, swing speed and level are
/// all derived there from the level budget.
class CombatEntity extends EncounterEntity {
  CombatEntity({required super.id, super.count, super.hitpoints});

  @override
  CombatEntityDefinition get definition =>
      id.definition as CombatEntityDefinition;

  int get attack => definition.attack;
  double get attackInterval => definition.attackInterval;
  int get level => definition.level;
}
