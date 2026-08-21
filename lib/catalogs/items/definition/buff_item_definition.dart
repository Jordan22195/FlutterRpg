import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/items/model/buff_item.dart';
import 'package:rpg/catalogs/items/definition/item_definition.dart';

class BuffItemDefinition extends ItemDefinition {
  final Map<SkillId, int> skillBonus;
  final Duration duration;

  const BuffItemDefinition({
    required super.name,
    required super.value,
    required this.skillBonus,
    required this.duration,
    super.description,
    super.iconAsset,
  });

  @override
  BuffItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Map<SkillId, int>? skillBonus,
    Duration? duration,
  }) {
    return BuffItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      skillBonus: skillBonus ?? this.skillBonus,
      duration: duration ?? this.duration,
    );
  }

  @override
  BuffItem toItem(ItemId id) => BuffItem(
    id: id,
    name: name,
    value: value,
    skillBonus: Map.of(skillBonus),
    duration: duration,
  );
}
