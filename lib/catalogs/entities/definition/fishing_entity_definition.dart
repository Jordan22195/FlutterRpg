import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/entities/model/fishing_entity.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';

/// A fishing spot. It never depletes; a cast rolls against its defence, and
/// a catch rolls its fish table — cut to the fish the Fishing level reaches,
/// each fish carrying its own unlock level. The spot itself is gated behind
/// [requiredLevel], which is also its first fish's level.
class FishingEntityDefinition extends EncounterEntityDefinition {
  /// Fishing level required to fish here.
  @override
  final int requiredLevel;

  const FishingEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.entityType = SkillId.FISHING,
    required super.defence,
    required super.hitpoints,
    required super.itemDrops,
    super.bonusDrops,
    this.requiredLevel = 1,
  });

  @override
  FishingEntity toEntity(EntityId id) => FishingEntity(id: id);

  @override
  FishingEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<ItemDropType>? itemDrops,
    List<DropRoll>? bonusDrops,
    int? requiredLevel,
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
      requiredLevel: requiredLevel ?? this.requiredLevel,
    );
  }
}
