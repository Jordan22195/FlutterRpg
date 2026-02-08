import 'package:rpg/data/ObjectStack.dart';
import 'package:flutter/widgets.dart';
import 'skill.dart';
import 'item.dart';
import '../controllers/weighted_drop_table.dart';
import '../utilities/image_resolver.dart';

enum Entities { NULL, TREE, GOBLIN, COPPER }

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
  final WeightedDropTable<Items> dropTable;
  final String? iconAsset;

  EntityDefinition({
    required this.name,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
    required this.itemDrops,
    this.iconAsset,
  }) : dropTable = WeightedDropTable<Items>(items: itemDrops);

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
    Entities.TREE: EntityDefinition(
      name: "Tree",
      iconAsset: "assets/images/entities/tree.png",

      entityType: Skills.WOODCUTTING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [WeightedDropTableEntry<Items>(item: Items.LOGS, weight: 1)],
    ),
    Entities.GOBLIN: CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin.png",

      entityType: Skills.ATTACK,
      defence: 1,
      hitpoints: 10,
      attack: 2,
      attackInterval: 2.0,
      itemDrops: [WeightedDropTableEntry<Items>(item: Items.COINS, weight: 1)],
    ),
    Entities.COPPER: EntityDefinition(
      name: "Copper Vein",
      iconAsset: "assets/images/entities/copper.png",

      entityType: Skills.MINING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<Items>(item: Items.COPPER_ORE, weight: 1),
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

    final result = _defs[id]?.dropTable.roll();
    if (result == null) {
      return ObjectStack(id: Items.NULL, count: 0);
    }
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
