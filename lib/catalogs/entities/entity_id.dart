import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/dungeons/dungeon_id.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:flutter/widgets.dart';

// ignore_for_file: constant_identifier_names

/// Every entity in the game, and its definition.
///
/// The definition rides on the enum constant, so an entity is one entry in
/// one place and the compiler will not let an id exist without a definition.
///
/// **Where does a new entity go?** Entities are grouped into sections by
/// kind, and each section maps to exactly one definition class — the section
/// banner tells you which constructor to write. Within a section, entries
/// ascend by that kind's natural progression (tier, then level, then
/// difficulty).
///
/// Definitions are `const`. Call [build] for a mutable runtime [Entity], or
/// `definition.copyWith(...)` for a variant template.
///
/// [Rarity] is cosmetic — it colors the border around the entity's
/// portrait — and defaults to common, so only an entity that stands out
/// from its neighbours spells one out. Within a section, rarity climbs
/// with the same progression the section is already ordered by.
///
/// The enum *value names* are the save format, so they must never be renamed.
enum EntityId {
  // ── SENTINEL ────────────────────────────────────────────────────
  NULL(EntityDefinition(name: "Nothing", iconAsset: "")),

  // ── CRAFTING STATIONS ───────────────────────────────────────────
  // CraftingEntityDefinition, by craftingSkill in SkillId order
  ANVIL(
    CraftingEntityDefinition(
      name: "Anvil",
      craftingSkill: SkillId.BLACKSMITHING,
      iconAsset: "assets/icons/anvil.png",
    ),
  ),
  ENCHANTING_BENCH(
    CraftingEntityDefinition(
      name: "Enchanting Bench",
      craftingSkill: SkillId.ENCHANTING,
      iconAsset: "assets/icons/enchanting_bench.png",
    ),
  ),
  JEWELCRAFTING_BENCH(
    CraftingEntityDefinition(
      name: "Jewelcrafting Bench",
      craftingSkill: SkillId.JEWELCRAFTING,
      iconAsset: "assets/icons/jewelcrafting_bench.png",
    ),
  ),

  // ── FIREPIT ─────────────────────────────────────────────────────
  // FirePitEntityDefinition
  FIREPIT(
    FirePitEntityDefinition(
      name: "Firepit",
      iconAsset: "assets/images/entities/firepit.png",
    ),
  ),

