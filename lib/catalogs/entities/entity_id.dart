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

  /// The stand-in the encounter ui falls back to when nothing is selected.
  /// Separate from [NULL] because it has to *be* an EncounterEntity for the
  /// screen to render at all, while [NULL] must stay a plain Entity or the
  /// entity screen router would send a not-found lookup to the encounter
  /// screen. Zeroed on every stat, so it reads as an empty bar.
  NULL_ENCOUNTER(
    EncounterEntityDefinition(
      name: "Nothing",
      iconAsset: "",
      entityType: SkillId.NULL,
      defence: 0,
      hitpoints: 0,
      itemDrops: [],
    ),
  ),

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
  // Tier 4 mining, the rung above the coal and gold veins, and the first
  // node anywhere that yields MITHRIL_ORE — the ore and the whole mithril
  // gear tier existed as items with no way to obtain either. Mining has no
  // per-node level gate, so its difficulty is the defence a swing is rolled
  // against, plus the Foothills' own exploration gate.
  MITHRIL_VEIN(
    EncounterEntityDefinition(
      name: "Mithril Vein",
      iconAsset: "assets/images/entities/mithril_vein.png",

      entityType: SkillId.MINING,
      defence: 40,
      hitpoints: 40,
      itemDrops: [ItemDropType(id: ItemId.MITHRIL_ORE, weight: 1)],
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.15)],
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

  // ── COMBAT ─────────────────────────────────────────────────────
  // CombatEntityDefinition. Stats are not written here: the shared
  // CombatArchetype sets the tier and how it fights, and the variant's
  // own rarity walks it up the Fibonacci ladder from there (see
  // CombatEntityDefinition.level). A monster is five entries — one per
  // Rarity — differing only in name, rarity and drop table.
  //
  // Ordered by tier, and within a tier by the zone the monster belongs
  // to. Drop tables written as a bare COINS range are stubs: the roster
  // gave levels, not loot, and a table has to be rollable to ship.

  //
  // Tier 3 - Level 3
  //
  // Chicken · roster tier 1 · farm
  CHICKEN(
    CombatEntityDefinition(
      chicken,
      name: "Chicken",
      itemDrops: [
        ItemDropType(id: ItemId.CHICKEN_MEAT, weight: 1),
        ItemDropType(id: ItemId.FEATHER, lowCount: 1, highCount: 5, weight: 1),
      ],
    ),
  ),
  CHICKEN_UNCOMMON(
    CombatEntityDefinition(
      chicken,
      name: "Chicken",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 5, highCount: 15, weight: 1),
      ],
    ),
  ),
  CHICKEN_RARE(
    CombatEntityDefinition(
      chicken,
      name: "Chicken",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 8, highCount: 24, weight: 1),
      ],
    ),
  ),
  CHICKEN_EPIC(
    CombatEntityDefinition(
      chicken,
      name: "Chicken",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 13, highCount: 39, weight: 1),
      ],
    ),
  ),
  CHICKEN_LEGENDARY(
    CombatEntityDefinition(
      chicken,
      name: "Chicken",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 21, highCount: 63, weight: 1),
      ],
    ),
  ),

  //
  // Tier 4 - Level 5
  //
  // Cow · roster tier 1 · farm
  COW(
    CombatEntityDefinition(
      cow,
      name: "Cow",
      itemDrops: [
        ItemDropType(id: ItemId.COW_MEAT, weight: 1),
        ItemDropType(id: ItemId.COW_HIDE, weight: 1),
      ],
    ),
  ),
  COW_UNCOMMON(
    CombatEntityDefinition(
      cow,
      name: "Cow",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 8, highCount: 24, weight: 1),
      ],
    ),
  ),
  COW_RARE(
    CombatEntityDefinition(
      cow,
      name: "Cow",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 13, highCount: 39, weight: 1),
      ],
    ),
  ),
  COW_EPIC(
    CombatEntityDefinition(
      cow,
      name: "Cow",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 21, highCount: 63, weight: 1),
      ],
    ),
  ),
  COW_LEGENDARY(
    CombatEntityDefinition(
      cow,
      name: "Cow",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),

  //
  // Tier 5 - Level 8
  //
  // Giant Rat · roster tier 1 · farm
  GIANT_RAT(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 8, highCount: 24, weight: 1),
      ],
    ),
  ),
  GIANT_RAT_UNCOMMON(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 13, highCount: 39, weight: 1),
      ],
    ),
  ),
  GIANT_RAT_RARE(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 21, highCount: 63, weight: 1),
      ],
    ),
  ),
  GIANT_RAT_EPIC(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),
  GIANT_RAT_LEGENDARY(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),

  //
  // Tier 6 - Level 13
  //
  // Rotwood Scarecrow · roster tier 1 · farm
  ROTWOOD_SCARECROW(
    CombatEntityDefinition(
      scarecrow,
      name: "Rotwood Scarecrow",
      itemDrops: [
        ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 1, highCount: 4),
        ItemDropType(id: ItemId.COINS, weight: 1, lowCount: 3, highCount: 10),
        ItemDropType(id: ItemId.IRON_ORE, weight: 1, lowCount: 1, highCount: 2),
      ],
      // an independent 5% on top of the main pick, so it costs the other
      // three drops nothing
      bonusDrops: [
        DropRoll(chance: 0.05, entries: [ItemDropType(id: ItemId.PITCHFORK)]),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_UNCOMMON(
    CombatEntityDefinition(
      scarecrow,
      name: "Rotwood Scarecrow",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 21, highCount: 63, weight: 1),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_1(
    CombatEntityDefinition(
      scarecrow,
      name: "Rotwood Scarecrow",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 1, highCount: 4),
        ItemDropType(id: ItemId.COINS, weight: 1, lowCount: 3, highCount: 10),
        ItemDropType(id: ItemId.IRON_ORE, weight: 1, lowCount: 1, highCount: 2),
      ],
      // a rare pitchfork is the ordinary one at Rarity.RARE - two rungs up
      // its ladder - which is what retired the separate RARE_PITCHFORK item
      bonusDrops: [
        DropRoll(
          chance: 0.50,
          entries: [ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.RARE)],
        ),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_EPIC(
    CombatEntityDefinition(
      scarecrow,
      name: "Rotwood Scarecrow",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_LEGENDARY(
    CombatEntityDefinition(
      scarecrow,
      name: "Rotwood Scarecrow",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),

  //
  // Tier 7 - Level 21
  //
  // Giant Spider · roster tier 2 · forest
  GIANT_SPIDER(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      itemDrops: [
        ItemDropType(id: ItemId.SILK, weight: 1),
        ItemDropType(id: ItemId.VENOM, weight: 1),
      ],
    ),
  ),
  GIANT_SPIDER_UNCOMMON(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),
  GIANT_SPIDER_RARE(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  GIANT_SPIDER_EPIC(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  GIANT_SPIDER_LEGENDARY(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  // Forest Wolf · roster tier 2 · forest
  FOREST_WOLF(
    CombatEntityDefinition(
      wolf,
      name: "Forest Wolf",
      itemDrops: [
        ItemDropType(id: ItemId.CLAW, weight: 1),
        ItemDropType(id: ItemId.ANIMAL_PELT, weight: 1),
      ],
    ),
  ),
  FOREST_WOLF_UNCOMMON(
    CombatEntityDefinition(
      wolf,
      name: "Elder Forest Wolf",
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
    ),
  ),
  FOREST_WOLF_RARE(
    CombatEntityDefinition(
      wolf,
      name: "Forest Wolf",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  FOREST_WOLF_EPIC(
    CombatEntityDefinition(
      wolf,
      name: "Forest Wolf",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  FOREST_WOLF_LEGENDARY(
    CombatEntityDefinition(
      wolf,
      name: "Forest Wolf",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  // Giant Bat · roster tier 2 · mine
  GIANT_BAT(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 21, highCount: 63, weight: 1),
      ],
    ),
  ),
  GIANT_BAT_UNCOMMON(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),
  GIANT_BAT_RARE(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  GIANT_BAT_EPIC(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  GIANT_BAT_LEGENDARY(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  // Slime · roster tier 2 · mine
  SLIME(
    CombatEntityDefinition(
      slime,
      name: "Slime",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 21, highCount: 63, weight: 1),
      ],
    ),
  ),
  SLIME_UNCOMMON(
    CombatEntityDefinition(
      slime,
      name: "Slime",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),
  SLIME_RARE(
    CombatEntityDefinition(
      slime,
      name: "Slime",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  SLIME_EPIC(
    CombatEntityDefinition(
      slime,
      name: "Slime",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  SLIME_LEGENDARY(
    CombatEntityDefinition(
      slime,
      name: "Slime",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 8 - Level 34
  //
  // Goblin · roster tier 2 · forest
  GOBLIN(
    CombatEntityDefinition(
      goblin,
      name: "Goblin",
      itemDrops: [ItemDropType(id: ItemId.COINS, weight: 1)],
      // 5% chance, on top of the coin drop, to yield the key that opens
      // the Goblin Queen's Lair landmark dungeon
      bonusDrops: [
        DropRoll(
          chance: 0.05,
          entries: [
            ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_UNCOMMON(
    CombatEntityDefinition(
      goblin,
      name: "Goblin",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  GOBLIN_RARE(
    CombatEntityDefinition(
      goblin,
      name: "Goblin",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  GOBLIN_EPIC(
    CombatEntityDefinition(
      goblin,
      name: "Goblin",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  GOBLIN_LEGENDARY(
    CombatEntityDefinition(
      goblin,
      name: "Goblin",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  // Bear · roster tier 2 · forest
  BEAR(
    CombatEntityDefinition(
      bear,
      name: "Bear",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),
  BEAR_UNCOMMON(
    CombatEntityDefinition(
      bear,
      name: "Bear",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  BEAR_RARE(
    CombatEntityDefinition(
      bear,
      name: "Bear",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  BEAR_EPIC(
    CombatEntityDefinition(
      bear,
      name: "Bear",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  BEAR_LEGENDARY(
    CombatEntityDefinition(
      bear,
      name: "Bear",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  // Mudlurc · roster tier 2 · swamp
  MUDLURC(
    CombatEntityDefinition(
      mudlurc,
      name: "Mudlurc",
      itemDrops: [
        ItemDropType(id: ItemId.SALMON, weight: 1),
        ItemDropType(id: ItemId.PIKE, weight: 1),
        ItemDropType(id: ItemId.TROUT, weight: 1),
        ItemDropType(id: ItemId.SCALE, lowCount: 1, highCount: 3, weight: 3),
      ],
    ),
  ),
  MUDLURC_WARRIOR(
    CombatEntityDefinition(
      mudlurc,
      name: "Mudlurc",
      rarity: Rarity.UNCOMMON,
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
    ),
  ),
  MUDLURC_RARE(
    CombatEntityDefinition(
      mudlurc,
      name: "Mudlurc",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  MUDLURC_EPIC(
    CombatEntityDefinition(
      mudlurc,
      name: "Mudlurc",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  MUDLURC_LEGENDARY(
    CombatEntityDefinition(
      mudlurc,
      name: "Mudlurc",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  // Fungal Monster · roster tier 2 · swamp
  FUNGAL_MONSTER(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
      // it grows in the same wet ground the herbs do
      bonusDrops: [DropRoll(entries: herbDropTable, chance: 0.25)],
    ),
  ),
  FUNGAL_MONSTER_UNCOMMON(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  FUNGAL_MONSTER_RARE(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  FUNGAL_MONSTER_EPIC(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  FUNGAL_MONSTER_LEGENDARY(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  // Kobold · roster tier 2 · mine
  KOBOLD(
    CombatEntityDefinition(
      kobold,
      name: "Kobold",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 34, highCount: 102, weight: 1),
      ],
    ),
  ),
  KOBOLD_UNCOMMON(
    CombatEntityDefinition(
      kobold,
      name: "Kobold",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  KOBOLD_RARE(
    CombatEntityDefinition(
      kobold,
      name: "Kobold",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  KOBOLD_EPIC(
    CombatEntityDefinition(
      kobold,
      name: "Kobold",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  KOBOLD_LEGENDARY(
    CombatEntityDefinition(
      kobold,
      name: "Kobold",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 9 - Level 55
  //
  // Skeleton · roster tier 3 · dark forest
  SKELETON(
    CombatEntityDefinition(
      skeleton,
      name: "Skeleton",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
        ItemDropType(id: ItemId.ENCHANTING_DUST, lowCount: 1, highCount: 2, weight: 1),
      ],
    ),
  ),
  SKELETON_UNCOMMON(
    CombatEntityDefinition(
      skeleton,
      name: "Skeleton",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  SKELETON_RARE(
    CombatEntityDefinition(
      skeleton,
      name: "Skeleton",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  SKELETON_EPIC(
    CombatEntityDefinition(
      skeleton,
      name: "Skeleton",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  SKELETON_LEGENDARY(
    CombatEntityDefinition(
      skeleton,
      name: "Skeleton",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  // Zombie · roster tier 3 · dark forest
  ZOMBIE(
    CombatEntityDefinition(
      zombie,
      name: "Zombie",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
        ItemDropType(id: ItemId.ANIMAL_PELT, weight: 1),
        ItemDropType(id: ItemId.ENCHANTING_DUST, weight: 1),
      ],
    ),
  ),
  ZOMBIE_UNCOMMON(
    CombatEntityDefinition(
      zombie,
      name: "Zombie",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  ZOMBIE_RARE(
    CombatEntityDefinition(
      zombie,
      name: "Zombie",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  ZOMBIE_EPIC(
    CombatEntityDefinition(
      zombie,
      name: "Zombie",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  ZOMBIE_LEGENDARY(
    CombatEntityDefinition(
      zombie,
      name: "Zombie",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  // Harpy · roster tier 3 · foothills
  HARPY(
    CombatEntityDefinition(
      harpy,
      name: "Harpy",
      itemDrops: [
        ItemDropType(id: ItemId.FEATHER, lowCount: 1, highCount: 5, weight: 2),
        ItemDropType(id: ItemId.CLAW, weight: 1),
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  HARPY_UNCOMMON(
    CombatEntityDefinition(
      harpy,
      name: "Harpy",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  HARPY_RARE(
    CombatEntityDefinition(
      harpy,
      name: "Harpy",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  HARPY_EPIC(
    CombatEntityDefinition(
      harpy,
      name: "Harpy",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  HARPY_LEGENDARY(
    CombatEntityDefinition(
      harpy,
      name: "Harpy",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  // Naga · roster tier 3 · coast
  NAGA(
    CombatEntityDefinition(
      naga,
      name: "Naga",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 55, highCount: 165, weight: 1),
      ],
    ),
  ),
  NAGA_UNCOMMON(
    CombatEntityDefinition(
      naga,
      name: "Naga",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  NAGA_RARE(
    CombatEntityDefinition(
      naga,
      name: "Naga",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  NAGA_EPIC(
    CombatEntityDefinition(
      naga,
      name: "Naga",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  NAGA_LEGENDARY(
    CombatEntityDefinition(
      naga,
      name: "Naga",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 10 - Level 89
  //
  // Giant Scorpion · roster tier 3 · swamp
  GIANT_SCORPION(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      itemDrops: [
        ItemDropType(id: ItemId.VENOM, weight: 1),
        ItemDropType(id: ItemId.CLAW, lowCount: 1, highCount: 2, weight: 1),
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  GIANT_SCORPION_UNCOMMON(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  GIANT_SCORPION_RARE(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  GIANT_SCORPION_EPIC(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  GIANT_SCORPION_LEGENDARY(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  // Imp · roster tier 3 · foothills
  IMP(
    CombatEntityDefinition(
      imp,
      name: "Imp",
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
        ItemDropType(id: ItemId.ENCHANTING_ESSENCE, lowCount: 1, highCount: 3, weight: 1),
      ],
    ),
  ),
  IMP_UNCOMMON(
    CombatEntityDefinition(
      imp,
      name: "Imp",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  IMP_RARE(
    CombatEntityDefinition(
      imp,
      name: "Imp",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  IMP_EPIC(
    CombatEntityDefinition(
      imp,
      name: "Imp",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  IMP_LEGENDARY(
    CombatEntityDefinition(
      imp,
      name: "Imp",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  // Orc · roster tier 3 · foothills
  ORC(
    CombatEntityDefinition(
      orc,
      name: "Orc",
      itemDrops: [
        ItemDropType(id: ItemId.ANIMAL_PELT, weight: 1),
        ItemDropType(id: ItemId.CLAW, weight: 1),
        ItemDropType(id: ItemId.COINS, lowCount: 89, highCount: 267, weight: 1),
      ],
    ),
  ),
  ORC_UNCOMMON(
    CombatEntityDefinition(
      orc,
      name: "Orc",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  ORC_RARE(
    CombatEntityDefinition(
      orc,
      name: "Orc",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  ORC_EPIC(
    CombatEntityDefinition(
      orc,
      name: "Orc",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  ORC_LEGENDARY(
    CombatEntityDefinition(
      orc,
      name: "Orc",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 11 - Level 144
  //
  // Wraith · roster tier 4 · dark forest
  WRAITH(
    CombatEntityDefinition(
      wraith,
      name: "Wraith",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
        ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1),
      ],
    ),
  ),
  WRAITH_UNCOMMON(
    CombatEntityDefinition(
      wraith,
      name: "Wraith",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  WRAITH_RARE(
    CombatEntityDefinition(
      wraith,
      name: "Wraith",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  WRAITH_EPIC(
    CombatEntityDefinition(
      wraith,
      name: "Wraith",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  WRAITH_LEGENDARY(
    CombatEntityDefinition(
      wraith,
      name: "Wraith",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  // Banshee · roster tier 4 · dark forest
  BANSHEE(
    CombatEntityDefinition(
      banshee,
      name: "Banshee",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
        ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1),
      ],
    ),
  ),
  BANSHEE_UNCOMMON(
    CombatEntityDefinition(
      banshee,
      name: "Banshee",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  BANSHEE_RARE(
    CombatEntityDefinition(
      banshee,
      name: "Banshee",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  BANSHEE_EPIC(
    CombatEntityDefinition(
      banshee,
      name: "Banshee",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  BANSHEE_LEGENDARY(
    CombatEntityDefinition(
      banshee,
      name: "Banshee",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  // Troll · roster tier 4 · foothills
  TROLL(
    CombatEntityDefinition(
      troll,
      name: "Troll",
      itemDrops: [
        ItemDropType(id: ItemId.ANIMAL_PELT, lowCount: 2, highCount: 5, weight: 1),
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  TROLL_UNCOMMON(
    CombatEntityDefinition(
      troll,
      name: "Troll",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  TROLL_RARE(
    CombatEntityDefinition(
      troll,
      name: "Troll",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  TROLL_EPIC(
    CombatEntityDefinition(
      troll,
      name: "Troll",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  TROLL_LEGENDARY(
    CombatEntityDefinition(
      troll,
      name: "Troll",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  // Minotaur · roster tier 4 · mine
  MINOTAUR(
    CombatEntityDefinition(
      minotaur,
      name: "Minotaur",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  MINOTAUR_UNCOMMON(
    CombatEntityDefinition(
      minotaur,
      name: "Minotaur",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  MINOTAUR_RARE(
    CombatEntityDefinition(
      minotaur,
      name: "Minotaur",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  MINOTAUR_EPIC(
    CombatEntityDefinition(
      minotaur,
      name: "Minotaur",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  MINOTAUR_LEGENDARY(
    CombatEntityDefinition(
      minotaur,
      name: "Minotaur",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  // Basilisk · roster tier 4 · mine
  BASILISK(
    CombatEntityDefinition(
      basilisk,
      name: "Basilisk",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  BASILISK_UNCOMMON(
    CombatEntityDefinition(
      basilisk,
      name: "Basilisk",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  BASILISK_RARE(
    CombatEntityDefinition(
      basilisk,
      name: "Basilisk",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  BASILISK_EPIC(
    CombatEntityDefinition(
      basilisk,
      name: "Basilisk",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  BASILISK_LEGENDARY(
    CombatEntityDefinition(
      basilisk,
      name: "Basilisk",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  // Dark Wizard · roster tier 4 · crypt
  DARK_WIZARD(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  DARK_WIZARD_UNCOMMON(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  DARK_WIZARD_RARE(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  DARK_WIZARD_EPIC(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  DARK_WIZARD_LEGENDARY(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  // Gargoyle · roster tier 4 · crypt
  GARGOYLE(
    CombatEntityDefinition(
      gargoyle,
      name: "Gargoyle",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 144,
          highCount: 432,
          weight: 1,
        ),
      ],
    ),
  ),
  GARGOYLE_UNCOMMON(
    CombatEntityDefinition(
      gargoyle,
      name: "Gargoyle",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  GARGOYLE_RARE(
    CombatEntityDefinition(
      gargoyle,
      name: "Gargoyle",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  GARGOYLE_EPIC(
    CombatEntityDefinition(
      gargoyle,
      name: "Gargoyle",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  GARGOYLE_LEGENDARY(
    CombatEntityDefinition(
      gargoyle,
      name: "Gargoyle",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 12 - Level 233
  //
  // Moss Golem · roster tier 5 · swamp
  MOSS_GOLEM(
    CombatEntityDefinition(
      mossGolem,
      name: "Moss Golem",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
      // the stone it is grown over carries gems
      bonusDrops: [DropRoll(entries: gemDropTable, chance: 0.3)],
    ),
  ),
  MOSS_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      mossGolem,
      name: "Moss Golem",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  MOSS_GOLEM_RARE(
    CombatEntityDefinition(
      mossGolem,
      name: "Moss Golem",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  MOSS_GOLEM_EPIC(
    CombatEntityDefinition(
      mossGolem,
      name: "Moss Golem",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  MOSS_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      mossGolem,
      name: "Moss Golem",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Hill Giant · roster tier 5 · foothills
  HILL_GIANT(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
        ItemDropType(id: ItemId.COAL, lowCount: 1, highCount: 3, weight: 1),
        ItemDropType(id: ItemId.GOLD_ORE, weight: .5),
      ],
    ),
  ),
  HILL_GIANT_UNCOMMON(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  HILL_GIANT_RARE(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  HILL_GIANT_EPIC(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  HILL_GIANT_LEGENDARY(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Earth Elemental · roster tier 5 · mine
  EARTH_ELEMENTAL(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  EARTH_ELEMENTAL_UNCOMMON(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  EARTH_ELEMENTAL_RARE(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  EARTH_ELEMENTAL_EPIC(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  EARTH_ELEMENTAL_LEGENDARY(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Ogre · roster tier 5 · mountains
  OGRE(
    CombatEntityDefinition(
      ogre,
      name: "Ogre",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  OGRE_UNCOMMON(
    CombatEntityDefinition(
      ogre,
      name: "Ogre",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  OGRE_RARE(
    CombatEntityDefinition(
      ogre,
      name: "Ogre",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  OGRE_EPIC(
    CombatEntityDefinition(
      ogre,
      name: "Ogre",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  OGRE_LEGENDARY(
    CombatEntityDefinition(
      ogre,
      name: "Ogre",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Stone Golem · roster tier 5 · mountains
  STONE_GOLEM(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  STONE_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  STONE_GOLEM_RARE(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  STONE_GOLEM_EPIC(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  STONE_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Griffin · roster tier 5 · frozen peaks
  GRIFFIN(
    CombatEntityDefinition(
      griffin,
      name: "Griffin",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  GRIFFIN_UNCOMMON(
    CombatEntityDefinition(
      griffin,
      name: "Griffin",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  GRIFFIN_RARE(
    CombatEntityDefinition(
      griffin,
      name: "Griffin",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  GRIFFIN_EPIC(
    CombatEntityDefinition(
      griffin,
      name: "Griffin",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  GRIFFIN_LEGENDARY(
    CombatEntityDefinition(
      griffin,
      name: "Griffin",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Fire Elemental · roster tier 5 · volcanic
  FIRE_ELEMENTAL(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  FIRE_ELEMENTAL_UNCOMMON(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  FIRE_ELEMENTAL_RARE(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  FIRE_ELEMENTAL_EPIC(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  FIRE_ELEMENTAL_LEGENDARY(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  // Water Elemental · roster tier 5 · coast
  WATER_ELEMENTAL(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 233,
          highCount: 699,
          weight: 1,
        ),
      ],
    ),
  ),
  WATER_ELEMENTAL_UNCOMMON(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  WATER_ELEMENTAL_RARE(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  WATER_ELEMENTAL_EPIC(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  WATER_ELEMENTAL_LEGENDARY(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 13 - Level 377
  //
  // Yeti · roster tier 6 · frozen peaks
  YETI(
    CombatEntityDefinition(
      yeti,
      name: "Yeti",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  YETI_UNCOMMON(
    CombatEntityDefinition(
      yeti,
      name: "Yeti",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  YETI_RARE(
    CombatEntityDefinition(
      yeti,
      name: "Yeti",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  YETI_EPIC(
    CombatEntityDefinition(
      yeti,
      name: "Yeti",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  YETI_LEGENDARY(
    CombatEntityDefinition(
      yeti,
      name: "Yeti",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Iron Golem · roster tier 6 · volcanic
  IRON_GOLEM(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  IRON_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  IRON_GOLEM_RARE(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  IRON_GOLEM_EPIC(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  IRON_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Steel Golem · roster tier 6 · mine
  STEEL_GOLEM(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  STEEL_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  STEEL_GOLEM_RARE(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  STEEL_GOLEM_EPIC(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  STEEL_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Lich · roster tier 6 · crypt
  LICH(
    CombatEntityDefinition(
      lich,
      name: "Lich",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  LICH_UNCOMMON(
    CombatEntityDefinition(
      lich,
      name: "Lich",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  LICH_RARE(
    CombatEntityDefinition(
      lich,
      name: "Lich",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  LICH_EPIC(
    CombatEntityDefinition(
      lich,
      name: "Lich",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  LICH_LEGENDARY(
    CombatEntityDefinition(
      lich,
      name: "Lich",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Cloud Giant · roster tier 6 · mountains
  CLOUD_GIANT(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  CLOUD_GIANT_UNCOMMON(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  CLOUD_GIANT_RARE(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  CLOUD_GIANT_EPIC(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  CLOUD_GIANT_LEGENDARY(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Roc · roster tier 6 · frozen peaks
  ROC(
    CombatEntityDefinition(
      roc,
      name: "Roc",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  ROC_UNCOMMON(
    CombatEntityDefinition(
      roc,
      name: "Roc",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  ROC_RARE(
    CombatEntityDefinition(
      roc,
      name: "Roc",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  ROC_EPIC(
    CombatEntityDefinition(
      roc,
      name: "Roc",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  ROC_LEGENDARY(
    CombatEntityDefinition(
      roc,
      name: "Roc",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Wyvern · roster tier 6 · volcanic
  WYVERN(
    CombatEntityDefinition(
      wyvern,
      name: "Wyvern",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  WYVERN_UNCOMMON(
    CombatEntityDefinition(
      wyvern,
      name: "Wyvern",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  WYVERN_RARE(
    CombatEntityDefinition(
      wyvern,
      name: "Wyvern",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  WYVERN_EPIC(
    CombatEntityDefinition(
      wyvern,
      name: "Wyvern",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  WYVERN_LEGENDARY(
    CombatEntityDefinition(
      wyvern,
      name: "Wyvern",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  // Drake · roster tier 6 · volcanic
  DRAKE(
    CombatEntityDefinition(
      drake,
      name: "Drake",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 377,
          highCount: 1131,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAKE_UNCOMMON(
    CombatEntityDefinition(
      drake,
      name: "Drake",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAKE_RARE(
    CombatEntityDefinition(
      drake,
      name: "Drake",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAKE_EPIC(
    CombatEntityDefinition(
      drake,
      name: "Drake",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAKE_LEGENDARY(
    CombatEntityDefinition(
      drake,
      name: "Drake",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),

  //
  // Tier 14 - Level 610
  //
  // Kraken · roster tier 7 · deep water dungeon
  KRAKEN(
    CombatEntityDefinition(
      kraken,
      name: "Kraken",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  KRAKEN_UNCOMMON(
    CombatEntityDefinition(
      kraken,
      name: "Kraken",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  KRAKEN_RARE(
    CombatEntityDefinition(
      kraken,
      name: "Kraken",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  KRAKEN_EPIC(
    CombatEntityDefinition(
      kraken,
      name: "Kraken",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  KRAKEN_LEGENDARY(
    CombatEntityDefinition(
      kraken,
      name: "Kraken",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 4181,
          highCount: 12543,
          weight: 1,
        ),
      ],
    ),
  ),
  // Dragon · roster tier 7 · dragon's lair
  DRAGON(
    CombatEntityDefinition(
      dragon,
      name: "Dragon",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAGON_UNCOMMON(
    CombatEntityDefinition(
      dragon,
      name: "Dragon",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAGON_RARE(
    CombatEntityDefinition(
      dragon,
      name: "Dragon",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAGON_EPIC(
    CombatEntityDefinition(
      dragon,
      name: "Dragon",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  DRAGON_LEGENDARY(
    CombatEntityDefinition(
      dragon,
      name: "Dragon",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 4181,
          highCount: 12543,
          weight: 1,
        ),
      ],
    ),
  ),
  // Lesser Demon · roster tier 7 · underworld
  LESSER_DEMON(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  LESSER_DEMON_UNCOMMON(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  LESSER_DEMON_RARE(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  LESSER_DEMON_EPIC(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  LESSER_DEMON_LEGENDARY(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 4181,
          highCount: 12543,
          weight: 1,
        ),
      ],
    ),
  ),
  // Greater Demon · roster tier 7 · underworld
  GREATER_DEMON(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 610,
          highCount: 1830,
          weight: 1,
        ),
      ],
    ),
  ),
  GREATER_DEMON_UNCOMMON(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 987,
          highCount: 2961,
          weight: 1,
        ),
      ],
    ),
  ),
  GREATER_DEMON_RARE(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 1597,
          highCount: 4791,
          weight: 1,
        ),
      ],
    ),
  ),
  GREATER_DEMON_EPIC(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.EPIC,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 2584,
          highCount: 7752,
          weight: 1,
        ),
      ],
    ),
  ),
  GREATER_DEMON_LEGENDARY(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(
          id: ItemId.COINS,
          lowCount: 4181,
          highCount: 12543,
          weight: 1,
        ),
      ],
    ),
  ),

  // ── COMBAT · NAMED CHARACTERS ──────────────────────────────────
  // One-offs that sit outside the roster, each its own archetype.
  FIELD_RAT(
    CombatEntityDefinition(
      fieldRat,
      name: "Field Rat",
      // The weakest thing in the game, so it pays the smallest purse rather
      // than nothing: an empty table is not rollable — roll() returns
      // `ObjectStack(id: 0 as T)` for one, which throws on the cast.
      itemDrops: [
        ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 3, weight: 1),
      ],
    ),
  ),
  BIG_RED(
    CombatEntityDefinition(
      bigRed,
      name: "Big Red",
      rarity: Rarity.UNCOMMON,
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
      goblinScout,
      name: "Goblin",
      rarity: Rarity.UNCOMMON,
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
        DropRoll(
          chance: 0.05,
          entries: [
            ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_SEARGENT(
    CombatEntityDefinition(
      goblinSeargent,
      name: "Goblin Seargent",
      rarity: Rarity.RARE,
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
        DropRoll(
          chance: 0.05,
          entries: [
            ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY),
          ],
        ),
      ],
    ),
  ),
  SPIDER_BROODMOTHER(
    CombatEntityDefinition(
      spiderBroodmother,
      name: "Spider Broodmother",
      rarity: Rarity.EPIC,
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
      goblinQueen,
      name: "Goblin Queen",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(id: ItemId.GOBLIN_CROWN, weight: 1),
        ItemDropType(id: ItemId.GOBLIN_SCEPTER, weight: 1),
      ],
      bonusDrops: [
        // guaranteed bulk currency
        DropRoll(
          entries: [
            ItemDropType(id: ItemId.COINS, lowCount: 500),
          ],
        ),
        // rare second unique on top of the guaranteed one
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.GOBLIN_CROWN),
            ItemDropType(id: ItemId.GOBLIN_SCEPTER),
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
