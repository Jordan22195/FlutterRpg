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
      itemDrops: [ItemDropType(id: ItemId.MAPLE_LOGS, weight: 1)],
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

  // Tier 6 mining, past the adamantite. Not placed in any zone yet.
  RUNITE_VEIN(
    EncounterEntityDefinition(
      name: "Runite Vein",
      iconAsset: "assets/images/entities/runite_vein.png",
      rarity: Rarity.EPIC,

      discoveryLevel: 80,
      entityType: SkillId.MINING,
      defence: 70,
      hitpoints: 60,
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
  // the pond and creek, up by 5 a spot to the ocean's 25
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
  // CombatArchetype sets the tier and how it fights, and the variant's
  // own rarity walks it up the Fibonacci ladder from there (see
  // CombatEntityDefinition.level). A monster is five entries — one per
  // Rarity — differing only in name, rarity and drop table.
  //
  // Ordered by tier, and within a tier by the zone the monster belongs
  // to. A variant that writes no drops inherits its common's, scaled to
  // its rarity (see CombatEntityDefinition.itemDrops); one that writes
  // itemDrops or bonusDrops replaces that table, and extraItemDrops /
  // extraBonusDrops add to it. A common with an empty table is a stub:
  // the roster gave levels, not loot.

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
    CombatEntityDefinition(chicken, name: "Chicken", rarity: Rarity.UNCOMMON),
  ),
  CHICKEN_RARE(
    CombatEntityDefinition(chicken, name: "Chicken", rarity: Rarity.RARE),
  ),
  CHICKEN_EPIC(
    CombatEntityDefinition(chicken, name: "Chicken", rarity: Rarity.EPIC),
  ),
  CHICKEN_LEGENDARY(
    CombatEntityDefinition(chicken, name: "Chicken", rarity: Rarity.LEGENDARY),
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
  COW_BOSS(
    CombatEntityDefinition(
      cow,
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
        ItemDropType(id: ItemId.MOOD_RING, rarity: Rarity.COMMON, weight: .5),
        ItemDropType(id: ItemId.MOOD_RING, rarity: Rarity.UNCOMMON, weight: .2),
      ],
    ),
  ),
  COW_RARE(CombatEntityDefinition(cow, name: "Cow", rarity: Rarity.RARE)),
  COW_EPIC(CombatEntityDefinition(cow, name: "Cow", rarity: Rarity.EPIC)),
  COW_LEGENDARY(
    CombatEntityDefinition(cow, name: "Cow", rarity: Rarity.LEGENDARY),
  ),

  //
  // Tier 5 - Level 8
  //
  // Giant Rat · roster tier 1 · farm
  GIANT_RAT(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      itemDrops: [ItemDropType(id: ItemId.GOLD_RING, lowCount: 1, weight: 1)],
    ),
  ),
  GIANT_RAT_UNCOMMON(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  GIANT_RAT_RARE(
    CombatEntityDefinition(giantRat, name: "Giant Rat", rarity: Rarity.RARE),
  ),
  GIANT_RAT_EPIC(
    CombatEntityDefinition(giantRat, name: "Giant Rat", rarity: Rarity.EPIC),
  ),
  GIANT_RAT_LEGENDARY(
    CombatEntityDefinition(
      giantRat,
      name: "Giant Rat",
      rarity: Rarity.LEGENDARY,
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
        ItemDropType(id: ItemId.IRON_ORE, weight: 1, lowCount: 1, highCount: 2),
        // the pitchfork is a main-table line, not a bonus roll: it used to
        // be an independent 5% layered on top, and moving it inline is what
        // takes the other three drops from a third each down to 2/7
        ItemDropType(id: ItemId.PITCHFORK, weight: .5),
        ItemDropType(id: ItemId.WOOD_SHIELD, weight: .3),
      ],
    ),
  ),
  ROTWOOD_SCARECROW_BOSS(
    CombatEntityDefinition(
      scarecrow,
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
          id: ItemId.COPPER_BAR,
          weight: 1,
          lowCount: 20,
          highCount: 50,
        ),
        ItemDropType(id: ItemId.PITCHFORK, weight: .8),
        ItemDropType(id: ItemId.WOOD_SHIELD, weight: .3),
        ItemDropType(
          id: ItemId.WOOD_SHIELD,
          rarity: Rarity.UNCOMMON,
          weight: .3,
        ),
        ItemDropType(id: ItemId.PITCHFORK, rarity: Rarity.UNCOMMON, weight: .5),
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
    ),
  ),
  ROTWOOD_SCARECROW_LEGENDARY(
    CombatEntityDefinition(
      scarecrow,
      name: "Rotwood Scarecrow",
      rarity: Rarity.LEGENDARY,
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
      itemDrops: [NestedDrop(spiderDropTable)],
    ),
  ),
  GIANT_SPIDER_UNCOMMON(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        NestedDrop(spiderDropTable, countMultiplier: 2),
        ItemDropType(id: ItemId.SPIDER_SILK_NECKLACE, weight: .2),
        ItemDropType(id: ItemId.SPIDER_SILK_NECKLACE, weight: .1),
      ],
    ),
  ),
  GIANT_SPIDER_RARE(
    CombatEntityDefinition(spider, name: "Giant Spider", rarity: Rarity.RARE),
  ),
  // the Spider Den's Webbed Thicket boss: a rare giant spider, with the
  // regulars' drops in bulk
  THICKET_WEAVER(
    CombatEntityDefinition(
      spider,
      name: "Thicket Weaver",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
      itemDrops: [NestedDrop(spiderDropTable, countMultiplier: 3)],
      bonusDrops: [
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.WEBBED_CLOAK)],
        ),
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.WEBBED_BRACERS)],
        ),
      ],
    ),
  ),
  GIANT_SPIDER_EPIC(
    CombatEntityDefinition(spider, name: "Giant Spider", rarity: Rarity.EPIC),
  ),
  GIANT_SPIDER_LEGENDARY(
    CombatEntityDefinition(
      spider,
      name: "Giant Spider",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Forest Wolf · roster tier 2 · forest
  FOREST_WOLF(
    CombatEntityDefinition(
      wolf,
      name: "Forest Wolf",
      itemDrops: [
        ItemDropType(id: ItemId.WOLF_CLAW, weight: 1),
        ItemDropType(id: ItemId.WOLF_PELT, weight: 1),
      ],
    ),
  ),
  FOREST_WOLF_UNCOMMON(
    CombatEntityDefinition(
      wolf,
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
    ),
  ),
  FOREST_WOLF_RARE(
    CombatEntityDefinition(
      wolf,
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
      // the Wolf Den's first boss: one of the basic fisher's set, a tenth of kills
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.BASIC_FISHERS_BOOTS)],
        ),
      ],
    ),
  ),
  FOREST_WOLF_EPIC(
    CombatEntityDefinition(wolf, name: "Forest Wolf", rarity: Rarity.EPIC),
  ),
  FOREST_WOLF_LEGENDARY(
    CombatEntityDefinition(wolf, name: "Forest Wolf", rarity: Rarity.LEGENDARY),
  ),
  // the Wolf Den's Deep Lair boss: a forest wolf's drops, and the den set's minor
  // slots on a rare chance
  DEN_ALPHA_WOLF(
    CombatEntityDefinition(
      wolf,
      name: "Den Alpha Wolf",
      isDungeonBoss: true,
      rarity: Rarity.RARE,
      itemDrops: [
        ItemDropType(id: ItemId.WOLF_CLAW, weight: 1),
        ItemDropType(id: ItemId.WOLF_PELT, weight: 1),
      ],
      bonusDrops: [DropRoll(chance: 0.05, entries: denAlphaArmorDropTable)],
    ),
  ),
  // Giant Bat · roster tier 2 · mine
  GIANT_BAT(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      itemDrops: [
        ItemDropType(id: ItemId.BAT_WING, lowCount: 1, highCount: 2, weight: 1),
        ItemDropType(id: ItemId.BAT_FANG, weight: 0.6),
      ],
    ),
  ),
  GIANT_BAT_UNCOMMON(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  GIANT_BAT_RARE(
    CombatEntityDefinition(giantBat, name: "Giant Bat", rarity: Rarity.RARE),
  ),
  GIANT_BAT_EPIC(
    CombatEntityDefinition(giantBat, name: "Giant Bat", rarity: Rarity.EPIC),
  ),
  GIANT_BAT_LEGENDARY(
    CombatEntityDefinition(
      giantBat,
      name: "Giant Bat",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Slime · roster tier 2 · mine
  SLIME(
    CombatEntityDefinition(
      slime,
      name: "Slime",
      itemDrops: [
        ItemDropType(
          id: ItemId.SLIME_OOZE,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
        // rare, and for nothing yet
        ItemDropType(id: ItemId.SLIME_CORE, weight: 0.05),
      ],
    ),
  ),
  SLIME_UNCOMMON(
    CombatEntityDefinition(slime, name: "Slime", rarity: Rarity.UNCOMMON),
  ),
  SLIME_RARE(CombatEntityDefinition(slime, name: "Slime", rarity: Rarity.RARE)),
  SLIME_EPIC(CombatEntityDefinition(slime, name: "Slime", rarity: Rarity.EPIC)),
  SLIME_LEGENDARY(
    CombatEntityDefinition(slime, name: "Slime", rarity: Rarity.LEGENDARY),
  ),
  // Carrion Crow · swamp. Quick and fragile; picks the bog's dead clean.
  CARRION_CROW(
    CombatEntityDefinition(
      carrionCrow,
      name: "Carrion Crow",
      itemDrops: [
        ItemDropType(id: ItemId.FEATHER, lowCount: 1, highCount: 3, weight: 1),
        ItemDropType(id: ItemId.CROW_QUILL, weight: 0.5),
      ],
    ),
  ),
  CARRION_CROW_UNCOMMON(
    CombatEntityDefinition(
      carrionCrow,
      name: "Carrion Crow",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  CARRION_CROW_RARE(
    CombatEntityDefinition(
      carrionCrow,
      name: "Carrion Crow",
      rarity: Rarity.RARE,
    ),
  ),
  // the Drowned Fen's Reedbank boss: an uncommon crow at level 55, the
  // flock's quills in bulk, and the bracers on a quarter of kills
  MURDER_KING(
    CombatEntityDefinition(
      carrionCrow,
      name: "Murder King",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      itemDrops: [
        ItemDropType(id: ItemId.FEATHER, lowCount: 20, highCount: 40),
        ItemDropType(id: ItemId.CROW_QUILL, lowCount: 5, highCount: 13),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.CROWQUILL_BRACERS)],
        ),
      ],
    ),
  ),
  CARRION_CROW_EPIC(
    CombatEntityDefinition(
      carrionCrow,
      name: "Carrion Crow",
      rarity: Rarity.EPIC,
    ),
  ),
  CARRION_CROW_LEGENDARY(
    CombatEntityDefinition(
      carrionCrow,
      name: "Carrion Crow",
      rarity: Rarity.LEGENDARY,
    ),
  ),

  //
  // Tier 8 - Level 34
  //
  // Goblin · roster tier 2 · forest
  // The goblin family shares one set of tables across all five rarity
  // variants: the gear nests take the variant's quality as an override, so
  // the ladder is five one-word edits rather than five hand-written copies
  // of the same six lines. The fish nest never takes one — only equipment
  // carries a quality.
  GOBLIN(
    CombatEntityDefinition(
      goblin,
      name: "Goblin",
      itemDrops: [
        NestedDrop(cookedFishDropTable, weight: 2),
        NestedDrop(mediumLeatherMinorArmorDropTable, weight: 1),
        ...goblinSupplyDrops,
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
  GOBLIN_UNCOMMON(
    CombatEntityDefinition(
      goblin,
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
  BEAR(
    CombatEntityDefinition(
      bear,
      name: "Bear",
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
    ),
  ),
  BEAR_UNCOMMON(
    CombatEntityDefinition(
      bear,
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
    ),
  ),
  BEAR_RARE(CombatEntityDefinition(bear, name: "Bear", rarity: Rarity.RARE)),
  BEAR_EPIC(CombatEntityDefinition(bear, name: "Bear", rarity: Rarity.EPIC)),
  BEAR_LEGENDARY(
    CombatEntityDefinition(bear, name: "Bear", rarity: Rarity.LEGENDARY),
  ),
  // the Wolf Den's Cave Entrance boss: a bear's drops, and the den set's minor slots
  // on a rare chance
  CAVE_BEAR(
    CombatEntityDefinition(
      bear,
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
      bonusDrops: [DropRoll(chance: 0.05, entries: caveBearArmorDropTable)],
    ),
  ),
  // Mudlurc · roster tier 2 · swamp
  MUDLURC(
    CombatEntityDefinition(
      mudlurc,
      name: "Mudlurc",
      itemDrops: [
        ItemDropType(id: ItemId.SALMON, weight: 1),
        ItemDropType(id: ItemId.STEEL_BAR, weight: 1),
        ItemDropType(id: ItemId.SCALE, lowCount: 1, highCount: 3, weight: 3),
        // the uncommon mudlurc's dagger, now that only the Drowned Fen
        // fields that variant
        ItemDropType(id: ItemId.FISHBONE_DAGGER, weight: 0.1),
        ItemDropType(id: ItemId.MEDIUM_LEATHER_BELT, weight: 1),
        ItemDropType(id: ItemId.MEDIUM_LEATHER_BOOTS, weight: 1),
        ItemDropType(id: ItemId.MEDIUM_LEATHER_BRACERS, weight: 1),
        ItemDropType(id: ItemId.MEDIUM_LEATHER_GLOVES, weight: 1),
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
  MUDLURC_RARE(
    CombatEntityDefinition(mudlurc, name: "Mudlurc", rarity: Rarity.RARE),
  ),
  MUDLURC_EPIC(
    CombatEntityDefinition(mudlurc, name: "Mudlurc", rarity: Rarity.EPIC),
  ),
  MUDLURC_LEGENDARY(
    CombatEntityDefinition(mudlurc, name: "Mudlurc", rarity: Rarity.LEGENDARY),
  ),
  // Fungal Monster · roster tier 2 · swamp
  FUNGAL_MONSTER(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      itemDrops: [
        ItemDropType(id: ItemId.MIRECAP, weight: 1),
        ItemDropType(id: ItemId.BOG_LOGS, weight: 1),
        ItemDropType(id: ItemId.COAL, weight: 1),
        ItemDropType(id: ItemId.MINOR_STRENGTH_POTION, weight: 1),
        ItemDropType(id: ItemId.MINOR_STAMINA_POTION, weight: 1),
      ],
    ),
  ),
  FUNGAL_MONSTER_UNCOMMON(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.UNCOMMON,
      itemDrops: [],
      // the Wolf Den's second boss: one of the basic fisher's set, a tenth of kills
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.BASIC_FISHERS_HAT)],
        ),
      ],
    ),
  ),
  FUNGAL_MONSTER_RARE(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.RARE,
    ),
  ),
  FUNGAL_MONSTER_EPIC(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.EPIC,
    ),
  ),
  FUNGAL_MONSTER_LEGENDARY(
    CombatEntityDefinition(
      fungalMonster,
      name: "Fungal Monster",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // the Wolf Den's Sunken Grotto boss: a fungal monster's drops, and the den set's
  // minor slots on a rare chance
  GROTTO_FUNGAL_MONSTER(
    CombatEntityDefinition(
      fungalMonster,
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
      bonusDrops: [
        DropRoll(chance: 0.1, entries: [ItemDropType(id: ItemId.REDCAP_RING)]),
        DropRoll(chance: 0.05, entries: wolfDenMinorArmorDropTable),
      ],
    ),
  ),
  // Ooze · swamp. The slime grown old in the bog: the same ooze in bulk,
  // and the core it was named for, often enough to brew with.
  OOZE(
    CombatEntityDefinition(
      ooze,
      name: "Ooze",
      itemDrops: [
        ItemDropType(
          id: ItemId.SLIME_OOZE,
          lowCount: 2,
          highCount: 4,
          weight: 1,
        ),
        ItemDropType(id: ItemId.SLIME_CORE, weight: 0.3),
      ],
    ),
  ),
  OOZE_UNCOMMON(
    CombatEntityDefinition(ooze, name: "Ooze", rarity: Rarity.UNCOMMON),
  ),
  // the Drowned Fen's Ooze Pits boss: an ooze at level 55, its cores in
  // bulk, and the belt on a quarter of kills
  PRIMORDIAL_OOZE(
    CombatEntityDefinition(
      ooze,
      name: "Primordial Ooze",
      isDungeonBoss: true,
      itemDrops: [
        ItemDropType(id: ItemId.SLIME_OOZE, lowCount: 20, highCount: 40),
        ItemDropType(id: ItemId.SLIME_CORE, lowCount: 3, highCount: 8),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.OOZE_SLICK_BELT)],
        ),
      ],
    ),
  ),
  OOZE_RARE(CombatEntityDefinition(ooze, name: "Ooze", rarity: Rarity.RARE)),
  OOZE_EPIC(CombatEntityDefinition(ooze, name: "Ooze", rarity: Rarity.EPIC)),
  OOZE_LEGENDARY(
    CombatEntityDefinition(ooze, name: "Ooze", rarity: Rarity.LEGENDARY),
  ),
  // Murkjaw · swamp. The bog's rare ambusher, and the only thing that
  // drops its fang - the super attack potion's reagent.
  MURKJAW(
    CombatEntityDefinition(
      murkjaw,
      name: "Murkjaw",
      itemDrops: [
        ItemDropType(id: ItemId.MURKJAW_HIDE, weight: 1),
        ItemDropType(id: ItemId.MURKJAW_FANG, weight: 0.5),
        ItemDropType(id: ItemId.SCALE, lowCount: 1, highCount: 3, weight: 1),
      ],
    ),
  ),
  MURKJAW_UNCOMMON(
    CombatEntityDefinition(murkjaw, name: "Murkjaw", rarity: Rarity.UNCOMMON),
  ),
  MURKJAW_RARE(
    CombatEntityDefinition(murkjaw, name: "Murkjaw", rarity: Rarity.RARE),
  ),
  // the Drowned Fen's last boss: an uncommon murkjaw at level 89, the hide and
  // fang in bulk, and the pauldrons at every quality the way the
  // Broodmother drops her necklace
  MURKJAW_MATRIARCH(
    CombatEntityDefinition(
      murkjaw,
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
        ItemDropType(
          id: ItemId.MURKJAW_PAULDRONS,
          rarity: Rarity.COMMON,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.MURKJAW_PAULDRONS,
          rarity: Rarity.UNCOMMON,
          weight: .8,
        ),
        ItemDropType(
          id: ItemId.MURKJAW_PAULDRONS,
          rarity: Rarity.RARE,
          weight: .6,
        ),
        ItemDropType(
          id: ItemId.MURKJAW_PAULDRONS,
          rarity: Rarity.EPIC,
          weight: .5,
        ),
      ],
    ),
  ),
  MURKJAW_EPIC(
    CombatEntityDefinition(murkjaw, name: "Murkjaw", rarity: Rarity.EPIC),
  ),
  MURKJAW_LEGENDARY(
    CombatEntityDefinition(murkjaw, name: "Murkjaw", rarity: Rarity.LEGENDARY),
  ),
  // Kobold · roster tier 2 · mine
  KOBOLD(
    CombatEntityDefinition(
      kobold,
      name: "Kobold",
      itemDrops: [
        // todo ore drop table
        // todo big rat tail ach
      ],
    ),
  ),
  KOBOLD_UNCOMMON(
    CombatEntityDefinition(kobold, name: "Kobold", rarity: Rarity.UNCOMMON),
  ),
  KOBOLD_RARE(
    CombatEntityDefinition(kobold, name: "Kobold", rarity: Rarity.RARE),
  ),
  KOBOLD_EPIC(
    CombatEntityDefinition(kobold, name: "Kobold", rarity: Rarity.EPIC),
  ),
  KOBOLD_LEGENDARY(
    CombatEntityDefinition(kobold, name: "Kobold", rarity: Rarity.LEGENDARY),
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
        NestedDrop(graveScrapDropTable, weight: 3),
        NestedDrop(steelMinorArmorDropTable, weight: 1),
        NestedDrop(steelToolsDropTable, weight: 0.6),
        NestedDrop(steelMajorArmorDropTable, weight: 0.4),
        ItemDropType(
          id: ItemId.STEEL_SHIELD,
          weight: 0.2,
          rarity: Rarity.UNCOMMON,
        ),
      ],
    ),
  ),
  SKELETON_UNCOMMON(
    CombatEntityDefinition(
      skeleton,
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
  SKELETON_RARE(
    CombatEntityDefinition(skeleton, name: "Skeleton", rarity: Rarity.RARE),
  ),
  SKELETON_EPIC(
    CombatEntityDefinition(skeleton, name: "Skeleton", rarity: Rarity.EPIC),
  ),
  SKELETON_LEGENDARY(
    CombatEntityDefinition(
      skeleton,
      name: "Skeleton",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Zombie · roster tier 3 · dark forest
  ZOMBIE(
    CombatEntityDefinition(
      zombie,
      name: "Zombie",
      itemDrops: [NestedDrop(graveScrapDropTable)],
      bonusDrops: [DropRoll(entries: tatteredClothDropTable, chance: 0.04)],
    ),
  ),
  ZOMBIE_UNCOMMON(
    CombatEntityDefinition(zombie, name: "Zombie", rarity: Rarity.UNCOMMON),
  ),
  // the Spider Den's Cocoon Hollow boss: an uncommon zombie, drops and all
  // (inherited from the common), kept apart from the regulars the
  // Broodmother's Lair fields
  THICKET_ZOMBIE(
    CombatEntityDefinition(
      zombie,
      name: "Cocooned Zombie",
      isDungeonBoss: true,
      rarity: Rarity.UNCOMMON,
      // on top of the zombie's own rolls
      extraBonusDrops: [
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.VENOMFANG_RING)],
        ),
      ],
    ),
  ),
  ZOMBIE_RARE(
    CombatEntityDefinition(zombie, name: "Zombie", rarity: Rarity.RARE),
  ),
  ZOMBIE_EPIC(
    CombatEntityDefinition(zombie, name: "Zombie", rarity: Rarity.EPIC),
  ),
  ZOMBIE_LEGENDARY(
    CombatEntityDefinition(zombie, name: "Zombie", rarity: Rarity.LEGENDARY),
  ),
  // Harpy · roster tier 3 · ironroot hills
  HARPY(
    CombatEntityDefinition(
      harpy,
      name: "Harpy",
      itemDrops: [
        ItemDropType(id: ItemId.FEATHER, lowCount: 1, highCount: 5, weight: 2),
        ItemDropType(id: ItemId.CLAW, weight: 1),
      ],
    ),
  ),
  HARPY_UNCOMMON(
    CombatEntityDefinition(harpy, name: "Harpy", rarity: Rarity.UNCOMMON),
  ),
  HARPY_RARE(CombatEntityDefinition(harpy, name: "Harpy", rarity: Rarity.RARE)),
  HARPY_EPIC(CombatEntityDefinition(harpy, name: "Harpy", rarity: Rarity.EPIC)),
  HARPY_LEGENDARY(
    CombatEntityDefinition(harpy, name: "Harpy", rarity: Rarity.LEGENDARY),
  ),
  // Naga · roster tier 3 · coast
  NAGA(
    CombatEntityDefinition(
      naga,
      name: "Naga",
      itemDrops: [],
      // the Wolf Den's last boss: one of the basic fisher's set, a tenth of kills
      bonusDrops: [
        DropRoll(
          chance: 0.1,
          entries: [ItemDropType(id: ItemId.BASIC_FISHERS_TUNIC)],
        ),
      ],
    ),
  ),
  NAGA_UNCOMMON(
    CombatEntityDefinition(naga, name: "Naga", rarity: Rarity.UNCOMMON),
  ),
  NAGA_RARE(CombatEntityDefinition(naga, name: "Naga", rarity: Rarity.RARE)),
  NAGA_EPIC(CombatEntityDefinition(naga, name: "Naga", rarity: Rarity.EPIC)),
  NAGA_LEGENDARY(
    CombatEntityDefinition(naga, name: "Naga", rarity: Rarity.LEGENDARY),
  ),

  //
  // Tier 10 - Level 89
  //
  // Giant Scorpion · roster tier 3 · copperdust flats
  GIANT_SCORPION(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      itemDrops: [
        ItemDropType(id: ItemId.VENOM, weight: 1),
        ItemDropType(id: ItemId.CLAW, lowCount: 1, highCount: 2, weight: 1),
      ],
    ),
  ),
  GIANT_SCORPION_UNCOMMON(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  GIANT_SCORPION_RARE(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.RARE,
    ),
  ),
  GIANT_SCORPION_EPIC(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.EPIC,
    ),
  ),
  GIANT_SCORPION_LEGENDARY(
    CombatEntityDefinition(
      giantScorpion,
      name: "Giant Scorpion",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Imp · roster tier 3 · ironroot hills
  IMP(
    CombatEntityDefinition(
      imp,
      name: "Imp",
      itemDrops: [
        ItemDropType(
          id: ItemId.ENCHANTING_ESSENCE,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
      ],
    ),
  ),
  IMP_UNCOMMON(
    CombatEntityDefinition(imp, name: "Imp", rarity: Rarity.UNCOMMON),
  ),
  IMP_RARE(CombatEntityDefinition(imp, name: "Imp", rarity: Rarity.RARE)),
  IMP_EPIC(CombatEntityDefinition(imp, name: "Imp", rarity: Rarity.EPIC)),
  IMP_LEGENDARY(
    CombatEntityDefinition(imp, name: "Imp", rarity: Rarity.LEGENDARY),
  ),
  // ── STORMGRASS PRAIRIE ──
  // Orc · stormgrass prairie. The common is the level 55 raider and the
  // uncommon the level 89 warband, one archetype between them. The tusk is
  // the greater strength potion's reagent, and a tenth of kills carry off a
  // piece of steel kit
  ORC(
    CombatEntityDefinition(
      orc,
      name: "Orc",
      itemDrops: [
        ItemDropType(id: ItemId.ANIMAL_PELT, weight: 1),
        ItemDropType(id: ItemId.ORC_TUSK, weight: 0.5),
      ],
      bonusDrops: [DropRoll(entries: orcSteelDropTable, chance: 0.1)],
    ),
  ),
  ORC_UNCOMMON(
    CombatEntityDefinition(orc, name: "Orc", rarity: Rarity.UNCOMMON),
  ),
  ORC_RARE(CombatEntityDefinition(orc, name: "Orc", rarity: Rarity.RARE)),
  ORC_EPIC(CombatEntityDefinition(orc, name: "Orc", rarity: Rarity.EPIC)),
  ORC_LEGENDARY(
    CombatEntityDefinition(orc, name: "Orc", rarity: Rarity.LEGENDARY),
  ),
  // Rattlesnake · stormgrass prairie, level 55. Its skin and its venom are
  // the greater defence and recovery potions' reagents
  RATTLESNAKE(
    CombatEntityDefinition(
      rattlesnake,
      name: "Rattlesnake",
      itemDrops: [
        ItemDropType(id: ItemId.SNAKESKIN, weight: 1),
        ItemDropType(id: ItemId.VENOM_GLAND, weight: 1),
      ],
    ),
  ),
  RATTLESNAKE_UNCOMMON(
    CombatEntityDefinition(
      rattlesnake,
      name: "Rattlesnake",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  RATTLESNAKE_RARE(
    CombatEntityDefinition(
      rattlesnake,
      name: "Rattlesnake",
      rarity: Rarity.RARE,
    ),
  ),
  RATTLESNAKE_EPIC(
    CombatEntityDefinition(
      rattlesnake,
      name: "Rattlesnake",
      rarity: Rarity.EPIC,
    ),
  ),
  RATTLESNAKE_LEGENDARY(
    CombatEntityDefinition(
      rattlesnake,
      name: "Rattlesnake",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Sabertooth · stormgrass prairie, level 89. The fang is the greater
  // attack potion's reagent; the pelt waits on leatherworking
  SABERTOOTH(
    CombatEntityDefinition(
      sabertooth,
      name: "Sabertooth",
      itemDrops: [
        ItemDropType(id: ItemId.SABERTOOTH_PELT, weight: 1),
        ItemDropType(id: ItemId.SABERTOOTH_FANG, weight: 0.5),
      ],
    ),
  ),
  SABERTOOTH_UNCOMMON(
    CombatEntityDefinition(
      sabertooth,
      name: "Sabertooth",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  // Tempest Reach's second boss: an uncommon sabertooth at level 144, its
  // fangs in bulk, and its fang and mantle at every quality the way the
  // Matriarch drops her pauldrons
  SABERTOOTH_ALPHA(
    CombatEntityDefinition(
      sabertooth,
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
        ItemDropType(id: ItemId.ALPHAS_FANG, rarity: Rarity.COMMON, weight: .5),
        ItemDropType(
          id: ItemId.ALPHAS_FANG,
          rarity: Rarity.UNCOMMON,
          weight: .4,
        ),
        ItemDropType(id: ItemId.ALPHAS_FANG, rarity: Rarity.RARE, weight: .3),
        ItemDropType(id: ItemId.ALPHAS_FANG, rarity: Rarity.EPIC, weight: .25),
        ItemDropType(
          id: ItemId.ALPHAS_MANTLE,
          rarity: Rarity.COMMON,
          weight: .5,
        ),
        ItemDropType(
          id: ItemId.ALPHAS_MANTLE,
          rarity: Rarity.UNCOMMON,
          weight: .4,
        ),
        ItemDropType(id: ItemId.ALPHAS_MANTLE, rarity: Rarity.RARE, weight: .3),
        ItemDropType(
          id: ItemId.ALPHAS_MANTLE,
          rarity: Rarity.EPIC,
          weight: .25,
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
    ),
  ),
  SABERTOOTH_RARE(
    CombatEntityDefinition(sabertooth, name: "Sabertooth", rarity: Rarity.RARE),
  ),
  SABERTOOTH_EPIC(
    CombatEntityDefinition(sabertooth, name: "Sabertooth", rarity: Rarity.EPIC),
  ),
  SABERTOOTH_LEGENDARY(
    CombatEntityDefinition(
      sabertooth,
      name: "Sabertooth",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Centaur · stormgrass prairie, level 89. The hoof is the greater stamina
  // potion's reagent; the sinew waits on fletching
  CENTAUR(
    CombatEntityDefinition(
      centaur,
      name: "Centaur",
      itemDrops: [
        ItemDropType(id: ItemId.BOWSTRING_SINEW, weight: 1),
        ItemDropType(id: ItemId.CENTAUR_HOOF, weight: 1),
      ],
    ),
  ),
  CENTAUR_UNCOMMON(
    CombatEntityDefinition(centaur, name: "Centaur", rarity: Rarity.UNCOMMON),
  ),
  CENTAUR_RARE(
    CombatEntityDefinition(centaur, name: "Centaur", rarity: Rarity.RARE),
  ),
  CENTAUR_EPIC(
    CombatEntityDefinition(centaur, name: "Centaur", rarity: Rarity.EPIC),
  ),
  CENTAUR_LEGENDARY(
    CombatEntityDefinition(centaur, name: "Centaur", rarity: Rarity.LEGENDARY),
  ),
  // Dust Devil · stormgrass prairie, level 89, and the first magic thing in
  // the game. The wind mote is the greater speed potion's reagent; the
  // essence feeds enchanting
  DUST_DEVIL(
    CombatEntityDefinition(
      dustDevil,
      name: "Dust Devil",
      itemDrops: [
        ItemDropType(
          id: ItemId.ENCHANTING_ESSENCE,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
        ItemDropType(id: ItemId.WIND_MOTE, weight: 0.5),
      ],
    ),
  ),
  DUST_DEVIL_UNCOMMON(
    CombatEntityDefinition(
      dustDevil,
      name: "Dust Devil",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  DUST_DEVIL_RARE(
    CombatEntityDefinition(dustDevil, name: "Dust Devil", rarity: Rarity.RARE),
  ),
  DUST_DEVIL_EPIC(
    CombatEntityDefinition(dustDevil, name: "Dust Devil", rarity: Rarity.EPIC),
  ),
  DUST_DEVIL_LEGENDARY(
    CombatEntityDefinition(
      dustDevil,
      name: "Dust Devil",
      rarity: Rarity.LEGENDARY,
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
        ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1),
        ItemDropType(
          id: ItemId.GRAVE_MOSS,
          lowCount: 1,
          highCount: 3,
          weight: 2,
        ),
        ItemDropType(id: ItemId.BLACK_GREATSWORD, weight: 0.2),
      ],
      // it wears the same rags a zombie does, better cut and far more often
      bonusDrops: [
        DropRoll(entries: tatteredClothUncommonDropTable, chance: 0.15),
      ],
    ),
  ),
  WRAITH_UNCOMMON(
    CombatEntityDefinition(wraith, name: "Wraith", rarity: Rarity.UNCOMMON),
  ),
  WRAITH_RARE(
    CombatEntityDefinition(wraith, name: "Wraith", rarity: Rarity.RARE),
  ),
  WRAITH_EPIC(
    CombatEntityDefinition(wraith, name: "Wraith", rarity: Rarity.EPIC),
  ),
  WRAITH_LEGENDARY(
    CombatEntityDefinition(wraith, name: "Wraith", rarity: Rarity.LEGENDARY),
  ),
  // Banshee · roster tier 4 · dark forest
  BANSHEE(
    CombatEntityDefinition(
      banshee,
      name: "Banshee",
      itemDrops: [ItemDropType(id: ItemId.ENCHANTING_RUNE, weight: 1)],
    ),
  ),
  BANSHEE_UNCOMMON(
    CombatEntityDefinition(banshee, name: "Banshee", rarity: Rarity.UNCOMMON),
  ),
  BANSHEE_RARE(
    CombatEntityDefinition(banshee, name: "Banshee", rarity: Rarity.RARE),
  ),
  BANSHEE_EPIC(
    CombatEntityDefinition(banshee, name: "Banshee", rarity: Rarity.EPIC),
  ),
  BANSHEE_LEGENDARY(
    CombatEntityDefinition(banshee, name: "Banshee", rarity: Rarity.LEGENDARY),
  ),
  // Troll · roster tier 4 · ironroot hills
  TROLL(
    CombatEntityDefinition(
      troll,
      name: "Troll",
      itemDrops: [
        ItemDropType(
          id: ItemId.ANIMAL_PELT,
          lowCount: 2,
          highCount: 5,
          weight: 1,
        ),
      ],
    ),
  ),
  TROLL_UNCOMMON(
    CombatEntityDefinition(troll, name: "Troll", rarity: Rarity.UNCOMMON),
  ),
  TROLL_RARE(CombatEntityDefinition(troll, name: "Troll", rarity: Rarity.RARE)),
  TROLL_EPIC(CombatEntityDefinition(troll, name: "Troll", rarity: Rarity.EPIC)),
  TROLL_LEGENDARY(
    CombatEntityDefinition(troll, name: "Troll", rarity: Rarity.LEGENDARY),
  ),
  // Minotaur · roster tier 4 · mine
  MINOTAUR(CombatEntityDefinition(minotaur, name: "Minotaur", itemDrops: [])),
  MINOTAUR_UNCOMMON(
    CombatEntityDefinition(minotaur, name: "Minotaur", rarity: Rarity.UNCOMMON),
  ),
  MINOTAUR_RARE(
    CombatEntityDefinition(minotaur, name: "Minotaur", rarity: Rarity.RARE),
  ),
  MINOTAUR_EPIC(
    CombatEntityDefinition(minotaur, name: "Minotaur", rarity: Rarity.EPIC),
  ),
  MINOTAUR_LEGENDARY(
    CombatEntityDefinition(
      minotaur,
      name: "Minotaur",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Basilisk · roster tier 4 · redwall bluffs
  BASILISK(CombatEntityDefinition(basilisk, name: "Basilisk", itemDrops: [])),
  BASILISK_UNCOMMON(
    CombatEntityDefinition(basilisk, name: "Basilisk", rarity: Rarity.UNCOMMON),
  ),
  BASILISK_RARE(
    CombatEntityDefinition(basilisk, name: "Basilisk", rarity: Rarity.RARE),
  ),
  BASILISK_EPIC(
    CombatEntityDefinition(basilisk, name: "Basilisk", rarity: Rarity.EPIC),
  ),
  BASILISK_LEGENDARY(
    CombatEntityDefinition(
      basilisk,
      name: "Basilisk",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Dark Wizard · roster tier 4 · crypt
  DARK_WIZARD(
    CombatEntityDefinition(darkWizard, name: "Dark Wizard", itemDrops: []),
  ),
  DARK_WIZARD_UNCOMMON(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  DARK_WIZARD_RARE(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.RARE,
    ),
  ),
  DARK_WIZARD_EPIC(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.EPIC,
    ),
  ),
  DARK_WIZARD_LEGENDARY(
    CombatEntityDefinition(
      darkWizard,
      name: "Dark Wizard",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Gargoyle · roster tier 4 · redwall bluffs
  GARGOYLE(CombatEntityDefinition(gargoyle, name: "Gargoyle", itemDrops: [])),
  GARGOYLE_UNCOMMON(
    CombatEntityDefinition(gargoyle, name: "Gargoyle", rarity: Rarity.UNCOMMON),
  ),
  GARGOYLE_RARE(
    CombatEntityDefinition(gargoyle, name: "Gargoyle", rarity: Rarity.RARE),
  ),
  GARGOYLE_EPIC(
    CombatEntityDefinition(gargoyle, name: "Gargoyle", rarity: Rarity.EPIC),
  ),
  GARGOYLE_LEGENDARY(
    CombatEntityDefinition(
      gargoyle,
      name: "Gargoyle",
      rarity: Rarity.LEGENDARY,
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
        // the mid-tier potions
        ItemDropType(id: ItemId.ATTACK_POTION, weight: 1),
        ItemDropType(id: ItemId.STRENGTH_POTION, weight: 1),
        ItemDropType(id: ItemId.DEFENCE_POTION, weight: 1),
        ItemDropType(id: ItemId.STAMINA_POTION, weight: 1),
        ItemDropType(id: ItemId.SPEED_POTION, weight: 1),
        NestedDrop(herbDropTable, weight: 3),
        ItemDropType(id: ItemId.OAK_LOGS, lowCount: 2, highCount: 5, weight: 1),
        ItemDropType(
          id: ItemId.WILLOW_LOGS,
          lowCount: 2,
          highCount: 5,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.MAPLE_LOGS,
          lowCount: 2,
          highCount: 4,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.STEEL_BAR,
          lowCount: 1,
          highCount: 3,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.MITHRIL_BAR,
          lowCount: 1,
          highCount: 2,
          weight: 1,
        ),
        NestedDrop(mithrilArmorDropTable, weight: 1),
        NestedDrop(mithrilWeaponsDropTable, weight: 1),
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
    ),
  ),
  MOSS_GOLEM_RARE(
    CombatEntityDefinition(mossGolem, name: "Moss Golem", rarity: Rarity.RARE),
  ),
  MOSS_GOLEM_EPIC(
    CombatEntityDefinition(mossGolem, name: "Moss Golem", rarity: Rarity.EPIC),
  ),
  MOSS_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      mossGolem,
      name: "Moss Golem",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Hill Giant · roster tier 5 · ironroot hills
  HILL_GIANT(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      itemDrops: [
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
    ),
  ),
  HILL_GIANT_RARE(
    CombatEntityDefinition(hillGiant, name: "Hill Giant", rarity: Rarity.RARE),
  ),
  HILL_GIANT_EPIC(
    CombatEntityDefinition(hillGiant, name: "Hill Giant", rarity: Rarity.EPIC),
  ),
  HILL_GIANT_LEGENDARY(
    CombatEntityDefinition(
      hillGiant,
      name: "Hill Giant",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Earth Elemental · roster tier 5 · mine
  EARTH_ELEMENTAL(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      itemDrops: [],
    ),
  ),
  EARTH_ELEMENTAL_UNCOMMON(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  EARTH_ELEMENTAL_RARE(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.RARE,
    ),
  ),
  EARTH_ELEMENTAL_EPIC(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.EPIC,
    ),
  ),
  EARTH_ELEMENTAL_LEGENDARY(
    CombatEntityDefinition(
      earthElemental,
      name: "Earth Elemental",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Ogre · roster tier 5 · mountains
  OGRE(CombatEntityDefinition(ogre, name: "Ogre", itemDrops: [])),
  OGRE_UNCOMMON(
    CombatEntityDefinition(ogre, name: "Ogre", rarity: Rarity.UNCOMMON),
  ),
  OGRE_RARE(CombatEntityDefinition(ogre, name: "Ogre", rarity: Rarity.RARE)),
  OGRE_EPIC(CombatEntityDefinition(ogre, name: "Ogre", rarity: Rarity.EPIC)),
  OGRE_LEGENDARY(
    CombatEntityDefinition(ogre, name: "Ogre", rarity: Rarity.LEGENDARY),
  ),
  // Stone Golem · roster tier 5 · mountains
  STONE_GOLEM(
    CombatEntityDefinition(stoneGolem, name: "Stone Golem", itemDrops: []),
  ),
  STONE_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  STONE_GOLEM_RARE(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.RARE,
    ),
  ),
  STONE_GOLEM_EPIC(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.EPIC,
    ),
  ),
  STONE_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      stoneGolem,
      name: "Stone Golem",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Griffin · roster tier 5 · redwall bluffs
  GRIFFIN(CombatEntityDefinition(griffin, name: "Griffin", itemDrops: [])),
  GRIFFIN_UNCOMMON(
    CombatEntityDefinition(griffin, name: "Griffin", rarity: Rarity.UNCOMMON),
  ),
  GRIFFIN_RARE(
    CombatEntityDefinition(griffin, name: "Griffin", rarity: Rarity.RARE),
  ),
  GRIFFIN_EPIC(
    CombatEntityDefinition(griffin, name: "Griffin", rarity: Rarity.EPIC),
  ),
  GRIFFIN_LEGENDARY(
    CombatEntityDefinition(griffin, name: "Griffin", rarity: Rarity.LEGENDARY),
  ),
  // Fire Elemental · roster tier 5 · volcanic
  FIRE_ELEMENTAL(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      itemDrops: [],
    ),
  ),
  FIRE_ELEMENTAL_UNCOMMON(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  FIRE_ELEMENTAL_RARE(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.RARE,
    ),
  ),
  FIRE_ELEMENTAL_EPIC(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.EPIC,
    ),
  ),
  FIRE_ELEMENTAL_LEGENDARY(
    CombatEntityDefinition(
      fireElemental,
      name: "Fire Elemental",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Water Elemental · roster tier 5 · coast
  WATER_ELEMENTAL(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      itemDrops: [],
    ),
  ),
  WATER_ELEMENTAL_UNCOMMON(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  WATER_ELEMENTAL_RARE(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.RARE,
    ),
  ),
  WATER_ELEMENTAL_EPIC(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.EPIC,
    ),
  ),
  WATER_ELEMENTAL_LEGENDARY(
    CombatEntityDefinition(
      waterElemental,
      name: "Water Elemental",
      rarity: Rarity.LEGENDARY,
    ),
  ),

  //
  // Tier 13 - Level 377
  //
  // Yeti · roster tier 6 · frozen peaks
  YETI(CombatEntityDefinition(yeti, name: "Yeti", itemDrops: [])),
  YETI_UNCOMMON(
    CombatEntityDefinition(yeti, name: "Yeti", rarity: Rarity.UNCOMMON),
  ),
  YETI_RARE(CombatEntityDefinition(yeti, name: "Yeti", rarity: Rarity.RARE)),
  YETI_EPIC(CombatEntityDefinition(yeti, name: "Yeti", rarity: Rarity.EPIC)),
  YETI_LEGENDARY(
    CombatEntityDefinition(yeti, name: "Yeti", rarity: Rarity.LEGENDARY),
  ),
  // Iron Golem · roster tier 6 · volcanic
  IRON_GOLEM(
    CombatEntityDefinition(ironGolem, name: "Iron Golem", itemDrops: []),
  ),
  IRON_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  IRON_GOLEM_RARE(
    CombatEntityDefinition(ironGolem, name: "Iron Golem", rarity: Rarity.RARE),
  ),
  IRON_GOLEM_EPIC(
    CombatEntityDefinition(ironGolem, name: "Iron Golem", rarity: Rarity.EPIC),
  ),
  IRON_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      ironGolem,
      name: "Iron Golem",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Steel Golem · roster tier 6 · mine
  STEEL_GOLEM(
    CombatEntityDefinition(steelGolem, name: "Steel Golem", itemDrops: []),
  ),
  STEEL_GOLEM_UNCOMMON(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  STEEL_GOLEM_RARE(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.RARE,
    ),
  ),
  STEEL_GOLEM_EPIC(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.EPIC,
    ),
  ),
  STEEL_GOLEM_LEGENDARY(
    CombatEntityDefinition(
      steelGolem,
      name: "Steel Golem",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Lich · roster tier 6 · crypt
  LICH(CombatEntityDefinition(lich, name: "Lich", itemDrops: [])),
  LICH_UNCOMMON(
    CombatEntityDefinition(lich, name: "Lich", rarity: Rarity.UNCOMMON),
  ),
  LICH_RARE(CombatEntityDefinition(lich, name: "Lich", rarity: Rarity.RARE)),
  LICH_EPIC(CombatEntityDefinition(lich, name: "Lich", rarity: Rarity.EPIC)),
  LICH_LEGENDARY(
    CombatEntityDefinition(lich, name: "Lich", rarity: Rarity.LEGENDARY),
  ),
  // Cloud Giant · roster tier 6 · mountains
  CLOUD_GIANT(
    CombatEntityDefinition(cloudGiant, name: "Cloud Giant", itemDrops: []),
  ),
  CLOUD_GIANT_UNCOMMON(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  CLOUD_GIANT_RARE(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.RARE,
    ),
  ),
  CLOUD_GIANT_EPIC(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.EPIC,
    ),
  ),
  CLOUD_GIANT_LEGENDARY(
    CombatEntityDefinition(
      cloudGiant,
      name: "Cloud Giant",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Roc · roster tier 6 · frozen peaks
  ROC(CombatEntityDefinition(roc, name: "Roc", itemDrops: [])),
  ROC_UNCOMMON(
    CombatEntityDefinition(roc, name: "Roc", rarity: Rarity.UNCOMMON),
  ),
  ROC_RARE(CombatEntityDefinition(roc, name: "Roc", rarity: Rarity.RARE)),
  ROC_EPIC(CombatEntityDefinition(roc, name: "Roc", rarity: Rarity.EPIC)),
  ROC_LEGENDARY(
    CombatEntityDefinition(roc, name: "Roc", rarity: Rarity.LEGENDARY),
  ),
  // Wyvern · roster tier 6 · volcanic
  WYVERN(CombatEntityDefinition(wyvern, name: "Wyvern", itemDrops: [])),
  WYVERN_UNCOMMON(
    CombatEntityDefinition(wyvern, name: "Wyvern", rarity: Rarity.UNCOMMON),
  ),
  WYVERN_RARE(
    CombatEntityDefinition(wyvern, name: "Wyvern", rarity: Rarity.RARE),
  ),
  WYVERN_EPIC(
    CombatEntityDefinition(wyvern, name: "Wyvern", rarity: Rarity.EPIC),
  ),
  WYVERN_LEGENDARY(
    CombatEntityDefinition(wyvern, name: "Wyvern", rarity: Rarity.LEGENDARY),
  ),
  // Drake · roster tier 6 · volcanic
  DRAKE(CombatEntityDefinition(drake, name: "Drake", itemDrops: [])),
  DRAKE_UNCOMMON(
    CombatEntityDefinition(drake, name: "Drake", rarity: Rarity.UNCOMMON),
  ),
  DRAKE_RARE(CombatEntityDefinition(drake, name: "Drake", rarity: Rarity.RARE)),
  DRAKE_EPIC(CombatEntityDefinition(drake, name: "Drake", rarity: Rarity.EPIC)),
  DRAKE_LEGENDARY(
    CombatEntityDefinition(drake, name: "Drake", rarity: Rarity.LEGENDARY),
  ),

  //
  // Tier 14 - Level 610
  //
  // Kraken · roster tier 7 · deep water dungeon
  KRAKEN(CombatEntityDefinition(kraken, name: "Kraken", itemDrops: [])),
  KRAKEN_UNCOMMON(
    CombatEntityDefinition(kraken, name: "Kraken", rarity: Rarity.UNCOMMON),
  ),
  KRAKEN_RARE(
    CombatEntityDefinition(kraken, name: "Kraken", rarity: Rarity.RARE),
  ),
  KRAKEN_EPIC(
    CombatEntityDefinition(kraken, name: "Kraken", rarity: Rarity.EPIC),
  ),
  KRAKEN_LEGENDARY(
    CombatEntityDefinition(kraken, name: "Kraken", rarity: Rarity.LEGENDARY),
  ),
  // Dragon · roster tier 7 · dragon's lair
  DRAGON(CombatEntityDefinition(dragon, name: "Dragon", itemDrops: [])),
  DRAGON_UNCOMMON(
    CombatEntityDefinition(dragon, name: "Dragon", rarity: Rarity.UNCOMMON),
  ),
  DRAGON_RARE(
    CombatEntityDefinition(dragon, name: "Dragon", rarity: Rarity.RARE),
  ),
  DRAGON_EPIC(
    CombatEntityDefinition(dragon, name: "Dragon", rarity: Rarity.EPIC),
  ),
  DRAGON_LEGENDARY(
    CombatEntityDefinition(dragon, name: "Dragon", rarity: Rarity.LEGENDARY),
  ),
  // Lesser Demon · roster tier 7 · underworld
  LESSER_DEMON(
    CombatEntityDefinition(lesserDemon, name: "Lesser Demon", itemDrops: []),
  ),
  LESSER_DEMON_UNCOMMON(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  LESSER_DEMON_RARE(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.RARE,
    ),
  ),
  LESSER_DEMON_EPIC(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.EPIC,
    ),
  ),
  LESSER_DEMON_LEGENDARY(
    CombatEntityDefinition(
      lesserDemon,
      name: "Lesser Demon",
      rarity: Rarity.LEGENDARY,
    ),
  ),
  // Greater Demon · roster tier 7 · underworld
  GREATER_DEMON(
    CombatEntityDefinition(greaterDemon, name: "Greater Demon", itemDrops: []),
  ),
  GREATER_DEMON_UNCOMMON(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.UNCOMMON,
    ),
  ),
  GREATER_DEMON_RARE(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.RARE,
    ),
  ),
  GREATER_DEMON_EPIC(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.EPIC,
    ),
  ),
  GREATER_DEMON_LEGENDARY(
    CombatEntityDefinition(
      greaterDemon,
      name: "Greater Demon",
      rarity: Rarity.LEGENDARY,
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
        ItemDropType(id: ItemId.COINS, lowCount: 1, highCount: 5),
        ItemDropType(id: ItemId.RAT_TAIL),
      ],
    ),
  ),
  BIG_RED(
    CombatEntityDefinition(
      bigRed,
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
        ItemDropType(
          id: ItemId.CHICKEN_CHARM,
          rarity: Rarity.COMMON,
          weight: .5,
        ),
        ItemDropType(
          id: ItemId.CHICKEN_CHARM,
          rarity: Rarity.UNCOMMON,
          weight: .2,
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
    ),
  ),
  SPIDER_BROODMOTHER(
    CombatEntityDefinition(
      spiderBroodmother,
      name: "Spider Broodmother",
      isDungeonBoss: true,
      rarity: Rarity.EPIC,
      itemDrops: [
        NestedDrop(spiderDropTable, countMultiplier: 6),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.COMMON,
          weight: 1,
        ),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.UNCOMMON,
          weight: .8,
        ),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.RARE,
          weight: .6,
        ),
        ItemDropType(
          id: ItemId.SPIDER_SILK_NECKLACE,
          rarity: Rarity.EPIC,
          weight: .5,
        ),
      ],
      bonusDrops: [
        DropRoll(
          chance: 0.25,
          entries: [ItemDropType(id: ItemId.BROODMOTHERS_MANTLE)],
        ),
      ],
    ),
  ),
  GOBLIN_QUEEN(
    CombatEntityDefinition(
      goblinQueen,
      name: "Goblin Queen",
      isDungeonBoss: true,
      rarity: Rarity.LEGENDARY,
      itemDrops: [
        ItemDropType(id: ItemId.GOBLIN_CROWN, weight: 1),
        ItemDropType(id: ItemId.GOBLIN_SCEPTER, weight: 1),
      ],
      bonusDrops: [
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
  // Tempest Reach's first boss, at level 144: the orcs' tusks in bulk, its
  // cleaver and warhelm at every quality, and a bundle of mithril bars on a
  // tenth of kills
  ORC_WARLORD(
    CombatEntityDefinition(
      orcWarlord,
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
        ItemDropType(
          id: ItemId.WARLORDS_CLEAVER,
          rarity: Rarity.COMMON,
          weight: .5,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_CLEAVER,
          rarity: Rarity.UNCOMMON,
          weight: .4,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_CLEAVER,
          rarity: Rarity.RARE,
          weight: .3,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_CLEAVER,
          rarity: Rarity.EPIC,
          weight: .25,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_WARHELM,
          rarity: Rarity.COMMON,
          weight: .5,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_WARHELM,
          rarity: Rarity.UNCOMMON,
          weight: .4,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_WARHELM,
          rarity: Rarity.RARE,
          weight: .3,
        ),
        ItemDropType(
          id: ItemId.WARLORDS_WARHELM,
          rarity: Rarity.EPIC,
          weight: .25,
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
    ),
  ),
  // Tempest Reach's last boss, at level 144: wind motes in bulk, its
  // scepter and gauntlets at every quality, and on a tenth of kills the
  // storm shard nothing else drops
  TEMPEST(
    CombatEntityDefinition(
      tempest,
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
        ItemDropType(
          id: ItemId.STORMCALLERS_SCEPTER,
          rarity: Rarity.COMMON,
          weight: .5,
        ),
        ItemDropType(
          id: ItemId.STORMCALLERS_SCEPTER,
          rarity: Rarity.UNCOMMON,
          weight: .4,
        ),
        ItemDropType(
          id: ItemId.STORMCALLERS_SCEPTER,
          rarity: Rarity.RARE,
          weight: .3,
        ),
        ItemDropType(
          id: ItemId.STORMCALLERS_SCEPTER,
          rarity: Rarity.EPIC,
          weight: .25,
        ),
        ItemDropType(
          id: ItemId.GALEWRAP_GAUNTLETS,
          rarity: Rarity.COMMON,
          weight: .5,
        ),
        ItemDropType(
          id: ItemId.GALEWRAP_GAUNTLETS,
          rarity: Rarity.UNCOMMON,
          weight: .4,
        ),
        ItemDropType(
          id: ItemId.GALEWRAP_GAUNTLETS,
          rarity: Rarity.RARE,
          weight: .3,
        ),
        ItemDropType(
          id: ItemId.GALEWRAP_GAUNTLETS,
          rarity: Rarity.EPIC,
          weight: .25,
        ),
      ],
      bonusDrops: [
        DropRoll(chance: 0.1, entries: [ItemDropType(id: ItemId.STORM_SHARD)]),
      ],
    ),
  ),

  // ── SHOPS ───────────────────────────────────────────────────────
  // ShopEntityDefinition, by zone then stock tier
  FARMER(
    ShopEntityDefinition(
      name: "Farmer John",
      iconAsset: "assets/images/entities/farmer_john.png",
      stockSlots: 13,
      restockInterval: Duration(minutes: 30),
      shopStockPool: [
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
        // the full iron set, one entry per slot, the basic fisher's pants, the
        // medium leather body pieces (the goblins drop its extremities), and
        // every skill's basic gloves, boots and cloak but the woodcutter's,
        // which come out of bird's nests: far more than stockSlots, so a
        // restock shelves a rotating ten of them
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
        ShopStockEntry(itemId: ItemId.BASIC_FISHERS_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_SPAULDERS, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_CHEST, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_BELT, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_BRACERS, count: 1),
        ShopStockEntry(itemId: ItemId.MEDIUM_LEATHER_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FISHERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_HERBALISTS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FIREMAKERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_COOKS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_BLACKSMITHS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ENCHANTERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_JEWELERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ALCHEMISTS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_EXPLORERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FISHERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_MINERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_HERBALISTS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FIREMAKERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_COOKS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_BLACKSMITHS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ENCHANTERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_JEWELERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_ALCHEMISTS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_EXPLORERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.BASIC_FISHERS_CLOAK, count: 1),
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
  // The village's fishing shop: every raw fish up to catfish, the novice
  // fisher's set and the rods up to mithril. The whole pool fits on the shelf
  // so a restock never hides an item.
  FISHING_SHOP(
    ShopEntityDefinition(
      name: "Fishing Shop",
      iconAsset: "assets/images/entities/trading_post.png",
      stockSlots: 20,
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
        ShopStockEntry(itemId: ItemId.NOVICE_FISHERS_HAT, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_FISHERS_TUNIC, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_FISHERS_PANTS, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_FISHERS_GLOVES, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_FISHERS_BOOTS, count: 1),
        ShopStockEntry(itemId: ItemId.NOVICE_FISHERS_CLOAK, count: 1),
        ShopStockEntry(itemId: ItemId.SIMPLE_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.COPPER_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.IRON_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.STEEL_FISHING_ROD, count: 1),
        ShopStockEntry(itemId: ItemId.MITHRIL_FISHING_ROD, count: 1),
      ],
    ),
  ),
  // The village's lumber mill: every log the game has, up to maple. Yew logs
  // don't exist yet; add them to this pool when the tree lands.
  LUMBER_MILL(
    ShopEntityDefinition(
      name: "Lumber Mill",
      iconAsset: "assets/images/entities/trading_post.png",
      // the whole pool fits on the shelf, so a restock never hides an item
      stockSlots: 5,
      shopStockPool: [
        ShopStockEntry(itemId: ItemId.LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.OAK_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.WILLOW_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.BOG_LOGS, count: 500),
        ShopStockEntry(itemId: ItemId.MAPLE_LOGS, count: 500),
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
