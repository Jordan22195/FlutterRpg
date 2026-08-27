import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/zone_buff_item.dart';
import 'package:rpg/catalogs/items/definition/buff_item_definition.dart';

class ZoneBuffItemDefinition extends BuffItemDefinition {
  const ZoneBuffItemDefinition({
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    super.description,
    super.iconAsset,
    super.quality,
  });

  @override
  ZoneBuffItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    Map<SkillId, int>? skillBonus,
    Duration? duration,
  }) {
    return ZoneBuffItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      skillBonus: skillBonus ?? this.skillBonus,
      duration: duration ?? this.duration,
    );
  }

  // zoneId and ownerEntityId are left unset: they belong to the moment the
  // buff is applied, not to the definition
  @override
  ZoneBuffItem toItem(ItemId id) => ZoneBuffItem(
    id: id,
    name: name,
    value: value,
    skillBonus: Map.of(skillBonus),
    duration: duration,
  );
}
