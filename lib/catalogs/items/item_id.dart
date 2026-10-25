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

  /// The stand-in [BuffService] hands back when nothing is buffing a stat.
  /// Separate from [NULL] because it has to *be* a BuffItemDefinition for
  /// the buff plumbing to type-check, while [NULL] stays a plain item.
  /// Empty bonus and zero duration, so it always reads as expired.
  NULL_BUFF(
    BuffItemDefinition(
      name: "Nothing",
      value: 0,
      skillBonus: {},
      duration: Duration.zero,
    ),
  ),

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
  ANIMAL_PELT(
    ItemDefinition(
      name: "Fur Pelt",
      value: 1,
      iconAsset: "assets/icons/items/fur_pelt.png",
    ),
  ),
  WOLF_PELT(
    ItemDefinition(
      name: "Wolf Pelt",
      value: 1,
      iconAsset: "assets/icons/items/wolf_pelt.png",
    ),
  ),
  BEAR_HIDE(
    ItemDefinition(
      name: "Bear Hide",
      value: 1,
      iconAsset: "assets/icons/items/bear_hide.png",
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
  WILLOW_LOGS(
    ItemDefinition(
      name: "Willow Logs",
      value: 12,
      iconAsset: "assets/icons/items/willow_logs.png",
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
  DRAGON_ORE(
    ItemDefinition(
      name: "Dragon Ore",
      value: 192,
      iconAsset: "assets/icons/items/dragon_ore.png",
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
  DRAGON_BAR(
    ItemDefinition(
      name: "Dragon Bar",
      value: 256,
      iconAsset: "assets/icons/items/dragon_bar.png",
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
  FANG(
    ItemDefinition(
      name: "Fang",
      value: 6,
      iconAsset: "assets/icons/items/fang.png",
    ),
  ),
  CLAW(
    ItemDefinition(
      name: "Claw",
      value: 6,
      iconAsset: "assets/icons/items/claw.png",
    ),
  ),
  WOLF_CLAW(
    ItemDefinition(
      name: "Wolf Claw",
      value: 6,
      iconAsset: "assets/icons/items/wolf_claw.png",
    ),
  ),
  BEAR_CLAW(
    ItemDefinition(
      name: "Bear Claw",
      value: 6,
      iconAsset: "assets/icons/items/bear_claw.png",
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
  // reagent for +5 to a single stat for three minutes. Drinking one is
  // PotionSystem's job — the buff is global, so it travels with the
  // player rather than sitting in a zone the way a fire does.
  MINOR_SPEED_POTION(
    BuffItemDefinition(
      name: "Minor Speed Potion",
      value: 12,
      description: "Guam steeped with a feather. Acts a shade faster.",
      skillBonus: {SkillId.SPEED: 5},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/minor_speed_potion.png",
    ),
  ),
  MINOR_FISHING_POTION(
    BuffItemDefinition(
      name: "Minor Fishing Potion",
      value: 12,
      description: "Guam soaked with a minnow. Lands a little more.",
      skillBonus: {SkillId.FISHING: 5},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/minor_fishing_potion.png",
    ),
  ),
  MINOR_DEFENCE_POTION(
    BuffItemDefinition(
      name: "Minor Defence Potion",
      value: 18,
      description: "Guam ground with iron. Turns a little more aside.",
      skillBonus: {SkillId.DEFENCE: 5},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/minor_defence_potion.png",
    ),
  ),
  MINOR_STAMINA_POTION(
    BuffItemDefinition(
      name: "Minor Stamina Potion",
      value: 25,
      description: "Guam and a ground scale. Holds a little more wind.",
      skillBonus: {SkillId.STAMINA: 5},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/minor_stamina_potion.png",
    ),
  ),
  MINOR_RECOVERY_POTION(
    BuffItemDefinition(
      name: "Minor Recovery Potion",
      value: 30,
      description: "Guam strained through silk. Gets the wind back sooner.",
      skillBonus: {SkillId.RECOVERY: 5},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/minor_recovery_potion.png",
    ),
  ),
  MINOR_ATTACK_POTION(
    BuffItemDefinition(
      name: "Minor Attack Potion",
      value: 40,
      description: "Guam cut with venom. Lands a little more often.",
      skillBonus: {SkillId.ATTACK: 5},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/minor_attack_potion.png",
    ),
  ),
  MINOR_STRENGTH_POTION(
    BuffItemDefinition(
      name: "Minor Strength Potion",
      value: 45,
      description: "Guam and a powdered claw. Hits a little harder.",
      skillBonus: {SkillId.STRENGTH: 5},
      duration: Duration(minutes: 3),
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
  BEAR_RUMP(
    ItemDefinition(
      name: "Bear Rump",
      value: 2,
      iconAsset: "assets/icons/items/bear_rump.png",
    ),
  ),

  // ── RAW FOOD · FISH ─────────────────────────────────────────────
  // fishing level ascending
  //
  // A fish's xp is about what one blacksmithing action pays at the level the
  // fish opens at - the tier's xp per bar, 3 at copper up to 17.5 at dragon -
  // so a cast and a smelt train at the same rate. Every fish a cast lands
  // pays it, overkill catches included.
  MINNOW(
    ItemDefinition(
      name: "Minnow",
      value: 1,
      iconAsset: "assets/icons/items/minnow.png",
      xpValue: 3,
    ),
  ),
  CARP(
    ItemDefinition(
      name: "Carp",
      value: 2,
      iconAsset: "assets/icons/items/carp.png",
      xpValue: 3,
    ),
  ),
  BLUEGILL(
    ItemDefinition(
      name: "Bluegill",
      value: 3,
      iconAsset: "assets/icons/items/bluegill.png",
      xpValue: 3,
    ),
  ),
  TROUT(
    ItemDefinition(
      name: "Trout",
      value: 5,
      iconAsset: "assets/icons/items/trout.png",
      xpValue: 4,
    ),
  ),
  PIKE(
    ItemDefinition(
      name: "Pike",
      value: 7,
      iconAsset: "assets/icons/items/pike.png",
      xpValue: 5,
    ),
  ),
  SALMON(
    ItemDefinition(
      name: "Salmon",
      value: 10,
      iconAsset: "assets/icons/items/salmon.png",
      xpValue: 6,
    ),
  ),
  CATFISH(
    ItemDefinition(
      name: "Catfish",
      value: 15,
      iconAsset: "assets/icons/items/catfish.png",
      xpValue: 8,
    ),
  ),
  BASS(
    ItemDefinition(
      name: "Bass",
      value: 20,
      iconAsset: "assets/icons/items/bass.png",
      xpValue: 8,
    ),
  ),
  WHITEFISH(
    ItemDefinition(
      name: "Whitefish",
      value: 25,
      iconAsset: "assets/icons/items/whitefish.png",
      xpValue: 10,
    ),
  ),
  TUNA(
    ItemDefinition(
      name: "Tuna",
      value: 30,
      iconAsset: "assets/icons/items/tuna.png",
      xpValue: 15,
    ),
  ),
  SWORDFISH(
    ItemDefinition(
      name: "Swordfish",
      value: 50,
      iconAsset: "assets/icons/items/swordfish.png",
      xpValue: 16,
    ),
  ),
  SHARK(
    ItemDefinition(
      name: "Shark",
      value: 100,
      iconAsset: "assets/icons/items/shark.png",
      xpValue: 18,
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
      fibLevel: 2,
      statWeights: {SkillId.RECOVERY: 4},
      iconAsset: "assets/icons/items/topaz_ring.png",
    ),
  ),
  TOPAZ_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Topaz Necklace",
      value: 55,
      fibLevel: 3,
      statWeights: {SkillId.RECOVERY: 6},
      iconAsset: "assets/icons/items/topaz_necklace.png",
    ),
  ),
  SAPPHIRE_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Sapphire Ring",
      value: 70,
      fibLevel: 3,
      statWeights: {SkillId.STAMINA: 5},
      iconAsset: "assets/icons/items/sapphire_ring.png",
    ),
  ),
  SAPPHIRE_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Sapphire Necklace",
      value: 90,
      fibLevel: 4,
      statWeights: {SkillId.STAMINA: 7},
      iconAsset: "assets/icons/items/sapphire_necklace.png",
    ),
  ),
  EMERALD_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Emerald Ring",
      value: 100,
      fibLevel: 4,
      statWeights: {SkillId.SPEED: 5},
      iconAsset: "assets/icons/items/emerald_ring.png",
    ),
  ),
  EMERALD_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Emerald Necklace",
      value: 130,
      fibLevel: 5,
      statWeights: {SkillId.SPEED: 7},
      iconAsset: "assets/icons/items/emerald_necklace.png",
    ),
  ),
  RUBY_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Ruby Ring",
      value: 150,
      fibLevel: 5,
      statWeights: {SkillId.HITPOINTS: 6},
      iconAsset: "assets/icons/items/ruby_ring.png",
    ),
  ),
  RUBY_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Ruby Necklace",
      value: 190,
      fibLevel: 6,
      statWeights: {SkillId.HITPOINTS: 9},
      iconAsset: "assets/icons/items/ruby_necklace.png",
    ),
  ),
  DIAMOND_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Diamond Ring",
      value: 220,
      fibLevel: 6,
      statWeights: {SkillId.DEFENCE: 8},
      iconAsset: "assets/icons/items/diamond_ring.png",
    ),
  ),
  DIAMOND_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Diamond Necklace",
      value: 280,
      fibLevel: 7,
      statWeights: {SkillId.DEFENCE: 12},
      iconAsset: "assets/icons/items/diamond_necklace.png",
    ),
  ),
  DRAGONSTONE_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Dragonstone Ring",
      value: 330,
      fibLevel: 7,
      statWeights: {SkillId.ATTACK: 9},
      iconAsset: "assets/icons/items/dragonstone_ring.png",
    ),
  ),
  DRAGONSTONE_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Dragonstone Necklace",
      value: 420,
      fibLevel: 8,
      statWeights: {SkillId.ATTACK: 13},
      iconAsset: "assets/icons/items/dragonstone_necklace.png",
    ),
  ),
  ONYX_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Onyx Ring",
      value: 550,
      fibLevel: 8,
      statWeights: {
        SkillId.ATTACK: 6,
        SkillId.DEFENCE: 6,
        SkillId.HITPOINTS: 6,
      },
      iconAsset: "assets/icons/items/onyx_ring.png",
    ),
  ),
  ONYX_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Onyx Necklace",
      value: 700,
      fibLevel: 9,
      statWeights: {
        SkillId.ATTACK: 9,
        SkillId.DEFENCE: 9,
        SkillId.HITPOINTS: 9,
      },
      iconAsset: "assets/icons/items/onyx_necklace.png",
    ),
  ),

  // ── FIRES ───────────────────────────────────────────────────────
  // log tier, then fire tier
  COOKFIRE(
    FireItemDefinition(
      name: "Cookfire",
      value: 4,
      // a cookfire is a meal and a warm seat: cooking, and hitpoints on the
      // same rung
      skillBonus: {SkillId.COOKING: 3, SkillId.HITPOINTS: 3},
      duration: Duration(minutes: 3),
      canCook: true,
      iconAsset: "assets/images/entities/cookfire.png",
    ),
  ),
  BASIC_CAMPFIRE(
    FireItemDefinition(
      name: "Campfire",
      value: 5,
      skillBonus: {SkillId.STAMINA: 5, SkillId.RECOVERY: 5},
      duration: Duration(minutes: 5),
      iconAsset: "assets/images/entities/campfire.png",
    ),
  ),
  BONFIRE(
    FireItemDefinition(
      name: "Bonfire",
      value: 18,
      skillBonus: {SkillId.SPEED: 5, SkillId.STRENGTH: 5},
      duration: Duration(minutes: 10),
      iconAsset: "assets/images/entities/bonfire.png",
    ),
  ),
  OAK_COOKFIRE(
    FireItemDefinition(
      name: "Oak Cookfire",
      value: 10,
      // 5, not 6: the three cookfires run 3 / 5 / 8 so the fire ladder
      // carries the same Fibonacci step as the gear tiers. hitpoints ride
      // the same rung
      skillBonus: {SkillId.COOKING: 5, SkillId.HITPOINTS: 5},
      duration: Duration(minutes: 5),
      canCook: true,
      iconAsset: "assets/images/entities/oak_cookfire.png",
    ),
  ),
  OAK_CAMPFIRE(
    FireItemDefinition(
      name: "Oak Campfire",
      value: 12,
      skillBonus: {SkillId.STAMINA: 8, SkillId.RECOVERY: 8},
      duration: Duration(minutes: 8),
      iconAsset: "assets/images/entities/oak_campfire.png",
    ),
  ),
  OAK_BONFIRE(
    FireItemDefinition(
      name: "Oak Bonfire",
      value: 40,
      skillBonus: {SkillId.SPEED: 8, SkillId.STRENGTH: 8},
      duration: Duration(minutes: 15),
      iconAsset: "assets/images/entities/oak_bonfire.png",
    ),
  ),
  // Tier 3 fires, burnt from the willow logs that grow in Darkwood. Stats
  // take the next Fibonacci rung (cooking 3/5/8, the rest 1/3/8) and the
  // burn times follow their own ladder (3/5/8, 5/8/13, 10/15/25 minutes).
  WILLOW_COOKFIRE(
    FireItemDefinition(
      name: "Willow Cookfire",
      value: 22,
      skillBonus: {SkillId.COOKING: 8, SkillId.HITPOINTS: 8},
      duration: Duration(minutes: 8),
      canCook: true,
      iconAsset: "assets/images/entities/willow_cookfire.png",
    ),
  ),
  WILLOW_CAMPFIRE(
    FireItemDefinition(
      name: "Willow Campfire",
      value: 26,
      skillBonus: {SkillId.STAMINA: 13, SkillId.RECOVERY: 13},
      duration: Duration(minutes: 13),
      iconAsset: "assets/images/entities/willow_campfire.png",
    ),
  ),
  WILLOW_BONFIRE(
    FireItemDefinition(
      name: "Willow Bonfire",
      value: 85,
      skillBonus: {SkillId.SPEED: 13, SkillId.STRENGTH: 13},
      duration: Duration(minutes: 25),
      iconAsset: "assets/images/entities/willow_bonfire.png",
    ),
  ),

  // ── ARMOR · HELMET ─────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Light Leather Coif",
      value: 50,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_coif.png",
    ),
  ),
  MEDIUM_LEATHER_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Medium Leather Coif",
      value: 100,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_coif.png",
    ),
  ),
  HEAVY_LEATHER_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Heavy Leather Coif",
      value: 200,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_coif.png",
    ),
  ),
  LIGHT_DRAGONHIDE_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Light Dragonhide Coif",
      value: 400,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_coif.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Medium Dragonhide Coif",
      value: 800,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_coif.png",
    ),
  ),
  HEAVY_DRAGONHIDE_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Heavy Dragonhide Coif",
      value: 1600,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_coif.png",
    ),
  ),
  LIGHT_DEMONHIDE_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Light Demonhide Coif",
      value: 3200,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_coif.png",
    ),
  ),
  MEDIUM_DEMONHIDE_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Medium Demonhide Coif",
      value: 6400,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_coif.png",
    ),
  ),
  HEAVY_DEMONHIDE_COIF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Heavy Demonhide Coif",
      value: 12800,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_coif.png",
    ),
  ),
  COPPER_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Copper Helmet",
      value: 15,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_helmet.png",
    ),
  ),
  IRON_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Iron Helmet",
      value: 30,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_helmet.png",
    ),
  ),
  STEEL_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Steel Helmet",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_helmet.png",
    ),
  ),
  MITHRIL_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Mithril Helmet",
      value: 120,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_helmet.png",
    ),
  ),
  ADAMANT_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Adamant Helmet",
      value: 240,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_helmet.png",
    ),
  ),
  RUNE_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Rune Helmet",
      value: 480,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_helmet.png",
    ),
  ),
  DRAGON_HELMET(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Dragon Helmet",
      value: 960,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_helmet.png",
    ),
  ),

  // ── ARMOUR · SHOULDER ───────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Light Leather Spaulders",
      value: 100,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_spaulders.png",
    ),
  ),
  MEDIUM_LEATHER_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Medium Leather Spaulders",
      value: 200,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_spaulders.png",
    ),
  ),
  HEAVY_LEATHER_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Heavy Leather Spaulders",
      value: 400,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_spaulders.png",
    ),
  ),
  LIGHT_DRAGONHIDE_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Light Dragonhide Spaulders",
      value: 800,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_spaulders.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Medium Dragonhide Spaulders",
      value: 1600,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_spaulders.png",
    ),
  ),
  HEAVY_DRAGONHIDE_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Heavy Dragonhide Spaulders",
      value: 3200,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_spaulders.png",
    ),
  ),
  LIGHT_DEMONHIDE_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Light Demonhide Spaulders",
      value: 6400,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_spaulders.png",
    ),
  ),
  MEDIUM_DEMONHIDE_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Medium Demonhide Spaulders",
      value: 12800,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_spaulders.png",
    ),
  ),
  HEAVY_DEMONHIDE_SPAULDERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Heavy Demonhide Spaulders",
      value: 25600,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_spaulders.png",
    ),
  ),
  COPPER_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Copper Pauldrons",
      value: 20,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_pauldrons.png",
    ),
  ),
  IRON_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Iron Pauldrons",
      value: 40,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_pauldrons.png",
    ),
  ),
  STEEL_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Steel Pauldrons",
      value: 80,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_pauldrons.png",
    ),
  ),
  MITHRIL_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Mithril Pauldrons",
      value: 160,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_pauldrons.png",
    ),
  ),
  ADAMANT_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Adamant Pauldrons",
      value: 320,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_pauldrons.png",
    ),
  ),
  RUNE_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Rune Pauldrons",
      value: 640,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_pauldrons.png",
    ),
  ),
  DRAGON_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Dragon Pauldrons",
      value: 1280,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_pauldrons.png",
    ),
  ),

  // ── ARMOUR · CHESTPLATE ─────────────────────────────────────────
  // tier ascending
  // the misspelling is this item's save format and cannot be corrected;
  // every tier above it spells leather properly
  LIGHT_LETHER_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Light Leather Jerkin",
      value: 150,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_chest.png",
    ),
  ),
  MEDIUM_LEATHER_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Medium Leather Jerkin",
      value: 300,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_chest.png",
    ),
  ),
  HEAVY_LEATHER_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Heavy Leather Jerkin",
      value: 600,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_chest.png",
    ),
  ),
  LIGHT_DRAGONHIDE_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Light Dragonhide Jerkin",
      value: 1200,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_chest.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Medium Dragonhide Jerkin",
      value: 2400,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_chest.png",
    ),
  ),
  HEAVY_DRAGONHIDE_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Heavy Dragonhide Jerkin",
      value: 4800,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_chest.png",
    ),
  ),
  LIGHT_DEMONHIDE_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Light Demonhide Jerkin",
      value: 9600,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_chest.png",
    ),
  ),
  MEDIUM_DEMONHIDE_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Medium Demonhide Jerkin",
      value: 19200,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_chest.png",
    ),
  ),
  HEAVY_DEMONHIDE_CHEST(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Heavy Demonhide Jerkin",
      value: 38400,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_chest.png",
    ),
  ),
  COPPER_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Copper Chestplate",
      value: 25,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_chestplate.png",
    ),
  ),
  IRON_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Iron Chestplate",
      value: 50,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_chestplate.png",
    ),
  ),
  STEEL_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Steel Chestplate",
      value: 100,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_chestplate.png",
    ),
  ),
  MITHRIL_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Mithril Chestplate",
      value: 200,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_chestplate.png",
    ),
  ),
  ADAMANT_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Adamant Chestplate",
      value: 400,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_chestplate.png",
    ),
  ),
  RUNE_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Rune Chestplate",
      value: 800,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_chestplate.png",
    ),
  ),
  DRAGON_CHESTPLATE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Dragon Chestplate",
      value: 1600,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_chestplate.png",
    ),
  ),

  // ── ARMOR · WAIST ───────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Light Leather Belt",
      value: 100,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_belt.png",
    ),
  ),
  MEDIUM_LEATHER_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Medium Leather Belt",
      value: 200,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_belt.png",
    ),
  ),
  HEAVY_LEATHER_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Heavy Leather Belt",
      value: 400,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_belt.png",
    ),
  ),
  LIGHT_DRAGONHIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Light Dragonhide Belt",
      value: 800,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_belt.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Medium Dragonhide Belt",
      value: 1600,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_belt.png",
    ),
  ),
  HEAVY_DRAGONHIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Heavy Dragonhide Belt",
      value: 3200,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_belt.png",
    ),
  ),
  LIGHT_DEMONHIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Light Demonhide Belt",
      value: 6400,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_belt.png",
    ),
  ),
  MEDIUM_DEMONHIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Medium Demonhide Belt",
      value: 12800,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_belt.png",
    ),
  ),
  HEAVY_DEMONHIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Heavy Demonhide Belt",
      value: 25600,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_belt.png",
    ),
  ),
  COPPER_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Copper Belt",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_belt.png",
    ),
  ),
  IRON_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Iron Belt",
      value: 20,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_belt.png",
    ),
  ),
  STEEL_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Steel Belt",
      value: 40,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_belt.png",
    ),
  ),
  MITHRIL_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Mithril Belt",
      value: 80,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_belt.png",
    ),
  ),
  ADAMANT_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Adamant Belt",
      value: 160,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_belt.png",
    ),
  ),
  RUNE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Rune Belt",
      value: 320,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_belt.png",
    ),
  ),
  DRAGON_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Dragon Belt",
      value: 640,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_belt.png",
    ),
  ),

  // ── ARMOR · WRIST ───────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Light Leather Bracers",
      value: 100,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_bracers.png",
    ),
  ),
  MEDIUM_LEATHER_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Medium Leather Bracers",
      value: 200,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_bracers.png",
    ),
  ),
  HEAVY_LEATHER_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Heavy Leather Bracers",
      value: 400,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_bracers.png",
    ),
  ),
  LIGHT_DRAGONHIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Light Dragonhide Bracers",
      value: 800,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_bracers.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Medium Dragonhide Bracers",
      value: 1600,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_bracers.png",
    ),
  ),
  HEAVY_DRAGONHIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Heavy Dragonhide Bracers",
      value: 3200,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_bracers.png",
    ),
  ),
  LIGHT_DEMONHIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Light Demonhide Bracers",
      value: 6400,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_bracers.png",
    ),
  ),
  MEDIUM_DEMONHIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Medium Demonhide Bracers",
      value: 12800,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_bracers.png",
    ),
  ),
  HEAVY_DEMONHIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Heavy Demonhide Bracers",
      value: 25600,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_bracers.png",
    ),
  ),
  COPPER_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Copper Bracers",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_bracers.png",
    ),
  ),
  IRON_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Iron Bracers",
      value: 20,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_bracers.png",
    ),
  ),
  STEEL_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Steel Bracers",
      value: 40,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_bracers.png",
    ),
  ),
  MITHRIL_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Mithril Bracers",
      value: 80,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_bracers.png",
    ),
  ),
  ADAMANT_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Adamant Bracers",
      value: 160,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_bracers.png",
    ),
  ),
  RUNE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Rune Bracers",
      value: 320,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_bracers.png",
    ),
  ),
  DRAGON_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Dragon Bracers",
      value: 640,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_bracers.png",
    ),
  ),
  BRACERS_OF_THE_WOLF(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Bracers of the Wolf",
      value: 100,
      quality: Rarity.COMMON,
      fibLevel: 1,
      statWeights: {SkillId.ATTACK: 1, SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/bracers_of_the_wolf.png",
    ),
  ),

  // ── ARMOUR · BACK ───────────────────────────────────────────────
  // tier ascending
  WOOL_CLOAK(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Wool Cloak",
      value: 60,
      fibLevel: 1,
      statWeights: {SkillId.DEFENCE: 2},
      iconAsset: "assets/icons/items/wool_cloak.png",
    ),
  ),
  LINEN_CAPE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Linen Cape",
      value: 120,
      fibLevel: 2,
      statWeights: {SkillId.DEFENCE: 3},
      iconAsset: "assets/icons/items/linen_cape.png",
    ),
  ),

  // ── ARMOUR · SKILLING GEAR ──────────────────────────────────────
  // A set per gathering and crafting skill, and one for exploration, a
  // piece in each of six slots, at five tiers. Every piece pours its whole
  // rung into its one skill — +2,
  // +3, +5, +8, +13 a common piece — and asks for 1, 20, 40, 60 or 80 in it
  // (see SkillingGearTier). By skill, then tier, then slot.
  //
  // The basic fisher's boots, hat and tunic drop off the Wolf Den's bosses;
  // the pants, gloves and cloak rotate through the trading post, whose
  // markup puts them at 1,000 coins. Nothing else has a source yet
  BASIC_FISHERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Fisher's Hat",
      value: 800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_fishers_hat.png",
    ),
  ),
  BASIC_FISHERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Fisher's Tunic",
      value: 800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_fishers_tunic.png",
    ),
  ),
  BASIC_FISHERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Fisher's Pants",
      value: 800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_fishers_pants.png",
    ),
  ),
  BASIC_FISHERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Fisher's Gloves",
      value: 800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_fishers_gloves.png",
    ),
  ),
  BASIC_FISHERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Fisher's Boots",
      value: 800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_fishers_boots.png",
    ),
  ),
  BASIC_FISHERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Fisher's Cloak",
      value: 800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_fishers_cloak.png",
    ),
  ),
  NOVICE_FISHERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Fisher's Hat",
      value: 1600,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_fishers_hat.png",
    ),
  ),
  NOVICE_FISHERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Fisher's Tunic",
      value: 1600,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_fishers_tunic.png",
    ),
  ),
  NOVICE_FISHERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Fisher's Pants",
      value: 1600,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_fishers_pants.png",
    ),
  ),
  NOVICE_FISHERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Fisher's Gloves",
      value: 1600,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_fishers_gloves.png",
    ),
  ),
  NOVICE_FISHERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Fisher's Boots",
      value: 1600,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_fishers_boots.png",
    ),
  ),
  NOVICE_FISHERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Fisher's Cloak",
      value: 1600,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_fishers_cloak.png",
    ),
  ),
  APPRENTICE_FISHERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Fisher's Hat",
      value: 3200,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_fishers_hat.png",
    ),
  ),
  APPRENTICE_FISHERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Fisher's Tunic",
      value: 3200,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_fishers_tunic.png",
    ),
  ),
  APPRENTICE_FISHERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Fisher's Pants",
      value: 3200,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_fishers_pants.png",
    ),
  ),
  APPRENTICE_FISHERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Fisher's Gloves",
      value: 3200,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_fishers_gloves.png",
    ),
  ),
  APPRENTICE_FISHERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Fisher's Boots",
      value: 3200,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_fishers_boots.png",
    ),
  ),
  APPRENTICE_FISHERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Fisher's Cloak",
      value: 3200,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_fishers_cloak.png",
    ),
  ),
  ADVANCED_FISHERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Fisher's Hat",
      value: 6400,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_fishers_hat.png",
    ),
  ),
  ADVANCED_FISHERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Fisher's Tunic",
      value: 6400,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_fishers_tunic.png",
    ),
  ),
  ADVANCED_FISHERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Fisher's Pants",
      value: 6400,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_fishers_pants.png",
    ),
  ),
  ADVANCED_FISHERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Fisher's Gloves",
      value: 6400,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_fishers_gloves.png",
    ),
  ),
  ADVANCED_FISHERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Fisher's Boots",
      value: 6400,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_fishers_boots.png",
    ),
  ),
  ADVANCED_FISHERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Fisher's Cloak",
      value: 6400,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_fishers_cloak.png",
    ),
  ),
  MASTER_FISHERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Fisher's Hat",
      value: 12800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_fishers_hat.png",
    ),
  ),
  MASTER_FISHERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Fisher's Tunic",
      value: 12800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_fishers_tunic.png",
    ),
  ),
  MASTER_FISHERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Fisher's Pants",
      value: 12800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_fishers_pants.png",
    ),
  ),
  MASTER_FISHERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Fisher's Gloves",
      value: 12800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_fishers_gloves.png",
    ),
  ),
  MASTER_FISHERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Fisher's Boots",
      value: 12800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_fishers_boots.png",
    ),
  ),
  MASTER_FISHERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Fisher's Cloak",
      value: 12800,
      skill: SkillId.FISHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_fishers_cloak.png",
    ),
  ),
  BASIC_MINERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Miner's Hat",
      value: 800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_miners_hat.png",
    ),
  ),
  BASIC_MINERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Miner's Tunic",
      value: 800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_miners_tunic.png",
    ),
  ),
  BASIC_MINERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Miner's Pants",
      value: 800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_miners_pants.png",
    ),
  ),
  BASIC_MINERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Miner's Gloves",
      value: 800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_miners_gloves.png",
    ),
  ),
  BASIC_MINERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Miner's Boots",
      value: 800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_miners_boots.png",
    ),
  ),
  BASIC_MINERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Miner's Cloak",
      value: 800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_miners_cloak.png",
    ),
  ),
  NOVICE_MINERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Miner's Hat",
      value: 1600,
      skill: SkillId.MINING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_miners_hat.png",
    ),
  ),
  NOVICE_MINERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Miner's Tunic",
      value: 1600,
      skill: SkillId.MINING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_miners_tunic.png",
    ),
  ),
  NOVICE_MINERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Miner's Pants",
      value: 1600,
      skill: SkillId.MINING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_miners_pants.png",
    ),
  ),
  NOVICE_MINERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Miner's Gloves",
      value: 1600,
      skill: SkillId.MINING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_miners_gloves.png",
    ),
  ),
  NOVICE_MINERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Miner's Boots",
      value: 1600,
      skill: SkillId.MINING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_miners_boots.png",
    ),
  ),
  NOVICE_MINERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Miner's Cloak",
      value: 1600,
      skill: SkillId.MINING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_miners_cloak.png",
    ),
  ),
  APPRENTICE_MINERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Miner's Hat",
      value: 3200,
      skill: SkillId.MINING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_miners_hat.png",
    ),
  ),
  APPRENTICE_MINERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Miner's Tunic",
      value: 3200,
      skill: SkillId.MINING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_miners_tunic.png",
    ),
  ),
  APPRENTICE_MINERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Miner's Pants",
      value: 3200,
      skill: SkillId.MINING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_miners_pants.png",
    ),
  ),
  APPRENTICE_MINERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Miner's Gloves",
      value: 3200,
      skill: SkillId.MINING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_miners_gloves.png",
    ),
  ),
  APPRENTICE_MINERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Miner's Boots",
      value: 3200,
      skill: SkillId.MINING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_miners_boots.png",
    ),
  ),
  APPRENTICE_MINERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Miner's Cloak",
      value: 3200,
      skill: SkillId.MINING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_miners_cloak.png",
    ),
  ),
  ADVANCED_MINERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Miner's Hat",
      value: 6400,
      skill: SkillId.MINING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_miners_hat.png",
    ),
  ),
  ADVANCED_MINERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Miner's Tunic",
      value: 6400,
      skill: SkillId.MINING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_miners_tunic.png",
    ),
  ),
  ADVANCED_MINERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Miner's Pants",
      value: 6400,
      skill: SkillId.MINING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_miners_pants.png",
    ),
  ),
  ADVANCED_MINERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Miner's Gloves",
      value: 6400,
      skill: SkillId.MINING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_miners_gloves.png",
    ),
  ),
  ADVANCED_MINERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Miner's Boots",
      value: 6400,
      skill: SkillId.MINING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_miners_boots.png",
    ),
  ),
  ADVANCED_MINERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Miner's Cloak",
      value: 6400,
      skill: SkillId.MINING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_miners_cloak.png",
    ),
  ),
  MASTER_MINERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Miner's Hat",
      value: 12800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_miners_hat.png",
    ),
  ),
  MASTER_MINERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Miner's Tunic",
      value: 12800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_miners_tunic.png",
    ),
  ),
  MASTER_MINERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Miner's Pants",
      value: 12800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_miners_pants.png",
    ),
  ),
  MASTER_MINERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Miner's Gloves",
      value: 12800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_miners_gloves.png",
    ),
  ),
  MASTER_MINERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Miner's Boots",
      value: 12800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_miners_boots.png",
    ),
  ),
  MASTER_MINERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Miner's Cloak",
      value: 12800,
      skill: SkillId.MINING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_miners_cloak.png",
    ),
  ),
  BASIC_WOODCUTTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Woodcutter's Hat",
      value: 800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_woodcutters_hat.png",
    ),
  ),
  BASIC_WOODCUTTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Woodcutter's Tunic",
      value: 800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_woodcutters_tunic.png",
    ),
  ),
  BASIC_WOODCUTTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Woodcutter's Pants",
      value: 800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_woodcutters_pants.png",
    ),
  ),
  BASIC_WOODCUTTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Woodcutter's Gloves",
      value: 800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_woodcutters_gloves.png",
    ),
  ),
  BASIC_WOODCUTTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Woodcutter's Boots",
      value: 800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_woodcutters_boots.png",
    ),
  ),
  BASIC_WOODCUTTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Woodcutter's Cloak",
      value: 800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_woodcutters_cloak.png",
    ),
  ),
  NOVICE_WOODCUTTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Woodcutter's Hat",
      value: 1600,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_woodcutters_hat.png",
    ),
  ),
  NOVICE_WOODCUTTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Woodcutter's Tunic",
      value: 1600,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_woodcutters_tunic.png",
    ),
  ),
  NOVICE_WOODCUTTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Woodcutter's Pants",
      value: 1600,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_woodcutters_pants.png",
    ),
  ),
  NOVICE_WOODCUTTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Woodcutter's Gloves",
      value: 1600,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_woodcutters_gloves.png",
    ),
  ),
  NOVICE_WOODCUTTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Woodcutter's Boots",
      value: 1600,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_woodcutters_boots.png",
    ),
  ),
  NOVICE_WOODCUTTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Woodcutter's Cloak",
      value: 1600,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_woodcutters_cloak.png",
    ),
  ),
  APPRENTICE_WOODCUTTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Woodcutter's Hat",
      value: 3200,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_woodcutters_hat.png",
    ),
  ),
  APPRENTICE_WOODCUTTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Woodcutter's Tunic",
      value: 3200,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_woodcutters_tunic.png",
    ),
  ),
  APPRENTICE_WOODCUTTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Woodcutter's Pants",
      value: 3200,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_woodcutters_pants.png",
    ),
  ),
  APPRENTICE_WOODCUTTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Woodcutter's Gloves",
      value: 3200,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_woodcutters_gloves.png",
    ),
  ),
  APPRENTICE_WOODCUTTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Woodcutter's Boots",
      value: 3200,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_woodcutters_boots.png",
    ),
  ),
  APPRENTICE_WOODCUTTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Woodcutter's Cloak",
      value: 3200,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_woodcutters_cloak.png",
    ),
  ),
  ADVANCED_WOODCUTTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Woodcutter's Hat",
      value: 6400,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_woodcutters_hat.png",
    ),
  ),
  ADVANCED_WOODCUTTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Woodcutter's Tunic",
      value: 6400,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_woodcutters_tunic.png",
    ),
  ),
  ADVANCED_WOODCUTTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Woodcutter's Pants",
      value: 6400,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_woodcutters_pants.png",
    ),
  ),
  ADVANCED_WOODCUTTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Woodcutter's Gloves",
      value: 6400,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_woodcutters_gloves.png",
    ),
  ),
  ADVANCED_WOODCUTTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Woodcutter's Boots",
      value: 6400,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_woodcutters_boots.png",
    ),
  ),
  ADVANCED_WOODCUTTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Woodcutter's Cloak",
      value: 6400,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_woodcutters_cloak.png",
    ),
  ),
  MASTER_WOODCUTTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Woodcutter's Hat",
      value: 12800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_woodcutters_hat.png",
    ),
  ),
  MASTER_WOODCUTTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Woodcutter's Tunic",
      value: 12800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_woodcutters_tunic.png",
    ),
  ),
  MASTER_WOODCUTTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Woodcutter's Pants",
      value: 12800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_woodcutters_pants.png",
    ),
  ),
  MASTER_WOODCUTTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Woodcutter's Gloves",
      value: 12800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_woodcutters_gloves.png",
    ),
  ),
  MASTER_WOODCUTTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Woodcutter's Boots",
      value: 12800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_woodcutters_boots.png",
    ),
  ),
  MASTER_WOODCUTTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Woodcutter's Cloak",
      value: 12800,
      skill: SkillId.WOODCUTTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_woodcutters_cloak.png",
    ),
  ),
  BASIC_HERBALISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Herbalist's Hat",
      value: 800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_herbalists_hat.png",
    ),
  ),
  BASIC_HERBALISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Herbalist's Tunic",
      value: 800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_herbalists_tunic.png",
    ),
  ),
  BASIC_HERBALISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Herbalist's Pants",
      value: 800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_herbalists_pants.png",
    ),
  ),
  BASIC_HERBALISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Herbalist's Gloves",
      value: 800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_herbalists_gloves.png",
    ),
  ),
  BASIC_HERBALISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Herbalist's Boots",
      value: 800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_herbalists_boots.png",
    ),
  ),
  BASIC_HERBALISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Herbalist's Cloak",
      value: 800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_herbalists_cloak.png",
    ),
  ),
  NOVICE_HERBALISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Herbalist's Hat",
      value: 1600,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_herbalists_hat.png",
    ),
  ),
  NOVICE_HERBALISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Herbalist's Tunic",
      value: 1600,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_herbalists_tunic.png",
    ),
  ),
  NOVICE_HERBALISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Herbalist's Pants",
      value: 1600,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_herbalists_pants.png",
    ),
  ),
  NOVICE_HERBALISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Herbalist's Gloves",
      value: 1600,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_herbalists_gloves.png",
    ),
  ),
  NOVICE_HERBALISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Herbalist's Boots",
      value: 1600,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_herbalists_boots.png",
    ),
  ),
  NOVICE_HERBALISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Herbalist's Cloak",
      value: 1600,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_herbalists_cloak.png",
    ),
  ),
  APPRENTICE_HERBALISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Herbalist's Hat",
      value: 3200,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_herbalists_hat.png",
    ),
  ),
  APPRENTICE_HERBALISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Herbalist's Tunic",
      value: 3200,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_herbalists_tunic.png",
    ),
  ),
  APPRENTICE_HERBALISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Herbalist's Pants",
      value: 3200,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_herbalists_pants.png",
    ),
  ),
  APPRENTICE_HERBALISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Herbalist's Gloves",
      value: 3200,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_herbalists_gloves.png",
    ),
  ),
  APPRENTICE_HERBALISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Herbalist's Boots",
      value: 3200,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_herbalists_boots.png",
    ),
  ),
  APPRENTICE_HERBALISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Herbalist's Cloak",
      value: 3200,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_herbalists_cloak.png",
    ),
  ),
  ADVANCED_HERBALISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Herbalist's Hat",
      value: 6400,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_herbalists_hat.png",
    ),
  ),
  ADVANCED_HERBALISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Herbalist's Tunic",
      value: 6400,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_herbalists_tunic.png",
    ),
  ),
  ADVANCED_HERBALISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Herbalist's Pants",
      value: 6400,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_herbalists_pants.png",
    ),
  ),
  ADVANCED_HERBALISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Herbalist's Gloves",
      value: 6400,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_herbalists_gloves.png",
    ),
  ),
  ADVANCED_HERBALISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Herbalist's Boots",
      value: 6400,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_herbalists_boots.png",
    ),
  ),
  ADVANCED_HERBALISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Herbalist's Cloak",
      value: 6400,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_herbalists_cloak.png",
    ),
  ),
  MASTER_HERBALISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Herbalist's Hat",
      value: 12800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_herbalists_hat.png",
    ),
  ),
  MASTER_HERBALISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Herbalist's Tunic",
      value: 12800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_herbalists_tunic.png",
    ),
  ),
  MASTER_HERBALISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Herbalist's Pants",
      value: 12800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_herbalists_pants.png",
    ),
  ),
  MASTER_HERBALISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Herbalist's Gloves",
      value: 12800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_herbalists_gloves.png",
    ),
  ),
  MASTER_HERBALISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Herbalist's Boots",
      value: 12800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_herbalists_boots.png",
    ),
  ),
  MASTER_HERBALISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Herbalist's Cloak",
      value: 12800,
      skill: SkillId.HERBALISM,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_herbalists_cloak.png",
    ),
  ),
  BASIC_FIREMAKERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Firemaker's Hat",
      value: 800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_firemakers_hat.png",
    ),
  ),
  BASIC_FIREMAKERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Firemaker's Tunic",
      value: 800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_firemakers_tunic.png",
    ),
  ),
  BASIC_FIREMAKERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Firemaker's Pants",
      value: 800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_firemakers_pants.png",
    ),
  ),
  BASIC_FIREMAKERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Firemaker's Gloves",
      value: 800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_firemakers_gloves.png",
    ),
  ),
  BASIC_FIREMAKERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Firemaker's Boots",
      value: 800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_firemakers_boots.png",
    ),
  ),
  BASIC_FIREMAKERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Firemaker's Cloak",
      value: 800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_firemakers_cloak.png",
    ),
  ),
  NOVICE_FIREMAKERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Firemaker's Hat",
      value: 1600,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_firemakers_hat.png",
    ),
  ),
  NOVICE_FIREMAKERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Firemaker's Tunic",
      value: 1600,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_firemakers_tunic.png",
    ),
  ),
  NOVICE_FIREMAKERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Firemaker's Pants",
      value: 1600,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_firemakers_pants.png",
    ),
  ),
  NOVICE_FIREMAKERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Firemaker's Gloves",
      value: 1600,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_firemakers_gloves.png",
    ),
  ),
  NOVICE_FIREMAKERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Firemaker's Boots",
      value: 1600,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_firemakers_boots.png",
    ),
  ),
  NOVICE_FIREMAKERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Firemaker's Cloak",
      value: 1600,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_firemakers_cloak.png",
    ),
  ),
  APPRENTICE_FIREMAKERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Firemaker's Hat",
      value: 3200,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_firemakers_hat.png",
    ),
  ),
  APPRENTICE_FIREMAKERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Firemaker's Tunic",
      value: 3200,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_firemakers_tunic.png",
    ),
  ),
  APPRENTICE_FIREMAKERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Firemaker's Pants",
      value: 3200,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_firemakers_pants.png",
    ),
  ),
  APPRENTICE_FIREMAKERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Firemaker's Gloves",
      value: 3200,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_firemakers_gloves.png",
    ),
  ),
  APPRENTICE_FIREMAKERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Firemaker's Boots",
      value: 3200,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_firemakers_boots.png",
    ),
  ),
  APPRENTICE_FIREMAKERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Firemaker's Cloak",
      value: 3200,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_firemakers_cloak.png",
    ),
  ),
  ADVANCED_FIREMAKERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Firemaker's Hat",
      value: 6400,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_firemakers_hat.png",
    ),
  ),
  ADVANCED_FIREMAKERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Firemaker's Tunic",
      value: 6400,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_firemakers_tunic.png",
    ),
  ),
  ADVANCED_FIREMAKERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Firemaker's Pants",
      value: 6400,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_firemakers_pants.png",
    ),
  ),
  ADVANCED_FIREMAKERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Firemaker's Gloves",
      value: 6400,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_firemakers_gloves.png",
    ),
  ),
  ADVANCED_FIREMAKERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Firemaker's Boots",
      value: 6400,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_firemakers_boots.png",
    ),
  ),
  ADVANCED_FIREMAKERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Firemaker's Cloak",
      value: 6400,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_firemakers_cloak.png",
    ),
  ),
  MASTER_FIREMAKERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Firemaker's Hat",
      value: 12800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_firemakers_hat.png",
    ),
  ),
  MASTER_FIREMAKERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Firemaker's Tunic",
      value: 12800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_firemakers_tunic.png",
    ),
  ),
  MASTER_FIREMAKERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Firemaker's Pants",
      value: 12800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_firemakers_pants.png",
    ),
  ),
  MASTER_FIREMAKERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Firemaker's Gloves",
      value: 12800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_firemakers_gloves.png",
    ),
  ),
  MASTER_FIREMAKERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Firemaker's Boots",
      value: 12800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_firemakers_boots.png",
    ),
  ),
  MASTER_FIREMAKERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Firemaker's Cloak",
      value: 12800,
      skill: SkillId.FIREMAKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_firemakers_cloak.png",
    ),
  ),
  BASIC_COOKS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Cook's Hat",
      value: 800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_cooks_hat.png",
    ),
  ),
  BASIC_COOKS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Cook's Tunic",
      value: 800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_cooks_tunic.png",
    ),
  ),
  BASIC_COOKS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Cook's Pants",
      value: 800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_cooks_pants.png",
    ),
  ),
  BASIC_COOKS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Cook's Gloves",
      value: 800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_cooks_gloves.png",
    ),
  ),
  BASIC_COOKS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Cook's Boots",
      value: 800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_cooks_boots.png",
    ),
  ),
  BASIC_COOKS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Cook's Cloak",
      value: 800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_cooks_cloak.png",
    ),
  ),
  NOVICE_COOKS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Cook's Hat",
      value: 1600,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_cooks_hat.png",
    ),
  ),
  NOVICE_COOKS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Cook's Tunic",
      value: 1600,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_cooks_tunic.png",
    ),
  ),
  NOVICE_COOKS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Cook's Pants",
      value: 1600,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_cooks_pants.png",
    ),
  ),
  NOVICE_COOKS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Cook's Gloves",
      value: 1600,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_cooks_gloves.png",
    ),
  ),
  NOVICE_COOKS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Cook's Boots",
      value: 1600,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_cooks_boots.png",
    ),
  ),
  NOVICE_COOKS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Cook's Cloak",
      value: 1600,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_cooks_cloak.png",
    ),
  ),
  APPRENTICE_COOKS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Cook's Hat",
      value: 3200,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_cooks_hat.png",
    ),
  ),
  APPRENTICE_COOKS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Cook's Tunic",
      value: 3200,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_cooks_tunic.png",
    ),
  ),
  APPRENTICE_COOKS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Cook's Pants",
      value: 3200,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_cooks_pants.png",
    ),
  ),
  APPRENTICE_COOKS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Cook's Gloves",
      value: 3200,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_cooks_gloves.png",
    ),
  ),
  APPRENTICE_COOKS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Cook's Boots",
      value: 3200,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_cooks_boots.png",
    ),
  ),
  APPRENTICE_COOKS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Cook's Cloak",
      value: 3200,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_cooks_cloak.png",
    ),
  ),
  ADVANCED_COOKS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Cook's Hat",
      value: 6400,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_cooks_hat.png",
    ),
  ),
  ADVANCED_COOKS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Cook's Tunic",
      value: 6400,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_cooks_tunic.png",
    ),
  ),
  ADVANCED_COOKS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Cook's Pants",
      value: 6400,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_cooks_pants.png",
    ),
  ),
  ADVANCED_COOKS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Cook's Gloves",
      value: 6400,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_cooks_gloves.png",
    ),
  ),
  ADVANCED_COOKS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Cook's Boots",
      value: 6400,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_cooks_boots.png",
    ),
  ),
  ADVANCED_COOKS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Cook's Cloak",
      value: 6400,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_cooks_cloak.png",
    ),
  ),
  MASTER_COOKS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Cook's Hat",
      value: 12800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_cooks_hat.png",
    ),
  ),
  MASTER_COOKS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Cook's Tunic",
      value: 12800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_cooks_tunic.png",
    ),
  ),
  MASTER_COOKS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Cook's Pants",
      value: 12800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_cooks_pants.png",
    ),
  ),
  MASTER_COOKS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Cook's Gloves",
      value: 12800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_cooks_gloves.png",
    ),
  ),
  MASTER_COOKS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Cook's Boots",
      value: 12800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_cooks_boots.png",
    ),
  ),
  MASTER_COOKS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Cook's Cloak",
      value: 12800,
      skill: SkillId.COOKING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_cooks_cloak.png",
    ),
  ),
  BASIC_BLACKSMITHS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Blacksmith's Hat",
      value: 800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_blacksmiths_hat.png",
    ),
  ),
  BASIC_BLACKSMITHS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Blacksmith's Tunic",
      value: 800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_blacksmiths_tunic.png",
    ),
  ),
  BASIC_BLACKSMITHS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Blacksmith's Pants",
      value: 800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_blacksmiths_pants.png",
    ),
  ),
  BASIC_BLACKSMITHS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Blacksmith's Gloves",
      value: 800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_blacksmiths_gloves.png",
    ),
  ),
  BASIC_BLACKSMITHS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Blacksmith's Boots",
      value: 800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_blacksmiths_boots.png",
    ),
  ),
  BASIC_BLACKSMITHS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Blacksmith's Cloak",
      value: 800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_blacksmiths_cloak.png",
    ),
  ),
  NOVICE_BLACKSMITHS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Blacksmith's Hat",
      value: 1600,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_blacksmiths_hat.png",
    ),
  ),
  NOVICE_BLACKSMITHS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Blacksmith's Tunic",
      value: 1600,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_blacksmiths_tunic.png",
    ),
  ),
  NOVICE_BLACKSMITHS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Blacksmith's Pants",
      value: 1600,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_blacksmiths_pants.png",
    ),
  ),
  NOVICE_BLACKSMITHS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Blacksmith's Gloves",
      value: 1600,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_blacksmiths_gloves.png",
    ),
  ),
  NOVICE_BLACKSMITHS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Blacksmith's Boots",
      value: 1600,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_blacksmiths_boots.png",
    ),
  ),
  NOVICE_BLACKSMITHS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Blacksmith's Cloak",
      value: 1600,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_blacksmiths_cloak.png",
    ),
  ),
  APPRENTICE_BLACKSMITHS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Blacksmith's Hat",
      value: 3200,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_blacksmiths_hat.png",
    ),
  ),
  APPRENTICE_BLACKSMITHS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Blacksmith's Tunic",
      value: 3200,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_blacksmiths_tunic.png",
    ),
  ),
  APPRENTICE_BLACKSMITHS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Blacksmith's Pants",
      value: 3200,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_blacksmiths_pants.png",
    ),
  ),
  APPRENTICE_BLACKSMITHS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Blacksmith's Gloves",
      value: 3200,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_blacksmiths_gloves.png",
    ),
  ),
  APPRENTICE_BLACKSMITHS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Blacksmith's Boots",
      value: 3200,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_blacksmiths_boots.png",
    ),
  ),
  APPRENTICE_BLACKSMITHS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Blacksmith's Cloak",
      value: 3200,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_blacksmiths_cloak.png",
    ),
  ),
  ADVANCED_BLACKSMITHS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Blacksmith's Hat",
      value: 6400,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_blacksmiths_hat.png",
    ),
  ),
  ADVANCED_BLACKSMITHS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Blacksmith's Tunic",
      value: 6400,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_blacksmiths_tunic.png",
    ),
  ),
  ADVANCED_BLACKSMITHS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Blacksmith's Pants",
      value: 6400,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_blacksmiths_pants.png",
    ),
  ),
  ADVANCED_BLACKSMITHS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Blacksmith's Gloves",
      value: 6400,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_blacksmiths_gloves.png",
    ),
  ),
  ADVANCED_BLACKSMITHS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Blacksmith's Boots",
      value: 6400,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_blacksmiths_boots.png",
    ),
  ),
  ADVANCED_BLACKSMITHS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Blacksmith's Cloak",
      value: 6400,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_blacksmiths_cloak.png",
    ),
  ),
  MASTER_BLACKSMITHS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Blacksmith's Hat",
      value: 12800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_blacksmiths_hat.png",
    ),
  ),
  MASTER_BLACKSMITHS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Blacksmith's Tunic",
      value: 12800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_blacksmiths_tunic.png",
    ),
  ),
  MASTER_BLACKSMITHS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Blacksmith's Pants",
      value: 12800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_blacksmiths_pants.png",
    ),
  ),
  MASTER_BLACKSMITHS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Blacksmith's Gloves",
      value: 12800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_blacksmiths_gloves.png",
    ),
  ),
  MASTER_BLACKSMITHS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Blacksmith's Boots",
      value: 12800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_blacksmiths_boots.png",
    ),
  ),
  MASTER_BLACKSMITHS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Blacksmith's Cloak",
      value: 12800,
      skill: SkillId.BLACKSMITHING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_blacksmiths_cloak.png",
    ),
  ),
  BASIC_ENCHANTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Enchanter's Hat",
      value: 800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_enchanters_hat.png",
    ),
  ),
  BASIC_ENCHANTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Enchanter's Tunic",
      value: 800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_enchanters_tunic.png",
    ),
  ),
  BASIC_ENCHANTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Enchanter's Pants",
      value: 800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_enchanters_pants.png",
    ),
  ),
  BASIC_ENCHANTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Enchanter's Gloves",
      value: 800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_enchanters_gloves.png",
    ),
  ),
  BASIC_ENCHANTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Enchanter's Boots",
      value: 800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_enchanters_boots.png",
    ),
  ),
  BASIC_ENCHANTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Enchanter's Cloak",
      value: 800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_enchanters_cloak.png",
    ),
  ),
  NOVICE_ENCHANTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Enchanter's Hat",
      value: 1600,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_enchanters_hat.png",
    ),
  ),
  NOVICE_ENCHANTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Enchanter's Tunic",
      value: 1600,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_enchanters_tunic.png",
    ),
  ),
  NOVICE_ENCHANTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Enchanter's Pants",
      value: 1600,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_enchanters_pants.png",
    ),
  ),
  NOVICE_ENCHANTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Enchanter's Gloves",
      value: 1600,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_enchanters_gloves.png",
    ),
  ),
  NOVICE_ENCHANTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Enchanter's Boots",
      value: 1600,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_enchanters_boots.png",
    ),
  ),
  NOVICE_ENCHANTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Enchanter's Cloak",
      value: 1600,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_enchanters_cloak.png",
    ),
  ),
  APPRENTICE_ENCHANTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Enchanter's Hat",
      value: 3200,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_enchanters_hat.png",
    ),
  ),
  APPRENTICE_ENCHANTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Enchanter's Tunic",
      value: 3200,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_enchanters_tunic.png",
    ),
  ),
  APPRENTICE_ENCHANTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Enchanter's Pants",
      value: 3200,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_enchanters_pants.png",
    ),
  ),
  APPRENTICE_ENCHANTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Enchanter's Gloves",
      value: 3200,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_enchanters_gloves.png",
    ),
  ),
  APPRENTICE_ENCHANTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Enchanter's Boots",
      value: 3200,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_enchanters_boots.png",
    ),
  ),
  APPRENTICE_ENCHANTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Enchanter's Cloak",
      value: 3200,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_enchanters_cloak.png",
    ),
  ),
  ADVANCED_ENCHANTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Enchanter's Hat",
      value: 6400,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_enchanters_hat.png",
    ),
  ),
  ADVANCED_ENCHANTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Enchanter's Tunic",
      value: 6400,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_enchanters_tunic.png",
    ),
  ),
  ADVANCED_ENCHANTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Enchanter's Pants",
      value: 6400,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_enchanters_pants.png",
    ),
  ),
  ADVANCED_ENCHANTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Enchanter's Gloves",
      value: 6400,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_enchanters_gloves.png",
    ),
  ),
  ADVANCED_ENCHANTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Enchanter's Boots",
      value: 6400,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_enchanters_boots.png",
    ),
  ),
  ADVANCED_ENCHANTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Enchanter's Cloak",
      value: 6400,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_enchanters_cloak.png",
    ),
  ),
  MASTER_ENCHANTERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Enchanter's Hat",
      value: 12800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_enchanters_hat.png",
    ),
  ),
  MASTER_ENCHANTERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Enchanter's Tunic",
      value: 12800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_enchanters_tunic.png",
    ),
  ),
  MASTER_ENCHANTERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Enchanter's Pants",
      value: 12800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_enchanters_pants.png",
    ),
  ),
  MASTER_ENCHANTERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Enchanter's Gloves",
      value: 12800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_enchanters_gloves.png",
    ),
  ),
  MASTER_ENCHANTERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Enchanter's Boots",
      value: 12800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_enchanters_boots.png",
    ),
  ),
  MASTER_ENCHANTERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Enchanter's Cloak",
      value: 12800,
      skill: SkillId.ENCHANTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_enchanters_cloak.png",
    ),
  ),
  BASIC_JEWELERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Jeweler's Hat",
      value: 800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_jewelers_hat.png",
    ),
  ),
  BASIC_JEWELERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Jeweler's Tunic",
      value: 800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_jewelers_tunic.png",
    ),
  ),
  BASIC_JEWELERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Jeweler's Pants",
      value: 800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_jewelers_pants.png",
    ),
  ),
  BASIC_JEWELERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Jeweler's Gloves",
      value: 800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_jewelers_gloves.png",
    ),
  ),
  BASIC_JEWELERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Jeweler's Boots",
      value: 800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_jewelers_boots.png",
    ),
  ),
  BASIC_JEWELERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Jeweler's Cloak",
      value: 800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_jewelers_cloak.png",
    ),
  ),
  NOVICE_JEWELERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Jeweler's Hat",
      value: 1600,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_jewelers_hat.png",
    ),
  ),
  NOVICE_JEWELERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Jeweler's Tunic",
      value: 1600,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_jewelers_tunic.png",
    ),
  ),
  NOVICE_JEWELERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Jeweler's Pants",
      value: 1600,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_jewelers_pants.png",
    ),
  ),
  NOVICE_JEWELERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Jeweler's Gloves",
      value: 1600,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_jewelers_gloves.png",
    ),
  ),
  NOVICE_JEWELERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Jeweler's Boots",
      value: 1600,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_jewelers_boots.png",
    ),
  ),
  NOVICE_JEWELERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Jeweler's Cloak",
      value: 1600,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_jewelers_cloak.png",
    ),
  ),
  APPRENTICE_JEWELERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Jeweler's Hat",
      value: 3200,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_jewelers_hat.png",
    ),
  ),
  APPRENTICE_JEWELERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Jeweler's Tunic",
      value: 3200,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_jewelers_tunic.png",
    ),
  ),
  APPRENTICE_JEWELERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Jeweler's Pants",
      value: 3200,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_jewelers_pants.png",
    ),
  ),
  APPRENTICE_JEWELERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Jeweler's Gloves",
      value: 3200,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_jewelers_gloves.png",
    ),
  ),
  APPRENTICE_JEWELERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Jeweler's Boots",
      value: 3200,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_jewelers_boots.png",
    ),
  ),
  APPRENTICE_JEWELERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Jeweler's Cloak",
      value: 3200,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_jewelers_cloak.png",
    ),
  ),
  ADVANCED_JEWELERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Jeweler's Hat",
      value: 6400,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_jewelers_hat.png",
    ),
  ),
  ADVANCED_JEWELERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Jeweler's Tunic",
      value: 6400,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_jewelers_tunic.png",
    ),
  ),
  ADVANCED_JEWELERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Jeweler's Pants",
      value: 6400,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_jewelers_pants.png",
    ),
  ),
  ADVANCED_JEWELERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Jeweler's Gloves",
      value: 6400,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_jewelers_gloves.png",
    ),
  ),
  ADVANCED_JEWELERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Jeweler's Boots",
      value: 6400,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_jewelers_boots.png",
    ),
  ),
  ADVANCED_JEWELERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Jeweler's Cloak",
      value: 6400,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_jewelers_cloak.png",
    ),
  ),
  MASTER_JEWELERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Jeweler's Hat",
      value: 12800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_jewelers_hat.png",
    ),
  ),
  MASTER_JEWELERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Jeweler's Tunic",
      value: 12800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_jewelers_tunic.png",
    ),
  ),
  MASTER_JEWELERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Jeweler's Pants",
      value: 12800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_jewelers_pants.png",
    ),
  ),
  MASTER_JEWELERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Jeweler's Gloves",
      value: 12800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_jewelers_gloves.png",
    ),
  ),
  MASTER_JEWELERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Jeweler's Boots",
      value: 12800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_jewelers_boots.png",
    ),
  ),
  MASTER_JEWELERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Jeweler's Cloak",
      value: 12800,
      skill: SkillId.JEWELCRAFTING,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_jewelers_cloak.png",
    ),
  ),
  BASIC_ALCHEMISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Alchemist's Hat",
      value: 800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_alchemists_hat.png",
    ),
  ),
  BASIC_ALCHEMISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Alchemist's Tunic",
      value: 800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_alchemists_tunic.png",
    ),
  ),
  BASIC_ALCHEMISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Alchemist's Pants",
      value: 800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_alchemists_pants.png",
    ),
  ),
  BASIC_ALCHEMISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Alchemist's Gloves",
      value: 800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_alchemists_gloves.png",
    ),
  ),
  BASIC_ALCHEMISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Alchemist's Boots",
      value: 800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_alchemists_boots.png",
    ),
  ),
  BASIC_ALCHEMISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Alchemist's Cloak",
      value: 800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_alchemists_cloak.png",
    ),
  ),
  NOVICE_ALCHEMISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Alchemist's Hat",
      value: 1600,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_alchemists_hat.png",
    ),
  ),
  NOVICE_ALCHEMISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Alchemist's Tunic",
      value: 1600,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_alchemists_tunic.png",
    ),
  ),
  NOVICE_ALCHEMISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Alchemist's Pants",
      value: 1600,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_alchemists_pants.png",
    ),
  ),
  NOVICE_ALCHEMISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Alchemist's Gloves",
      value: 1600,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_alchemists_gloves.png",
    ),
  ),
  NOVICE_ALCHEMISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Alchemist's Boots",
      value: 1600,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_alchemists_boots.png",
    ),
  ),
  NOVICE_ALCHEMISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Alchemist's Cloak",
      value: 1600,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_alchemists_cloak.png",
    ),
  ),
  APPRENTICE_ALCHEMISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Alchemist's Hat",
      value: 3200,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_alchemists_hat.png",
    ),
  ),
  APPRENTICE_ALCHEMISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Alchemist's Tunic",
      value: 3200,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_alchemists_tunic.png",
    ),
  ),
  APPRENTICE_ALCHEMISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Alchemist's Pants",
      value: 3200,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_alchemists_pants.png",
    ),
  ),
  APPRENTICE_ALCHEMISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Alchemist's Gloves",
      value: 3200,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_alchemists_gloves.png",
    ),
  ),
  APPRENTICE_ALCHEMISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Alchemist's Boots",
      value: 3200,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_alchemists_boots.png",
    ),
  ),
  APPRENTICE_ALCHEMISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Alchemist's Cloak",
      value: 3200,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_alchemists_cloak.png",
    ),
  ),
  ADVANCED_ALCHEMISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Alchemist's Hat",
      value: 6400,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_alchemists_hat.png",
    ),
  ),
  ADVANCED_ALCHEMISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Alchemist's Tunic",
      value: 6400,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_alchemists_tunic.png",
    ),
  ),
  ADVANCED_ALCHEMISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Alchemist's Pants",
      value: 6400,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_alchemists_pants.png",
    ),
  ),
  ADVANCED_ALCHEMISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Alchemist's Gloves",
      value: 6400,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_alchemists_gloves.png",
    ),
  ),
  ADVANCED_ALCHEMISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Alchemist's Boots",
      value: 6400,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_alchemists_boots.png",
    ),
  ),
  ADVANCED_ALCHEMISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Alchemist's Cloak",
      value: 6400,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_alchemists_cloak.png",
    ),
  ),
  MASTER_ALCHEMISTS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Alchemist's Hat",
      value: 12800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_alchemists_hat.png",
    ),
  ),
  MASTER_ALCHEMISTS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Alchemist's Tunic",
      value: 12800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_alchemists_tunic.png",
    ),
  ),
  MASTER_ALCHEMISTS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Alchemist's Pants",
      value: 12800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_alchemists_pants.png",
    ),
  ),
  MASTER_ALCHEMISTS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Alchemist's Gloves",
      value: 12800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_alchemists_gloves.png",
    ),
  ),
  MASTER_ALCHEMISTS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Alchemist's Boots",
      value: 12800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_alchemists_boots.png",
    ),
  ),
  MASTER_ALCHEMISTS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Alchemist's Cloak",
      value: 12800,
      skill: SkillId.ALCHEMY,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_alchemists_cloak.png",
    ),
  ),
  BASIC_EXPLORERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Basic Explorer's Hat",
      value: 800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_explorers_hat.png",
    ),
  ),
  BASIC_EXPLORERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Basic Explorer's Tunic",
      value: 800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_explorers_tunic.png",
    ),
  ),
  BASIC_EXPLORERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Basic Explorer's Pants",
      value: 800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_explorers_pants.png",
    ),
  ),
  BASIC_EXPLORERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Basic Explorer's Gloves",
      value: 800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_explorers_gloves.png",
    ),
  ),
  BASIC_EXPLORERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Basic Explorer's Boots",
      value: 800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_explorers_boots.png",
    ),
  ),
  BASIC_EXPLORERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Basic Explorer's Cloak",
      value: 800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.BASIC,
      iconAsset: "assets/icons/items/basic_explorers_cloak.png",
    ),
  ),
  NOVICE_EXPLORERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Novice Explorer's Hat",
      value: 1600,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_explorers_hat.png",
    ),
  ),
  NOVICE_EXPLORERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Novice Explorer's Tunic",
      value: 1600,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_explorers_tunic.png",
    ),
  ),
  NOVICE_EXPLORERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Novice Explorer's Pants",
      value: 1600,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_explorers_pants.png",
    ),
  ),
  NOVICE_EXPLORERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Novice Explorer's Gloves",
      value: 1600,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_explorers_gloves.png",
    ),
  ),
  NOVICE_EXPLORERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Novice Explorer's Boots",
      value: 1600,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_explorers_boots.png",
    ),
  ),
  NOVICE_EXPLORERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Novice Explorer's Cloak",
      value: 1600,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.NOVICE,
      iconAsset: "assets/icons/items/novice_explorers_cloak.png",
    ),
  ),
  APPRENTICE_EXPLORERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Apprentice Explorer's Hat",
      value: 3200,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_explorers_hat.png",
    ),
  ),
  APPRENTICE_EXPLORERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Apprentice Explorer's Tunic",
      value: 3200,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_explorers_tunic.png",
    ),
  ),
  APPRENTICE_EXPLORERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Apprentice Explorer's Pants",
      value: 3200,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_explorers_pants.png",
    ),
  ),
  APPRENTICE_EXPLORERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Apprentice Explorer's Gloves",
      value: 3200,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_explorers_gloves.png",
    ),
  ),
  APPRENTICE_EXPLORERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Apprentice Explorer's Boots",
      value: 3200,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_explorers_boots.png",
    ),
  ),
  APPRENTICE_EXPLORERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Apprentice Explorer's Cloak",
      value: 3200,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.APPRENTICE,
      iconAsset: "assets/icons/items/apprentice_explorers_cloak.png",
    ),
  ),
  ADVANCED_EXPLORERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Advanced Explorer's Hat",
      value: 6400,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_explorers_hat.png",
    ),
  ),
  ADVANCED_EXPLORERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Advanced Explorer's Tunic",
      value: 6400,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_explorers_tunic.png",
    ),
  ),
  ADVANCED_EXPLORERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Advanced Explorer's Pants",
      value: 6400,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_explorers_pants.png",
    ),
  ),
  ADVANCED_EXPLORERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Advanced Explorer's Gloves",
      value: 6400,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_explorers_gloves.png",
    ),
  ),
  ADVANCED_EXPLORERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Advanced Explorer's Boots",
      value: 6400,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_explorers_boots.png",
    ),
  ),
  ADVANCED_EXPLORERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Advanced Explorer's Cloak",
      value: 6400,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.ADVANCED,
      iconAsset: "assets/icons/items/advanced_explorers_cloak.png",
    ),
  ),
  MASTER_EXPLORERS_HAT(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Master Explorer's Hat",
      value: 12800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_explorers_hat.png",
    ),
  ),
  MASTER_EXPLORERS_TUNIC(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Master Explorer's Tunic",
      value: 12800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_explorers_tunic.png",
    ),
  ),
  MASTER_EXPLORERS_PANTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Master Explorer's Pants",
      value: 12800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_explorers_pants.png",
    ),
  ),
  MASTER_EXPLORERS_GLOVES(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Master Explorer's Gloves",
      value: 12800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_explorers_gloves.png",
    ),
  ),
  MASTER_EXPLORERS_BOOTS(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Master Explorer's Boots",
      value: 12800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_explorers_boots.png",
    ),
  ),
  MASTER_EXPLORERS_CLOAK(
    SkillingGearDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Master Explorer's Cloak",
      value: 12800,
      skill: SkillId.EXPLORATION,
      tier: SkillingGearTier.MASTER,
      iconAsset: "assets/icons/items/master_explorers_cloak.png",
    ),
  ),

  // ── ARMOUR · LEGS ───────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Light Leather Pants",
      value: 100,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_pants.png",
    ),
  ),
  MEDIUM_LEATHER_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Medium Leather Pants",
      value: 200,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_pants.png",
    ),
  ),
  HEAVY_LEATHER_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Heavy Leather Pants",
      value: 400,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_pants.png",
    ),
  ),
  LIGHT_DRAGONHIDE_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Light Dragonhide Pants",
      value: 800,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_pants.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Medium Dragonhide Pants",
      value: 1600,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_pants.png",
    ),
  ),
  HEAVY_DRAGONHIDE_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Heavy Dragonhide Pants",
      value: 3200,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_pants.png",
    ),
  ),
  LIGHT_DEMONHIDE_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Light Demonhide Pants",
      value: 6400,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_pants.png",
    ),
  ),
  MEDIUM_DEMONHIDE_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Medium Demonhide Pants",
      value: 12800,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_pants.png",
    ),
  ),
  HEAVY_DEMONHIDE_PANTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Heavy Demonhide Pants",
      value: 25600,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_pants.png",
    ),
  ),
  COPPER_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Copper Leggings",
      value: 20,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_legs.png",
    ),
  ),
  IRON_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Iron Leggings",
      value: 40,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_legs.png",
    ),
  ),
  STEEL_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Steel Leggings",
      value: 80,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_legs.png",
    ),
  ),
  MITHRIL_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Mithril Leggings",
      value: 160,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_legs.png",
    ),
  ),
  ADAMANT_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Adamant Leggings",
      value: 320,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_legs.png",
    ),
  ),
  RUNE_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Rune Leggings",
      value: 640,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_legs.png",
    ),
  ),
  DRAGON_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Dragon Leggings",
      value: 1280,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_legs.png",
    ),
  ),

  // ── ARMOUR · BOOTS ──────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Light Leather Boots",
      value: 50,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_boots.png",
    ),
  ),
  MEDIUM_LEATHER_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Medium Leather Boots",
      value: 100,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_boots.png",
    ),
  ),
  HEAVY_LEATHER_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Heavy Leather Boots",
      value: 200,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_boots.png",
    ),
  ),
  LIGHT_DRAGONHIDE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Light Dragonhide Boots",
      value: 400,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_boots.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Medium Dragonhide Boots",
      value: 800,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_boots.png",
    ),
  ),
  HEAVY_DRAGONHIDE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Heavy Dragonhide Boots",
      value: 1600,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_boots.png",
    ),
  ),
  LIGHT_DEMONHIDE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Light Demonhide Boots",
      value: 3200,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_boots.png",
    ),
  ),
  MEDIUM_DEMONHIDE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Medium Demonhide Boots",
      value: 6400,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_boots.png",
    ),
  ),
  HEAVY_DEMONHIDE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Heavy Demonhide Boots",
      value: 12800,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_boots.png",
    ),
  ),
  COPPER_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Copper Boots",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_boots.png",
    ),
  ),
  IRON_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Iron Boots",
      value: 20,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_boots.png",
    ),
  ),
  STEEL_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Steel Boots",
      value: 40,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_boots.png",
    ),
  ),
  MITHRIL_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Mithril Boots",
      value: 80,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_boots.png",
    ),
  ),
  ADAMANT_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Adamant Boots",
      value: 160,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_boots.png",
    ),
  ),
  RUNE_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Rune Boots",
      value: 320,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_boots.png",
    ),
  ),
  DRAGON_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Dragon Boots",
      value: 640,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_boots.png",
    ),
  ),

  // ── ARMOUR · GLOVES ─────────────────────────────────────────────
  // tier ascending
  LIGHT_LEATHER_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Light Leather Gloves",
      value: 50,
      materialId: EquipmentMaterialId.LIGHT_LEATHER,
      iconAsset: "assets/icons/items/light_leather_gloves.png",
    ),
  ),
  MEDIUM_LEATHER_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Medium Leather Gloves",
      value: 100,
      materialId: EquipmentMaterialId.MEDIUM_LEATHER,
      iconAsset: "assets/icons/items/medium_leather_gloves.png",
    ),
  ),
  HEAVY_LEATHER_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Heavy Leather Gloves",
      value: 200,
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_gloves.png",
    ),
  ),
  LIGHT_DRAGONHIDE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Light Dragonhide Gloves",
      value: 400,
      materialId: EquipmentMaterialId.LIGHT_DRAGONHIDE,
      iconAsset: "assets/icons/items/light_dragonhide_gloves.png",
    ),
  ),
  MEDIUM_DRAGONHIDE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Medium Dragonhide Gloves",
      value: 800,
      materialId: EquipmentMaterialId.MEDIUM_DRAGONHIDE,
      iconAsset: "assets/icons/items/medium_dragonhide_gloves.png",
    ),
  ),
  HEAVY_DRAGONHIDE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Heavy Dragonhide Gloves",
      value: 1600,
      materialId: EquipmentMaterialId.HEAVY_DRAGONHIDE,
      iconAsset: "assets/icons/items/heavy_dragonhide_gloves.png",
    ),
  ),
  LIGHT_DEMONHIDE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Light Demonhide Gloves",
      value: 3200,
      materialId: EquipmentMaterialId.LIGHT_DEMONHIDE,
      iconAsset: "assets/icons/items/light_demonhide_gloves.png",
    ),
  ),
  MEDIUM_DEMONHIDE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Medium Demonhide Gloves",
      value: 6400,
      materialId: EquipmentMaterialId.MEDIUM_DEMONHIDE,
      iconAsset: "assets/icons/items/medium_demonhide_gloves.png",
    ),
  ),
  HEAVY_DEMONHIDE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Heavy Demonhide Gloves",
      value: 12800,
      materialId: EquipmentMaterialId.HEAVY_DEMONHIDE,
      iconAsset: "assets/icons/items/heavy_demonhide_gloves.png",
    ),
  ),
  COPPER_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Copper Gloves",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_gloves.png",
    ),
  ),
  IRON_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Iron Gloves",
      value: 20,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_gloves.png",
    ),
  ),
  STEEL_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Steel Gloves",
      value: 40,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_gloves.png",
    ),
  ),
  MITHRIL_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Mithril Gloves",
      value: 80,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_gloves.png",
    ),
  ),
  ADAMANT_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Adamant Gloves",
      value: 160,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_gloves.png",
    ),
  ),
  RUNE_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Rune Gloves",
      value: 320,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_gloves.png",
    ),
  ),
  DRAGON_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Dragon Gloves",
      value: 640,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_gloves.png",
    ),
  ),

  // ── ARMOUR · SHIELD ─────────────────────────────────────────────
  // tier ascending
  COPPER_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Copper Shield",
      value: 15,
      materialId: EquipmentMaterialId.COPPER,
      iconAsset: "assets/icons/items/copper_shield.png",
    ),
  ),
  IRON_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Iron Shield",
      value: 30,
      materialId: EquipmentMaterialId.IRON,
      iconAsset: "assets/icons/items/iron_shield.png",
    ),
  ),
  STEEL_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Steel Shield",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      iconAsset: "assets/icons/items/steel_shield.png",
    ),
  ),
  MITHRIL_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Mithril Shield",
      value: 120,
      materialId: EquipmentMaterialId.MITHRIL,
      iconAsset: "assets/icons/items/mithril_shield.png",
    ),
  ),
  ADAMANT_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Adamant Shield",
      value: 240,
      materialId: EquipmentMaterialId.ADAMANT,
      iconAsset: "assets/icons/items/adamant_shield.png",
    ),
  ),
  RUNE_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Rune Shield",
      value: 480,
      materialId: EquipmentMaterialId.RUNE,
      iconAsset: "assets/icons/items/rune_shield.png",
    ),
  ),
  DRAGON_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Dragon Shield",
      value: 960,
      materialId: EquipmentMaterialId.DRAGON,
      iconAsset: "assets/icons/items/dragon_shield.png",
    ),
  ),
  // ── WEAPONS & TOOLS · 2H Swords ────────────────────────────────────
  // tier ascending
  COPPER_GREATSWORD(
    WeaponItemDefinition(
      name: "Copper Greatsword",
      value: 30,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/copper_greatsword.png",
    ),
  ),
  IRON_GREATSWORD(
    WeaponItemDefinition(
      name: "Iron Greatsword",
      value: 60,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/iron_greatsword.png",
    ),
  ),
  STEEL_GREATSWORD(
    WeaponItemDefinition(
      name: "Steel Greatsword",
      value: 120,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/steel_greatsword.png",
    ),
  ),
  MITHRIL_GREATSWORD(
    WeaponItemDefinition(
      name: "Mithril Greatsword",
      value: 240,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/mithril_greatsword.png",
    ),
  ),
  ADAMANT_GREATSWORD(
    WeaponItemDefinition(
      name: "Adamant Greatsword",
      value: 480,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/adamant_greatsword.png",
    ),
  ),
  RUNE_GREATSWORD(
    WeaponItemDefinition(
      name: "Rune Greatsword",
      value: 960,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/rune_greatsword.png",
    ),
  ),
  DRAGON_GREATSWORD(
    WeaponItemDefinition(
      name: "Dragon Greatsword",
      value: 1920,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.GREATSWORD,
      iconAsset: "assets/icons/items/dragon_greatsword.png",
    ),
  ),
  // ── WEAPONS & TOOLS · 1H Swords ────────────────────────────────────
  // tier ascending
  COPPER_SWORD(
    WeaponItemDefinition(
      name: "Copper Sword",
      value: 20,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/copper_sword.png",
    ),
  ),
  IRON_SWORD(
    WeaponItemDefinition(
      name: "Iron Sword",
      value: 40,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/iron_sword.png",
    ),
  ),
  STEEL_SWORD(
    WeaponItemDefinition(
      name: "Steel Sword",
      value: 80,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/steel_sword.png",
    ),
  ),
  MITHRIL_SWORD(
    WeaponItemDefinition(
      name: "Mithril Sword",
      value: 160,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/mithril_sword.png",
    ),
  ),
  ADAMANT_SWORD(
    WeaponItemDefinition(
      name: "Adamant Sword",
      value: 320,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/adamant_sword.png",
    ),
  ),
  RUNE_SWORD(
    WeaponItemDefinition(
      name: "Rune Sword",
      value: 640,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/rune_sword.png",
    ),
  ),
  DRAGON_SWORD(
    WeaponItemDefinition(
      name: "Dragon Sword",
      value: 1280,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.SWORD,
      iconAsset: "assets/icons/items/dragon_sword.png",
    ),
  ),
  // ── WEAPONS & TOOLS · DAGGER ────────────────────────────────────
  // tier ascending
  COPPER_DAGGER(
    WeaponItemDefinition(
      name: "Copper Dagger",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/copper_dagger.png",
    ),
  ),
  IRON_DAGGER(
    WeaponItemDefinition(
      name: "Iron Dagger",
      value: 25,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/iron_dagger.png",
    ),
  ),
  FISHBONE_DAGGER(
    WeaponItemDefinition(
      name: "Fishbone Dagger",
      value: 25,
      weaponType: WeaponTypeId.DAGGER,
      fibLevel: 2,
      iconAsset: "assets/icons/items/fishbone_dagger.png",
    ),
  ),
  STEEL_DAGGER(
    WeaponItemDefinition(
      name: "Steel Dagger",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/steel_dagger.png",
    ),
  ),
  MITHRIL_DAGGER(
    WeaponItemDefinition(
      name: "Mithril Dagger",
      value: 150,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/mithril_dagger.png",
    ),
  ),
  ADAMANT_DAGGER(
    WeaponItemDefinition(
      name: "Adamant Dagger",
      value: 300,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/adamant_dagger.png",
    ),
  ),
  RUNE_DAGGER(
    WeaponItemDefinition(
      name: "Rune Dagger",
      value: 600,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/rune_dagger.png",
    ),
  ),
  DRAGON_DAGGER(
    WeaponItemDefinition(
      name: "Dragon Dagger",
      value: 1200,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.DAGGER,
      iconAsset: "assets/icons/items/dragon_dagger.png",
    ),
  ),

  // ── WEAPONS & TOOLS · AXE ───────────────────────────────────────
  // tier ascending
  STONE_AXE(
    WeaponItemDefinition(
      name: "Stone Axe",
      value: 10,
      weaponType: WeaponTypeId.AXE,
      fibLevel: 0,
      iconAsset: "assets/icons/items/stone_axe.png",
    ),
  ),
  COPPER_AXE(
    WeaponItemDefinition(
      name: "Copper Axe",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/copper_axe.png",
    ),
  ),
  IRON_AXE(
    WeaponItemDefinition(
      name: "Iron Axe",
      value: 25,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/iron_axe.png",
    ),
  ),
  STEEL_AXE(
    WeaponItemDefinition(
      name: "Steel Axe",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/steel_axe.png",
    ),
  ),
  MITHRIL_AXE(
    WeaponItemDefinition(
      name: "Mithril Axe",
      value: 150,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/mithril_axe.png",
    ),
  ),
  ADAMANT_AXE(
    WeaponItemDefinition(
      name: "Adamant Axe",
      value: 300,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/adamant_axe.png",
    ),
  ),
  RUNE_AXE(
    WeaponItemDefinition(
      name: "Rune Axe",
      value: 600,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/rune_axe.png",
    ),
  ),
  DRAGON_AXE(
    WeaponItemDefinition(
      name: "Dragon Axe",
      value: 1200,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.AXE,
      iconAsset: "assets/icons/items/dragon_axe.png",
    ),
  ),

  // ── WEAPONS & TOOLS · PICKAXE ───────────────────────────────────
  // tier ascending
  STONE_PICKAXE(
    WeaponItemDefinition(
      name: "Stone Pickaxe",
      value: 10,
      weaponType: WeaponTypeId.PICKAXE,
      fibLevel: 0,
      iconAsset: "assets/icons/items/stone_pickaxe.png",
    ),
  ),
  COPPER_PICKAXE(
    WeaponItemDefinition(
      name: "Copper Pickaxe",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/copper_pickaxe.png",
    ),
  ),
  IRON_PICKAXE(
    WeaponItemDefinition(
      name: "Iron Pickaxe",
      value: 25,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/iron_pickaxe.png",
    ),
  ),
  STEEL_PICKAXE(
    WeaponItemDefinition(
      name: "Steel Pickaxe",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/steel_pickaxe.png",
    ),
  ),
  MITHRIL_PICKAXE(
    WeaponItemDefinition(
      name: "Mithril Pickaxe",
      value: 150,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/mithril_pickaxe.png",
    ),
  ),
  ADAMANT_PICKAXE(
    WeaponItemDefinition(
      name: "Adamant Pickaxe",
      value: 300,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/adamant_pickaxe.png",
    ),
  ),
  RUNE_PICKAXE(
    WeaponItemDefinition(
      name: "Rune Pickaxe",
      value: 600,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/rune_pickaxe.png",
    ),
  ),
  DRAGON_PICKAXE(
    WeaponItemDefinition(
      name: "Dragon Pickaxe",
      value: 1200,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.PICKAXE,
      iconAsset: "assets/icons/items/dragon_pickaxe.png",
    ),
  ),

  // ── WEAPONS & TOOLS · SICKLE ────────────────────────────────────
  // tier ascending
  COPPER_SICKLE(
    WeaponItemDefinition(
      name: "Copper Sickle",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/copper_sickle.png",
    ),
  ),
  IRON_SICKLE(
    WeaponItemDefinition(
      name: "Iron Sickle",
      value: 25,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/iron_sickle.png",
    ),
  ),
  STEEL_SICKLE(
    WeaponItemDefinition(
      name: "Steel Sickle",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/steel_sickle.png",
    ),
  ),
  MITHRIL_SICKLE(
    WeaponItemDefinition(
      name: "Mithril Sickle",
      value: 150,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/mithril_sickle.png",
    ),
  ),
  ADAMANT_SICKLE(
    WeaponItemDefinition(
      name: "Adamant Sickle",
      value: 300,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/adamant_sickle.png",
    ),
  ),
  RUNE_SICKLE(
    WeaponItemDefinition(
      name: "Rune Sickle",
      value: 600,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/rune_sickle.png",
    ),
  ),
  DRAGON_SICKLE(
    WeaponItemDefinition(
      name: "Dragon Sickle",
      value: 1200,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.SICKLE,
      iconAsset: "assets/icons/items/dragon_sickle.png",
    ),
  ),

  // ── WEAPONS & TOOLS · FISHING ROD ───────────────────────────────
  // tier ascending
  SIMPLE_FISHING_ROD(
    WeaponItemDefinition(
      name: "Simple Fishing Rod",
      value: 5,
      weaponType: WeaponTypeId.FISHING_ROD,
      fibLevel: 0,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),

  // ── WEAPONS & TOOLS · ODDITIES ──────────────────────────────────
  // tier ascending

  // ── BOSS UNIQUES ────────────────────────────────────────────────
  // by source dungeon

  CHICKEN_CHARM(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Chicken Charm",
      value: 150,
      fibLevel: 0,
      statWeights: {SkillId.ATTACK: 1, SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/chicken_charm.png",
    ),
  ),
  MOOD_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Mood Ring",
      value: 150,
      fibLevel: 0,
      statWeights: {SkillId.DEFENCE: 1},
      iconAsset: "assets/icons/items/mood_ring.png",
    ),
  ),
  PITCHFORK(
    WeaponItemDefinition(
      name: "Pitchfork",
      value: 30,
      weaponType: WeaponTypeId.PITCHFORK,
      fibLevel: 2,
      iconAsset: "assets/icons/items/pitchfork.png",
    ),
  ),

  GOBLIN_CROWN(
    EquipmentItemDefinition(
      quality: Rarity.LEGENDARY,
      armorSlot: ArmorSlots.HEAD,
      name: "Goblin Crown",
      value: 150,
      fibLevel: 5,
      statWeights: {SkillId.DEFENCE: 12, SkillId.ATTACK: 4},
      iconAsset: "assets/icons/items/goblin_crown.png",
    ),
  ),
  GOBLIN_SCEPTER(
    WeaponItemDefinition(
      name: "Goblin Scepter",
      value: 150,
      weaponType: WeaponTypeId.SCEPTER,
      fibLevel: 5,
      description: "The Queen's rod of office, still warm.",
      iconAsset: "assets/icons/items/goblin_scepter.png",
    ),
  ),
  SPIDER_SILK_NECKLACE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.NECK,
      name: "Spider Silk Necklace",
      value: 120,
      fibLevel: 5,
      statWeights: {SkillId.ATTACK: 8, SkillId.DEFENCE: 4},
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

  /// Ids that were renamed, keyed by the name a save written before the
  /// rename still holds. A rename is only safe with its old name here —
  /// every save decode goes through [byName], which falls back to this.
  static const Map<String, ItemId> renamed = {
    'FISHERMANS_BOOTS': BASIC_FISHERS_BOOTS,
    'FISHERMANS_HAT': BASIC_FISHERS_HAT,
    'FISHERMANS_TUNIC': BASIC_FISHERS_TUNIC,
    'FISHERMANS_PANTS': BASIC_FISHERS_PANTS,
    'FISHERMANS_GLOVES': BASIC_FISHERS_GLOVES,
    'FISHERMANS_CLOAK': BASIC_FISHERS_CLOAK,
  };

  static final Map<String, ItemId> _byName = values.asNameMap();

  /// The item a saved [name] refers to, following [renamed]; null when it
  /// names nothing, so a retired id can be skipped rather than thrown on.
  static ItemId? byName(String name) => _byName[name] ?? renamed[name];

  /// Icon lookup for [EnumImageProviderLookup], which keys on the id's Type
  /// and so hands back a `dynamic`.
  static ImageProvider? providerFor(dynamic id) {
    if (id is! ItemId) return null;
    final asset = id.iconAsset;
    return asset != null ? AssetImage(asset) : null;
  }
}
