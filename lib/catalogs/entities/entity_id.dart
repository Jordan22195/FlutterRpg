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
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: treeReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.SMALL_BIRDS_NEST)],
        ),
      ],
    ),
  ),
  OAK_TREE(
    EncounterEntityDefinition(
      name: "Oak Tree",
      iconAsset: "assets/images/entities/oak_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 10,
      hitpoints: 15,
      // a harder tree is chopped slower; it pays more a point to stay ahead
      xpPerDamage: 1.6,
      itemDrops: [ItemDropType(id: ItemId.OAK_LOGS, weight: 1)],
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: oakReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.SMALL_BIRDS_NEST)],
        ),
      ],
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
      // a harder tree is chopped slower; it pays more a point to stay ahead
      xpPerDamage: 2.6,
      itemDrops: [ItemDropType(id: ItemId.WILLOW_LOGS, weight: 1)],
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: willowReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.WOVEN_BIRDS_NEST)],
        ),
      ],
    ),
  ),
  // Willow's side-grade, the same tier. Grows in Blackmire Swamp.
  BOG_TREE(
    EncounterEntityDefinition(
      name: "Bog Tree",
      iconAsset: "assets/images/entities/bog_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 20,
      hitpoints: 25,
      // a harder tree is chopped slower; it pays more a point to stay ahead
      xpPerDamage: 2.6,
      itemDrops: [ItemDropType(id: ItemId.BOG_LOGS, weight: 1)],
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: willowReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.WOVEN_BIRDS_NEST)],
        ),
      ],
    ),
  ),
  // Willow's step up: the first tree to give maple logs. Grows by
  // Maplewater Lake.
  MAPLE_TREE(
    EncounterEntityDefinition(
      name: "Maple Tree",
      iconAsset: "assets/images/entities/maple_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 30,
      hitpoints: 35,
      // a harder tree is chopped slower; it pays more a point to stay ahead
      xpPerDamage: 3.6,
      itemDrops: [ItemDropType(id: ItemId.MAPLE_LOGS, weight: 1)],
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: mapleReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.STURDY_BIRDS_NEST)],
        ),
      ],
    ),
  ),
  // Tier 5, past the maple. Grows in the Old Yew Grove.
  YEW_TREE(
    EncounterEntityDefinition(
      name: "Yew Tree",
      iconAsset: "assets/images/entities/yew_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 45,
      hitpoints: 45,
      // a harder tree is chopped slower; it pays more a point to stay ahead
      xpPerDamage: 5.5,
      itemDrops: [ItemDropType(id: ItemId.YEW_LOGS, weight: 1)],
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: yewReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.GILDED_BIRDS_NEST)],
        ),
      ],
    ),
  ),
  // Tier 6, the top of the woodcutting ladder. Grows in Witchlight Grove.
  MAGIC_TREE(
    EncounterEntityDefinition(
      name: "Magic Tree",
      iconAsset: "assets/images/entities/magic_tree.png",

      entityType: SkillId.WOODCUTTING,
      defence: 60,
      hitpoints: 55,
      // a harder tree is chopped slower; it pays more a point to stay ahead
      xpPerDamage: 8,
      itemDrops: [ItemDropType(id: ItemId.MAGIC_LOGS, weight: 1)],
      // fire reagents and the odd bird's nest, besides the logs
      bonusDrops: [
        DropRoll(chance: treeReagentChance, entries: magicReagentDropTable),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.ENCHANTED_BIRDS_NEST)],
        ),
      ],
    ),
  ),

  // ── MINING ──────────────────────────────────────────────────────
  // EncounterEntityDefinition, tier ascending — pairs with the ORES items
  COPPER(
    EncounterEntityDefinition(
      name: "Copper Vein",
      iconAsset: "assets/images/entities/copper.png",

      discoveryLevel: 1,
      entityType: SkillId.MINING,
      defence: 1,
      hitpoints: 5,
      itemDrops: [
        ItemDropType(id: ItemId.COPPER_ORE, weight: 1),

        // rare gem finds (lower tiers only in the starter vein)
      ],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.05),
        DropRoll(chance: 0.02, entries: [ItemDropType(id: ItemId.DULL_GEODE)]),
      ],
    ),
  ),
  IRON(
    EncounterEntityDefinition(
      name: "Iron Vein",
      iconAsset: "assets/images/entities/iron.png",

      discoveryLevel: 20,
      entityType: SkillId.MINING,
      defence: 10,
      hitpoints: 15,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 1.6,
      itemDrops: [
        ItemDropType(id: ItemId.IRON_ORE, weight: 1),

        // rare gem finds, all tiers
      ],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.1),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.BANDED_GEODE)],
        ),
      ],
    ),
  ),
  // Tier 3 mining alongside the coal vein, and the first node anywhere that
  // yields GOLD_ORE — the ore existed as an item with no way to obtain it.
  GOLD_VEIN(
    EncounterEntityDefinition(
      name: "Gold Vein",
      iconAsset: "assets/images/entities/gold_vein.png",

      discoveryLevel: 25,
      entityType: SkillId.MINING,
      defence: 20,
      hitpoints: 30,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 2.6,
      itemDrops: [
        ItemDropType(id: ItemId.GOLD_ORE, weight: 1, lowCount: 1, highCount: 2),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.CRYSTAL_GEODE)],
        ),
      ],
    ),
  ),
  COAL_VEIN(
    EncounterEntityDefinition(
      name: "Coal Vein",
      iconAsset: "assets/images/entities/coal_vein.png",

      discoveryLevel: 40,
      entityType: SkillId.MINING,
      defence: 20,
      hitpoints: 25,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 2.6,
      itemDrops: [
        ItemDropType(id: ItemId.COAL, weight: 1, lowCount: 1, highCount: 3),
      ],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.5),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.BANDED_GEODE)],
        ),
      ],
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
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 4.2,
      itemDrops: gemDropTable,
      bonusDrops: [
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.CRYSTAL_GEODE)],
        ),
      ],
    ),
  ),
  // Tier 4 mining, the rung above the coal and gold veins, and the first
  // node anywhere that yields MITHRIL_ORE — the ore and the whole mithril
  // gear tier existed as items with no way to obtain either. Mining has no
  // per-node level gate, so its difficulty is the defence a swing is rolled
  // against, plus Stormgrass Prairie's own exploration gate.
  MITHRIL_VEIN(
    EncounterEntityDefinition(
      name: "Mithril Vein",
      iconAsset: "assets/images/entities/mithril_vein.png",

      discoveryLevel: 60,
      entityType: SkillId.MINING,
      defence: 40,
      hitpoints: 40,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 4.2,
      itemDrops: [ItemDropType(id: ItemId.MITHRIL_ORE, weight: 1)],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.15),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.PRISMATIC_GEODE)],
        ),
      ],
    ),
  ),
  // Tier 5 mining, the prairie's rare find past its mithril, and the first
  // node anywhere that yields ADAMANTITE_ORE
  ADAMANTITE_VEIN(
    EncounterEntityDefinition(
      name: "Adamantite Vein",
      iconAsset: "assets/images/entities/adamantite_vein.png",
      rarity: Rarity.RARE,

      discoveryLevel: 70,
      entityType: SkillId.MINING,
      defence: 55,
      hitpoints: 50,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 5.8,
      itemDrops: [ItemDropType(id: ItemId.ADAMANTITE_ORE, weight: 1)],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.2),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.PRISMATIC_GEODE)],
        ),
      ],
    ),
  ),

  // Tier 6 mining, past the adamantite. Rare, in the Ironroot Mine.
  RUNITE_VEIN(
    EncounterEntityDefinition(
      name: "Runite Vein",
      iconAsset: "assets/images/entities/runite_vein.png",
      rarity: Rarity.EPIC,

      discoveryLevel: 80,
      entityType: SkillId.MINING,
      defence: 70,
      hitpoints: 60,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 8.5,
      itemDrops: [ItemDropType(id: ItemId.RUNEITE_ORE, weight: 1)],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.25),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.RADIANT_GEODE)],
        ),
      ],
    ),
  ),
  // Tier 7 mining, the deepest vein. Not placed in any zone yet.
  DRAGONITE_VEIN(
    EncounterEntityDefinition(
      name: "Dragonite Vein",
      iconAsset: "assets/images/entities/dragonite_vein.png",
      rarity: Rarity.LEGENDARY,

      discoveryLevel: 90,
      entityType: SkillId.MINING,
      defence: 85,
      hitpoints: 70,
      // a harder vein is mined slower; it pays more a point to stay ahead
      xpPerDamage: 12,
      itemDrops: [ItemDropType(id: ItemId.DRAGON_ORE, weight: 1)],
      bonusDrops: [
        DropRoll(entries: gemDropTable, chance: 0.3),
        DropRoll(
          chance: 0.02,
          entries: [ItemDropType(id: ItemId.RADIANT_GEODE)],
        ),
      ],
    ),
  ),

  // ── FISHING ─────────────────────────────────────────────────────
  // FishingEntityDefinition, by Fishing level. Each spot is gated at its
  // first fish's level, its defence climbs past that gate (2 at the pond to
  // 176 at the ocean, so a fresh level lands about 60% of casts at the pond
  // and 11% at the ocean), and its other fish spread from there toward the
  // next spot's level
  // A spot's hitpoints are a catch's worth of damage - each further pool's
  // worth of overkill rolls the table again - and climb with the spot: 5 at
  // the pond and creek, up by 5 a spot to the ocean's 25.
  // Every spot also brings up junk in place of a catch, now and then one of
  // its own two reagents, and rarely its sunken cache (see drop_tables.dart)
  TRANQUIL_POND(
    FishingEntityDefinition(
      name: "Pond",
      iconAsset: "assets/images/entities/tranquil_pond.png",

      entityType: SkillId.FISHING,
      defence: 2,
      hitpoints: 5,
      requiredLevel: 1,
      itemDrops: [
        ItemDropType(id: ItemId.MINNOW, weight: 1, unlockLevel: 1),
        ItemDropType(id: ItemId.CARP, weight: 0.5, unlockLevel: 5),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(chance: waterReagentChance, entries: pondReagentDropTable),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.POND_CACHE)],
        ),
      ],
    ),
  ),
  CREEK(
    FishingEntityDefinition(
      name: "Creek",
      iconAsset: "assets/images/entities/creek.png",

      entityType: SkillId.FISHING,
      defence: 10,
      hitpoints: 5,
      requiredLevel: 7,
      itemDrops: [
        ItemDropType(id: ItemId.CRAYFISH, weight: 1, unlockLevel: 7),
        ItemDropType(id: ItemId.BLUEGILL, weight: 0.5, unlockLevel: 10),
        ItemDropType(id: ItemId.TROUT, weight: 0.25, unlockLevel: 15),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(chance: waterReagentChance, entries: creekReagentDropTable),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.CREEK_CACHE)],
        ),
      ],
    ),
  ),
  RIVER(
    FishingEntityDefinition(
      name: "River",
      iconAsset: "assets/images/entities/river.png",

      entityType: SkillId.FISHING,
      defence: 31,
      hitpoints: 10,
      requiredLevel: 20,
      itemDrops: [
        ItemDropType(id: ItemId.PIKE, weight: 1, unlockLevel: 20),
        ItemDropType(id: ItemId.SALMON, weight: 0.5, unlockLevel: 35),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(chance: waterReagentChance, entries: riverReagentDropTable),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.RIVER_CACHE)],
        ),
      ],
    ),
  ),
  // the swamp's River: the same level and numbers, but the catch is half
  // eels and half alchemy reagents
  MURKY_MARSH(
    FishingEntityDefinition(
      name: "Murky Marsh",
      iconAsset: "assets/images/entities/murky_marsh.png",

      entityType: SkillId.FISHING,
      defence: 31,
      hitpoints: 10,
      requiredLevel: 20,
      itemDrops: [
        ItemDropType(id: ItemId.BOG_EEL, weight: 1, unlockLevel: 20),
        ItemDropType(id: ItemId.LEECH, weight: 0.6, unlockLevel: 20),
        ItemDropType(id: ItemId.MARSH_FROG, weight: 0.4, unlockLevel: 25),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(chance: waterReagentChance, entries: marshReagentDropTable),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.MARSH_CACHE)],
        ),
      ],
    ),
  ),
  DEEP_POND(
    FishingEntityDefinition(
      name: "Small Lake",
      iconAsset: "assets/images/entities/tranquil_pond.png",

      entityType: SkillId.FISHING,
      defence: 78,
      hitpoints: 15,
      requiredLevel: 45,
      itemDrops: [
        ItemDropType(id: ItemId.CATFISH, weight: 1, unlockLevel: 45),
        ItemDropType(id: ItemId.BASS, weight: 0.5, unlockLevel: 55),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(
          chance: waterReagentChance,
          entries: smallLakeReagentDropTable,
        ),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.SMALL_LAKE_CACHE)],
        ),
      ],
    ),
  ),
  LAKE(
    FishingEntityDefinition(
      name: "Lake",
      iconAsset: "assets/images/entities/lake.png",

      entityType: SkillId.FISHING,
      defence: 115,
      hitpoints: 20,
      requiredLevel: 60,
      itemDrops: [
        ItemDropType(id: ItemId.WHITEFISH, weight: 1, unlockLevel: 60),
        ItemDropType(id: ItemId.STURGEON, weight: 0.5, unlockLevel: 70),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(chance: waterReagentChance, entries: lakeReagentDropTable),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.LAKE_CACHE)],
        ),
      ],
    ),
  ),
  OCEAN(
    FishingEntityDefinition(
      name: "Ocean",
      iconAsset: "assets/images/entities/ocean.png",

      entityType: SkillId.FISHING,
      defence: 176,
      hitpoints: 25,
      requiredLevel: 80,
      itemDrops: [
        ItemDropType(id: ItemId.TUNA, weight: 1, unlockLevel: 80),
        ItemDropType(id: ItemId.SWORDFISH, weight: 0.5, unlockLevel: 86),
        ItemDropType(id: ItemId.SHARK, weight: 0.25, unlockLevel: 93),
        // junk in place of a catch
        NestedDrop(fishingJunkDropTable, weight: fishingJunkWeight),
      ],
      bonusDrops: [
        DropRoll(chance: waterReagentChance, entries: oceanReagentDropTable),
        DropRoll(
          chance: sunkenCacheChance,
          entries: [ItemDropType(id: ItemId.OCEAN_CACHE)],
        ),
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
  // the swamp's fungal herb, the base of the super potions
  MIRECAP(
    HerbEntityDefinition(
      name: "Mirecap",
      iconAsset: "assets/images/entities/mirecap.png",
      requiredLevel: 25,
      defence: 25,
      itemDrops: [ItemDropType(id: ItemId.MIRECAP, weight: 1)],
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
  // the prairie's grasses: sweetgrass for the utility potions, bluestem
  // for the greater ones
  SWEETGRASS(
    HerbEntityDefinition(
      name: "Sweetgrass",
      iconAsset: "assets/images/entities/sweetgrass.png",
      requiredLevel: 30,
      defence: 30,
      itemDrops: [ItemDropType(id: ItemId.SWEETGRASS, weight: 1)],
    ),
  ),
  BLUESTEM(
    HerbEntityDefinition(
      name: "Bluestem",
      iconAsset: "assets/images/entities/bluestem.png",
      requiredLevel: 35,
      defence: 35,
      itemDrops: [ItemDropType(id: ItemId.BLUESTEM, weight: 1)],
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
  // CombatArchetype sets the art and how it fights, and each monster
  // names its own rung of the Fibonacci ladder with fibLevel (see
  // CombatEntityDefinition.level). Rarity only picks the portrait border.
  //
  // Ordered by archetype tier, and within a tier by the zone the monster
  // belongs to. A monster that writes no drops inherits its archetype's,
  // scaled by how many rungs above the archetype's lootFibLevel it stands
  // (see CombatEntityDefinition.itemDrops); one that writes itemDrops or
  // bonusDrops replaces that table, and extraItemDrops / extraBonusDrops
  // add to it.

  //
  // Tier 3 - Level 3
  //
  // Chicken · roster tier 1 · farm
  CHICKEN(CombatEntityDefinition(chicken, fibLevel: 2, name: "Chicken")),

  //
  // Tier 4 - Level 5
  //
  // Cow · roster tier 1 · farm
  COW(CombatEntityDefinition(cow, fibLevel: 3, name: "Cow")),
  COW_BOSS(
    CombatEntityDefinition(
      cow,
      fibLevel: 4,
      name: "Bo",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.COW_MEAT,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
        ItemDropType(
          id: ItemId.COOKED_BEEF,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
        ItemDropType(
          id: ItemId.COW_HIDE,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.MOOD_RING, rarity: Rarity.COMMON)],
        ),
        DropRoll(
          chance: 0.035,
          entries: [
            ItemDropType(id: ItemId.MOOD_RING, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
    ),
  ),

  //
  // Tier 5 - Level 8
  //
  // Giant Rat · roster tier 1 · farm
  GIANT_RAT(CombatEntityDefinition(giantRat, fibLevel: 4, name: "Giant Rat")),

  //
  // Tier 6 - Level 13
  //
  // Rotwood Scarecrow · roster tier 1 · farm
  ROTWOOD_SCARECROW(
    CombatEntityDefinition(scarecrow, fibLevel: 4, name: "Rotwood Scarecrow"),
  ),
  ROTWOOD_SCARECROW_BOSS(
    CombatEntityDefinition(
      scarecrow,
      fibLevel: 5,
      name: "Brainless",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 20, highCount: 50),
        ItemDropType(
          id: ItemId.IRON_ORE,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
        ItemDropType(
          id: ItemId.COPPER_BAR,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
        ItemDropType(
          id: ItemId.COPPER_ORE,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.COMMON)],
        ),
        DropRoll(
          chance: 0.035,
          entries: [
            ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.WOOD_SHIELD, rarity: Rarity.COMMON),
          ],
        ),
        DropRoll(
          chance: 0.035,
          entries: [
            ItemDropType(id: ItemId.WOOD_SHIELD, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_1(
    CombatEntityDefinition(
      scarecrow,
      fibLevel: 6,
      name: "Rotwood Scarecrow",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.LOGS, weight: 1, lowCount: 1, highCount: 4),
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

  //
  // Tier 7 - Level 21
  //
  // Giant Spider · roster tier 2 · forest
  GIANT_SPIDER(
    CombatEntityDefinition(spider, fibLevel: 6, name: "Giant Spider"),
  ),
  GIANT_SPIDER_UNCOMMON(
    CombatEntityDefinition(
      spider,
      fibLevel: 7,
      name: "Giant Spider",
      rarity: Rarity.UNCOMMON,
      itemDrops: [NestedDrop(spiderDropTable, countMultiplier: 2)],
    ),
  ),
  // the Spider Den's Webbed Thicket boss: a rare giant spider, with the
  // regulars' drops in bulk
  THICKET_WEAVER(
    CombatEntityDefinition(
      spider,
      fibLevel: 8,
      name: "Thicket Weaver",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
      itemDrops: [NestedDrop(spiderDropTable, countMultiplier: 3)],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.WEBBED_CLOAK, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.WEBBED_CLOAK, rarity: Rarity.RARE)],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.WEBBED_BRACERS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.WEBBED_BRACERS, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Forest Wolf · roster tier 2 · forest
  FOREST_WOLF(CombatEntityDefinition(wolf, fibLevel: 6, name: "Forest Wolf")),
  FOREST_WOLF_UNCOMMON(
    CombatEntityDefinition(
      wolf,
      fibLevel: 7,
      name: "Elder Forest Wolf",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.FANG, lowCount: 2, highCount: 5, weight: 1),
        ItemDropType(
          id: ItemId.WOLF_PELT,
          lowCount: 2,
          highCount: 5,
          weight: 1,
        ),
      ],
      // a Wolf Den piece no den boss owns
      extraBonusDrops: [
        DropRoll(
          chance: 0.02,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_CLOAK, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
    ),
  ),
  FOREST_WOLF_RARE(
    CombatEntityDefinition(
      wolf,
      fibLevel: 8,
      name: "Alpha Forest Wolf",
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.FANG, lowCount: 2, highCount: 5, weight: 1),

        ItemDropType(id: ItemId.WOOL_CLOAK, weight: .1),
        ItemDropType(
          id: ItemId.WOOL_CLOAK,
          weight: .01,
          rarity: Rarity.UNCOMMON,
        ),
        ItemDropType(id: ItemId.WOOL_CLOAK, weight: .002, rarity: Rarity.RARE),
      ],
    ),
  ),
  // the Wolf Den's Deep Lair boss: a forest wolf's drops, and its own two
  // den pieces, the bracers and the boots
  DEN_ALPHA_WOLF(
    CombatEntityDefinition(
      wolf,
      fibLevel: 8,
      name: "Den Alpha Wolf",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.WOLF_CLAW, weight: 1),
        ItemDropType(id: ItemId.WOLF_PELT, weight: 1),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.33,
          entries: [
            ItemDropType(id: ItemId.WOLF_HIDE_BRACERS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.11,
          entries: [
            ItemDropType(id: ItemId.WOLF_HIDE_BRACERS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.33,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_BOOTS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.11,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_BOOTS, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Giant Bat · roster tier 2 · mine
  GIANT_BAT(CombatEntityDefinition(giantBat, fibLevel: 7, name: "Giant Bat")),
  GIANT_BAT_UNCOMMON(
    CombatEntityDefinition(
      giantBat,
      fibLevel: 8,
      name: "Giant Bat",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  // Slime · roster tier 2 · mine
  SLIME(CombatEntityDefinition(slime, fibLevel: 7, name: "Slime")),
  // Carrion Crow · swamp. Quick and fragile; picks the bog's dead clean.
  CARRION_CROW(
    CombatEntityDefinition(carrionCrow, fibLevel: 7, name: "Carrion Crow"),
  ),
  // the Drowned Fen's Reedbank boss: an uncommon crow at level 55, the
  // flock's quills in bulk, and its bracers
  MURDER_KING(
    CombatEntityDefinition(
      carrionCrow,
      fibLevel: 8,
      name: "Murder King",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.FEATHER, lowCount: 20, highCount: 40),
        ItemDropType(id: ItemId.CROW_QUILL, lowCount: 5, highCount: 13),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.CROWQUILL_BRACERS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.CROWQUILL_BRACERS, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),

  //
  // Tier 8 - Level 34
  //
  // Goblin · roster tier 2 · forest
  // The goblin family shares one set of tables: the gear nests take each
  // goblin's quality as an override, so the family is one-word edits
  // rather than hand-written copies of the same six lines. The fish nest never takes one — only equipment
  // carries a quality.
  GOBLIN(CombatEntityDefinition(goblin, fibLevel: 5, name: "Goblin")),
  GOBLIN_UNCOMMON(
    CombatEntityDefinition(
      goblin,
      fibLevel: 6,
      name: "Goblin Scout",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        NestedDrop(cookedFishDropTable, weight: 2),
        NestedDrop(
          mediumLeatherMinorArmorDropTable,
          weight: 1,
          rarity: Rarity.UNCOMMON,
        ),
        ...goblinSupplyDrops,
      ],
      // written in full, so the common's bonus rolls stay its own
      bonusDrops: const [],
    ),
  ),
  GOBLIN_RARE(
    CombatEntityDefinition(
      goblin,
      fibLevel: 7,
      name: "Goblin Warrior",
      rarity: Rarity.RARE,
      itemDrops: [
        NestedDrop(cookedFishDropTable, weight: 2),
        NestedDrop(
          mediumLeatherMinorArmorDropTable,
          weight: 1,
          rarity: Rarity.RARE,
        ),
        ...goblinSupplyDrops,
      ],
      // written in full, so the common's bonus rolls stay its own
      bonusDrops: const [],
    ),
  ),
  GOBLIN_EPIC(
    CombatEntityDefinition(
      goblin,
      fibLevel: 8,
      name: "Goblin General",
      rarity: Rarity.EPIC,
      itemDrops: [
        NestedDrop(cookedFishDropTable, weight: 2),
        NestedDrop(
          mediumLeatherMinorArmorDropTable,
          weight: 1,
          rarity: Rarity.EPIC,
        ),
        ...goblinSupplyDrops,
      ],
      // written in full, so the common's bonus rolls stay its own
      bonusDrops: const [],
    ),
  ),
  GOBLIN_LEGENDARY(
    CombatEntityDefinition(
      goblin,
      fibLevel: 9,
      name: "Goblin Queen",
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        NestedDrop(cookedFishDropTable, weight: 2),
        NestedDrop(
          mediumLeatherMinorArmorDropTable,
          weight: 1,
          rarity: Rarity.LEGENDARY,
        ),
        ...goblinSupplyDrops,
      ],
      // written in full, so the common's bonus rolls stay its own
      bonusDrops: const [],
    ),
  ),
  // Bear · roster tier 2 · forest
  BEAR(CombatEntityDefinition(bear, fibLevel: 6, name: "Bear")),
  BEAR_UNCOMMON(
    CombatEntityDefinition(
      bear,
      fibLevel: 7,
      name: "Bear",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.BEAR_CLAW,
          lowCount: 2,
          highCount: 5,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.BEAR_HIDE,
          lowCount: 2,
          highCount: 5,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.BEAR_RUMP,
          lowCount: 2,
          highCount: 3,
          weight: 1,
        ),
      ],
      // a Wolf Den piece no den boss owns
      extraBonusDrops: [
        DropRoll(
          chance: 0.02,
          entries: [
            ItemDropType(id: ItemId.WOLF_HIDE_BELT, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
    ),
  ),
  // the Wolf Den's Cave Entrance boss: a bear's drops, and its own two den
  // pieces, the bear hide bracers and the helm
  CAVE_BEAR(
    CombatEntityDefinition(
      bear,
      fibLevel: 8,
      name: "Cave Bear",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(
          id: ItemId.BEAR_CLAW,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
        ItemDropType(id: ItemId.BEAR_HIDE, weight: 1),
        ItemDropType(id: ItemId.BEAR_RUMP, weight: 1),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.33,
          entries: [
            ItemDropType(id: ItemId.BEAR_HIDE_BRACERS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.11,
          entries: [
            ItemDropType(id: ItemId.BEAR_HIDE_BRACERS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.33,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.11,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_HELM, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Mudlurc · roster tier 2 · swamp
  MUDLURC(CombatEntityDefinition(mudlurc, fibLevel: 7, name: "Mudlurc")),
  MUDLURC_WARRIOR(
    CombatEntityDefinition(
      mudlurc,
      fibLevel: 8,
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
        ItemDropType(
          id: ItemId.MEDIUM_LEATHER_BELT,
          rarity: Rarity.UNCOMMON,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.MEDIUM_LEATHER_BOOTS,
          rarity: Rarity.UNCOMMON,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.MEDIUM_LEATHER_BRACERS,
          rarity: Rarity.UNCOMMON,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.MEDIUM_LEATHER_GLOVES,
          rarity: Rarity.UNCOMMON,
          weight: 1,
        ),
      ],
    ),
  ),
  // Fungal Monster · roster tier 2 · swamp
  FUNGAL_MONSTER(
    CombatEntityDefinition(fungalMonster, fibLevel: 8, name: "Fungal Monster"),
  ),
  FUNGAL_MONSTER_UNCOMMON(
    CombatEntityDefinition(
      fungalMonster,
      fibLevel: 9,
      name: "Fungal Monster",
      rarity: Rarity.UNCOMMON,
      itemDrops: [],
    ),
  ),
  // the Wolf Den's Sunken Grotto boss: a fungal monster's drops, and its own
  // two den pieces, the redcap ring and the gloves
  GROTTO_FUNGAL_MONSTER(
    CombatEntityDefinition(
      fungalMonster,
      fibLevel: 8,
      name: "Grotto Fungal Monster",
      isDungeonBoss: true,
      // a bulk haul: one stack of the grotto's growth per kill
      itemDrops: [
        ItemDropType(id: ItemId.GUAM_LEAF, lowCount: 50, highCount: 150),
        ItemDropType(id: ItemId.HARRALANDER, lowCount: 50, highCount: 150),
        ItemDropType(id: ItemId.RED_CAP_MUSHROOM, lowCount: 50, highCount: 150),
        ItemDropType(id: ItemId.OAK_LOGS, lowCount: 50, highCount: 150),
        ItemDropType(id: ItemId.MAPLE_LOGS, lowCount: 50, highCount: 150),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.33,
          entries: [
            ItemDropType(id: ItemId.REDCAP_RING, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.11,
          entries: [ItemDropType(id: ItemId.REDCAP_RING, rarity: Rarity.RARE)],
        ),
        DropRoll(
          chance: 0.33,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_GLOVES, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.11,
          entries: [
            ItemDropType(id: ItemId.WOLF_DEN_GLOVES, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Ooze · swamp. The slime grown old in the bog: the same ooze in bulk,
  // and the core it was named for, often enough to brew with.
  OOZE(CombatEntityDefinition(ooze, fibLevel: 8, name: "Ooze")),
  // the Drowned Fen's Ooze Pits boss: an ooze at level 55, its cores in
  // bulk, and its belt
  PRIMORDIAL_OOZE(
    CombatEntityDefinition(
      ooze,
      fibLevel: 8,
      name: "Primordial Ooze",
      isDungeonBoss: true,
      itemDrops: [
        ItemDropType(id: ItemId.SLIME_OOZE, lowCount: 20, highCount: 40),
        ItemDropType(id: ItemId.SLIME_CORE, lowCount: 3, highCount: 8),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.OOZE_SLICK_BELT, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.OOZE_SLICK_BELT, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Murkjaw · swamp. The bog's rare ambusher, and the only thing that
  // drops its fang - the super attack potion's reagent.
  MURKJAW(CombatEntityDefinition(murkjaw, fibLevel: 8, name: "Murkjaw")),
  // the Drowned Fen's last boss: an uncommon murkjaw at level 89, the hide and
  // fang in bulk, and its pauldrons
  MURKJAW_MATRIARCH(
    CombatEntityDefinition(
      murkjaw,
      fibLevel: 9,
      name: "Murkjaw Matriarch",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.MURKJAW_HIDE,
          lowCount: 3,
          highCount: 8,
          weight: 0.5,
        ),
        ItemDropType(
          id: ItemId.MURKJAW_FANG,
          lowCount: 2,
          highCount: 5,
          weight: 0.5,
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.MURKJAW_PAULDRONS, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.MURKJAW_PAULDRONS, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Kobold · roster tier 2 · mine
  KOBOLD(CombatEntityDefinition(kobold, fibLevel: 7, name: "Kobold")),

  //
  // Tier 9 - Level 55
  //
  // Skeleton · roster tier 3 · dark forest
  SKELETON(CombatEntityDefinition(skeleton, fibLevel: 7, name: "Skeleton")),
  SKELETON_UNCOMMON(
    CombatEntityDefinition(
      skeleton,
      fibLevel: 8,
      name: "Skeleton",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        NestedDrop(graveScrapDropTable, weight: 3, countMultiplier: 2),
        NestedDrop(
          steelMinorArmorDropTable,
          weight: 1,
          rarity: Rarity.UNCOMMON,
        ),
        NestedDrop(
          steelMajorArmorDropTable,
          weight: 0.4,
          rarity: Rarity.UNCOMMON,
        ),
        ItemDropType(
          id: ItemId.STEEL_SHIELD,
          weight: 0.4,
          rarity: Rarity.UNCOMMON,
        ),
      ],
    ),
  ),
  // Zombie · roster tier 3 · dark forest
  ZOMBIE(CombatEntityDefinition(zombie, fibLevel: 8, name: "Zombie")),
  ZOMBIE_UNCOMMON(
    CombatEntityDefinition(
      zombie,
      fibLevel: 9,
      name: "Zombie",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  // the Spider Den's Cocoon Hollow boss: an uncommon zombie, drops and all
  // (inherited from the common), kept apart from the regulars the
  // Broodmother's Lair fields
  THICKET_ZOMBIE(
    CombatEntityDefinition(
      zombie,
      fibLevel: 9,
      name: "Cocooned Zombie",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      // its ring, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md).
      // Written in full, not added on top, so the zombie's Tattered rags
      // stay overworld loot rather than a boss's
      bonusDrops: [
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(id: ItemId.VENOMFANG_RING, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.VENOMFANG_RING, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  // Harpy · roster tier 3 · ironroot hills
  HARPY(CombatEntityDefinition(harpy, fibLevel: 8, name: "Harpy")),
  // Naga · roster tier 3 · coast
  NAGA(CombatEntityDefinition(naga, fibLevel: 8, name: "Naga")),

  //
  // Tier 10 - Level 89
  //
  // Giant Scorpion · roster tier 3 · copperdust flats
  GIANT_SCORPION(
    CombatEntityDefinition(giantScorpion, fibLevel: 9, name: "Giant Scorpion"),
  ),
  // Imp · roster tier 3 · ironroot hills
  IMP(CombatEntityDefinition(imp, fibLevel: 9, name: "Imp")),
  // ── STORMGRASS PRAIRIE ──
  // Orc · stormgrass prairie. The common is the level 55 raider and the
  // uncommon the level 89 warband, one archetype between them. The tusk is
  // the greater strength potion's reagent, and a tenth of kills carry off a
  // piece of steel kit
  ORC(CombatEntityDefinition(orc, fibLevel: 8, name: "Orc")),
  ORC_UNCOMMON(
    CombatEntityDefinition(
      orc,
      fibLevel: 9,
      name: "Orc",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  // Rattlesnake · stormgrass prairie, level 55. Its skin and its venom are
  // the greater defence and recovery potions' reagents
  RATTLESNAKE(
    CombatEntityDefinition(rattlesnake, fibLevel: 8, name: "Rattlesnake"),
  ),
  // Sabertooth · stormgrass prairie, level 89. The fang is the greater
  // attack potion's reagent; the pelt waits on leatherworking
  SABERTOOTH(
    CombatEntityDefinition(sabertooth, fibLevel: 9, name: "Sabertooth"),
  ),
  // Tempest Reach's second boss: an uncommon sabertooth at level 144, its
  // fangs in bulk, and its fang and mantle
  SABERTOOTH_ALPHA(
    CombatEntityDefinition(
      sabertooth,
      fibLevel: 10,
      name: "Sabertooth Alpha",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.SABERTOOTH_FANG,
          lowCount: 3,
          highCount: 5,
          weight: 0.5,
        ),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(
              id: ItemId.SABERTOOTH_PELT,
              lowCount: 5,
              highCount: 13,
            ),
          ],
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.17,
          entries: [ItemDropType(id: ItemId.ALPHAS_FANG, rarity: Rarity.RARE)],
        ),
        DropRoll(
          chance: 0.04,
          entries: [ItemDropType(id: ItemId.ALPHAS_FANG, rarity: Rarity.EPIC)],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.ALPHAS_MANTLE, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.04,
          entries: [
            ItemDropType(id: ItemId.ALPHAS_MANTLE, rarity: Rarity.EPIC),
          ],
        ),
      ],
    ),
  ),
  // Centaur · stormgrass prairie, level 89. The hoof is the greater stamina
  // potion's reagent; the sinew waits on fletching
  CENTAUR(CombatEntityDefinition(centaur, fibLevel: 9, name: "Centaur")),
  // Dust Devil · stormgrass prairie, level 89, and the first magic thing in
  // the game. The wind mote is the greater speed potion's reagent; the
  // essence feeds enchanting
  DUST_DEVIL(
    CombatEntityDefinition(dustDevil, fibLevel: 9, name: "Dust Devil"),
  ),

  //
  // Tier 11 - Level 144
  //
  // Wraith · roster tier 4 · dark forest
  WRAITH(CombatEntityDefinition(wraith, fibLevel: 10, name: "Wraith")),
  // Banshee · roster tier 4 · dark forest
  BANSHEE(CombatEntityDefinition(banshee, fibLevel: 10, name: "Banshee")),
  // Troll · roster tier 4 · ironroot hills
  TROLL(CombatEntityDefinition(troll, fibLevel: 10, name: "Troll")),
  // Minotaur · roster tier 4 · mine
  MINOTAUR(CombatEntityDefinition(minotaur, fibLevel: 10, name: "Minotaur")),
  // Basilisk · roster tier 4 · redwall bluffs
  BASILISK(CombatEntityDefinition(basilisk, fibLevel: 10, name: "Basilisk")),
  // Dark Wizard · roster tier 4 · crypt
  DARK_WIZARD(
    CombatEntityDefinition(darkWizard, fibLevel: 10, name: "Dark Wizard"),
  ),
  // Gargoyle · roster tier 4 · redwall bluffs
  GARGOYLE(CombatEntityDefinition(gargoyle, fibLevel: 10, name: "Gargoyle")),

  //
  // Tier 12 - Level 233
  //
  // Moss Golem · roster tier 5 · swamp
  MOSS_GOLEM(
    CombatEntityDefinition(mossGolem, fibLevel: 11, name: "Moss Golem"),
  ),
  // Hill Giant · roster tier 5 · ironroot hills
  HILL_GIANT(
    CombatEntityDefinition(hillGiant, fibLevel: 11, name: "Hill Giant"),
  ),
  // Earth Elemental · roster tier 5 · mine
  EARTH_ELEMENTAL(
    CombatEntityDefinition(
      earthElemental,
      fibLevel: 11,
      name: "Earth Elemental",
    ),
  ),
  // Ogre · roster tier 5 · mountains
  OGRE(CombatEntityDefinition(ogre, fibLevel: 11, name: "Ogre")),
  // Stone Golem · roster tier 5 · mountains
  STONE_GOLEM(
    CombatEntityDefinition(stoneGolem, fibLevel: 11, name: "Stone Golem"),
  ),
  // Griffin · roster tier 5 · redwall bluffs
  GRIFFIN(CombatEntityDefinition(griffin, fibLevel: 11, name: "Griffin")),
  // Fire Elemental · roster tier 5 · volcanic
  FIRE_ELEMENTAL(
    CombatEntityDefinition(fireElemental, fibLevel: 11, name: "Fire Elemental"),
  ),
  // Water Elemental · roster tier 5 · coast
  WATER_ELEMENTAL(
    CombatEntityDefinition(
      waterElemental,
      fibLevel: 11,
      name: "Water Elemental",
    ),
  ),

  //
  // Tier 13 - Level 377
  //
  // Yeti · roster tier 6 · frozen peaks
  YETI(CombatEntityDefinition(yeti, fibLevel: 12, name: "Yeti")),
  // Iron Golem · roster tier 6 · volcanic
  IRON_GOLEM(
    CombatEntityDefinition(ironGolem, fibLevel: 12, name: "Iron Golem"),
  ),
  // Steel Golem · roster tier 6 · mine
  STEEL_GOLEM(
    CombatEntityDefinition(steelGolem, fibLevel: 12, name: "Steel Golem"),
  ),
  // Lich · roster tier 6 · crypt
  LICH(CombatEntityDefinition(lich, fibLevel: 12, name: "Lich")),
  // Cloud Giant · roster tier 6 · mountains
  CLOUD_GIANT(
    CombatEntityDefinition(cloudGiant, fibLevel: 12, name: "Cloud Giant"),
  ),
  // Roc · roster tier 6 · frozen peaks
  ROC(CombatEntityDefinition(roc, fibLevel: 12, name: "Roc")),
  // Wyvern · roster tier 6 · volcanic
  WYVERN(CombatEntityDefinition(wyvern, fibLevel: 12, name: "Wyvern")),
  // Drake · roster tier 6 · volcanic
  DRAKE(CombatEntityDefinition(drake, fibLevel: 12, name: "Drake")),

  //
  // Tier 14 - Level 610
  //
  // Kraken · roster tier 7 · deep water dungeon
  KRAKEN(CombatEntityDefinition(kraken, fibLevel: 13, name: "Kraken")),
  // Dragon · roster tier 7 · dragon's lair
  DRAGON(CombatEntityDefinition(dragon, fibLevel: 13, name: "Dragon")),
  // Lesser Demon · roster tier 7 · underworld
  LESSER_DEMON(
    CombatEntityDefinition(lesserDemon, fibLevel: 13, name: "Lesser Demon"),
  ),
  // Greater Demon · roster tier 7 · underworld
  GREATER_DEMON(
    CombatEntityDefinition(greaterDemon, fibLevel: 13, name: "Greater Demon"),
  ),

  // ── COMBAT · NAMED CHARACTERS ──────────────────────────────────
  // One-offs that sit outside the roster, each its own archetype.
  FIELD_RAT(CombatEntityDefinition(fieldRat, fibLevel: 0, name: "Field Rat")),
  BIG_RED(
    CombatEntityDefinition(
      bigRed,
      fibLevel: 4,
      name: "Big Red",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.CHICKEN_MEAT, weight: 1),
        ItemDropType(
          id: ItemId.FEATHER,
          weight: 1,
          lowCount: 25,
          highCount: 50,
        ),
        ItemDropType(
          id: ItemId.CHICKEN_MEAT,
          weight: 1,
          lowCount: 25,
          highCount: 50,
        ),
        ItemDropType(
          id: ItemId.COOKED_CHICKEN,
          weight: 1,
          lowCount: 25,
          highCount: 50,
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.CHICKEN_CHARM, rarity: Rarity.COMMON),
          ],
        ),
        DropRoll(
          chance: 0.035,
          entries: [
            ItemDropType(id: ItemId.CHICKEN_CHARM, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_SCOUT(
    CombatEntityDefinition(
      goblinScout,
      fibLevel: 4,
      name: "Goblin",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.IRON_DAGGER, weight: 1),
        ItemDropType(
          id: ItemId.COOKED_BLUEGILL,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
      ],
      // 5% chance, on top of the main drop, to yield the key that opens
      // the Goblin Queen's Lair landmark dungeon
      bonusDrops: [
        DropRoll(
          chance: 0.05,
          entries: [ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY)],
        ),
      ],
    ),
  ),
  GOBLIN_SEARGENT(
    CombatEntityDefinition(
      goblinSeargent,
      fibLevel: 6,
      name: "Goblin Seargent",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.IRON_DAGGER, weight: 1),
        ItemDropType(
          id: ItemId.IRON_DAGGER,
          rarity: Rarity.UNCOMMON,
          weight: .1,
        ),
        ItemDropType(id: ItemId.IRON_DAGGER, rarity: Rarity.RARE, weight: .01),
        ItemDropType(id: ItemId.GUAM_LEAF, weight: 1),
        ItemDropType(id: ItemId.LIGHT_LEATHER_BOOTS, weight: 1),
        ItemDropType(
          id: ItemId.COOKED_BLUEGILL,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
      ],
      // 5% chance, on top of the main drop, to yield the key that opens
      // the Goblin Queen's Lair landmark dungeon
      bonusDrops: [
        DropRoll(
          chance: 0.05,
          entries: [ItemDropType(id: ItemId.GOBLIN_QUEEN_KEY)],
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.08,
          entries: [
            ItemDropType(id: ItemId.SERGEANTS_SHIV, rarity: Rarity.COMMON),
          ],
        ),
        DropRoll(
          chance: 0.03,
          entries: [
            ItemDropType(id: ItemId.SERGEANTS_SHIV, rarity: Rarity.UNCOMMON),
          ],
        ),
        DropRoll(
          chance: 0.08,
          entries: [
            ItemDropType(id: ItemId.WARBAND_BELT, rarity: Rarity.COMMON),
          ],
        ),
        DropRoll(
          chance: 0.03,
          entries: [
            ItemDropType(id: ItemId.WARBAND_BELT, rarity: Rarity.UNCOMMON),
          ],
        ),
      ],
    ),
  ),
  SPIDER_BROODMOTHER(
    CombatEntityDefinition(
      spiderBroodmother,
      fibLevel: 9,
      name: "Spider Broodmother",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
      itemDrops: [NestedDrop(spiderDropTable, countMultiplier: 6)],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(
              id: ItemId.SPIDER_SILK_NECKLACE,
              rarity: Rarity.UNCOMMON,
            ),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.SPIDER_SILK_NECKLACE, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.3,
          entries: [
            ItemDropType(
              id: ItemId.BROODMOTHERS_MANTLE,
              rarity: Rarity.UNCOMMON,
            ),
          ],
        ),
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.BROODMOTHERS_MANTLE, rarity: Rarity.RARE),
          ],
        ),
      ],
    ),
  ),
  GOBLIN_QUEEN(
    CombatEntityDefinition(
      goblinQueen,
      fibLevel: 11,
      name: "Goblin Queen",
      isDungeonBoss: true,
      rarity: Rarity.LEGENDARY,
      // her hoard: a gem or a stack of bars on every kill
      itemDrops: [
        NestedDrop(gemDropTable, weight: 1),
        ItemDropType(
          id: ItemId.RUNITE_BAR,
          lowCount: 5,
          highCount: 13,
          weight: 1,
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.17,
          entries: [ItemDropType(id: ItemId.GOBLIN_CROWN, rarity: Rarity.RARE)],
        ),
        DropRoll(
          chance: 0.04,
          entries: [ItemDropType(id: ItemId.GOBLIN_CROWN, rarity: Rarity.EPIC)],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.GOBLIN_SCEPTER, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.04,
          entries: [
            ItemDropType(id: ItemId.GOBLIN_SCEPTER, rarity: Rarity.EPIC),
          ],
        ),
      ],
    ),
  ),
  // Tempest Reach's first boss, at level 144: the orcs' tusks in bulk, its
  // cleaver and warhelm, and a bundle of mithril bars on a tenth of kills
  ORC_WARLORD(
    CombatEntityDefinition(
      orcWarlord,
      fibLevel: 10,
      name: "Orc Warlord",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.ORC_TUSK,
          lowCount: 3,
          highCount: 5,
          weight: 0.5,
        ),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 5, highCount: 13),
          ],
        ),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.WARLORDS_CLEAVER, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.04,
          entries: [
            ItemDropType(id: ItemId.WARLORDS_CLEAVER, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.WARLORDS_WARHELM, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.04,
          entries: [
            ItemDropType(id: ItemId.WARLORDS_WARHELM, rarity: Rarity.EPIC),
          ],
        ),
      ],
    ),
  ),
  // Tempest Reach's last boss, at level 144: wind motes in bulk, its
  // scepter and gauntlets, and on a tenth of kills the storm shard nothing
  // else drops
  TEMPEST(
    CombatEntityDefinition(
      tempest,
      fibLevel: 10,
      name: "Tempest",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.WIND_MOTE,
          lowCount: 3,
          highCount: 5,
          weight: 0.5,
        ),
      ],
      bonusDrops: [
        DropRoll(chance: 0.1, entries: [ItemDropType(id: ItemId.STORM_SHARD)]),
      ],
      // its uniques, at its band's two rarities (design/DUNGEON_LOOT_GUIDE.md)
      extraBonusDrops: [
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.STORMCALLERS_SCEPTER, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.04,
          entries: [
            ItemDropType(id: ItemId.STORMCALLERS_SCEPTER, rarity: Rarity.EPIC),
          ],
        ),
        DropRoll(
          chance: 0.17,
          entries: [
            ItemDropType(id: ItemId.GALEWRAP_GAUNTLETS, rarity: Rarity.RARE),
          ],
        ),
        DropRoll(
          chance: 0.04,
          entries: [
            ItemDropType(id: ItemId.GALEWRAP_GAUNTLETS, rarity: Rarity.EPIC),
          ],
        ),
      ],
    ),
  ),

  // ── COMBAT · MOUNTAIN AND PEAK DUNGEON BOSSES ──────────────────
  // The mountains' zone monsters stop at 233 and the peaks' at 377: the
  // rung above each is held by these bosses alone, one at the end of each
  // card of the zone's dungeon. Each is its own entity on a roster
  // archetype, so it shares that monster's art and inherited loot.
  //
  // Spinehold Caverns · Greyspine Mountain · level 377
  ELDER_ROC(
    CombatEntityDefinition(
      roc,
      fibLevel: 12,
      name: "Elder Roc",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
    ),
  ),
  STEEL_SENTINEL(
    CombatEntityDefinition(
      steelGolem,
      fibLevel: 12,
      name: "Steel Sentinel",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
    ),
  ),
  GREYSPINE_DRAKE(
    CombatEntityDefinition(
      drake,
      fibLevel: 12,
      name: "Greyspine Drake",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  // The Ashen Vaults · Ashridge Mountains · level 377
  ASH_WYVERN(
    CombatEntityDefinition(
      wyvern,
      fibLevel: 12,
      name: "Ash Wyvern",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
    ),
  ),
  SLAG_WARDEN(
    CombatEntityDefinition(
      ironGolem,
      fibLevel: 12,
      name: "Slag Warden",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
    ),
  ),
  // a fire elemental a rung above the ridge's own, fed by the vaults' slag
  HEART_OF_THE_RIDGE(
    CombatEntityDefinition(
      fireElemental,
      fibLevel: 12,
      name: "Heart of the Ridge",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  // Hoarfrost Hollow · Frostcrown Peaks · level 610
  YETI_PATRIARCH(
    CombatEntityDefinition(
      yeti,
      fibLevel: 13,
      name: "Yeti Patriarch",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  FROST_GIANT(
    CombatEntityDefinition(
      frostGiant,
      fibLevel: 13,
      name: "Frost Giant",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  FROST_WYRM(
    CombatEntityDefinition(
      frostWyrm,
      fibLevel: 13,
      name: "Frost Wyrm",
      isDungeonBoss: true,
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Thunderhall · Stormcrown Peaks · level 610
  ROC_BROODMOTHER(
    CombatEntityDefinition(
      roc,
      fibLevel: 13,
      name: "Roc Broodmother",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  THUNDERBIRD(
    CombatEntityDefinition(
      thunderbird,
      fibLevel: 13,
      name: "Thunderbird",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  STORM_GIANT(
    CombatEntityDefinition(
      stormGiant,
      fibLevel: 13,
      name: "Storm Giant",
      isDungeonBoss: true,
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // The Caldera · Moltenspire Peaks · level 610
  CALDERA_LESSER_DEMON(
    CombatEntityDefinition(
      lesserDemon,
      fibLevel: 13,
      name: "Lesser Demon",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  CALDERA_GREATER_DEMON(
    CombatEntityDefinition(
      greaterDemon,
      fibLevel: 13,
      name: "Greater Demon",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
    ),
  ),
  CALDERA_DRAGON(
    CombatEntityDefinition(
      dragon,
      fibLevel: 13,
      name: "Dragon",
      isDungeonBoss: true,
      rarity: Rarity.LEGENDARY,
    ),
  ),

  // ── COMBAT · MISTGRAVE HOLLOW ──────────────────────────────────
  // The haunted cemetery south of the darkwood and the Haunted Ruins
  // monastery in it, at Stormgrass Prairie's tier: regulars at 55 and 89,
  // a level-144 boss at the end of each of the ruins' floors. Each is a
  // named monster on an undead archetype, wearing that archetype's art.
  // The ones below their archetype's lootFibLevel write their own tables.
  //
  // level 55, the skeleton's loot a rung up
  RESTLESS_SKELETON(
    CombatEntityDefinition(skeleton, fibLevel: 8, name: "Restless Skeleton"),
  ),
  // level 89, the zombie's loot a rung up
  GRAVE_GHOUL(CombatEntityDefinition(zombie, fibLevel: 9, name: "Grave Ghoul")),
  // level 89
  WAILING_BANSHEE(
    CombatEntityDefinition(
      banshee,
      fibLevel: 9,
      name: "Wailing Banshee",
      itemDrops: [
        ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1),
        ItemDropType(
          id: ItemId.GRAVE_MOSS,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.ENCHANTING_ESSENCE,
          lowCount: 1,
          highCount: 2,
          weight: .5,
        ),
      ],
    ),
  ),
  // level 89, the darkwood's wraith a rung down and thinner
  MIST_WRAITH(
    CombatEntityDefinition(
      wraith,
      fibLevel: 9,
      name: "Mist Wraith",
      itemDrops: [
        ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1),
        ItemDropType(
          id: ItemId.GRAVE_MOSS,
          lowCount: 1,
          highCount: 3,
          weight: 2,
        ),
      ],
      bonusDrops: [
        DropRoll(entries: tatteredClothUncommonDropTable, chance: 0.15),
      ],
    ),
  ),
  // level 89, the ruins' own: the brothers who stayed
  FALLEN_MONK(
    CombatEntityDefinition(
      darkWizard,
      fibLevel: 9,
      name: "Fallen Monk",
      itemDrops: [
        ItemDropType(
          id: ItemId.ENCHANTING_ESSENCE,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
        ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: .5),
      ],
    ),
  ),
  // The Graveyard Gate's boss, level 144
  THE_GRAVEKEEPER(
    CombatEntityDefinition(
      skeleton,
      fibLevel: 10,
      name: "The Gravekeeper",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.ROTTEN_FLESH,
          lowCount: 3,
          highCount: 5,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.GRAVE_MOSS,
          lowCount: 3,
          highCount: 5,
          weight: 1,
        ),
        NestedDrop(steelMinorArmorDropTable, rarity: Rarity.RARE, weight: .5),
        NestedDrop(steelMajorArmorDropTable, rarity: Rarity.RARE, weight: .3),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [
            ItemDropType(id: ItemId.MITHRIL_BAR, lowCount: 5, highCount: 13),
          ],
        ),
      ],
    ),
  ),
  // The Silent Nave's boss, level 144
  THE_WEEPING_ABBESS(
    CombatEntityDefinition(
      banshee,
      fibLevel: 10,
      name: "The Weeping Abbess",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.ENCHANTING_RUNE,
          lowCount: 3,
          highCount: 5,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.ENCHANTING_ESSENCE,
          lowCount: 5,
          highCount: 13,
          weight: 1,
        ),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.ENCHANTING_PRISM)],
        ),
      ],
    ),
  ),
  // The Ossuary's boss and the ruins' last, level 144
  THE_UNDYING_ABBOT(
    CombatEntityDefinition(
      lich,
      fibLevel: 10,
      name: "The Undying Abbot",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(
          id: ItemId.ENCHANTING_RUNE,
          lowCount: 3,
          highCount: 5,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.GRAVE_MOSS,
          lowCount: 5,
          highCount: 13,
          weight: 1,
        ),
      ],
      bonusDrops: [
        DropRoll(chance: 0.05, entries: [ItemDropType(id: ItemId.SOUL_SHARD)]),
      ],
    ),
  ),

  // ── SHOPS ───────────────────────────────────────────────────────
  // ShopEntityDefinition, by zone then stock tier
  FARMER(
    ShopEntityDefinition(
      name: "Farmer's Stall",
      iconAsset: "assets/images/entities/farmer_john.png",
      stockSlots: 14,
      restockInterval: Duration(minutes: 30),
      shopStockPool: [
        // the meadow's own survey, always on the shelf
        ShopStockEntry(
          itemId: ItemId.SCOUTING_MAP_TUTORIAL_FARM,
          count: 5,
          alwaysStocked: true,
        ),
        ShopStockEntry(itemId: ItemId.COOKED_MINNOW, count: 200),
        ShopStockEntry(
          itemId: ItemId.COOKED_CHICKEN,
          count: 5,
          priceOverride: 0,
        ),
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
        // the scouting maps, always on the shelf ahead of the rotating draw
        ShopStockEntry(
          itemId: ItemId.SCOUTING_MAP_SOUTHWOOD_FOREST,
          count: 5,
          alwaysStocked: true,
        ),
        ShopStockEntry(
          itemId: ItemId.SCOUTING_MAP_DARKWOOD_FOREST,
          count: 5,
          alwaysStocked: true,
        ),
        ShopStockEntry(
          itemId: ItemId.SCOUTING_MAP_FOREST_MINE,
          count: 5,
          alwaysStocked: true,
        ),
        // the full iron set, one entry per slot, the medium leather body
        // pieces (the goblins drop its extremities), and every skill's basic
        // gloves, boots and cloak but the woodcutter's and the fisher's,
        // which come out of bird's nests and sunken caches: far more than
        // stockSlots, so a restock shelves a rotating ten of them
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
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_SPAULDERS, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_CHEST, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_BELT, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_BRACERS, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_HERBALISTS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FIREMAKERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_COOKS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_BLACKSMITHS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ENCHANTERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_JEWELERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ALCHEMISTS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_EXPLORERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_HERBALISTS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FIREMAKERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_COOKS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_BLACKSMITHS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ENCHANTERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_JEWELERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ALCHEMISTS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_EXPLORERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_HERBALISTS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FIREMAKERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_COOKS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_BLACKSMITHS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ENCHANTERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_JEWELERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ALCHEMISTS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_EXPLORERS_CLOAK, count: 1),
      ],
      // defaults: 25% markup, 6 hour restock, 10 stock slots
    ),
  ),
  MINING_SHOP(
    ShopEntityDefinition(
      name: "Mining Shop",
      iconAsset: "assets/images/entities/trading_post.png",
      // the whole pool fits on the shelf, so a restock never hides an item
      stockSlots: 19,
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.COPPER_ORE, count: 200),
        ShopStockEntry(itemId: ItemId.IRON_ORE, count: 200),
        ShopStockEntry(itemId: ItemId.COAL, count: 200),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_HAT, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_TUNIC, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_MINERS_HAT, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_MINERS_TUNIC, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_MINERS_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_MINERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_MINERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_MINERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.COPPER_PICKAXE, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_PICKAXE, count: 1),
        ShopStockEntry(itemId: ItemId.STEEL_PICKAXE, count: 1),
        ShopStockEntry(itemId: ItemId.MITHRIL_PICKAXE, count: 1),
      ],
    ),
  ),
  // Maplewater Village's own trading post. The stock is TBD: a single
  // placeholder entry keeps the shop valid until the real pool is decided.
  MAPLEWATER_TRADING_POST(
    ShopEntityDefinition(
      name: "Maplewater Trading Post",
      iconAsset: "assets/images/entities/trading_post.png",
      rarity: Rarity.UNCOMMON,
      stockSlots: 1,
      shopStockPool: [
        // TBD: placeholder stock
        ShopStockEntry(itemId: ItemId.LOGS, count: 100),
      ],
    ),
  ),
  // The village's fishing shop: every raw fish up to catfish and the rods
  // up to mithril (the Fisher's set comes out of sunken caches). The whole
  // pool fits on the shelf so a restock never hides an item.
  FISHING_SHOP(
    ShopEntityDefinition(
      name: "Fishing Shop",
      iconAsset: "assets/images/entities/trading_post.png",
      stockSlots: 14,
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.MINNOW, count: 500),
        ShopStockEntry(itemId: ItemId.CARP, count: 500),
        ShopStockEntry(itemId: ItemId.CRAYFISH, count: 500),
        ShopStockEntry(itemId: ItemId.BLUEGILL, count: 500),
        ShopStockEntry(itemId: ItemId.TROUT, count: 500),
        ShopStockEntry(itemId: ItemId.PIKE, count: 500),
        ShopStockEntry(itemId: ItemId.BOG_EEL, count: 500),
        ShopStockEntry(itemId: ItemId.SALMON, count: 500),
        ShopStockEntry(itemId: ItemId.CATFISH, count: 500),
        ShopStockEntry(itemId: ItemId.SIMPLE_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.COPPER_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.STEEL_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.MITHRIL_FISHING_ROD, count: 1),
      ],
    ),
  ),
  // The village's lumber mill: every log the game has, up to yew. Magic
  // logs are only ever cut, never bought.
  LUMBER_MILL(
    ShopEntityDefinition(
      name: "Lumber Mill",
      iconAsset: "assets/images/entities/trading_post.png",
      // the whole pool fits on the shelf, so a restock never hides an item
      stockSlots: 6,
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.OAK_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.WILLOW_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.BOG_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.MAPLE_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.YEW_LOGS, count: 500),
      ],
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

  DEV_SHOP(
    DevShopEntityDefinition(
      name: "Dev Shop",
      iconAsset: "assets/images/entities/trading_post.png",
      rarity: Rarity.LEGENDARY,
    ),
  ),

  // ── DUNGEON ENTRANCES ───────────────────────────────────────────
  // DungeonEntityDefinition, same order as dungeon_id.dart
  GRAINERY_ENTRANCE(
    DungeonEntityDefinition(
      name: "Grainery",
      iconAsset: "assets/images/entities/grainery.png",
      rarity: Rarity.UNCOMMON,
      dungeonId: DungeonId.GRAINERY,
    ),
  ),
  SPIDER_DEN_ENTRANCE(
    DungeonEntityDefinition(
      name: "Spider Den",
      iconAsset: "assets/images/entities/spider_den.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.SPIDER_DEN,
    ),
  ),
  WOLF_DEN_ENTRANCE(
    DungeonEntityDefinition(
      name: "Wolf Den",
      iconAsset: "assets/images/entities/wolf_den.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.WOLF_DEN,
    ),
  ),
  DROWNED_FEN_ENTRANCE(
    DungeonEntityDefinition(
      name: "Drowned Fen",
      iconAsset: "assets/images/entities/drowned_fen.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.DROWNED_FEN,
    ),
  ),
  TEMPEST_REACH_ENTRANCE(
    DungeonEntityDefinition(
      name: "Tempest Reach",
      iconAsset: "assets/images/entities/tempest_reach.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.TEMPEST_REACH,
    ),
  ),
  HAUNTED_RUINS_ENTRANCE(
    DungeonEntityDefinition(
      name: "Haunted Ruins",
      iconAsset: "assets/images/entities/haunted_ruins.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.HAUNTED_RUINS,
    ),
  ),
  SPINEHOLD_CAVERNS_ENTRANCE(
    DungeonEntityDefinition(
      name: "Spinehold Caverns",
      iconAsset: "assets/images/entities/spinehold_caverns.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.SPINEHOLD_CAVERNS,
    ),
  ),
  ASHEN_VAULTS_ENTRANCE(
    DungeonEntityDefinition(
      name: "The Ashen Vaults",
      iconAsset: "assets/images/entities/ashen_vaults.png",
      rarity: Rarity.RARE,
      dungeonId: DungeonId.ASHEN_VAULTS,
    ),
  ),
  HOARFROST_HOLLOW_ENTRANCE(
    DungeonEntityDefinition(
      name: "Hoarfrost Hollow",
      iconAsset: "assets/images/entities/hoarfrost_hollow.png",
      rarity: Rarity.EPIC,
      dungeonId: DungeonId.HOARFROST_HOLLOW,
    ),
  ),
  THUNDERHALL_ENTRANCE(
    DungeonEntityDefinition(
      name: "Thunderhall",
      iconAsset: "assets/images/entities/thunderhall.png",
      rarity: Rarity.EPIC,
      dungeonId: DungeonId.THUNDERHALL,
    ),
  ),
  THE_CALDERA_ENTRANCE(
    DungeonEntityDefinition(
      name: "The Caldera",
      iconAsset: "assets/images/entities/the_caldera.png",
      rarity: Rarity.EPIC,
      dungeonId: DungeonId.THE_CALDERA,
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
