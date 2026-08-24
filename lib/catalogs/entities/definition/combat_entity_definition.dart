import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/rarity.dart';
import 'package:rpg/catalogs/entities/model/combat_entity.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';

class CombatEntityDefinition extends EncounterEntityDefinition {
  final int attack;
  final double attackInterval;

  const CombatEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.entityType = SkillId.ATTACK,
    required super.defence,
    required super.hitpoints,
    required super.itemDrops,
    super.bonusDrops,
    required this.attack,
    required this.attackInterval,
  });

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

  @override
  CombatEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<WeightedDropTableEntry<ItemId>>? itemDrops,
    List<DropRoll<ItemId>>? bonusDrops,
    int? attack,
    double? attackInterval,
  }) {
    return CombatEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      entityType: entityType ?? this.entityType,
      defence: defence ?? this.defence,
      hitpoints: hitpoints ?? this.hitpoints,
      itemDrops: itemDrops ?? this.itemDrops,
      bonusDrops: bonusDrops ?? this.bonusDrops,
      attack: attack ?? this.attack,
      attackInterval: attackInterval ?? this.attackInterval,
    );
  }
}
