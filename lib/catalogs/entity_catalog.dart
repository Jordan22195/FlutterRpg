import 'package:flutter/widgets.dart';
import '../data/skill_data.dart';
import 'item_catalog.dart';
import '../services/weighted_drop_table_service.dart';

enum EntityId {
  NULL,
  ANVIL,
  ENCHANTING_BENCH,
  JEWELCRAFTING_BENCH,
  BASIC_CAMPIRE,
  OAK_CAMPFIRE,
  FIREPIT,
  TREE,
  OAK_TREE,
  GOBLIN,
  CHICKEN,
  GIANT_SPIDER,
  COPPER,
  IRON,
  TRANQUIL_POND,
  DEEP_POND,
  RIVER,
  LAKE,
  OCEAN,
  TRADING_POST,
  WANDERING_MERCHANT,
}

// Base Entity Class
class Entity {
  final EntityId id;
  final String name;
  final String instanceId;

  Entity({required this.id, required this.name})
    : instanceId = UniqueKey().toString();

  Map<String, dynamic> toJson() {
    return {
      'runtimeType': 'Entity',
      'id': id.name,
      'name': name,
      // instanceId is intentionally not serialized because it is a runtime-only value
    };
  }

  factory Entity.fromJson(Map<String, dynamic> json) {
    final runtimeType = json['runtimeType'];

    if (runtimeType is! String) {
      throw FormatException(
        'Missing or invalid "runtimeType". Expected String.',
      );
    }

    switch (runtimeType) {
      case 'Entity':
        final rawId = json['id'];
        final rawName = json['name'];

        if (rawId is! String) {
          throw FormatException('Missing or invalid "id". Expected String.');
        }

        if (rawName is! String) {
          throw FormatException('Missing or invalid "name". Expected String.');
        }

        final entityId = EntityId.values.firstWhere(
          (e) => e.name == rawId,
          orElse: () => throw FormatException('Invalid EntityId "$rawId".'),
        );

        return Entity(id: entityId, name: rawName);
      case 'CraftingEntity':
        return CraftingEntity.fromJson(json);
      case 'CampfireEntity':
        return CampfireEntity.fromJson(json);
      case 'EncounterEntity':
        return EncounterEntity.fromJson(json);
      case 'CombatEntity':
        return CombatEntity.fromJson(json);
      case 'ShopEntity':
        return ShopEntity.fromJson(json);
      default:
        throw FormatException('Unsupported runtimeType "$runtimeType".');
    }
  }
}

class EntityDefinition {
  final String name;
  final String iconAsset;

  EntityDefinition({required this.name, required this.iconAsset});

  Entity toEntity(EntityId id) => Entity(id: id, name: name);
}

class CraftingEntity extends Entity {
  final SkillId craftingSkill;
  CraftingEntity({
    required super.id,
    required super.name,
    required this.craftingSkill,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'CraftingEntity';
    json['craftingSkill'] = craftingSkill.name;
    return json;
  }

  factory CraftingEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});
    final rawCraftingSkill = json['craftingSkill'];

    if (rawCraftingSkill is! String) {
      throw FormatException(
        'Missing or invalid "craftingSkill". Expected String.',
      );
    }

    final craftingSkill = SkillId.values.firstWhere(
      (s) => s.name == rawCraftingSkill,
      orElse: () =>
          throw FormatException('Invalid SkillId "$rawCraftingSkill".'),
    );

    return CraftingEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      craftingSkill: craftingSkill,
    );
  }
}

class CampfireEntity extends CraftingEntity {
  DateTime? expirationTime;

  CampfireEntity({
    required super.id,
    required super.name,
    super.craftingSkill = SkillId.COOKING,
  });

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'CampfireEntity';
    if (expirationTime != null) {
      json['expirationTime'] = expirationTime!.toIso8601String();
    }
    return json;
  }

  factory CampfireEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = CraftingEntity.fromJson({
      ...json,
      'runtimeType': 'CraftingEntity',
    });

    final campfire = CampfireEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      craftingSkill: baseEntity.craftingSkill,
    );

    // optional: older saves have no expiration on the entity
    final rawExpiration = json['expirationTime'];
    if (rawExpiration is String) {
      campfire.expirationTime = DateTime.tryParse(rawExpiration);
    }

    return campfire;
  }
}

