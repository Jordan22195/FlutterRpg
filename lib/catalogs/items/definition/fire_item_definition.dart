import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/fire_item.dart';
import 'package:rpg/catalogs/items/definition/zone_buff_item_definition.dart';

/// A fire. Its [skillBonus] is what it gives while it burns, and
/// [duration] is how long one lay burns.
///
/// - a cookfire cooks ([canCook]) and carries a fixed cooking + hitpoints
///   bonus.
/// - a bonfire is laid from a [wood] and one fire [reagent]: the reagent
///   picks the stat and the wood its size. Every wood has one bonfire per
///   reagent, each its own recipe.
class FireItemDefinition extends ZoneBuffItemDefinition {
  final bool canCook;

  /// The logs a bonfire is laid from; null for a cookfire.
  final ItemId? wood;

  /// The fire reagent a bonfire is laid with, which picks its stat; null
  /// for a cookfire.
  final ItemId? reagent;

  const FireItemDefinition({
    required super.name,
    required super.value,
    required super.skillBonus,
    required super.duration,
    this.canCook = false,
    this.wood,
    this.reagent,
    super.description,
    super.iconAsset,
    super.quality,
  });

  /// Whether this is a bonfire: laid with a reagent for its stat.
  bool get isBonfire => reagent != null;

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
    ItemId? wood,
    ItemId? reagent,
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
      wood: wood ?? this.wood,
      reagent: reagent ?? this.reagent,
    );
  }

  @override
  FireItem toItem(ItemId id) => FireItem(id: id);
}
