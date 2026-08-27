import 'package:rpg/utilities/image_resolver.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:flutter/widgets.dart';

// ignore_for_file: constant_identifier_names

/// Every item in the game, and its definition.
///
/// The definition rides on the enum constant, so an item is one entry in one
/// place: there is no separate map to keep in sync, and the compiler will not
/// let an id exist without a definition.
///
/// **Where does a new item go?** Sections appear in the fixed order below;
/// within a section, entries ascend by that section's natural progression
/// (tier, then level, then value). Put a new item in its section, in
/// progression order.
///
/// Definitions are `const`, so nothing here can be mutated. Call [build] for
/// a mutable runtime [Item], or `definition.copyWith(...)` for a variant
/// template.
///
/// The enum *value names* are the save format ([Item.toJson] writes
/// `id.name`), so they must never be renamed — typos included. Display names,
/// values and icons are all free to change.
enum ItemId {
  // ── SENTINEL ────────────────────────────────────────────────────
  NULL(ItemDefinition(name: "Nothing", value: 0)),

  // ── CURRENCY ────────────────────────────────────────────────────
  COINS(
    ItemDefinition(
      name: "Coins",
      value: 1,
      iconAsset: "assets/icons/items/coins.png",
    ),
  ),

  // ── JUNK ────────────────────────────────────────────────────────
  // byproducts nobody wants and hides nobody has tanned yet
  BURNT_FOOD(
    ItemDefinition(
      name: "Burnt Food",
      value: 1,
      iconAsset: "assets/icons/items/burnt_food.png",
    ),
  ),
  COW_HIDE(
    ItemDefinition(
      name: "Cow Hide",
      value: 1,
      iconAsset: "assets/icons/items/cow_hide.png",
    ),
  ),

  // ── LOGS ────────────────────────────────────────────────────────
  // tier ascending
  LOGS(
    ItemDefinition(
      name: "Logs",
      value: 2,
      iconAsset: "assets/icons/items/regular_logs.png",
    ),
  ),
  OAK_LOGS(
    ItemDefinition(
      name: "Oak Logs",
      value: 5,
      iconAsset: "assets/icons/items/oak_logs.png",
    ),
  ),

  // ── ORES ────────────────────────────────────────────────────────
  // value ascending
  COPPER_ORE(
    ItemDefinition(
      name: "Copper Ore",
      value: 3,
      iconAsset: "assets/icons/items/copper_ore.png",
    ),
  ),
  IRON_ORE(
    ItemDefinition(
      name: "Iron Ore",
      value: 6,
      iconAsset: "assets/icons/items/iron_ore.png",
    ),
  ),
  COAL(
    ItemDefinition(
      name: "Coal",
      value: 6,
      iconAsset: "assets/icons/items/coal.png",
    ),
  ),
  GOLD_ORE(
    ItemDefinition(
      name: "Gold Ore",
      value: 15,
      iconAsset: "assets/icons/items/gold_ore.png",
    ),
  ),
  MITHRIL_ORE(
    ItemDefinition(
      name: "Mithril Ore",
      value: 24,
      iconAsset: "assets/icons/items/mithril_ore.png",
    ),
  ),
  ADAMANTITE_ORE(
    ItemDefinition(
      name: "Adamantite Ore",
      value: 48,
      iconAsset: "assets/icons/items/adamantite_ore.png",
    ),
  ),
  RUNEITE_ORE(
    ItemDefinition(
      name: "Runite Ore",
      value: 96,
      iconAsset: "assets/icons/items/runeite_ore.png",
    ),
  ),

  // ── BARS ────────────────────────────────────────────────────────
  // same material order as the ores
  COPPER_BAR(
    ItemDefinition(
      name: "Copper Bar",
      value: 2,
      iconAsset: "assets/icons/items/copper_bar.png",
    ),
  ),
  IRON_BAR(
    ItemDefinition(
      name: "Iron Bar",
      value: 8,
      iconAsset: "assets/icons/items/iron_bar.png",
    ),
  ),
  STEEL_BAR(
    ItemDefinition(
      name: "Steel Bar",
      value: 16,
      iconAsset: "assets/icons/items/steel_bar.png",
    ),
  ),
  GOLD_BAR(
    ItemDefinition(
      name: "Gold Bar",
      value: 30,
      iconAsset: "assets/icons/items/gold_bar.png",
    ),
  ),
  MITHRIL_BAR(
    ItemDefinition(
      name: "Mithril Bar",
      value: 32,
      iconAsset: "assets/icons/items/mithril_bar.png",
    ),
  ),
  ADAMANTITE_BAR(
    ItemDefinition(
      name: "Adamantite Bar",
      value: 64,
      iconAsset: "assets/icons/items/adamantite_bar.png",
    ),
  ),
  RUNITE_BAR(
    ItemDefinition(
      name: "Runite Bar",
      value: 128,
      iconAsset: "assets/icons/items/runite_bar.png",
    ),
  ),

