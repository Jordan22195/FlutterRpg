import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/item_drop_type.dart';
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
  final List<ItemDropType> itemDrops;

  /// Extra layered rolls on top of the main drop (rare uniques, bulk
  /// stacks, tertiary drops). Empty for most entities.
  final List<DropRoll> bonusDrops;

  const EncounterEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.rarity,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
    required this.itemDrops,
    this.bonusDrops = const [],
  });

  /// [itemDrops] as a table keyed by the drops themselves, so a roll comes
  /// back knowing which quality it landed on rather than just which item.
  /// Built on read: a definition is const, so it cannot hold a table it
  /// assembled in its constructor.
  List<WeightedDropTableEntry<ItemDropType>> get weightedDropTable =>
      itemDrops.weighted;

  @override
  EncounterEntity toEntity(EntityId id) => EncounterEntity(id: id);

  @override
  EncounterEntityDefinition copyWith({
    String? name,
    String? iconAsset,
    Rarity? rarity,
    SkillId? entityType,
    int? defence,
    int? hitpoints,
    List<ItemDropType>? itemDrops,
    List<DropRoll>? bonusDrops,
  }) {
    return EncounterEntityDefinition(
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
