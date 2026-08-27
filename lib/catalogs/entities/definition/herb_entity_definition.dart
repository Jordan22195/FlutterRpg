import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/entities/definition/encounter_entity_definition.dart';
import 'package:rpg/catalogs/rarity.dart';

// An herb node. Unlike trees/ore it has no meaningful hitpoints: one
// gathering action consumes one count and always succeeds; the roll
// against its difficulty (defence) only sets the yield. Picking is
// gated behind a herbalism level. The runtime entity is a plain
// EncounterEntity, so nothing new serializes.
class HerbEntityDefinition extends EncounterEntityDefinition {
  /// Herbalism level required to pick this herb.
  final int requiredLevel;

  const HerbEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    super.entityType = SkillId.HERBALISM,
    required super.defence,
    super.hitpoints = 1,
    required super.itemDrops,
    super.bonusDrops,
    this.requiredLevel = 1,
  });

  @override
  HerbEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<WeightedDropTableEntry<ItemId>>? itemDrops,
    List<DropRoll<ItemId>>? bonusDrops,
    int? requiredLevel,
  }) {
    return HerbEntityDefinition(
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