  // ── GEMS ────────────────────────────────────────────────────────
  // value ascending
  TOPAZ(
    ItemDefinition(
      name: "Topaz",
      value: 20,
      iconAsset: "assets/icons/items/topaz.png",
    ),
  ),
  SAPPHIRE(
    ItemDefinition(
      name: "Sapphire",
      value: 40,
      iconAsset: "assets/icons/items/sapphire.png",
    ),
  ),
  EMERALD(
    ItemDefinition(
      name: "Emerald",
      value: 60,
      iconAsset: "assets/icons/items/emerald.png",
    ),
  ),
  RUBY(
    ItemDefinition(
      name: "Ruby",
      value: 90,
      iconAsset: "assets/icons/items/ruby.png",
    ),
  ),
  DIAMOND(
    ItemDefinition(
      name: "Diamond",
      value: 130,
      iconAsset: "assets/icons/items/diamond.png",
    ),
  ),
  DRAGONSTONE(
    ItemDefinition(
      name: "Dragonstone",
      value: 200,
      iconAsset: "assets/icons/items/dragonstone.png",
    ),
  ),
  ONYX(
    ItemDefinition(
      name: "Onyx",
      value: 350,
      iconAsset: "assets/icons/items/onyx.png",
    ),
  ),

  // ── HERBS ───────────────────────────────────────────────────────
  // herbalism level ascending
  GUAM_LEAF(
    ItemDefinition(
      name: "Guam Leaf",
      value: 1,
      iconAsset: "assets/icons/items/guam_leaf.png",
      xpValue: 5,
    ),
  ),
  MARRENTILL(
    ItemDefinition(
      name: "Marrentill",
      value: 2,
      iconAsset: "assets/icons/items/marrentill.png",
      xpValue: 8,
    ),
  ),
  TARROMIN(
    ItemDefinition(
      name: "Tarromin",
      value: 3,
      iconAsset: "assets/icons/items/tarromin.png",
      xpValue: 12,
    ),
  ),
  HARRALANDER(
    ItemDefinition(
      name: "Harralander",
      value: 5,
      iconAsset: "assets/icons/items/harralander.png",
      xpValue: 18,
    ),
  ),
  RANARR_WEED(
    ItemDefinition(
      name: "Ranarr Weed",
      value: 12,
      iconAsset: "assets/icons/items/ranarr_weed.png",
      xpValue: 24,
    ),
  ),
  TOADFLAX(
    ItemDefinition(
      name: "Toadflax",
      value: 10,
      iconAsset: "assets/icons/items/toadflax.png",
      xpValue: 30,
    ),
  ),
  IRIT_LEAF(
    ItemDefinition(
      name: "Irit Leaf",
      value: 12,
      iconAsset: "assets/icons/items/irit_leaf.png",
      xpValue: 40,
    ),
  ),
  AVANTOE(
    ItemDefinition(
      name: "Avantoe",
      value: 15,
      iconAsset: "assets/icons/items/avantoe.png",
      xpValue: 48,
    ),
  ),
  KWUARM(
    ItemDefinition(
      name: "Kwuarm",
      value: 18,
      iconAsset: "assets/icons/items/kwuarm.png",
      xpValue: 55,
    ),
  ),
  SNAPDRAGON(
    ItemDefinition(
      name: "Snapdragon",
      value: 25,
      iconAsset: "assets/icons/items/snapdragon.png",
      xpValue: 62,
    ),
  ),
  CADANTINE(
    ItemDefinition(
      name: "Cadantine",
      value: 22,
      iconAsset: "assets/icons/items/cadantine.png",
      xpValue: 70,
    ),
  ),
  LANTADYME(
    ItemDefinition(
      name: "Lantadyme",
      value: 24,
      iconAsset: "assets/icons/items/lantadyme.png",
      xpValue: 74,
    ),
  ),
  DWARF_WEED(
    ItemDefinition(
      name: "Dwarf Weed",
      value: 26,
      iconAsset: "assets/icons/items/dwarf_weed.png",
      xpValue: 78,
    ),
  ),
  TORSTOL(
    ItemDefinition(
      name: "Torstol",
      value: 40,
      iconAsset: "assets/icons/items/torstol.png",
      xpValue: 85,
    ),
  ),

