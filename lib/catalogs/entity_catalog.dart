import 'package:rpg/data/ObjectStack.dart';
import 'package:flutter/widgets.dart';
import '../data/skill.dart';
import 'item_catalog.dart';
import '../services/weighted_drop_table_service.dart';
import '../utilities/image_resolver.dart';

enum EntityId { NULL, TREE, GOBLIN, COPPER, TRANQUIL_POND, RIVER, LAKE, OCEAN }

// Base Entity Class
class Entity {
  final EntityId id;
  final String name;
  final String instanceId;

  Entity({required this.id, required this.name})
    : instanceId = UniqueKey().toString();
}

// Encounter Entity Class
class EncounterEntity extends Entity {
  final SkillId entityType;
  final int defence;
  int count;
  int hitpoints;
  int maxHitPoints;

  EncounterEntity({
    required super.id,
    required super.name,
    required this.count,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
  }) : maxHitPoints = hitpoints;
}

class EncounterEntityDefinition {
  final String name;
  final SkillId entityType;
  final int defence;
  final int hitpoints;
  final List<WeightedDropTableEntry<ItemId>> itemDrops;
  final String? iconAsset;

  EncounterEntityDefinition({
    required this.name,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
    required this.itemDrops,
    this.iconAsset,
  });

  EncounterEntity toEntity(EntityId id) => EncounterEntity(
    id: id,
    name: name,
    count: 1,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
  );
}

// Combat Encounter Entity Class
class CombatEntity extends EncounterEntity {
  final int attack;
  final double attackInterval;
  CombatEntity({
    required super.id,
    required super.name,
    super.entityType = SkillId.ATTACK,
    required super.count,
    required super.defence,
    required super.hitpoints,
    required this.attack,
    required this.attackInterval,
  });
}

class CombatEntityDefinition extends EncounterEntityDefinition {
  final int attack;
  final double attackInterval;

  CombatEntityDefinition({
    required super.name,
    super.entityType = SkillId.ATTACK,
    required super.defence,
    required super.hitpoints,
    required super.itemDrops,
    required this.attack,
    required this.attackInterval,
    super.iconAsset,
  });

  CombatEntity toEntity(EntityId id) => CombatEntity(
    id: id,
    name: name,
    count: 1,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
    attack: attack,
    attackInterval: attackInterval,
  );
}

// Catalog

class EntityCatalog {
  static void init() {
    // Register the image resolver for Items.
    EnumImageProviderLookup.register<EntityId>(EntityCatalog.imageProviderFor);
  }

  final _defs = <EntityId, EncounterEntityDefinition>{
    // WOODCUTTING
    EntityId.TREE: EncounterEntityDefinition(
      name: "Tree",
      iconAsset: "assets/images/entities/tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1)],
    ),

    // COMBAT
    EntityId.GOBLIN: CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin.png",

      entityType: SkillId.ATTACK,
      defence: 1,
      hitpoints: 10,
      attack: 2,
      attackInterval: 2.0,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1)],
    ),

    // MINING
    EntityId.COPPER: EncounterEntityDefinition(
      name: "Copper Vein",
      iconAsset: "assets/images/entities/copper.png",

      entityType: SkillId.MINING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.COPPER_ORE, weight: 1),
      ],
    ),
    // FISHING
    EntityId.TRANQUIL_POND: EncounterEntityDefinition(
      name: "Pond",
      iconAsset: "assets/images/entities/tranquil_pond.png",

      entityType: SkillId.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.MINNOW, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.CARP, weight: 0.5),
        WeightedDropTableEntry(id: ItemId.BLUEGILL, weight: .25),
      ],
    ),
    EntityId.RIVER: EncounterEntityDefinition(
      name: "River",
      iconAsset: "assets/images/entities/river.png",

      entityType: SkillId.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.PIKE, weight: 1),
        WeightedDropTableEntry(id: ItemId.SALMON, weight: .5),
        WeightedDropTableEntry(id: ItemId.TROUT, weight: .25),
      ],
    ),
    EntityId.LAKE: EncounterEntityDefinition(
      name: "Lake",
      iconAsset: "assets/images/entities/lake.png",

      entityType: SkillId.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.WHITEFISH, weight: 1),
        WeightedDropTableEntry(id: ItemId.BASS, weight: .5),
        WeightedDropTableEntry(id: ItemId.WHITEFISH, weight: .25),
      ],
    ),
    EntityId.OCEAN: EncounterEntityDefinition(
      name: "Ocean",
      iconAsset: "assets/images/entities/ocean.png",

      entityType: SkillId.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.TUNA, weight: 1),
        WeightedDropTableEntry(id: ItemId.SWORDFISH, weight: .5),
        WeightedDropTableEntry(id: ItemId.SHARK, weight: .25),
      ],
    ),
  };

  EncounterEntityDefinition getDefinitionFor(EntityId id) {
    return _defs[id] ??
        EncounterEntityDefinition(
          name: "",
          entityType: SkillId.NULL,
          defence: 0,
          hitpoints: 0,
          itemDrops: [],
        );
  }

  static EncounterEntity buildEntity(EntityId id) {
    final def = _defs[id];
    if (def == null) {
      return EncounterEntity(
        id: EntityId.NULL,
        name: "Null",
        entityType: SkillId.WOODCUTTING,
        defence: 1,
        hitpoints: 10,
      );
    }
    return def.toEntity(id);
  }

  static ObjectStack entityDropTableRoll(EntityId id) {
    print("rolling loot");
    if (_defs[id] == null) {
      return ObjectStack(id: ItemId.NULL, count: 0);
    }

    final result = WeightedDropTableService.roll(_defs[id]!.itemDrops);

    return result;
  }

  static EncounterEntityDefinition? definitionFor(dynamic objectId) {
    return _defs[objectId as EntityId];
  }

  /// Returns the icon asset path (if any) for any enum-like id value.
  static String? iconAssetFor(dynamic objectId) {
    return EntityCatalog._defs[objectId]?.iconAsset;
  }

  /// Returns an ImageProvider for any enum-like id value.
  /// If no icon is configured, returns null.
  static ImageProvider? imageProviderFor(dynamic objectId) {
    final asset = iconAssetFor(objectId);
    return asset != null ? AssetImage(asset) : null;
  }
}
