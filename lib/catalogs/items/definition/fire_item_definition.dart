import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/fire_item.dart';
import 'package:rpg/catalogs/items/definition/zone_buff_item_definition.dart';

class FireItemDefinition extends ZoneBuffItemDefinition {
  final bool canCook;

  const FireItemDefinition({
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    this.canCook = false,
    super.description,
    super.iconAsset,
    super.quality,
  });

  @override
  FireItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
    Map<SkillId, int>? skillBonus,
    Duration? duration,
    bool? canCook,
  }) {
    return FireItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      quality: quality ?? this.quality,
      skillBonus: skillBonus ?? this.skillBonus,
      duration: duration ?? this.duration,
      canCook: canCook ?? this.canCook,
    );
  }

  @override
  FireItem toItem(ItemId id) => FireItem(id: id);
}