  // ── ALCHEMY REAGENTS ────────────────────────────────────────────
  // What a herb is brewed *with*, alchemy level ascending. A herb sets
  // what a potion is; the reagent it is paired with sets which stat the
  // potion moves. Iron ore doubles as one and stays in ORES.
  FEATHER(
    ItemDefinition(
      name: "Feather",
      value: 1,
      iconAsset: "assets/icons/items/feather.png",
    ),
  ),
  SCALE(
    ItemDefinition(
      name: "Scale",
      value: 4,
      iconAsset: "assets/icons/items/scale.png",
    ),
  ),
  SILK(
    ItemDefinition(
      name: "Silk",
      value: 8,
      iconAsset: "assets/icons/items/silk.png",
    ),
  ),
  CLAW(
    ItemDefinition(
      name: "Claw",
      value: 6,
      iconAsset: "assets/icons/items/claw.png",
    ),
  ),
  VENOM(
    ItemDefinition(
      name: "Venom",
      value: 10,
      iconAsset: "assets/icons/items/venom.png",
    ),
  ),

  // ── POTIONS ─────────────────────────────────────────────────────
  // BuffItemDefinition, alchemy level ascending. A restore-type potion is
  // a FoodItemDefinition with restoreSkill set.
  //
  // The minor tier is the whole of alchemy so far: one guam leaf and one
  // reagent for +1 to a single stat for a minute. Drinking one is
  // PotionSystem's job — the buff is global, so it travels with the
  // player rather than sitting in a zone the way a fire does.
  MINOR_SPEED_POTION(
    BuffItemDefinition(
      name: "Minor Speed Potion",
      value: 12,
      description: "Guam steeped with a feather. Acts a shade faster.",
      skillBonus: {SkillId.SPEED: 1},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/minor_speed_potion.png",
    ),
  ),
  MINOR_DEFENCE_POTION(
    BuffItemDefinition(
      name: "Minor Defence Potion",
      value: 18,
      description: "Guam ground with iron. Turns a little more aside.",
      skillBonus: {SkillId.DEFENCE: 1},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/minor_defence_potion.png",
    ),
  ),
  MINOR_STAMINA_POTION(
    BuffItemDefinition(
      name: "Minor Stamina Potion",
      value: 25,
      description: "Guam and a ground scale. Holds a little more wind.",
      skillBonus: {SkillId.STAMINA: 1},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/minor_stamina_potion.png",
    ),
  ),
  MINOR_RECOVERY_POTION(
    BuffItemDefinition(
      name: "Minor Recovery Potion",
      value: 30,
      description: "Guam strained through silk. Gets the wind back sooner.",
      skillBonus: {SkillId.RECOVERY: 1},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/minor_recovery_potion.png",
    ),
  ),
  MINOR_ATTACK_POTION(
    BuffItemDefinition(
      name: "Minor Attack Potion",
      value: 40,
      description: "Guam cut with venom. Lands a little more often.",
      skillBonus: {SkillId.ATTACK: 1},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/minor_attack_potion.png",
    ),
  ),
  MINOR_STRENGTH_POTION(
    BuffItemDefinition(
      name: "Minor Strength Potion",
      value: 45,
      description: "Guam and a powdered claw. Hits a little harder.",
      skillBonus: {SkillId.STRENGTH: 1},
      duration: Duration(minutes: 1),
      iconAsset: "assets/icons/items/minor_strength_potion.png",
    ),
  ),

  // ── RAW FOOD · MEAT ─────────────────────────────────────────────
  // level ascending
  CHICKEN_MEAT(
    ItemDefinition(
      name: "Chicken Meat",
      value: 2,
      iconAsset: "assets/icons/items/chicken_meat.png",
    ),
  ),
  COW_MEAT(
    ItemDefinition(
      name: "Cow Meat",
      value: 1,
      iconAsset: "assets/icons/items/cow_meat.png",
      xpValue: 5,
    ),
  ),