class CraftingEntityDefinition extends EntityDefinition {
  final SkillId craftingSkill;

  CraftingEntityDefinition({
    required super.name,
    required super.iconAsset,
    required this.craftingSkill,
  });

  @override
  CraftingEntity toEntity(EntityId id) =>
      CraftingEntity(id: id, name: name, craftingSkill: craftingSkill);
}

class CampfireEntityDefinition extends CraftingEntityDefinition {
  CampfireEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.craftingSkill = SkillId.COOKING,
  });

  @override
  CampfireEntity toEntity(EntityId id) =>
      CampfireEntity(id: id, name: name, craftingSkill: craftingSkill);
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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'EncounterEntity';
    json['entityType'] = entityType.name;
    json['defence'] = defence;
    json['count'] = count;
    json['hitpoints'] = hitpoints;
    json['maxHitPoints'] = maxHitPoints;
    return json;
  }

  factory EncounterEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});
    final rawEntityType = json['entityType'];
    final rawDefence = json['defence'];
    final rawCount = json['count'];
    final rawHitpoints = json['hitpoints'];
    final rawMaxHitPoints = json['maxHitPoints'];

    if (rawEntityType is! String) {
      throw FormatException(
        'Missing or invalid "entityType". Expected String.',
      );
    }

    if (rawDefence is! int) {
      throw FormatException('Missing or invalid "defence". Expected int.');
    }

    if (rawCount is! int) {
      throw FormatException('Missing or invalid "count". Expected int.');
    }

    if (rawHitpoints is! int) {
      throw FormatException('Missing or invalid "hitpoints". Expected int.');
    }

    if (rawMaxHitPoints is! int) {
      throw FormatException('Missing or invalid "maxHitPoints". Expected int.');
    }

    final entityType = SkillId.values.firstWhere(
      (s) => s.name == rawEntityType,
      orElse: () => throw FormatException('Invalid SkillId "$rawEntityType".'),
    );

    final entity = EncounterEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      count: rawCount,
      entityType: entityType,
      defence: rawDefence,
      hitpoints: rawHitpoints,
    );

    entity.maxHitPoints = rawMaxHitPoints;
    return entity;
  }
}

class EncounterEntityDefinition extends EntityDefinition {
  final SkillId entityType;
  final int defence;
  final int hitpoints;
  final List<WeightedDropTableEntry<ItemId>> itemDrops;

  EncounterEntityDefinition({
    required super.name,
    required super.iconAsset,
    required this.entityType,
    required this.defence,
    required this.hitpoints,
    required this.itemDrops,
  });

  @override
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

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'CombatEntity';
    json['attack'] = attack;
    json['attackInterval'] = attackInterval;
    return json;
  }

  factory CombatEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = EncounterEntity.fromJson({
      ...json,
      'runtimeType': 'EncounterEntity',
    });
    final rawAttack = json['attack'];
    final rawAttackInterval = json['attackInterval'];

    if (rawAttack is! int) {
      throw FormatException('Missing or invalid "attack". Expected int.');
    }

    if (rawAttackInterval is! num) {
      throw FormatException(
        'Missing or invalid "attackInterval". Expected number.',
      );
    }

    final entity = CombatEntity(
      id: baseEntity.id,
      name: baseEntity.name,
      entityType: baseEntity.entityType,
      count: baseEntity.count,
      defence: baseEntity.defence,
      hitpoints: baseEntity.hitpoints,
      attack: rawAttack,
      attackInterval: rawAttackInterval.toDouble(),
    );

    entity.maxHitPoints = baseEntity.maxHitPoints;
    return entity;
  }
}

class CombatEntityDefinition extends EncounterEntityDefinition {
  final int attack;
  final double attackInterval;

  CombatEntityDefinition({
    required super.name,
    required super.iconAsset,
    super.entityType = SkillId.ATTACK,
    required super.defence,
    required super.hitpoints,
    required super.itemDrops,
    required this.attack,
    required this.attackInterval,
  });

  @override
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

// one item stack a shop currently offers
class ShopStockEntry {
  final ItemId itemId;
  int count;

  ShopStockEntry({required this.itemId, required this.count});

