import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/rarity.dart';
import 'package:rpg/catalogs/entities/combat_type.dart';
import 'package:rpg/catalogs/entities/model/combat_entity.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';

/// A thing that fights back. Its stats are never written by hand: [level]
/// sets the size of its stat budget and [combatType] splits that budget
/// across attack, defence and hitpoints, so every enemy sits on the same
/// curve and a level reads the same everywhere.
class CombatEntityDefinition extends EncounterEntityDefinition {
  /// The stat budget. Recoverable from the three stats via
  /// [CombatType.levelOf].
  final int level;

  /// How the budget splits.
  final CombatType combatType;

  final double attackInterval;

  const CombatEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.entityType = SkillId.ATTACK,
    required this.level,
    required this.combatType,
    required super.itemDrops,
    super.bonusDrops,
    required this.attackInterval,
    // combat stats are derived from level and type by the getters below;
    // the fields the parent stores for them are never read.
  }) : super(defence: 0, hitpoints: 0);

  int get attack => combatType.attackAt(level);

  @override
  int get defence => combatType.defenceAt(level);

  @override
  int get hitpoints => combatType.hitpointsAt(level);

  @override
  CombatEntity toEntity(EntityId id) => CombatEntity(
    id: id,
    name: name,
    count: 1,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
    attack: attack,
    attackInterval: attackInterval,
  );

  /// [defence] and [hitpoints] are inherited from the base signature but
  /// have no meaning here — a combat entity's stats come from [level] and
  /// [combatType], so vary those instead.
  @override
  CombatEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    int? level,
    CombatType? combatType,
    List<WeightedDropTableEntry<ItemId>>? itemDrops,
    List<DropRoll<ItemId>>? bonusDrops,
    double? attackInterval,
  }) {
    assert(
      defence == null && hitpoints == null,
      'combat stats are derived: pass level/combatType, not defence/hitpoints',
    );
    return CombatEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      entityType: entityType ?? this.entityType,
      level: level ?? this.level,
      combatType: combatType ?? this.combatType,
      itemDrops: itemDrops ?? this.itemDrops,
      bonusDrops: bonusDrops ?? this.bonusDrops,
      attackInterval: attackInterval ?? this.attackInterval,
    );
  }
}