  // ── RAW FOOD · FISH ─────────────────────────────────────────────
  // fishing level ascending
  MINNOW(
    ItemDefinition(
      name: "Minnow",
      value: 1,
      iconAsset: "assets/icons/items/minnow.png",
      xpValue: 5,
    ),
  ),
  CARP(
    ItemDefinition(
      name: "Carp",
      value: 2,
      iconAsset: "assets/icons/items/carp.png",
      xpValue: 10,
    ),
  ),
  BLUEGILL(
    ItemDefinition(
      name: "Bluegill",
      value: 3,
      iconAsset: "assets/icons/items/bluegill.png",
      xpValue: 15,
    ),
  ),
  TROUT(
    ItemDefinition(
      name: "Trout",
      value: 5,
      iconAsset: "assets/icons/items/trout.png",
      xpValue: 25,
    ),
  ),
  PIKE(
    ItemDefinition(
      name: "Pike",
      value: 7,
      iconAsset: "assets/icons/items/pike.png",
      xpValue: 30,
    ),
  ),
  SALMON(
    ItemDefinition(
      name: "Salmon",
      value: 10,
      iconAsset: "assets/icons/items/salmon.png",
      xpValue: 50,
    ),
  ),
  CATFISH(
    ItemDefinition(
      name: "Catfish",
      value: 15,
      iconAsset: "assets/icons/items/catfish.png",
      xpValue: 75,
    ),
  ),
  BASS(
    ItemDefinition(
      name: "Bass",
      value: 20,
      iconAsset: "assets/icons/items/bass.png",
      xpValue: 100,
    ),
  ),
  WHITEFISH(
    ItemDefinition(
      name: "Whitefish",
      value: 25,
      iconAsset: "assets/icons/items/whitefish.png",
      xpValue: 125,
    ),
  ),
  TUNA(
    ItemDefinition(
      name: "Tuna",
      value: 30,
      iconAsset: "assets/icons/items/tuna.png",
      xpValue: 125,
    ),
  ),
  SWORDFISH(
    ItemDefinition(
      name: "Swordfish",
      value: 50,
      iconAsset: "assets/icons/items/swordfish.png",
      xpValue: 150,
    ),
  ),
  SHARK(
    ItemDefinition(
      name: "Shark",
      value: 100,
      iconAsset: "assets/icons/items/shark.png",
      xpValue: 200,
    ),
  ),

  // ── COOKED FOOD ─────────────────────────────────────────────────
  // same order as the raw counterpart above
  COOKED_CHICKEN(
    FoodItemDefinition(
      name: "Cooked Chicken",
      value: 4,
      restoreAmount: 4,
      xpValue: 10,
      iconAsset: "assets/icons/items/cooked_chicken.png",
    ),
  ),
  COOKED_BEEF(
    FoodItemDefinition(
      name: "Cooked Beef",
      value: 4,
      restoreAmount: 5,
      xpValue: 10,
      iconAsset: "assets/icons/items/cooked_beef.png",
    ),
  ),
  COOKED_MINNOW(
    FoodItemDefinition(
      name: "Cooked Minnow",
      value: 2,
      restoreAmount: 1,
      xpValue: 10,
      iconAsset: "assets/icons/items/cooked_minnow.png",
    ),
  ),
  COOKED_CARP(
    FoodItemDefinition(
      name: "Cooked Carp",
      value: 4,
      restoreAmount: 2,
      xpValue: 20,
      iconAsset: "assets/icons/items/cooked_carp.png",
    ),
  ),
  COOKED_BLUEGILL(
    FoodItemDefinition(
      name: "Cooked Bluegill",
      value: 6,
      restoreAmount: 3,
      xpValue: 30,
      iconAsset: "assets/icons/items/cooked_bluegill.png",
    ),
  ),
  COOKED_TROUT(
    FoodItemDefinition(
      name: "Cooked Trout",
      value: 10,
      restoreAmount: 5,
      xpValue: 50,
      iconAsset: "assets/icons/items/cooked_trout.png",
    ),
  ),
  COOKED_PIKE(
    FoodItemDefinition(
      name: "Cooked Pike",
      value: 14,
      restoreAmount: 7,
      xpValue: 70,
      iconAsset: "assets/icons/items/cooked_pike.png",
    ),
  ),
  COOKED_SALMON(
    FoodItemDefinition(
      name: "Cooked Salmon",
      value: 20,
      restoreAmount: 12,
      xpValue: 100,
      iconAsset: "assets/icons/items/cooked_salmon.png",
    ),
  ),
  COOKED_CATFISH(
    FoodItemDefinition(
      name: "Cooked Catfish",
      value: 30,
      restoreAmount: 15,
      xpValue: 150,
      iconAsset: "assets/icons/items/cooked_catfish.png",
    ),
  ),
  COOKED_BASS(
    FoodItemDefinition(
      name: "Cooked Bass",
      value: 40,
      restoreAmount: 20,
      xpValue: 200,
      iconAsset: "assets/icons/items/cooked_bass.png",
    ),
  ),
  COOKED_WHITEFISH(
    FoodItemDefinition(
      name: "Cooked Whitefish",
      value: 50,
      restoreAmount: 22,
      xpValue: 250,
      iconAsset: "assets/icons/items/cooked_whitefish.png",
    ),
  ),
  COOKED_TUNA(
    FoodItemDefinition(
      name: "Cooked Tuna",
      value: 60,
      restoreAmount: 25,
      xpValue: 300,
      iconAsset: "assets/icons/items/cooked_tuna.png",
    ),
  ),
  COOKED_SWORDFISH(
    FoodItemDefinition(
      name: "Cooked Swordfish",
      value: 100,
      restoreAmount: 30,
      xpValue: 500,
      iconAsset: "assets/icons/items/cooked_swordfish.png",
    ),
  ),
  COOKED_SHARK(
    FoodItemDefinition(
      name: "Cooked Shark",
      value: 200,
      restoreAmount: 35,
      xpValue: 1000,
      iconAsset: "assets/icons/items/cooked_shark.png",
    ),
  ),

