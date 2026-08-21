import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/model/encounter_entity.dart';
import 'package:rpg/catalogs/entities/definition/entity_definition.dart';

class EncounterEntityDefinition extends EntityDefinition {
  final SkillId entityType;
  final int defence;
  final int hitpoints;

  /// The main drop: rolled once per kill, always yields one weighted pick.
  final List<WeightedDropTableEntry<ItemId>> itemDrops;

  /// Extra layered rolls on top of the main drop (rare uniques, bulk
  /// stacks, tertiary drops). Empty for most entities.
  final List<DropRoll<ItemId>> bonusDrops;

  const EncounterEntityDefinition({
    required super.name,
    required super.iconAsset,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
    required this.itemDrops,
    this.bonusDrops = const [],
  });

  @override
  EncounterEntity toEntity(EntityId id) => EncounterEntity(
    id: id,
    name: name,
    count: 1,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
  );

  @override
  EncounterEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<WeightedDropTableEntry<ItemId>>? itemDrops,
    List<DropRoll<ItemId>>? bonusDrops,
  }) {
    return EncounterEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      entityType: entityType ?? this.entityType,
      defence: defence ?? this.defence,
      hitpoints: hitpoints ?? this.hitpoints,
      itemDrops: itemDrops ?? this.itemDrops,
      bonusDrops: bonusDrops ?? this.bonusDrops,
    );
  }
}