  Map<String, dynamic> toJson() {
    return {'itemId': itemId.name, 'count': count};
  }

  factory ShopStockEntry.fromJson(Map<String, dynamic> json) {
    final rawItemId = json['itemId'];
    final rawCount = json['count'];

    if (rawItemId is! String) {
      throw FormatException('Missing or invalid "itemId". Expected String.');
    }
    if (rawCount is! int) {
      throw FormatException('Missing or invalid "count". Expected int.');
    }

    final itemId = ItemId.values.firstWhere(
      (i) => i.name == rawItemId,
      orElse: () => throw FormatException('Invalid ItemId "$rawItemId".'),
    );

    return ShopStockEntry(itemId: itemId, count: rawCount);
  }
}

// Shop Entity Class
// a permanent entity that trades items for coins. its stock and next
// restock time are runtime state, so they serialize with the zone;
// pricing and restock cadence live on the definition
class ShopEntity extends Entity {
  final List<ShopStockEntry> stock = [];
  DateTime? nextRestockAt;

  ShopEntity({required super.id, required super.name});

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['runtimeType'] = 'ShopEntity';
    json['stock'] = stock.map((s) => s.toJson()).toList();
    if (nextRestockAt != null) {
      json['nextRestockAt'] = nextRestockAt!.toIso8601String();
    }
    return json;
  }

  factory ShopEntity.fromJson(Map<String, dynamic> json) {
    final baseEntity = Entity.fromJson({...json, 'runtimeType': 'Entity'});

    final shop = ShopEntity(id: baseEntity.id, name: baseEntity.name);

    final rawStock = json['stock'];
    if (rawStock is List) {
      for (final rawEntry in rawStock) {
        if (rawEntry is Map<String, dynamic>) {
          shop.stock.add(ShopStockEntry.fromJson(rawEntry));
        }
      }
    }

    // optional: a shop that never restocked has no timestamp yet
    final rawRestock = json['nextRestockAt'];
    if (rawRestock is String) {
      shop.nextRestockAt = DateTime.tryParse(rawRestock);
    }

    return shop;
  }
}

class ShopEntityDefinition extends EntityDefinition {
  /// Buy price multiplier applied to an item's value (1.25 = 25% over).
  final double priceMarkup;

  /// How often the shop rerolls its stock.
  final Duration restockInterval;

  /// How many random item stacks a restock puts on the shelf.
  final int stockSlots;

  ShopEntityDefinition({
    required super.name,
    required super.iconAsset,
    this.priceMarkup = 1.25,
    this.restockInterval = const Duration(hours: 6),
    this.stockSlots = 10,
  });

  @override
  ShopEntity toEntity(EntityId id) => ShopEntity(id: id, name: name);
}

// Catalog