  // ── ENCHANTING MATERIALS ────────────────────────────────────────
  // tier ascending
  ENCHANTING_DUST(
    ItemDefinition(
      name: "Enchanting Dust",
      value: 1,
      description: "Disenchanted from common equipment.",
      iconAsset: "assets/icons/items/enchanting_dust.png",
    ),
  ),
  ENCHANTING_ESSENCE(
    ItemDefinition(
      name: "Enchanting Essence",
      value: 4,
      description: "Disenchanted from uncommon equipment.",
      iconAsset: "assets/icons/items/enchanting_essence.png",
    ),
  ),
  ENCHANTING_RUNE(
    ItemDefinition(
      name: "Enchanting Rune",
      value: 15,
      description: "Disenchanted from rare equipment.",
      iconAsset: "assets/icons/items/enchanting_rune.png",
    ),
  ),
  ENCHANTING_PRISM(
    ItemDefinition(
      name: "Enchanting Prism",
      value: 50,
      description: "Disenchanted from epic equipment.",
      iconAsset: "assets/icons/items/enchanting_prism.png",
    ),
  ),
  SOUL_SHARD(
    ItemDefinition(
      name: "Soul Shard",
      value: 200,
      description: "Disenchanted from legendary equipment.",
      iconAsset: "assets/icons/items/soul_shard.png",
    ),
  ),

  // ── JEWELLERY BASES ─────────────────────────────────────────────
  GOLD_RING(
    ItemDefinition(
      name: "Gold Ring",
      value: 8,
      description: "A plain band, ready for a gem.",
      iconAsset: "assets/icons/items/copper_ring.png",
    ),
  ),
  GOLD_NECKLACE(
    ItemDefinition(
      name: "Gold Necklace",
      value: 16,
      description: "A plain chain, ready for a gem.",
      iconAsset: "assets/icons/items/copper_necklace.png",
    ),
  ),