  // ── WOODCUTTING ─────────────────────────────────────────────────
  // EncounterEntityDefinition, tier ascending — pairs with the LOGS items
  TREE(
    EncounterEntityDefinition(
      name: "Tree",
      iconAsset: "assets/images/entities/tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 1,
      hitpoints: 5,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.LOGS, weight: 1)],
    ),
  ),
  OAK_TREE(
    EncounterEntityDefinition(
      name: "Oak Tree",
      iconAsset: "assets/images/entities/oak_tree.png",
      rarity: Rarity.UNCOMMON,

      entityType: SkillId.WOODCUTTING,
      defence: 10,
      hitpoints: 15,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.OAK_LOGS, weight: 1),
      ],
    ),
  ),

  // ── MINING ──────────────────────────────────────────────────────
  // EncounterEntityDefinition, tier ascending — pairs with the ORES items
  COPPER(
    EncounterEntityDefinition(
      name: "Copper Vein",
      iconAsset: "assets/images/entities/copper.png",

      entityType: SkillId.MINING,
      defence: 1,
      hitpoints: 5,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.COPPER_ORE, weight: 1),

        // rare gem finds (lower tiers only in the starter vein)
      ],
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.05)],
    ),
  ),
  IRON(
    EncounterEntityDefinition(
      name: "Iron Vein",
      iconAsset: "assets/images/entities/iron.png",

      entityType: SkillId.MINING,
      defence: 10,
      hitpoints: 15,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.IRON_ORE, weight: 1),

        // rare gem finds, all tiers
      ],
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.1)],
    ),
  ),
  COAL_VEIN(
    EncounterEntityDefinition(
      name: "Coal Vein",
      iconAsset: "assets/images/entities/coal_vein.png",

      entityType: SkillId.MINING,
      defence: 20,
      hitpoints: 25,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COAL,
          weight: 1,
          count: 1,
          highCount: 3,
        ),
      ],
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.5)],
    ),
  ),
  GEM_VEIN(
    EncounterEntityDefinition(
      name: "Gem Vein",
      iconAsset: "assets/images/entities/gem_vein.png",
      rarity: Rarity.EPIC,

      entityType: SkillId.MINING,
      defence: 40,
      hitpoints: 30,
      itemDrops: gemDropTable,
    ),
  ),

  // ── FISHING ─────────────────────────────────────────────────────
  // FishingEntityDefinition, by the fishing level of what it yields
  TRANQUIL_POND(
    FishingEntityDefinition(
      name: "Pond",
      iconAsset: "assets/images/entities/tranquil_pond.png",

      entityType: SkillId.FISHING,
      defence: 1,
      hitpoints: 10,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.MINNOW, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.CARP, weight: 0.5),
      ],
    ),
  ),
  RIVER(
    FishingEntityDefinition(
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
  ),
  DEEP_POND(
    FishingEntityDefinition(
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
  ),
  LAKE(
    FishingEntityDefinition(
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
  ),
  OCEAN(
    FishingEntityDefinition(
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
  ),

  // ── HERBS ───────────────────────────────────────────────────────
  // HerbEntityDefinition, requiredLevel ascending
  GUAM(
    HerbEntityDefinition(
      name: "Guam Leaf",
      iconAsset: "assets/images/entities/guam.png",
      requiredLevel: 1,
      defence: 1,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.GUAM_LEAF, weight: 1),
      ],
    ),
  ),
  MARRENTILL(
    HerbEntityDefinition(
      name: "Marrentill",
      iconAsset: "assets/images/entities/marrentill.png",
      requiredLevel: 5,
      defence: 5,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.MARRENTILL, weight: 1),
      ],
    ),
  ),
  TARROMIN(
    HerbEntityDefinition(
      name: "Tarromin",
      iconAsset: "assets/images/entities/tarromin.png",
      rarity: Rarity.UNCOMMON,
      requiredLevel: 11,
      defence: 11,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.TARROMIN, weight: 1),
      ],
    ),
  ),
  HARRALANDER(
    HerbEntityDefinition(
      name: "Harralander",
      iconAsset: "assets/images/entities/harralander.png",
      rarity: Rarity.UNCOMMON,
      requiredLevel: 20,
      defence: 20,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.HARRALANDER, weight: 1),
      ],
    ),
  ),
  RANARR(
    HerbEntityDefinition(
      name: "Ranarr Weed",
      iconAsset: "assets/images/entities/ranarr.png",
      rarity: Rarity.RARE,
      requiredLevel: 25,
      defence: 25,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.RANARR_WEED, weight: 1),
      ],
    ),
  ),
  TOADFLAX(
    HerbEntityDefinition(
      name: "Toadflax",
      iconAsset: "assets/images/entities/toadflax.png",
      rarity: Rarity.RARE,
      requiredLevel: 30,
      defence: 30,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.TOADFLAX, weight: 1),
      ],
    ),
  ),
  IRIT(
    HerbEntityDefinition(
      name: "Irit Leaf",
      iconAsset: "assets/images/entities/irit.png",
      rarity: Rarity.RARE,
      requiredLevel: 40,
      defence: 40,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.IRIT_LEAF, weight: 1),
      ],
    ),
  ),
  AVANTOE(
    HerbEntityDefinition(
      name: "Avantoe",
      iconAsset: "assets/images/entities/avantoe.png",
      rarity: Rarity.RARE,
      requiredLevel: 48,
      defence: 48,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.AVANTOE, weight: 1),
      ],
    ),
  ),
  KWUARM(
    HerbEntityDefinition(
      name: "Kwuarm",
      iconAsset: "assets/images/entities/kwuarm.png",
      rarity: Rarity.EPIC,
      requiredLevel: 54,
      defence: 54,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.KWUARM, weight: 1)],
    ),
  ),
  SNAPDRAGON(
    HerbEntityDefinition(
      name: "Snapdragon",
      iconAsset: "assets/images/entities/snapdragon.png",
      rarity: Rarity.EPIC,
      requiredLevel: 59,
      defence: 59,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.SNAPDRAGON, weight: 1),
      ],
    ),
  ),
  CADANTINE(
    HerbEntityDefinition(
      name: "Cadantine",
      iconAsset: "assets/images/entities/cadantine.png",
      rarity: Rarity.EPIC,
      requiredLevel: 65,
      defence: 65,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.CADANTINE, weight: 1),
      ],
    ),
  ),
  LANTADYME(
    HerbEntityDefinition(
      name: "Lantadyme",
      iconAsset: "assets/images/entities/lantadyme.png",
      rarity: Rarity.EPIC,
      requiredLevel: 67,
      defence: 67,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.LANTADYME, weight: 1),
      ],
    ),
  ),
  DWARF_WEED(
    HerbEntityDefinition(
      name: "Dwarf Weed",
      iconAsset: "assets/images/entities/dwarf_weed.png",
      rarity: Rarity.LEGENDARY,
      requiredLevel: 70,
      defence: 70,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.DWARF_WEED, weight: 1),
      ],
    ),
  ),
  TORSTOL(
    HerbEntityDefinition(
      name: "Torstol",
      iconAsset: "assets/images/entities/torstol.png",
      rarity: Rarity.LEGENDARY,
      requiredLevel: 75,
      defence: 75,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.TORSTOL, weight: 1),
      ],
    ),
  ),

  // ── ALCHEMY STATION ─────────────────────────────────────────────
  // CraftingEntityDefinition with craftingSkill: SkillId.ALCHEMY, the
  // counterpart to the ALCHEMY REAGENTS and POTIONS item sections.
  // Nothing here yet.

  // ── COMBAT ──────────────────────────────────────────────────────
  // CombatEntityDefinition, difficulty ascending by hitpoints (2, 5,
  // 10, 10, 20, 20, 25, 50, 120, 200) — bosses land last by construction
  FIELD_RAT(
    CombatEntityDefinition(
      name: "Field Rat",
      iconAsset: "assets/images/entities/field_rat.png",

      entityType: SkillId.ATTACK,
      defence: 1,
      hitpoints: 2,
      attack: 1,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.CHICKEN_MEAT, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.FEATHER, weight: 1),
      ],
    ),
  ),

  CHICKEN(
    CombatEntityDefinition(
      name: "Chicken",
      iconAsset: "assets/images/entities/chicken.png",

      entityType: SkillId.ATTACK,
      defence: 3,
      hitpoints: 5,
      attack: 3,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.CHICKEN_MEAT, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.FEATHER, weight: 1),
      ],
    ),
  ),
  COW(
    CombatEntityDefinition(
      name: "Cow",
      iconAsset: "assets/images/entities/cow.png",

      entityType: SkillId.ATTACK,
      defence: 5,
      hitpoints: 10,
      attack: 5,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.COW_MEAT, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.COW_HIDE, weight: 1),
      ],
    ),
  ),
  GOBLIN(
    CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin.png",

      entityType: SkillId.ATTACK,
      defence: 2,
      hitpoints: 10,
      attack: 6,
      attackInterval: 2.0,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1)],
      // 5% chance, on top of the coin drop, to yield the key that opens
      // the Goblin Queen's Lair landmark dungeon
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.05,
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.GOBLIN_QUEEN_KEY,
              weight: 1,
            ),
          ],
        ),
      ],
    ),
  ),
  BIG_RED(
    CombatEntityDefinition(
      name: "Big Red",
      iconAsset: "assets/images/entities/big_red.png",
      rarity: Rarity.UNCOMMON,

      entityType: SkillId.ATTACK,
      defence: 5,
      hitpoints: 25,
      attack: 7,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.CHICKEN_MEAT, weight: 1),
        WeightedDropTableEntry<ItemId>(
          id: ItemId.FEATHER,
          weight: 1,
          count: 100,
        ),
      ],
    ),
  ),
  GOBLIN_SCOUT(
    CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin_scout.png",
      rarity: Rarity.UNCOMMON,

      entityType: SkillId.ATTACK,
      defence: 5,
      hitpoints: 25,
      attack: 7,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          count: 5,
          highCount: 15,
          weight: 1,
        ),
        WeightedDropTableEntry(id: ItemId.IRON_DAGGER, weight: 1),
        WeightedDropTableEntry(
          id: ItemId.COOKED_BLUEGILL,
          count: 1,
          highCount: 3,
          weight: 1,
        ),
      ],
      // 5% chance, on top of the coin drop, to yield the key that opens
      // the Goblin Queen's Lair landmark dungeon
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.05,
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.GOBLIN_QUEEN_KEY,
              weight: 1,
            ),
          ],
        ),
      ],
    ),
  ),
  GIANT_SPIDER(
    CombatEntityDefinition(
      name: "Giant Spider",
      iconAsset: "assets/images/entities/giant_spider.png",
      rarity: Rarity.UNCOMMON,

      entityType: SkillId.ATTACK,
      defence: 5,
      hitpoints: 20,
      attack: 4,
      attackInterval: 1.5,
      itemDrops: [WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1)],
    ),
  ),
  ROTWOOD_SCARECROW_0(
    CombatEntityDefinition(
      name: "Rotwood Scarecrow",
      iconAsset: "assets/images/entities/rotwood_scarecrow.png",

      entityType: SkillId.ATTACK,
      defence: 12,
      hitpoints: 40,
      attack: 4,
      attackInterval: 2.5,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.FEATHER,
          weight: 1,
          count: 20,
          highCount: 60,
        ),
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          weight: 1,
          count: 25,
          highCount: 75,
        ),
      ],
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.05,
          entries: [
            WeightedDropTableEntry<ItemId>(id: ItemId.PITCHFORK, weight: 1),
          ],
        ),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_1(
    CombatEntityDefinition(
      name: "Rotwood Scarecrow",
      iconAsset: "assets/images/entities/rotwood_scarecrow.png",
      rarity: Rarity.RARE,

      entityType: SkillId.ATTACK,
      defence: 15,
      hitpoints: 60,
      attack: 10,
      attackInterval: 2.5,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.FEATHER,
          weight: 1,
          count: 20,
          highCount: 60,
        ),
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          weight: 1,
          count: 25,
          highCount: 75,
        ),
      ],
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.05,
          entries: [
            WeightedDropTableEntry<ItemId>(id: ItemId.PITCHFORK, weight: 1),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_SEARGENT(
    CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin_scout.png",
      rarity: Rarity.RARE,

      entityType: SkillId.ATTACK,
      defence: 10,
      hitpoints: 50,
      attack: 15,
      attackInterval: 2.0,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(
          id: ItemId.COINS,
          count: 5,
          highCount: 15,
          weight: 1,
        ),
        WeightedDropTableEntry(id: ItemId.IRON_DAGGER, weight: 1),
        WeightedDropTableEntry(id: ItemId.GUAM_LEAF, weight: 1),
        WeightedDropTableEntry(id: ItemId.LIGHT_LEATHER_BOOTS, weight: 1),
        WeightedDropTableEntry(
          id: ItemId.COOKED_BLUEGILL,
          count: 1,
          highCount: 3,
          weight: 1,
        ),
      ],
      // 5% chance, on top of the coin drop, to yield the key that opens
      // the Goblin Queen's Lair landmark dungeon
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.05,
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.GOBLIN_QUEEN_KEY,
              weight: 1,
            ),
          ],
        ),
      ],
    ),
  ),
  SPIDER_BROODMOTHER(
    CombatEntityDefinition(
      name: "Spider Broodmother",
      iconAsset: "assets/images/entities/spider_broodmother.png",
      rarity: Rarity.EPIC,

      entityType: SkillId.ATTACK,
      defence: 12,
      hitpoints: 120,
      attack: 8,
      attackInterval: 2.5,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.COINS, weight: 1, count: 100),
      ],
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.08,
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.SPIDER_SILK_NECKLACE,
              weight: 1,
            ),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_QUEEN(
    CombatEntityDefinition(
      name: "Goblin Queen",
      iconAsset: "assets/images/entities/goblin_queen.png",
      rarity: Rarity.LEGENDARY,

      entityType: SkillId.ATTACK,
      defence: 30,
      hitpoints: 200,
      attack: 14,
      attackInterval: 2.5,
      itemDrops: [
        WeightedDropTableEntry<ItemId>(id: ItemId.GOBLIN_CROWN, weight: 1),
        WeightedDropTableEntry<ItemId>(id: ItemId.GOBLIN_SCEPTER, weight: 1),
      ],
      bonusDrops: [
        // guaranteed bulk currency
        DropRoll<ItemId>(
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.COINS,
              weight: 1,
              count: 500,
            ),
          ],
        ),
        // rare second unique on top of the guaranteed one
        DropRoll<ItemId>(
          chance: 0.1,
          entries: [
            WeightedDropTableEntry<ItemId>(id: ItemId.GOBLIN_CROWN, weight: 1),
            WeightedDropTableEntry<ItemId>(
              id: ItemId.GOBLIN_SCEPTER,
              weight: 1,
            ),
          ],
        ),
      ],
    ),
  ),

  // ── SHOPS ───────────────────────────────────────────────────────
  // ShopEntityDefinition, by zone then stock tier
  FARMER(
    ShopEntityDefinition(
      name: "Farmer John",
      iconAsset: "assets/images/entities/farmer_john.png",
      stockSlots: 11,
      restockInterval: Duration(minutes: 30),
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.COOKED_MINNOW, count: 10),
        ShopStockEntry(itemId: ItemId.MINNOW, count: 20),
        ShopStockEntry(itemId: ItemId.FEATHER, count: 20),
        ShopStockEntry(itemId: ItemId.LIGHT_LEATHER_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.LIGHT_LEATHER_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.LIGHT_LEATHER_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.LIGHT_LETHER_CHEST, count: 1),
        ShopStockEntry(itemId: ItemId.PITCHFORK, count: 1),
        ShopStockEntry(itemId: ItemId.SIMPLE_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.STONE_AXE, count: 1),
        ShopStockEntry(itemId: ItemId.STONE_PICKAXE, count: 1),
      ],

      // defaults: 25% markup, 6 hour restock, 10 stock slots
    ),
  ),
  TRADING_POST(
    ShopEntityDefinition(
      name: "Trading Post",
      iconAsset: "assets/images/entities/trading_post.png",
      rarity: Rarity.UNCOMMON,
      shopStockPool: [
        // the full iron set, one entry per slot: exactly stockSlots many, so
        // a restock puts the whole set on the shelf
        ShopStockEntry(itemId: ItemId.IRON_HELMET, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_CHESTPLATE, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_LEGS, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_SHIELD, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_DAGGER, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_AXE, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_PICKAXE, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_SICKLE, count: 1),
      ],
      // defaults: 25% markup, 6 hour restock, 10 stock slots
    ),
  ),
  WANDERING_MERCHANT(
    ShopEntityDefinition(
      name: "Wandering Merchant",
      iconAsset: "assets/images/entities/wandering_merchant.png",
      rarity: Rarity.RARE,
      // pricier but restocks much faster than the trading post
      priceMarkup: 1.5,
      restockInterval: Duration(hours: 1),
      stockSlots: 1,
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.COPPER_PICKAXE, count: 1),
        ShopStockEntry(itemId: ItemId.COPPER_AXE, count: 1),
        ShopStockEntry(itemId: ItemId.COPPER_SICKLE, count: 1),
        ShopStockEntry(itemId: ItemId.GOBLIN_QUEEN_KEY, count: 1),
        ShopStockEntry(itemId: ItemId.GOBLIN_SCEPTER, count: 1),
      ],
    ),
  ),

  // ── DUNGEON ENTRANCES ───────────────────────────────────────────
  // DungeonEntityDefinition, same order as dungeon_id.dart
  SPIDER_DEN_ENTRANCE(
    DungeonEntityDefinition(
      name: "Spider Den",
      iconAsset: "assets/images/entities/spider_den.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.SPIDER_DEN,
    ),
  ),
  GOBLIN_CAMP(
    DungeonEntityDefinition(
      name: "Goblin Camp",
      iconAsset: "assets/images/entities/goblin_camp.png",
      rarity: Rarity.EPIC,
      dungeonId: DungeonId.GOBLIN_CAMP,
    ),
  ),
  DEV_DUNGEON_ENTRANCE(
    DungeonEntityDefinition(
      name: "Dev Transient Dungeon",
      iconAsset: "assets/images/entities/spider_den.png",
      dungeonId: DungeonId.DEV_TRANSIENT_DUNGEON,
    ),
  );

  const EntityId(this.definition);

  /// The design-time template for this entity. Never mutate it.
  final EntityDefinition definition;

  /// A fresh, mutable runtime instance of this entity.
  Entity build() => definition.toEntity(this);

  String get iconAsset => definition.iconAsset;

  /// Icon lookup for [EnumImageProviderLookup], which keys on the id's Type
  /// and so hands back a `dynamic`.
  static ImageProvider? providerFor(dynamic id) {
    if (id is! EntityId) return null;
    final asset = id.iconAsset;
    return asset.isEmpty ? null : AssetImage(asset);
  }
}
