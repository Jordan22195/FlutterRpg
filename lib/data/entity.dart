import 'package:rpg/data/ObjectStack.dart';
import 'package:flutter/widgets.dart';
import 'skill.dart';
import 'item.dart';
import '../controllers/weighted_drop_table.dart';
import '../utilities/image_resolver.dart';

enum Entities { NULL, TREE, GOBLIN, COPPER, TRANQUIL_POND, RIVER, LAKE, OCEAN }

class Entity {
  final Entities id;
  final String name;
  final Skills entityType;
  final int defence;
  int hitpoints;
  int maxHitPoints;

  Entity({
    required this.id,
    required this.name,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
  }) : maxHitPoints = hitpoints;
}

class CombatEntity extends Entity {
  final int attack;
  final double attackInterval;
  CombatEntity({
    required super.id,
    required super.name,
    super.entityType = Skills.ATTACK,
    required super.defence,
    required super.hitpoints,
    required this.attack,
    required this.attackInterval,
  });
}

class EntityDefinition {
  final String name;
  final Skills entityType;
  final int defence;
  final int hitpoints;
  final List<WeightedDropTableEntry<Items>> itemDrops;
  final String? iconAsset;

  EntityDefinition({
    required this.name,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
    required this.itemDrops,
    this.iconAsset,
  });

  Entity toEntity(Entities id) => Entity(
    id: id,
    name: name,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
  );
}

class CombatEntityDefinition extends EntityDefinition {
  final int attack;
  final double attackInterval;

  CombatEntityDefinition({
    required super.name,
    super.entityType = Skills.ATTACK,
    required super.defence,
    required super.hitpoints,
    required super.itemDrops,
    required this.attack,
    required this.attackInterval,
    super.iconAsset,
  });

  CombatEntity toEntity(Entities id) => CombatEntity(
    id: id,
    name: name,
    entityType: entityType,
    defence: defence,
    hitpoints: hitpoints,
    attack: attack,
    attackInterval: attackInterval,
  );
}

class EntityController {
  static void init() {
    // Register the image resolver for Items.
    EnumImageProviderLookup.register<Entities>(
      EntityController.imageProviderFor,
    );
  }

  static final _defs = <Entities, EntityDefinition>{
    // WOODCUTTING
    Entities.TREE: EntityDefinition(
      name: "Tree",
      iconAsset: "assets/images/entities/tree.png",

      entityType: Skills.WOODCUTTING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [WeightedDropTableEntry<Items>(id: Items.LOGS, weight: 1)],
    ),

    // COMBAT
    Entities.GOBLIN: CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin.png",

      entityType: Skills.ATTACK,
      defence: 1,
      hitpoints: 10,
      attack: 2,
      attackInterval: 2.0,
      itemDrops: [WeightedDropTableEntry<Items>(id: Items.COINS, weight: 1)],
    ),

    // MINING
    Entities.COPPER: EntityDefinition(
      name: "Copper Vein",
      iconAsset: "assets/images/entities/copper.png",

      entityType: Skills.MINING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<Items>(id: Items.COPPER_ORE, weight: 1),
      ],
    ),
    // FISHING
    Entities.TRANQUIL_POND: EntityDefinition(
      name: "Pond",
      iconAsset: "assets/images/entities/tranquil_pond.png",

      entityType: Skills.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<Items>(id: Items.MINNOW, weight: 1),
        WeightedDropTableEntry<Items>(id: Items.CARP, weight: 0.5),
        WeightedDropTableEntry(id: Items.BLUEGILL, weight: .25),
      ],
    ),
    Entities.RIVER: EntityDefinition(
      name: "River",
      iconAsset: "assets/images/entities/river.png",

      entityType: Skills.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<Items>(id: Items.PIKE, weight: 1),
        WeightedDropTableEntry(id: Items.SALMON, weight: .5),
        WeightedDropTableEntry(id: Items.TROUT, weight: .25),
      ],
    ),
    Entities.LAKE: EntityDefinition(
      name: "Lake",
      iconAsset: "assets/images/entities/lake.png",

      entityType: Skills.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<Items>(id: Items.WHITEFISH, weight: 1),
        WeightedDropTableEntry(id: Items.BASS, weight: .5),
        WeightedDropTableEntry(id: Items.WHITEFISH, weight: .25),
      ],
    ),
    Entities.OCEAN: EntityDefinition(
      name: "Ocean",
      iconAsset: "assets/images/entities/ocean.png",

      entityType: Skills.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<Items>(id: Items.TUNA, weight: 1),
        WeightedDropTableEntry(id: Items.SWORDFISH, weight: .5),
        WeightedDropTableEntry(id: Items.SHARK, weight: .25),
      ],
    ),
  };

  static Entity buildEntity(Entities id) {
    final def = _defs[id];
    if (def == null) {
      return Entity(
        id: Entities.NULL,
        name: "Null",
        entityType: Skills.WOODCUTTING,
        defence: 1,
        hitpoints: 10,
      );
    }
    return def.toEntity(id);
  }

  static ObjectStack entityDropTableRoll(Entities id) {
    print("rolling loot");
    if (_defs[id] == null) {
      return ObjectStack(id: Items.NULL, count: 0);
    }

    final result = WeightedDropTable.roll(_defs[id]!.itemDrops);

    return result;
  }

  static EntityDefinition? definitionFor(dynamic objectId) {
    return _defs[objectId as Entities];
  }

  /// Returns the icon asset path (if any) for any enum-like id value.
  static String? iconAssetFor(dynamic objectId) {
    return EntityController._defs[objectId]?.iconAsset;
  }

  /// Returns an ImageProvider for any enum-like id value.
  /// If no icon is configured, returns null.
  static ImageProvider? imageProviderFor(dynamic objectId) {
    final asset = iconAssetFor(objectId);
    return asset != null ? AssetImage(asset) : null;
  }
}
