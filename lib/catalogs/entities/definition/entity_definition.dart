import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/model/entity.dart';
import 'package:rpg/catalogs/entities/rarity.dart';

class EntityDefinition {
  final String name;
  final String iconAsset;

  /// How rare this entity is. Cosmetic only — it tints the border drawn
  /// around the portrait, on the same ladder crafted equipment uses.
  final Rarity rarity;

  const EntityDefinition({
    required this.name,
    required this.iconAsset,
    this.rarity = Rarity.COMMON,
  });

  Entity toEntity(EntityId id) => Entity(id: id, name: name);

  /// A variant of this definition. Definitions are `const` and shared by
  /// every consumer, so anything needing a tweaked one builds a new value
  /// here rather than writing through a field. For a *mutable* object,
  /// call [toEntity] (or `EntityId.build()`) instead.
  EntityDefinition copyWith({String? name, String? iconAsset, Rarity? rarity}) {
    return EntityDefinition(
      name: name ?? this.name,
      iconAsset: iconAsset ?? this.iconAsset,
      rarity: rarity ?? this.rarity,
    );
  }
}
