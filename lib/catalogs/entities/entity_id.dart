import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/items/attack_speed.dart';
import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/catalogs/dungeons/dungeon_id.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/item_drop_type.dart';

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
      itemDrops: [ItemDropType(id: ItemId.LOGS, weight: 1)],
    ),
  ),
  OAK_TREE(
    EncounterEntityDefinition(
      name: "Oak Tree",
      iconAsset: "assets/images/entities/oak_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 10,
      hitpoints: 15,
      itemDrops: [ItemDropType(id: ItemId.OAK_LOGS, weight: 1)],
    ),
  ),
  // Tier 3 woodcutting, sat at the same level as the coal vein so the two
  // gathering ladders stay in step. Grows in Darkwood Forest.
  WILLOW_TREE(
    EncounterEntityDefinition(
      name: "Willow Tree",
      iconAsset: "assets/images/entities/willow_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 20,
      hitpoints: 25,
      itemDrops: [ItemDropType(id: ItemId.WILLOW_LOGS, weight: 1)],
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
        ItemDropType(id: ItemId.COPPER_ORE, weight: 1),

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
        ItemDropType(id: ItemId.IRON_ORE, weight: 1),

        // rare gem finds, all tiers
      ],
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.1)],
    ),
  ),
  // Tier 3 mining alongside the coal vein, and the first node anywhere that
  // yields GOLD_ORE — the ore existed as an item with no way to obtain it.
  GOLD_VEIN(
    EncounterEntityDefinition(
      name: "Gold Vein",
      iconAsset: "assets/images/entities/gold_vein.png",

      entityType: SkillId.MINING,
      defence: 20,
      hitpoints: 30,
      itemDrops: [
        ItemDropType(id: ItemId.GOLD_ORE, weight: 1, lowCount: 1, highCount: 2),
      ],
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
        ItemDropType(id: ItemId.COAL, weight: 1, lowCount: 1, highCount: 3),
      ],
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.5)],
    ),
  ),
  GEM_VEIN(
    EncounterEntityDefinition(
      name: "Gem Vein",
      iconAsset: "assets/images/entities/gem_vein.png",
      rarity: Rarity.RARE,

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
        ItemDropType(id: ItemId.MINNOW, weight: 1),
        ItemDropType(id: ItemId.CARP, weight: 0.5),
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
        ItemDropType(id: ItemId.PIKE, weight: 1),
        ItemDropType(id: ItemId.SALMON, weight: .5),
        ItemDropType(id: ItemId.TROUT, weight: .25),
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
        ItemDropType(id: ItemId.TROUT, weight: 1),
        ItemDropType(id: ItemId.PIKE, weight: 0.5),
        ItemDropType(id: ItemId.SALMON, weight: 0.25),
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
        ItemDropType(id: ItemId.WHITEFISH, weight: 1),
        ItemDropType(id: ItemId.BASS, weight: .5),
        ItemDropType(id: ItemId.WHITEFISH, weight: .25),
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
        ItemDropType(id: ItemId.TUNA, weight: 1),
        ItemDropType(id: ItemId.SWORDFISH, weight: .5),
        ItemDropType(id: ItemId.SHARK, weight: .25),
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
      itemDrops: [ItemDropType(id: ItemId.GUAM_LEAF, weight: 1)],
    ),
  ),
  MARRENTILL(
    HerbEntityDefinition(
      name: "Marrentill",
      iconAsset: "assets/images/entities/marrentill.png",
      requiredLevel: 5,
      defence: 5,
      itemDrops: [ItemDropType(id: ItemId.MARRENTILL, weight: 1)],
    ),
  ),
  TARROMIN(
    HerbEntityDefinition(
      name: "Tarromin",
      iconAsset: "assets/images/entities/tarromin.png",
      requiredLevel: 11,
      defence: 11,
      itemDrops: [ItemDropType(id: ItemId.TARROMIN, weight: 1)],
    ),
  ),
  HARRALANDER(
    HerbEntityDefinition(
      name: "Harralander",
      iconAsset: "assets/images/entities/harralander.png",
      requiredLevel: 20,
      defence: 20,
      itemDrops: [ItemDropType(id: ItemId.HARRALANDER, weight: 1)],
    ),
  ),
  RANARR(
    HerbEntityDefinition(
      name: "Ranarr Weed",
      iconAsset: "assets/images/entities/ranarr.png",
      requiredLevel: 25,
      defence: 25,
      itemDrops: [ItemDropType(id: ItemId.RANARR_WEED, weight: 1)],
    ),
  ),
  TOADFLAX(
    HerbEntityDefinition(
      name: "Toadflax",
      iconAsset: "assets/images/entities/toadflax.png",
      requiredLevel: 30,
      defence: 30,
      itemDrops: [ItemDropType(id: ItemId.TOADFLAX, weight: 1)],
    ),
  ),
  IRIT(
    HerbEntityDefinition(
      name: "Irit Leaf",
      iconAsset: "assets/images/entities/irit.png",
      requiredLevel: 40,
      defence: 40,
      itemDrops: [ItemDropType(id: ItemId.IRIT_LEAF, weight: 1)],
    ),
  ),
  AVANTOE(
    HerbEntityDefinition(
      name: "Avantoe",
      iconAsset: "assets/images/entities/avantoe.png",
      requiredLevel: 48,
      defence: 48,
      itemDrops: [ItemDropType(id: ItemId.AVANTOE, weight: 1)],
    ),
  ),
  KWUARM(
    HerbEntityDefinition(
      name: "Kwuarm",
      iconAsset: "assets/images/entities/kwuarm.png",
      requiredLevel: 54,
      defence: 54,
      itemDrops: [ItemDropType(id: ItemId.KWUARM, weight: 1)],
    ),
  ),
  SNAPDRAGON(
    HerbEntityDefinition(
      name: "Snapdragon",
      iconAsset: "assets/images/entities/snapdragon.png",
      requiredLevel: 59,
      defence: 59,
      itemDrops: [ItemDropType(id: ItemId.SNAPDRAGON, weight: 1)],
    ),
  ),
  CADANTINE(
    HerbEntityDefinition(
      name: "Cadantine",
      iconAsset: "assets/images/entities/cadantine.png",
      requiredLevel: 65,
      defence: 65,
      itemDrops: [ItemDropType(id: ItemId.CADANTINE, weight: 1)],
    ),
  ),
  LANTADYME(
    HerbEntityDefinition(
      name: "Lantadyme",
      iconAsset: "assets/images/entities/lantadyme.png",
      requiredLevel: 67,
      defence: 67,
      itemDrops: [ItemDropType(id: ItemId.LANTADYME, weight: 1)],
    ),
  ),
  DWARF_WEED(
    HerbEntityDefinition(
      name: "Dwarf Weed",
      iconAsset: "assets/images/entities/dwarf_weed.png",
      requiredLevel: 70,
      defence: 70,
      itemDrops: [ItemDropType(id: ItemId.DWARF_WEED, weight: 1)],
    ),
  ),
  TORSTOL(
    HerbEntityDefinition(
      name: "Torstol",
      iconAsset: "assets/images/entities/torstol.png",
      requiredLevel: 75,
      defence: 75,
      itemDrops: [ItemDropType(id: ItemId.TORSTOL, weight: 1)],
    ),
  ),

  // ── ALCHEMY STATION ─────────────────────────────────────────────
  // CraftingEntityDefinition with craftingSkill: SkillId.ALCHEMY, the
  // counterpart to the ALCHEMY REAGENTS and POTIONS item sections.
  ALCHEMY_STATION(
    CraftingEntityDefinition(
      name: "Alchemy Station",
      craftingSkill: SkillId.ALCHEMY,
      iconAsset: "assets/icons/alchemy_station.png",
    ),
  ),

  // ── COMBAT ──────────────────────────────────────────────────────
  // CombatEntityDefinition. Stats are not written here: level sets
  // the stat budget and combatType splits it (see CombatType).
  // Ascending by level (1, 2, 3, 4, 4, 6, 6, 8, 12, 12, 15, 28) —
  // bosses land last by construction
  FIELD_RAT(
    CombatEntityDefinition(
      name: "Field Rat",
      iconAsset: "assets/images/entities/field_rat.png",

      entityType: SkillId.ATTACK,
      level: 1,
      combatType: CombatType.PLATE_DPS,
      attackInterval: 2.0,
      // The weakest thing in the game, so it pays the smallest purse rather
      // than nothing: an empty table is not rollable — roll() returns
      // `ObjectStack(id: 0 as T)` for one, which throws on the cast.
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 3, weight: 1),
      ],
    ),
  ),

  CHICKEN(
    CombatEntityDefinition(
      name: "Chicken",
      iconAsset: "assets/images/entities/chicken.png",

      entityType: SkillId.ATTACK,
      level: 2,
      combatType: CombatType.LEATHER_DPS,
      attackInterval: 2.0,
      itemDrops: [
        ItemDropType(id: ItemId.CHICKEN_MEAT, weight: 1),
        ItemDropType(id: ItemId.FEATHER, lowCount: 1, highCount: 5, weight: 1),
      ],
    ),
  ),
  GOBLIN(
    CombatEntityDefinition(
      name: "Goblin",
      iconAsset: "assets/images/entities/goblin.png",

      entityType: SkillId.ATTACK,
      level: 5,
      combatType: CombatType.CLOTH_DPS,
      attackInterval: 2.0,
      itemDrops: [ItemDropType(id: ItemId.COINS, weight: 1)],
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
  COW(
    CombatEntityDefinition(
      name: "Cow",
      iconAsset: "assets/images/entities/cow.png",

      entityType: SkillId.ATTACK,
      level: 5,
      combatType: CombatType.PLATE_DPS,
      attackInterval: 2.0,
      itemDrops: [
        ItemDropType(id: ItemId.COW_MEAT, weight: 1),
        ItemDropType(id: ItemId.COW_HIDE, weight: 1),
      ],
    ),
  ),
  GIANT_SPIDER(
    CombatEntityDefinition(
      name: "Giant Spider",
      iconAsset: "assets/images/entities/giant_spider.png",
      rarity: Rarity.UNCOMMON,

      entityType: SkillId.ATTACK,
      level: 13,
      combatType: CombatType.BALANCE,
      attackInterval: 1.5,
      itemDrops: [
        ItemDropType(id: ItemId.SILK, weight: 1),
        ItemDropType(id: ItemId.VENOM, weight: 1),
      ],
    ),
  ),
  BIG_RED(
    CombatEntityDefinition(
      name: "Big Red",
      iconAsset: "assets/images/entities/big_red.png",
      rarity: Rarity.UNCOMMON,

      entityType: SkillId.ATTACK,
      level: 8,
      combatType: CombatType.LEATHER_DPS,
      attackInterval: 2.0,
      itemDrops: [
        ItemDropType(id: ItemId.CHICKEN_MEAT, weight: 1),
        ItemDropType(
          id: ItemId.FEATHER,
          weight: 1,
          lowCount: 25,
          highCount: 50,
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
      level: 8,
      combatType: CombatType.LEATHER_DPS,
      attackInterval: 2.0,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 5, highCount: 15, weight: 1),
        ItemDropType(id: ItemId.IRON_DAGGER, weight: 1),
        ItemDropType(
          id: ItemId.COOKED_BLUEGILL,
          lowCount: 1,
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
  ROTWOOD_SCARECROW(
    CombatEntityDefinition(
      name: "Rotwood Scarecrow",
      iconAsset: "assets/images/entities/rotwood_scarecrow.png",

      entityType: SkillId.ATTACK,
      level: 8,
      combatType: CombatType.PLATE_TANK,
      attackInterval: 2.5,
      itemDrops: [
        ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 1, highCount: 4),
        ItemDropType(id: ItemId.COINS, weight: 1, lowCount: 3, highCount: 10),
        ItemDropType(id: ItemId.IRON_ORE, weight: 1, lowCount: 1, highCount: 2),
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
      level: 13,
      combatType: CombatType.LEATHER_TANK,
      attackInterval: 2.5,
      itemDrops: [
        ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 1, highCount: 4),
        ItemDropType(id: ItemId.COINS, weight: 1, lowCount: 3, highCount: 10),
        ItemDropType(id: ItemId.IRON_ORE, weight: 1, lowCount: 1, highCount: 2),
      ],
      bonusDrops: [
        DropRoll<ItemId>(
          chance: 0.50,
          entries: [
            WeightedDropTableEntry<ItemId>(
              id: ItemId.RARE_PITCHFORK,
              weight: 1,
            ),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_SEARGENT(
    CombatEntityDefinition(
      name: "Goblin Seargent",
      iconAsset: "assets/images/entities/goblin_scout.png",
      rarity: Rarity.RARE,

      entityType: SkillId.ATTACK,
      level: 21,
      combatType: CombatType.LEATHER_DPS,
      attackInterval: 2.0,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 5, highCount: 15, weight: 1),
        ItemDropType(id: ItemId.IRON_DAGGER, weight: 1),
        ItemDropType(id: ItemId.GUAM_LEAF, weight: 1),
        ItemDropType(id: ItemId.LIGHT_LEATHER_BOOTS, weight: 1),
        ItemDropType(
          id: ItemId.COOKED_BLUEGILL,
          lowCount: 1,
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
  MUDLURC(
    CombatEntityDefinition(
      name: "Mudlurc",
      iconAsset: "assets/images/entities/mudlurc.png",
      level: 35,
      combatType: CombatType.CLOTH_DPS,
      itemDrops: [
        ItemDropType(id: ItemId.SALMON, weight: 1),
        ItemDropType(id: ItemId.PIKE, weight: 1),
        ItemDropType(id: ItemId.TROUT, weight: 1),
        ItemDropType(id: ItemId.SCALE, lowCount: 1, highCount: 3, weight: 3),
      ],
      attackInterval: 1.0,
    ),
  ),
  // the weighted drop table just spits out the object you put in as an id.
  // right now the id is alwasy an enumeration but it could be an Item type.
  // Make a lightweght item drop type with id, quality, count, drop weight.
  // under the hood itme drop type is passed as an entry into the wieghted
  // drop table and the item quality is preserved in the results.
  MUDLURC_WARRIOR(
    CombatEntityDefinition(
      name: "Mudlurc",
      iconAsset: "assets/images/entities/mudlurc.png",
      level: 55,
      combatType: CombatType.CLOTH_DPS,
      itemDrops: [
        ItemDropType(id: ItemId.SALMON),
        ItemDropType(id: ItemId.PIKE),
        ItemDropType(id: ItemId.TROUT),
        ItemDropType(id: ItemId.SCALE, highCount: 3, weight: 3),
        ItemDropType(
          id: ItemId.FISHBONE_DAGGER,
          rarity: Rarity.COMMON,
          weight: 0.1,
        ),
        ItemDropType(
          id: ItemId.FISHBONE_DAGGER,
          rarity: Rarity.UNCOMMON,
          weight: 0.05,
        ),
      ],
      attackInterval: 1.0,
    ),
  ),
  FOREST_WOLF(
    CombatEntityDefinition(
      name: "Forest Wolf",
      iconAsset: "assets/images/entities/wolf.png",
      level: 35,
      combatType: CombatType.LEATHER_DPS,
      itemDrops: [
        ItemDropType(id: ItemId.CLAW, weight: 1),
        ItemDropType(id: ItemId.ANIMAL_PELT, weight: 1),
      ],
      attackInterval: 1.0,
    ),
  ),
  FOREST_WOLF_UNCOMMON(
    CombatEntityDefinition(
      name: "Elder Forest Wolf",
      iconAsset: "assets/images/entities/wolf.png",
      level: 55,
      combatType: CombatType.LEATHER_DPS,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.CLAW, lowCount: 2, highCount: 5, weight: 1),
        ItemDropType(
          id: ItemId.ANIMAL_PELT,
          lowCount: 2,
          highCount: 5,
          weight: 1,
        ),
      ],
      attackInterval: 1.0,
    ),
  ),
  SPIDER_BROODMOTHER(
    CombatEntityDefinition(
      name: "Spider Broodmother",
      iconAsset: "assets/images/entities/spider_broodmother.png",
      rarity: Rarity.EPIC,

      entityType: SkillId.ATTACK,
      level: 55,
      combatType: CombatType.LEATHER_TANK,
      attackInterval: 2.5,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, weight: 1, lowCount: 100),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.COMMON,
          weight: .1,
        ),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.UNCOMMON,
          weight: .05,
        ),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.RARE,
          weight: .01,
        ),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.EPIC,
          weight: .005,
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
      level: 233,
      combatType: CombatType.LEATHER_TANK,
      attackInterval: 2.5,
      itemDrops: [
        ItemDropType(id: ItemId.GOBLIN_CROWN, weight: 1),
        ItemDropType(id: ItemId.GOBLIN_SCEPTER, weight: 1),
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
      stockSlots: 12,
      restockInterval: Duration(minutes: 30),
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.COOKED_MINNOW, count: 200),
        ShopStockEntry(itemId: ItemId.LOGS, count: 1000),
        ShopStockEntry(itemId: ItemId.CHICKEN_MEAT, count: 1000),
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
      rarity: Rarity.UNCOMMON,
      dungeonId: DungeonId.GOBLIN_CAMP,
    ),
  ),
  DEV_DUNGEON_ENTRANCE(
    DungeonEntityDefinition(
      name: "Dev Transient Dungeon",
      iconAsset: "assets/images/entities/spider_den.png",
      rarity: Rarity.LEGENDARY,
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
