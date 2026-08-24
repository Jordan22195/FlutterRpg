import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/rarity.dart';
import 'package:rpg/catalogs/entities/model/fishing_entity.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';

class FishingEntityDefinition extends EncounterEntityDefinition {
  const FishingEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.entityType = SkillId.FISHING,
    required super.defence,
    required super.hitpoints,
    required super.itemDrops,
    super.bonusDrops,
  });

  @override
  FishingEntity toEntity(EntityId id) => FishingEntity(
    id: id,
    name: name,
    count: 1,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
  );

  @override
  FishingEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<WeightedDropTableEntry<ItemId>>? itemDrops,
    List<DropRoll<ItemId>>? bonusDrops,
  }) {
    return FishingEntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
      entityType: entityType ?? this.entityType,
      defence: defence ?? this.defence,
      hitpoints: hitpoints ?? this.hitpoints,
      itemDrops: itemDrops ?? this.itemDrops,
      bonusDrops: bonusDrops ?? this.bonusDrops,
    );
  }
}
