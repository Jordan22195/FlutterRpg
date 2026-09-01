import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/entities/definition/entity_definition.dart';
import 'package:rpg/catalogs/entities/model/encounter_entity.dart';
import 'package:rpg/catalogs/entities/model/shop_entity.dart';
import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/rarity.dart';

/// A live entity standing in a zone.
///
/// An instance holds only what is unique to *this* one: its [id], its
/// [instanceId], and whatever runtime state a subclass adds on top. Name,
/// art, rarity and every stat are read through [definition] on each access
/// instead of being copied in at construction, so a catalog tuning change
/// reaches entities that were instantiated long before it was made.
class Entity {
  final EntityId id;

  /// Unique per instance, so the same [EntityId] standing in two zones — or
  /// twice in one dungeon queue — can be told apart. Runtime-only: it is
  /// regenerated on load and never serialized.
  final String instanceId;

  Entity({required this.id}) : instanceId = UniqueKey().toString();

  /// The design-time template every stat is read from. Never mutate it.
  EntityDefinition get definition => id.definition;

  String get name => definition.name;
  Rarity get rarity => definition.rarity;
  String get iconAsset => definition.iconAsset;

  Map<String, dynamic> toJson() {
    // instanceId is intentionally not serialized because it is a
    // runtime-only value
    return {'id': id.name};
  }

  /// Rebuilds an entity from the definition its id names, then overlays the
  /// runtime state the save carries.
  ///
  /// Which class comes back is decided by the definition rather than by a
  /// stored `runtimeType`, so an entity retyped in the catalog resolves to
  /// the right class on its own — no migration. Stat fields written by
  /// older saves are ignored: reading them back is exactly what used to
  /// make a tuning change miss everything already instantiated.
  factory Entity.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    if (rawId is! String) {
      throw FormatException('Missing or invalid "id". Expected String.');
    }

    final entity = parseEntityId(rawId).build();

    if (entity is EncounterEntity) {
      entity.readEncounterStateFromJson(json);
    }
    if (entity is ShopEntity) {
      entity.readShopStateFromJson(json);
    }

    return entity;
  }
}