class EntityCatalog {
  final _defs = <EntityId, EntityDefinition>{
    //
    //
    //  CRAFTING
    //
    //
    EntityId.ANVIL: CraftingEntityDefinition(
      name: "Anvil",
      craftingSkill: SkillId.BLACKSMITHING,
      iconAsset: "assets/icons/anvil.png",
    ),

    EntityId.ENCHANTING_BENCH: CraftingEntityDefinition(
      name: "Enchanting Bench",
      craftingSkill: SkillId.ENCHANTING,
      iconAsset: "assets/icons/enchanting_bench.png",
    ),

    EntityId.JEWELCRAFTING_BENCH: CraftingEntityDefinition(
      name: "Jewelcrafting Bench",
      craftingSkill: SkillId.JEWELCRAFTING,
      iconAsset: "assets/icons/jewelcrafting_bench.png",
    ),

    EntityId.BASIC_CAMPIRE: CampfireEntityDefinition(
      name: "Basic Campfire",
      craftingSkill: SkillId.COOKING,
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),

    EntityId.OAK_CAMPFIRE: CampfireEntityDefinition(
      name: "Oak Campfire",
      craftingSkill: SkillId.COOKING,
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),

    EntityId.FIREPIT: CraftingEntityDefinition(
      name: "Firepit",
      craftingSkill: SkillId.FIREMAKING,
      iconAsset: "assets/icons/items/basic_campfire.png",
    ),

    //
    //
    //  SHOPS
    //
    //
    EntityId.TRADING_POST: ShopEntityDefinition(
      name: "Trading Post",
      iconAsset: "assets/images/entities/trading_post.png",
      // defaults: 25% markup, 6 hour restock, 10 stock slots
    ),
    EntityId.WANDERING_MERCHANT: ShopEntityDefinition(
      name: "Wandering Merchant",
      iconAsset: "assets/images/entities/wandering_merchant.png",
      // pricier but restocks much faster than the trading post
      priceMarkup: 1.5,
      restockInterval: Duration(hours: 1),
    ),

    //
    //
    //  GATHERING
    //
    //

    // WOODCUTTING
    EntityId.TREE: EncounterEntityDefinition(
      name: "Tree",
      iconAsset: "assets/images/entities/tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1)],
    ),
    EntityId.OAK_TREE: EncounterEntityDefinition(
      name: "Oak Tree",
      iconAsset: "assets/images/entities/oak_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 10,
      hitpoints: 15,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.OAK_LOGS, weight: 1),
      ],
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
    EntityId.GIANT_SPIDER: CombatEntityDefinition(
      name: "Giant Spider",
      iconAsset: "assets/images/entities/giant_spider.png",

      entityType: SkillId.ATTACK,
      defence: 5,
      hitpoints: 20,
      attack: 4,
      attackInterval: 1.5,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1)],
    ),
    EntityId.CHICKEN: CombatEntityDefinition(
      name: "Chicken",
      iconAsset: "assets/images/entities/chicken.png",

      entityType: SkillId.ATTACK,
      defence: 1,
      hitpoints: 5,
      attack: 1,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.CHICKEN_MEAT, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.FEATHER, weight: 1),
      ],
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
        // rare gem finds (lower tiers only in the starter vein)
        WeightedDropTableEntry<ItemId>(id: ItemId.TOPAZ, weight: 0.05),
        WeightedDropTableEntry<ItemId>(id: ItemId.SAPPHIRE, weight: 0.03),
        WeightedDropTableEntry<ItemId>(id: ItemId.EMERALD, weight: 0.02),
      ],
    ),
    EntityId.IRON: EncounterEntityDefinition(
      name: "Iron Vein",
      iconAsset: "assets/images/entities/iron.png",

      entityType: SkillId.MINING,
      defence: 10,
      hitpoints: 15,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.IRON_ORE, weight: 1),
        // rare gem finds, all tiers
        WeightedDropTableEntry<ItemId>(id: ItemId.TOPAZ, weight: 0.06),
        WeightedDropTableEntry<ItemId>(id: ItemId.SAPPHIRE, weight: 0.04),
        WeightedDropTableEntry<ItemId>(id: ItemId.EMERALD, weight: 0.03),
        WeightedDropTableEntry<ItemId>(id: ItemId.RUBY, weight: 0.02),
        WeightedDropTableEntry<ItemId>(id: ItemId.DIAMOND, weight: 0.012),
        WeightedDropTableEntry<ItemId>(id: ItemId.DRAGONSTONE, weight: 0.006),
        WeightedDropTableEntry<ItemId>(id: ItemId.ONYX, weight: 0.003),
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
    EntityId.DEEP_POND: EncounterEntityDefinition(
      name: "Deep Pond",
      iconAsset: "assets/images/entities/tranquil_pond.png",

      entityType: SkillId.FISHING,
      defence: 10,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.TROUT, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.PIKE, weight: 0.5),
        WeightedDropTableEntry<ItemId>(id: ItemId.SALMON, weight: 0.25),
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

  EntityDefinition getDefinitionFor(EntityId id) {
    return _defs[id] ?? EntityDefinition(name: "", iconAsset: "");
  }

  Entity buildEntity(EntityId id) {
    final def = _defs[id];
    if (def == null) {
      return Entity(id: EntityId.NULL, name: "Null");
    }
    return def.toEntity(id);
  }

  /// Returns the icon asset path (if any) for any enum-like id value.
  String iconAssetFor(dynamic objectId) {
    return _defs[objectId]?.iconAsset ?? "";
  }

  /// Returns an ImageProvider for any enum-like id value.
  /// If no icon is configured, returns null.
  ImageProvider? imageProviderFor(dynamic objectId) {
    final asset = iconAssetFor(objectId);
    return AssetImage(asset);
  }
}
