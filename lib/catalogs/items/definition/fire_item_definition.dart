import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/fire_item.dart';
import 'package:rpg/catalogs/items/definition/zone_buff_item_definition.dart';

/// A fire. Three parts decide what it does:
///
/// - its type is its behaviour: a cookfire cooks, and carries a fixed
///   [skillBonus]; a campfire or bonfire carries none of its own and is
///   tended with fire reagents instead.
/// - its wood is its [power]: the bonus every reagent thrown on it gives,
///   whatever the stat. Better wood, bigger buffs.
/// - [reagentBurn] is how long one reagent lasts on it. A bonfire is a
///   rung stronger than a campfire of the same wood, but eats reagents
///   faster.
class FireItemDefinition extends ZoneBuffItemDefinition {
  final bool canCook;

  /// What one reagent's buff is worth on this fire. Zero for a cookfire,
  /// which cannot be tended.
  final int power;

  /// How long one reagent burns on this fire.
  final Duration reagentBurn;

  const FireItemDefinition({
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    this.canCook = false,
    this.power = 0,
    this.reagentBurn = const Duration(minutes: 5),
    super.description,
    super.iconAsset,
    super.quality,
  });

  /// Whether reagents can be thrown on this fire.
  bool get tendable => power > 0;

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
    int? power,
    Duration? reagentBurn,
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
      power: power ?? this.power,
      reagentBurn: reagentBurn ?? this.reagentBurn,
    );
  }

  @override
  FireItem toItem(ItemId id) => FireItem(id: id);
}