  // ── JEWELLERY ───────────────────────────────────────────────────
  // by gem, in gem order; ring then necklace
  TOPAZ_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Topaz Ring",
      value: 40,
      skillBonus: {SkillId.RECOVERY: 4},
      iconAsset: "assets/icons/items/topaz_ring.png",
    ),
  ),
  TOPAZ_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Topaz Necklace",
      value: 55,
      skillBonus: {SkillId.RECOVERY: 6},
      iconAsset: "assets/icons/items/topaz_necklace.png",
    ),
  ),
  SAPPHIRE_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Sapphire Ring",
      value: 70,
      skillBonus: {SkillId.STAMINA: 5},
      iconAsset: "assets/icons/items/sapphire_ring.png",
    ),
  ),
  SAPPHIRE_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Sapphire Necklace",
      value: 90,
      skillBonus: {SkillId.STAMINA: 7},
      iconAsset: "assets/icons/items/sapphire_necklace.png",
    ),
  ),
  EMERALD_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Emerald Ring",
      value: 100,
      skillBonus: {SkillId.SPEED: 5},
      iconAsset: "assets/icons/items/emerald_ring.png",
    ),
  ),
  EMERALD_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Emerald Necklace",
      value: 130,
      skillBonus: {SkillId.SPEED: 7},
      iconAsset: "assets/icons/items/emerald_necklace.png",
    ),
  ),
  RUBY_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Ruby Ring",
      value: 150,
      skillBonus: {SkillId.HITPOINTS: 6},
      iconAsset: "assets/icons/items/ruby_ring.png",
    ),
  ),
  RUBY_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Ruby Necklace",
      value: 190,
      skillBonus: {SkillId.HITPOINTS: 9},
      iconAsset: "assets/icons/items/ruby_necklace.png",
    ),
  ),
  DIAMOND_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Diamond Ring",
      value: 220,
      skillBonus: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/diamond_ring.png",
    ),
  ),
  DIAMOND_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Diamond Necklace",
      value: 280,
      skillBonus: {SkillId.DEFENCE: 12},
      iconAsset: "assets/icons/items/diamond_necklace.png",
    ),
  ),
  DRAGONSTONE_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Dragonstone Ring",
      value: 330,
      skillBonus: {SkillId.ATTACK: 9},
      iconAsset: "assets/icons/items/dragonstone_ring.png",
    ),
  ),
  DRAGONSTONE_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Dragonstone Necklace",
      value: 420,
      skillBonus: {SkillId.ATTACK: 13},
      iconAsset: "assets/icons/items/dragonstone_necklace.png",
    ),
  ),
  ONYX_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Onyx Ring",
      value: 550,
      skillBonus: {SkillId.ATTACK: 6, SkillId.DEFENCE: 6, SkillId.HITPOINTS: 6},
      iconAsset: "assets/icons/items/onyx_ring.png",
    ),
  ),
  ONYX_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Onyx Necklace",
      value: 700,
      skillBonus: {SkillId.ATTACK: 9, SkillId.DEFENCE: 9, SkillId.HITPOINTS: 9},
      iconAsset: "assets/icons/items/onyx_necklace.png",
    ),
  ),

  // ── FIRES ───────────────────────────────────────────────────────
  // log tier, then fire tier
  COOKFIRE(
    FireItemDefinition(
      name: "Cookfire",
      value: 4,
      skillBonus: {SkillId.COOKING: 3},
      duration: Duration(minutes: 3),
      canCook: true,
      iconAsset: "assets/images/entities/cookfire.png",
    ),
  ),
  BASIC_CAMPFIRE(
    FireItemDefinition(
      name: "Campfire",
      value: 5,
      skillBonus: {SkillId.STAMINA: 1, SkillId.RECOVERY: 1},
      duration: Duration(minutes: 5),
      iconAsset: "assets/images/entities/campfire.png",
    ),
  ),
  BONFIRE(
    FireItemDefinition(
      name: "Bonfire",
      value: 18,
      skillBonus: {SkillId.SPEED: 1, SkillId.STRENGTH: 1},
      duration: Duration(minutes: 10),
      iconAsset: "assets/images/entities/bonfire.png",
    ),
  ),
  OAK_COOKFIRE(
    FireItemDefinition(
      name: "Oak Cookfire",
      value: 10,
      skillBonus: {SkillId.COOKING: 6},
      duration: Duration(minutes: 5),
      canCook: true,
      iconAsset: "assets/images/entities/oak_cookfire.png",
    ),
  ),
  OAK_CAMPFIRE(
    FireItemDefinition(
      name: "Oak Campfire",
      value: 12,
      skillBonus: {SkillId.STAMINA: 3, SkillId.RECOVERY: 3},
      duration: Duration(minutes: 8),
      iconAsset: "assets/images/entities/oak_campfire.png",
    ),
  ),
  OAK_BONFIRE(
    FireItemDefinition(
      name: "Oak Bonfire",
      value: 40,
      skillBonus: {SkillId.SPEED: 3, SkillId.STRENGTH: 3},
      duration: Duration(minutes: 15),
      iconAsset: "assets/images/entities/oak_bonfire.png",
    ),
  ),

  // ── ARMOUR · HELMET ─────────────────────────────────────────────
  // tier ascending
  COPPER_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Copper Helmet",
      value: 15,
      skillBonus: {SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/copper_helmet.png",
    ),
  ),
  IRON_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Iron Helmet",
      value: 30,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/iron_helmet.png",
    ),
  ),
  STEEL_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Steel Helmet",
      value: 60,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/steel_helmet.png",
    ),
  ),
  MITHRIL_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Mithril Helmet",
      value: 120,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/mithril_helmet.png",
    ),
  ),

  // ── ARMOUR · CHESTPLATE ─────────────────────────────────────────
  // tier ascending
  LIGHT_LETHER_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Light Leather Jerkin",
      value: 150,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/light_leather_chest.png",
    ),
  ),
  COPPER_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Copper Chestplate",
      value: 25,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/copper_chestplate.png",
    ),
  ),
  IRON_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Iron Chestplate",
      value: 50,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/iron_chestplate.png",
    ),
  ),
  STEEL_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Steel Chestplate",
      value: 100,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/steel_chestplate.png",
    ),
  ),
  MITHRIL_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Mithril Chestplate",
      value: 200,
      skillBonus: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/mithril_chestplate.png",
    ),
  ),

  // ── ARMOUR · LEGS ───────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Light Leather Pants",
      value: 100,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/light_leather_pants.png",
    ),
  ),
  COPPER_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Copper Leggings",
      value: 20,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/copper_legs.png",
    ),
  ),
  IRON_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Iron Leggings",
      value: 40,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/iron_legs.png",
    ),
  ),
  STEEL_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Steel Leggings",
      value: 80,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/steel_legs.png",
    ),
  ),
  MITHRIL_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Mithril Leggings",
      value: 160,
      skillBonus: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/mithril_legs.png",
    ),
  ),

  // ── ARMOUR · BOOTS ──────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Light Leather Boots",
      value: 50,
      skillBonus: {SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/light_leather_boots.png",
    ),
  ),
  COPPER_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Copper Boots",
      value: 10,
      skillBonus: {SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/copper_boots.png",
    ),
  ),
  IRON_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Iron Boots",
      value: 20,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/iron_boots.png",
    ),
  ),
  STEEL_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Steel Boots",
      value: 40,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/steel_boots.png",
    ),
  ),
  MITHRIL_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Mithril Boots",
      value: 80,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/mithril_boots.png",
    ),
  ),

  // ── ARMOUR · GLOVES ─────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Light Leather Gloves",
      value: 50,
      skillBonus: {SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/light_leather_gloves.png",
    ),
  ),
  COPPER_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Copper Gloves",
      value: 10,
      skillBonus: {SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/copper_gloves.png",
    ),
  ),
  IRON_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Iron Gloves",
      value: 20,
      skillBonus: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/iron_gloves.png",
    ),
  ),
  STEEL_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Steel Gloves",
      value: 40,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/steel_gloves.png",
    ),
  ),
  MITHRIL_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Mithril Gloves",
      value: 80,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/mithril_gloves.png",
    ),
  ),

  // ── ARMOUR · SHIELD ─────────────────────────────────────────────
  // tier ascending
  COPPER_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Copper Shield",
      value: 15,
      skillBonus: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/copper_shield.png",
    ),
  ),
  IRON_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Iron Shield",
      value: 30,
      skillBonus: {SkillId.DEFENCE: 5},
      iconAsset: "assets/icons/items/iron_shield.png",
    ),
  ),
  STEEL_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Steel Shield",
      value: 60,
      skillBonus: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/steel_shield.png",
    ),
  ),
  MITHRIL_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Mithril Shield",
      value: 120,
      skillBonus: {SkillId.DEFENCE: 13},
      iconAsset: "assets/icons/items/mithril_shield.png",
    ),
  ),

  // ── WEAPONS & TOOLS · DAGGER ────────────────────────────────────
  // tier ascending
  COPPER_DAGGER(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Copper Dagger",
      value: 10,
      skillBonus: {SkillId.ATTACK: 1},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/copper_dagger.png",
    ),
  ),
  IRON_DAGGER(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Iron Dagger",
      value: 25,
      skillBonus: {SkillId.ATTACK: 2},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/iron_dagger.png",
    ),
  ),
  STEEL_DAGGER(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Steel Dagger",
      value: 60,
      skillBonus: {SkillId.ATTACK: 3},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/steel_dagger.png",
    ),
  ),
  MITHRIL_DAGGER(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Mithril Dagger",
      value: 150,
      skillBonus: {SkillId.ATTACK: 5},
      actionInterval: FastAttackSpeed,
      iconAsset: "assets/icons/items/mithril_dagger.png",
    ),
  ),

  // ── WEAPONS & TOOLS · AXE ───────────────────────────────────────
  // tier ascending
  STONE_AXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Stone Axe",
      value: 10,
      skillBonus: {SkillId.WOODCUTTING: 1},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/stone_axe.png",
    ),
  ),
  COPPER_AXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Copper Axe",
      value: 10,
      skillBonus: {SkillId.WOODCUTTING: 2},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_axe.png",
    ),
  ),
  IRON_AXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Iron Axe",
      value: 25,
      skillBonus: {SkillId.WOODCUTTING: 3},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/iron_axe.png",
    ),
  ),
  STEEL_AXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Steel Axe",
      value: 60,
      skillBonus: {SkillId.WOODCUTTING: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/steel_axe.png",
    ),
  ),
  MITHRIL_AXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Mithril Axe",
      value: 150,
      skillBonus: {SkillId.WOODCUTTING: 8},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/mithril_axe.png",
    ),
  ),

  // ── WEAPONS & TOOLS · PICKAXE ───────────────────────────────────
  // tier ascending
  STONE_PICKAXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Stone Pickaxe",
      value: 10,
      skillBonus: {SkillId.MINING: 1},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/stone_pickaxe.png",
    ),
  ),
  COPPER_PICKAXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Copper Pickaxe",
      value: 10,
      skillBonus: {SkillId.MINING: 2},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_pickaxe.png",
    ),
  ),
  IRON_PICKAXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Iron Pickaxe",
      value: 25,
      skillBonus: {SkillId.MINING: 3},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/iron_pickaxe.png",
    ),
  ),
  STEEL_PICKAXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Steel Pickaxe",
      value: 60,
      skillBonus: {SkillId.MINING: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/steel_pickaxe.png",
    ),
  ),
  MITHRIL_PICKAXE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Mithril Pickaxe",
      value: 150,
      skillBonus: {SkillId.MINING: 8},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/mithril_pickaxe.png",
    ),
  ),

  // ── WEAPONS & TOOLS · SICKLE ────────────────────────────────────
  // tier ascending
  COPPER_SICKLE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Copper Sickle",
      value: 10,
      skillBonus: {SkillId.HERBALISM: 2},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/copper_sickle.png",
    ),
  ),
  IRON_SICKLE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Iron Sickle",
      value: 25,
      skillBonus: {SkillId.HERBALISM: 3},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/iron_sickle.png",
    ),
  ),
  STEEL_SICKLE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Steel Sickle",
      value: 60,
      skillBonus: {SkillId.HERBALISM: 5},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/steel_sickle.png",
    ),
  ),
  MITHRIL_SICKLE(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Mithril Sickle",
      value: 150,
      skillBonus: {SkillId.HERBALISM: 8},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/mithril_sickle.png",
    ),
  ),

  // ── WEAPONS & TOOLS · FISHING ROD ───────────────────────────────
  // tier ascending
  SIMPLE_FISHING_ROD(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.TOOL,
      name: "Simple Fishing Rod",
      value: 5,
      skillBonus: {SkillId.FISHING: 1},
      actionInterval: MediumAttackSpeed,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),

  // ── WEAPONS & TOOLS · ODDITIES ──────────────────────────────────
  // tier ascending
  PITCHFORK(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_2H,
      name: "Pitchfork",
      value: 30,
      skillBonus: {SkillId.ATTACK: 5},
      actionInterval: SlowAttackSpeed,
      iconAsset: "assets/icons/items/pitchfork.png",
    ),
  ),
  RARE_PITCHFORK(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_2H,
      name: "Pitchfork",
      value: 30,
      skillBonus: {SkillId.ATTACK: 7},
      quality: ItemQuality.RARE,
      actionInterval: SlowAttackSpeed,
      iconAsset: "assets/icons/items/pitchfork.png",
    ),
  ),

  // ── BOSS UNIQUES ────────────────────────────────────────────────
  // by source dungeon
  GOBLIN_CROWN(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Goblin Crown",
      value: 150,
      skillBonus: {SkillId.DEFENCE: 12, SkillId.ATTACK: 4},
      iconAsset: "assets/icons/items/goblin_crown.png",
    ),
  ),
  GOBLIN_SCEPTER(
    WeaponItemDefinition(
      armorSlot: ArmorSlots.WEAPON_1H,
      name: "Goblin Scepter",
      value: 150,
      skillBonus: {SkillId.ATTACK: 12, SkillId.DEFENCE: 4},
      actionInterval: MediumAttackSpeed,
      description: "The Queen's rod of office, still warm.",
      iconAsset: "assets/icons/items/goblin_scepter.png",
    ),
  ),
  SPIDER_SILK_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Spider Silk Necklace",
      value: 120,
      skillBonus: {SkillId.ATTACK: 8, SkillId.DEFENCE: 4},
      iconAsset: "assets/icons/items/spider_silk_necklace.png",
    ),
  ),

  // ── DUNGEON KEYS ────────────────────────────────────────────────
  // by dungeon
  GOBLIN_QUEEN_KEY(
    ItemDefinition(
      name: "Goblin Queen Key",
      value: 0,
      iconAsset: "assets/icons/items/goblin_queen_key.png",
    ),
  );

  const ItemId(this.definition);

  /// The design-time template for this item: name, value, icon, and whatever
  /// its subtype adds. Never mutate it.
  final ItemDefinition definition;

  /// A fresh, mutable runtime instance of this item.
  Item build() => definition.toItem(this);

  String? get iconAsset => definition.iconAsset;

  /// Icon lookup for [EnumImageProviderLookup], which keys on the id's Type
  /// and so hands back a `dynamic`.
  static ImageProvider? providerFor(dynamic id) {
    if (id is! ItemId) return null;
    final asset = id.iconAsset;
    return asset != null ? AssetImage(asset) : null;
  }
}
