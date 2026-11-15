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
      quality: Rarity.JUNK,
      name: "Burnt Food",
      value: 1,
      iconAsset: "assets/icons/items/burnt_food.png",
    ),
  ),
  COW_HIDE(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Cow Hide",
      value: 1,
      iconAsset: "assets/icons/items/cow_hide.png",
    ),
  ),
  ANIMAL_PELT(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Fur Pelt",
      value: 1,
      iconAsset: "assets/icons/items/fur_pelt.png",
    ),
  ),
  WOLF_PELT(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Wolf Pelt",
      value: 1,
      iconAsset: "assets/icons/items/wolf_pelt.png",
    ),
  ),
  BEAR_HIDE(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Bear Hide",
      value: 1,
      iconAsset: "assets/icons/items/bear_hide.png",
    ),
  ),
  // the Murkjaw's hide: tough, scaled and held for a crafting use to come
  MURKJAW_HIDE(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Murkjaw Hide",
      value: 30,
      description: "Thick, scaled and still smelling of the bog.",
      iconAsset: "assets/icons/items/murkjaw_hide.png",
    ),
  ),

  // what a line drags up instead of a fish: worth nothing, sold for a coin
  OLD_BOOT(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Old Boot",
      value: 1,
      description: "Waterlogged and missing its partner.",
      iconAsset: "assets/icons/items/old_boot.png",
    ),
  ),
  TIN_CAN(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Tin Can",
      value: 1,
      description: "Rusted through. Something used to live in it.",
      iconAsset: "assets/icons/items/tin_can.png",
    ),
  ),
  TANGLED_LINE(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Tangled Line",
      value: 1,
      description: "Someone else's lost tackle, knotted past saving.",
      iconAsset: "assets/icons/items/tangled_line.png",
    ),
  ),
  SODDEN_DRIFTWOOD(
    ItemDefinition(
      quality: Rarity.JUNK,
      name: "Sodden Driftwood",
      value: 1,
      description: "Too wet to burn and too soft to carve.",
      iconAsset: "assets/icons/items/sodden_driftwood.png",
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
  // the swamp's side-grade to willow: the same tier, wetter wood
  BOG_LOGS(
    ItemDefinition(
      name: "Bog Logs",
      value: 12,
      description: "Dark, damp wood that smoulders more than it burns.",
      iconAsset: "assets/icons/items/bog_logs.png",
    ),
  ),
  MAPLE_LOGS(
    ItemDefinition(
      name: "Maple Logs",
      value: 25,
      iconAsset: "assets/icons/items/maple_logs.png",
    ),
  ),
  // the Old Yew Grove's wood, past the maple
  YEW_LOGS(
    ItemDefinition(
      name: "Yew Logs",
      value: 50,
      iconAsset: "assets/icons/items/yew_logs.png",
    ),
  ),
  // Witchlight Grove's wood, the top of the ladder
  MAGIC_LOGS(
    ItemDefinition(
      name: "Magic Logs",
      value: 100,
      description: "Faintly warm, and lighter than wood should be.",
      iconAsset: "assets/icons/items/magic_logs.png",
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
  // the swamp's fungal herb, the base of the third potion tier
  MIRECAP(
    ItemDefinition(
      name: "Mirecap",
      value: 8,
      description:
          "A pale, spongy cap that only grows where the ground is wet.",
      iconAsset: "assets/icons/items/mirecap.png",
      xpValue: 21,
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
  // Stormgrass Prairie's two grasses. Sweetgrass brews the utility potions
  // that speed gathering and crafting; bluestem is the base of the greater
  // potions, the rung past the swamp's mirecap
  SWEETGRASS(
    ItemDefinition(
      name: "Sweetgrass",
      value: 10,
      description: "A braid of pale grass that smells of hay and honey.",
      iconAsset: "assets/icons/items/sweetgrass.png",
      xpValue: 30,
    ),
  ),
  BLUESTEM(
    ItemDefinition(
      name: "Bluestem",
      value: 14,
      description: "Tall prairie grass, its stems blue-green at the joint.",
      iconAsset: "assets/icons/items/bluestem.png",
      xpValue: 35,
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
  RAT_TAIL(
    ItemDefinition(
      name: "Rat Tail",
      value: 1,
      iconAsset: "assets/icons/items/rat_tail.png",
    ),
  ),
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
  ROTTEN_FLESH(
    ItemDefinition(
      name: "Rotten Flesh",
      value: 3,
      description: "Past saving. Dropped by the dark forest's dead.",
      iconAsset: "assets/icons/items/rotten_flesh.png",
    ),
  ),
  GRAVE_MOSS(
    ItemDefinition(
      name: "Grave Moss",
      value: 6,
      description: "Pale moss that only grows where something was buried.",
      iconAsset: "assets/icons/items/grave_moss.png",
    ),
  ),
  BAT_WING(
    ItemDefinition(
      name: "Bat Wing",
      value: 5,
      description: "A leathery wing, still twitching.",
      iconAsset: "assets/icons/items/bat_wing.png",
    ),
  ),
  BAT_FANG(
    ItemDefinition(
      name: "Bat Fang",
      value: 7,
      description: "A needle-thin fang from a mine bat.",
      iconAsset: "assets/icons/items/bat_fang.png",
    ),
  ),
  SLIME_OOZE(
    ItemDefinition(
      name: "Slime Ooze",
      value: 4,
      description: "Thick, cold and faintly sweet. It clings to everything.",
      iconAsset: "assets/icons/items/slime_ooze.png",
    ),
  ),
  SLIME_CORE(
    ItemDefinition(
      name: "Slime Core",
      value: 60,
      description: "The dense heart of a slime. Alchemists prize it.",
      iconAsset: "assets/icons/items/slime_core.png",
    ),
  ),
  RED_CAP_MUSHROOM(
    ItemDefinition(
      name: "Red Cap Mushroom",
      value: 8,
      description: "Bright, spotted and best left uneaten.",
      iconAsset: "assets/icons/items/red_cap_mushroom.png",
    ),
  ),
  // the swamp's reagents: three from the marsh, one off its crows, and the
  // Murkjaw's fang, which nothing else drops
  LEECH(
    ItemDefinition(
      name: "Leech",
      value: 10,
      description: "Fat and still wriggling. Draws out what ails you.",
      iconAsset: "assets/icons/items/leech.png",
    ),
  ),
  CROW_QUILL(
    ItemDefinition(
      name: "Crow Quill",
      value: 10,
      description: "A long black flight feather, stiff as a nib.",
      iconAsset: "assets/icons/items/crow_quill.png",
    ),
  ),
  MARSH_FROG(
    ItemDefinition(
      name: "Marsh Frog",
      value: 14,
      description: "All leg and no sense. Kicks like a mule.",
      iconAsset: "assets/icons/items/marsh_frog.png",
    ),
  ),
  MURKJAW_FANG(
    ItemDefinition(
      name: "Murkjaw Fang",
      value: 40,
      description: "A yellowed, hooked tooth from something that waits.",
      iconAsset: "assets/icons/items/murkjaw_fang.png",
    ),
  ),
  // Stormgrass Prairie's reagents, one off each of its monsters: the
  // greater potions' second halves
  ORC_TUSK(
    ItemDefinition(
      name: "Orc Tusk",
      value: 20,
      description: "A chipped yellow tusk, filed to a point.",
      iconAsset: "assets/icons/items/orc_tusk.png",
    ),
  ),
  SNAKESKIN(
    ItemDefinition(
      name: "Snakeskin",
      value: 18,
      description: "A shed rattlesnake skin, dry and diamond-patterned.",
      iconAsset: "assets/icons/items/snakeskin.png",
    ),
  ),
  VENOM_GLAND(
    ItemDefinition(
      name: "Venom Gland",
      value: 22,
      description: "A rattlesnake's venom sac. Handle it by the edges.",
      iconAsset: "assets/icons/items/venom_gland.png",
    ),
  ),
  CENTAUR_HOOF(
    ItemDefinition(
      name: "Centaur Hoof",
      value: 22,
      description: "A worn hoof, still shod in iron.",
      iconAsset: "assets/icons/items/centaur_hoof.png",
    ),
  ),
  WIND_MOTE(
    ItemDefinition(
      name: "Wind Mote",
      value: 30,
      description: "A speck of grit that will not stop spinning.",
      iconAsset: "assets/icons/items/wind_mote.png",
    ),
  ),
  SABERTOOTH_FANG(
    ItemDefinition(
      name: "Sabertooth Fang",
      value: 40,
      description: "A curved fang as long as a dagger.",
      iconAsset: "assets/icons/items/sabertooth_fang.png",
    ),
  ),
  // held for leatherworking and fletching, which have no recipes yet
  SABERTOOTH_PELT(
    ItemDefinition(
      name: "Sabertooth Pelt",
      value: 30,
      description: "A tawny pelt the color of dry grass.",
      iconAsset: "assets/icons/items/sabertooth_pelt.png",
    ),
  ),
  BOWSTRING_SINEW(
    ItemDefinition(
      name: "Bowstring Sinew",
      value: 15,
      description: "Twisted sinew off a centaur's bow, still taut.",
      iconAsset: "assets/icons/items/bowstring_sinew.png",
    ),
  ),

  // the waters' alchemy reagents, one per fishing spot, pulled up now and
  // then in place of nothing and lining that water's sunken cache. The
  // marsh has none of its own here: its leech and frog come up as catches
  LILY_PAD(
    ItemDefinition(
      name: "Lily Pad",
      value: 6,
      description: "Broad, waxy and cool. Settles a cook's nerves.",
      iconAsset: "assets/icons/items/lily_pad.png",
    ),
  ),
  CREEK_MOSS(
    ItemDefinition(
      name: "Creek Moss",
      value: 8,
      description: "A green fist of it, torn off a streambed stone.",
      iconAsset: "assets/icons/items/creek_moss.png",
    ),
  ),
  FRESHWATER_MUSSEL(
    ItemDefinition(
      name: "Freshwater Mussel",
      value: 20,
      description: "Clamped shut on whatever it found.",
      iconAsset: "assets/icons/items/freshwater_mussel.png",
    ),
  ),
  DUCKWEED(
    ItemDefinition(
      name: "Duckweed",
      value: 30,
      description: "A dripping mat of tiny leaves, thick as felt.",
      iconAsset: "assets/icons/items/duckweed.png",
    ),
  ),
  LAKE_SPONGE(
    ItemDefinition(
      name: "Lake Sponge",
      value: 45,
      description: "Soft, pale and full of cold deep water.",
      iconAsset: "assets/icons/items/lake_sponge.png",
    ),
  ),
  SEA_KELP(
    ItemDefinition(
      name: "Sea Kelp",
      value: 55,
      description: "A long ribbon of brown kelp, slick with salt.",
      iconAsset: "assets/icons/items/sea_kelp.png",
    ),
  ),

  // ── FIRE REAGENTS ───────────────────────────────────────────────
  // FireReagentDefinition, firemaking level ascending. Woodcutting's side
  // drops: three off the tree, four off the oak, and all seven off every
  // tree above them. Thrown on a lit campfire or bonfire, each buffs its
  // stat by the fire's power.
  DRY_TWIGS(
    FireReagentDefinition(
      name: "Dry Twigs",
      value: 2,
      stat: SkillId.STAMINA,
      levelRequirement: 5,
      description: "Snaps clean and catches fast. Keeps you going.",
      iconAsset: "assets/icons/items/dry_twigs.png",
    ),
  ),
  TREE_BARK(
    FireReagentDefinition(
      name: "Tree Bark",
      value: 2,
      stat: SkillId.DEFENCE,
      levelRequirement: 5,
      description: "A curl of rough bark that burns slow and steady.",
      iconAsset: "assets/icons/items/tree_bark.png",
    ),
  ),
  PINE_RESIN(
    FireReagentDefinition(
      name: "Pine Resin",
      value: 2,
      stat: SkillId.RECOVERY,
      levelRequirement: 8,
      description: "Sticky and fragrant. The smoke clears the head.",
      iconAsset: "assets/icons/items/pine_resin.png",
    ),
  ),
  ACORN(
    FireReagentDefinition(
      name: "Acorn",
      value: 2,
      stat: SkillId.STRENGTH,
      levelRequirement: 8,
      description: "Pops in the heat with a crack like a knuckle.",
      iconAsset: "assets/icons/items/acorn.png",
    ),
  ),
  OAK_GALL(
    FireReagentDefinition(
      name: "Oak Gall",
      value: 2,
      stat: SkillId.ATTACK,
      levelRequirement: 8,
      description:
          "A hard little knot from an oak twig. Burns bitter and sharp.",
      iconAsset: "assets/icons/items/oak_gall.png",
    ),
  ),
  DRY_LEAVES(
    FireReagentDefinition(
      name: "Dry Leaves",
      value: 2,
      stat: SkillId.SPEED,
      levelRequirement: 13,
      description: "A crisp handful that flares up in a rush.",
      iconAsset: "assets/icons/items/dry_leaves.png",
    ),
  ),
  OAK_SAP(
    FireReagentDefinition(
      name: "Oak Sap",
      value: 2,
      stat: SkillId.HITPOINTS,
      levelRequirement: 13,
      description: "Thick, dark sap that hisses and warms the blood.",
      iconAsset: "assets/icons/items/oak_sap.png",
    ),
  ),

  // the waters' fire reagents, one per fishing spot. Every wood reagent
  // already holds a combat stat, so these buff the skills instead, on the
  // Fibonacci rungs past the oak's 13
  CATTAIL_FLUFF(
    FireReagentDefinition(
      name: "Cattail Fluff",
      value: 4,
      stat: SkillId.FISHING,
      levelRequirement: 21,
      description:
          "Burst seed-heads that catch in a breath. The smoke smells of the pond.",
      iconAsset: "assets/icons/items/cattail_fluff.png",
    ),
  ),
  DRIED_REEDS(
    FireReagentDefinition(
      name: "Dried Reeds",
      value: 4,
      stat: SkillId.COOKING,
      levelRequirement: 21,
      description: "A bundle of creek reeds, dry enough to crackle.",
      iconAsset: "assets/icons/items/dried_reeds.png",
    ),
  ),
  RIVER_DRIFTWOOD(
    FireReagentDefinition(
      name: "River Driftwood",
      value: 8,
      stat: SkillId.WOODCUTTING,
      levelRequirement: 34,
      description: "Grey and smooth, worn bare by the current.",
      iconAsset: "assets/icons/items/river_driftwood.png",
    ),
  ),
  PEAT_CLOD(
    FireReagentDefinition(
      name: "Peat Clod",
      value: 8,
      stat: SkillId.HERBALISM,
      levelRequirement: 34,
      description: "Dense black bog earth that smoulders for hours.",
      iconAsset: "assets/icons/items/peat_clod.png",
    ),
  ),
  DRIED_RUSHES(
    FireReagentDefinition(
      name: "Dried Rushes",
      value: 14,
      stat: SkillId.MINING,
      levelRequirement: 55,
      description: "Stiff lake rushes that burn hot and fast.",
      iconAsset: "assets/icons/items/dried_rushes.png",
    ),
  ),
  BONE_CORAL(
    FireReagentDefinition(
      name: "Bleached Bone Coral",
      value: 20,
      stat: SkillId.ALCHEMY,
      levelRequirement: 55,
      description: "Chalk-white and brittle. Its smoke burns blue.",
      iconAsset: "assets/icons/items/bone_coral.png",
    ),
  ),
  AMBERGRIS(
    FireReagentDefinition(
      name: "Ambergris",
      value: 40,
      stat: SkillId.EXPLORATION,
      levelRequirement: 89,
      description:
          "A waxy grey lump from the deep. Its smoke carries a long way.",
      iconAsset: "assets/icons/items/ambergris.png",
    ),
  ),

  // ── BIRD'S NESTS ────────────────────────────────────────────────
  // Woodcutting's treasure chests, tree tier ascending. Opened from the
  // bag; what is inside is birdsNestRolls in drop_tables.dart. One nest a
  // tier of Woodcutter's gear: small and woven off the low trees, sturdy
  // off the maple, gilded off the yew, enchanted off the magic tree.
  SMALL_BIRDS_NEST(
    ItemDefinition(
      name: "Small Bird's Nest",
      value: 20,
      description: "Knocked loose from a low branch. Something glints inside.",
      iconAsset: "assets/icons/items/small_birds_nest.png",
    ),
  ),
  WOVEN_BIRDS_NEST(
    ItemDefinition(
      name: "Woven Bird's Nest",
      value: 60,
      description: "Tightly woven and heavier than it looks.",
      iconAsset: "assets/icons/items/woven_birds_nest.png",
    ),
  ),
  STURDY_BIRDS_NEST(
    ItemDefinition(
      name: "Sturdy Bird's Nest",
      value: 150,
      description: "Built of maple twigs to last a dozen springs.",
      iconAsset: "assets/icons/items/sturdy_birds_nest.png",
    ),
  ),
  GILDED_BIRDS_NEST(
    ItemDefinition(
      name: "Gilded Bird's Nest",
      value: 400,
      description: "Some magpie has lined it with gold thread.",
      iconAsset: "assets/icons/items/gilded_birds_nest.png",
    ),
  ),
  ENCHANTED_BIRDS_NEST(
    ItemDefinition(
      name: "Enchanted Bird's Nest",
      value: 1000,
      description: "It hums softly, and the eggs inside never hatch.",
      iconAsset: "assets/icons/items/enchanted_birds_nest.png",
    ),
  ),

  // ── GEODES ──────────────────────────────────────────────────────
  // Mining's treasure chests, opened from the bag like a bird's nest. A
  // geode's quality is the tier of the vein it came out of, copper to
  // adamantite, and sets what is inside: the Miner's set of the matching
  // tier, and a gem from a richer table the higher it goes. Contents are
  // geodeRolls in drop_tables.dart.
  DULL_GEODE(
    ItemDefinition(
      name: "Dull Geode",
      value: 25,
      quality: Rarity.COMMON,
      description: "Plain grey stone. It rattles when shaken.",
      iconAsset: "assets/icons/items/dull_geode.png",
    ),
  ),
  BANDED_GEODE(
    ItemDefinition(
      name: "Banded Geode",
      value: 70,
      quality: Rarity.UNCOMMON,
      description: "Ringed with bands of iron-red mineral.",
      iconAsset: "assets/icons/items/banded_geode.png",
    ),
  ),
  CRYSTAL_GEODE(
    ItemDefinition(
      name: "Crystal Geode",
      value: 160,
      quality: Rarity.RARE,
      description: "A hairline crack shows a lining of glittering crystal.",
      iconAsset: "assets/icons/items/crystal_geode.png",
    ),
  ),
  PRISMATIC_GEODE(
    ItemDefinition(
      name: "Prismatic Geode",
      value: 400,
      quality: Rarity.EPIC,
      description: "Throws a small rainbow wherever the light touches it.",
      iconAsset: "assets/icons/items/prismatic_geode.png",
    ),
  ),
  RADIANT_GEODE(
    ItemDefinition(
      name: "Radiant Geode",
      value: 1000,
      quality: Rarity.LEGENDARY,
      description: "Warm to the touch, and faintly glowing.",
      iconAsset: "assets/icons/items/radiant_geode.png",
    ),
  ),

  // ── SUNKEN CACHES ───────────────────────────────────────────────
  // Fishing's treasure chests, opened from the bag like a geode. One per
  // body of water, its quality the water's tier: inside are that water's
  // own reagents, its cooked fish, a fishing potion, now and then a
  // scouting map of the zone it lies in, and a long shot at the Fisher's
  // set of the matching tier. Contents are sunkenCacheRolls in
  // drop_tables.dart.
  POND_CACHE(
    ItemDefinition(
      name: "Silted Tackle Box",
      value: 20,
      quality: Rarity.COMMON,
      description: "Someone's lost tackle box, clogged with pond silt.",
      iconAsset: "assets/icons/items/pond_cache.png",
    ),
  ),
  CREEK_CACHE(
    ItemDefinition(
      name: "Mossy Creek Cache",
      value: 30,
      quality: Rarity.COMMON,
      description: "A little tin box, green with moss, wedged under a stone.",
      iconAsset: "assets/icons/items/creek_cache.png",
    ),
  ),
  RIVER_CACHE(
    ItemDefinition(
      name: "Rusted River Cache",
      value: 70,
      quality: Rarity.UNCOMMON,
      description: "A rusted lockbox the current rolled downstream.",
      iconAsset: "assets/icons/items/river_cache.png",
    ),
  ),
  MARSH_CACHE(
    ItemDefinition(
      name: "Bog-Sunk Cache",
      value: 80,
      quality: Rarity.UNCOMMON,
      description: "Black with peat and heavier than it should be.",
      iconAsset: "assets/icons/items/marsh_cache.png",
    ),
  ),
  SMALL_LAKE_CACHE(
    ItemDefinition(
      name: "Silt-Crusted Chest",
      value: 160,
      quality: Rarity.RARE,
      description: "A small chest, crusted shut with lake silt.",
      iconAsset: "assets/icons/items/small_lake_cache.png",
    ),
  ),
  LAKE_CACHE(
    ItemDefinition(
      name: "Waterlogged Strongbox",
      value: 400,
      quality: Rarity.EPIC,
      description: "Iron-banded and swollen with lake water.",
      iconAsset: "assets/icons/items/lake_cache.png",
    ),
  ),
  OCEAN_CACHE(
    ItemDefinition(
      name: "Barnacled Sea Chest",
      value: 1000,
      quality: Rarity.LEGENDARY,
      description: "Crusted in barnacles. Something rattles inside.",
      iconAsset: "assets/icons/items/ocean_cache.png",
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
      description: "Guam and a rat tail. Holds a little more wind.",
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
  RECOVERY_POTION(
    BuffItemDefinition(
      name: "Recovery Potion",
      value: 90,
      description:
          "Harralander steeped in grave moss. Gets the wind back fast.",
      skillBonus: {SkillId.RECOVERY: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/recovery_potion.png",
    ),
  ),
  SPEED_POTION(
    BuffItemDefinition(
      name: "Speed Potion",
      value: 80,
      description:
          "Harralander ground with a bat wing. Acts a good deal faster.",
      skillBonus: {SkillId.SPEED: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/speed_potion.png",
    ),
  ),
  ATTACK_POTION(
    BuffItemDefinition(
      name: "Attack Potion",
      value: 110,
      description: "Harralander and a fang. Lands far more often.",
      skillBonus: {SkillId.ATTACK: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/attack_potion.png",
    ),
  ),
  STRENGTH_POTION(
    BuffItemDefinition(
      name: "Strength Potion",
      value: 120,
      description: "Harralander and a bat fang. Hits much harder.",
      skillBonus: {SkillId.STRENGTH: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/strength_potion.png",
    ),
  ),
  FISHING_POTION(
    BuffItemDefinition(
      name: "Fishing Potion",
      value: 90,
      description: "Harralander and crayfish. The water gives up its best.",
      skillBonus: {SkillId.FISHING: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/fishing_potion.png",
    ),
  ),
  DEFENCE_POTION(
    BuffItemDefinition(
      name: "Defence Potion",
      value: 100,
      description: "Harralander and iron bar. Blows glance off.",
      skillBonus: {SkillId.DEFENCE: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/defence_potion.png",
    ),
  ),
  STAMINA_POTION(
    BuffItemDefinition(
      name: "Stamina Potion",
      value: 95,
      description: "Harralander and slime ooze. Holds out far longer.",
      skillBonus: {SkillId.STAMINA: 10},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/stamina_potion.png",
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

  // The super tier: one mirecap and a swamp reagent for +13, the next rung
  // of the Fibonacci ladder past the minor (+5) and the standard (+10).
  SUPER_RECOVERY_POTION(
    BuffItemDefinition(
      name: "Super Recovery Potion",
      value: 150,
      description: "Mirecap and a leech. The wind comes back at once.",
      skillBonus: {SkillId.RECOVERY: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_recovery_potion.png",
    ),
  ),
  SUPER_FISHING_POTION(
    BuffItemDefinition(
      name: "Super Fishing Potion",
      value: 150,
      description: "Mirecap and bog eel. Fish all but jump in.",
      skillBonus: {SkillId.FISHING: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_fishing_potion.png",
    ),
  ),
  SUPER_STAMINA_POTION(
    BuffItemDefinition(
      name: "Super Stamina Potion",
      value: 160,
      description: "Mirecap and a slime core. Hardly tires at all.",
      skillBonus: {SkillId.STAMINA: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_stamina_potion.png",
    ),
  ),
  SUPER_DEFENCE_POTION(
    BuffItemDefinition(
      name: "Super Defence Potion",
      value: 160,
      description: "Mirecap and ground scale. Skin like a mudlurc's.",
      skillBonus: {SkillId.DEFENCE: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_defence_potion.png",
    ),
  ),
  SUPER_SPEED_POTION(
    BuffItemDefinition(
      name: "Super Speed Potion",
      value: 150,
      description: "Mirecap and a crow quill. Moves before it thinks.",
      skillBonus: {SkillId.SPEED: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_speed_potion.png",
    ),
  ),
  SUPER_STRENGTH_POTION(
    BuffItemDefinition(
      name: "Super Strength Potion",
      value: 190,
      description: "Mirecap and a marsh frog. Hits like a falling tree.",
      skillBonus: {SkillId.STRENGTH: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_strength_potion.png",
    ),
  ),
  SUPER_ATTACK_POTION(
    BuffItemDefinition(
      name: "Super Attack Potion",
      value: 200,
      description: "Mirecap and a murkjaw fang. Never misses its mark.",
      skillBonus: {SkillId.ATTACK: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/super_attack_potion.png",
    ),
  ),

  // The utility tier: one sweetgrass and a reagent for +13 to a gathering
  // or crafting skill, the super tier's strength on the skills the combat
  // potions leave alone
  PROSPECTORS_POTION(
    BuffItemDefinition(
      name: "Prospector's Potion",
      value: 150,
      description: "Sweetgrass and mithril ore. Finds the seam first time.",
      skillBonus: {SkillId.MINING: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/prospectors_potion.png",
    ),
  ),
  FORAGERS_POTION(
    BuffItemDefinition(
      name: "Forager's Potion",
      value: 150,
      description: "Sweetgrass and a wind mote. Spots every leaf.",
      skillBonus: {SkillId.HERBALISM: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/foragers_potion.png",
    ),
  ),
  SMITHS_POTION(
    BuffItemDefinition(
      name: "Smith's Potion",
      value: 160,
      description: "Sweetgrass and a mithril bar. A steady hammer hand.",
      skillBonus: {SkillId.BLACKSMITHING: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/smiths_potion.png",
    ),
  ),
  ALCHEMISTS_POTION(
    BuffItemDefinition(
      name: "Alchemist's Potion",
      value: 160,
      description: "Sweetgrass and a venom gland. Measures by eye.",
      skillBonus: {SkillId.ALCHEMY: 13},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/alchemists_potion.png",
    ),
  ),

  // The greater tier: one bluestem and a prairie reagent for +21, the
  // Fibonacci rung past the super tier's +13. There is no greater fishing
  // potion: the prairie has no water to give its reagent
  GREATER_STRENGTH_POTION(
    BuffItemDefinition(
      name: "Greater Strength Potion",
      value: 300,
      description: "Bluestem and an orc tusk. Hits like a charging orc.",
      skillBonus: {SkillId.STRENGTH: 21},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/greater_strength_potion.png",
    ),
  ),
  GREATER_ATTACK_POTION(
    BuffItemDefinition(
      name: "Greater Attack Potion",
      value: 320,
      description: "Bluestem and a sabertooth fang. Strikes from the grass.",
      skillBonus: {SkillId.ATTACK: 21},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/greater_attack_potion.png",
    ),
  ),
  GREATER_DEFENCE_POTION(
    BuffItemDefinition(
      name: "Greater Defence Potion",
      value: 260,
      description: "Bluestem and snakeskin. Blows slide off like scales.",
      skillBonus: {SkillId.DEFENCE: 21},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/greater_defence_potion.png",
    ),
  ),
  GREATER_RECOVERY_POTION(
    BuffItemDefinition(
      name: "Greater Recovery Potion",
      value: 240,
      description: "Bluestem and a venom gland. What bites also heals.",
      skillBonus: {SkillId.RECOVERY: 21},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/greater_recovery_potion.png",
    ),
  ),
  GREATER_STAMINA_POTION(
    BuffItemDefinition(
      name: "Greater Stamina Potion",
      value: 250,
      description: "Bluestem and a centaur hoof. Runs all day.",
      skillBonus: {SkillId.STAMINA: 21},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/greater_stamina_potion.png",
    ),
  ),
  GREATER_SPEED_POTION(
    BuffItemDefinition(
      name: "Greater Speed Potion",
      value: 240,
      description: "Bluestem and a wind mote. Gone before the dust settles.",
      skillBonus: {SkillId.SPEED: 21},
      duration: Duration(minutes: 3),
      iconAsset: "assets/icons/items/greater_speed_potion.png",
    ),
  ),

  // The waters' potions: a herb of each tier and a fishing spot's reagent,
  // at that tier's strength. The lake's sponge makes the greater fishing
  // potion the prairie had no water for
  MINOR_COOKING_POTION(
    BuffItemDefinition(
      name: "Minor Cooking Potion",
      value: 14,
      skillBonus: {SkillId.COOKING: 5},
      duration: Duration(minutes: 3),
      description: "Guam and a lily pad. Burns a little less.",
      iconAsset: "assets/icons/items/minor_cooking_potion.png",
    ),
  ),
  MINOR_WOODCUTTING_POTION(
    BuffItemDefinition(
      name: "Minor Woodcutting Potion",
      value: 16,
      skillBonus: {SkillId.WOODCUTTING: 5},
      duration: Duration(minutes: 3),
      description: "Guam and creek moss. Bites a little deeper.",
      iconAsset: "assets/icons/items/minor_woodcutting_potion.png",
    ),
  ),
  COOKING_POTION(
    BuffItemDefinition(
      name: "Cooking Potion",
      value: 90,
      skillBonus: {SkillId.COOKING: 10},
      duration: Duration(minutes: 3),
      description: "Harralander and a mussel. A cook's steady hand.",
      iconAsset: "assets/icons/items/cooking_potion.png",
    ),
  ),
  WOODSMANS_POTION(
    BuffItemDefinition(
      name: "Woodsman's Potion",
      value: 150,
      skillBonus: {SkillId.WOODCUTTING: 13},
      duration: Duration(minutes: 3),
      description: "Sweetgrass and duckweed. Every swing finds the grain.",
      iconAsset: "assets/icons/items/woodsmans_potion.png",
    ),
  ),
  EXPLORERS_POTION(
    BuffItemDefinition(
      name: "Explorer's Potion",
      value: 170,
      skillBonus: {SkillId.EXPLORATION: 13},
      duration: Duration(minutes: 3),
      description: "Sweetgrass and sea kelp. The horizon looks closer.",
      iconAsset: "assets/icons/items/explorers_potion.png",
    ),
  ),
  GREATER_FISHING_POTION(
    BuffItemDefinition(
      name: "Greater Fishing Potion",
      value: 260,
      skillBonus: {SkillId.FISHING: 21},
      duration: Duration(minutes: 3),
      description: "Bluestem and a lake sponge. The deep water comes to you.",
      iconAsset: "assets/icons/items/greater_fishing_potion.png",
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
  CRAYFISH(
    ItemDefinition(
      name: "Crayfish",
      value: 2,
      iconAsset: "assets/icons/items/crayfish.png",
      xpValue: 6,
    ),
  ),
  BLUEGILL(
    ItemDefinition(
      name: "Bluegill",
      value: 3,
      iconAsset: "assets/icons/items/bluegill.png",
      xpValue: 6,
    ),
  ),
  TROUT(
    ItemDefinition(
      name: "Trout",
      value: 5,
      iconAsset: "assets/icons/items/trout.png",
      xpValue: 8,
    ),
  ),
  PIKE(
    ItemDefinition(
      name: "Pike",
      value: 7,
      iconAsset: "assets/icons/items/pike.png",
      xpValue: 28,
    ),
  ),
  // the marsh's catch, the River's level-20 equivalent
  BOG_EEL(
    ItemDefinition(
      name: "Bog Eel",
      value: 7,
      iconAsset: "assets/icons/items/bog_eel.png",
      xpValue: 40,
    ),
  ),
  SALMON(
    ItemDefinition(
      name: "Salmon",
      value: 10,
      iconAsset: "assets/icons/items/salmon.png",
      xpValue: 33,
    ),
  ),
  CATFISH(
    ItemDefinition(
      name: "Catfish",
      value: 15,
      iconAsset: "assets/icons/items/catfish.png",
      xpValue: 150,
    ),
  ),
  BASS(
    ItemDefinition(
      name: "Bass",
      value: 20,
      iconAsset: "assets/icons/items/bass.png",
      xpValue: 150,
    ),
  ),
  WHITEFISH(
    ItemDefinition(
      name: "Whitefish",
      value: 25,
      iconAsset: "assets/icons/items/whitefish.png",
      xpValue: 470,
    ),
  ),
  STURGEON(
    ItemDefinition(
      name: "Sturgeon",
      value: 27,
      iconAsset: "assets/icons/items/sturgeon.png",
      xpValue: 565,
    ),
  ),
  TUNA(
    ItemDefinition(
      name: "Tuna",
      value: 30,
      iconAsset: "assets/icons/items/tuna.png",
      xpValue: 2150,
    ),
  ),
  SWORDFISH(
    ItemDefinition(
      name: "Swordfish",
      value: 50,
      iconAsset: "assets/icons/items/swordfish.png",
      xpValue: 2295,
    ),
  ),
  SHARK(
    ItemDefinition(
      name: "Shark",
      value: 100,
      iconAsset: "assets/icons/items/shark.png",
      xpValue: 2580,
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
  COOKED_CRAYFISH(
    FoodItemDefinition(
      name: "Cooked Crayfish",
      value: 5,
      restoreAmount: 3,
      xpValue: 25,
      iconAsset: "assets/icons/items/cooked_crayfish.png",
    ),
  ),
  COOKED_BLUEGILL(
    FoodItemDefinition(
      name: "Cooked Bluegill",
      value: 6,
      restoreAmount: 5,
      xpValue: 30,
      iconAsset: "assets/icons/items/cooked_bluegill.png",
    ),
  ),
  COOKED_TROUT(
    FoodItemDefinition(
      name: "Cooked Trout",
      value: 10,
      restoreAmount: 8,
      xpValue: 50,
      iconAsset: "assets/icons/items/cooked_trout.png",
    ),
  ),
  COOKED_PIKE(
    FoodItemDefinition(
      name: "Cooked Pike",
      value: 14,
      restoreAmount: 13,
      xpValue: 70,
      iconAsset: "assets/icons/items/cooked_pike.png",
    ),
  ),
  COOKED_BOG_EEL(
    FoodItemDefinition(
      name: "Cooked Bog Eel",
      value: 14,
      restoreAmount: 13,
      xpValue: 70,
      iconAsset: "assets/icons/items/cooked_bog_eel.png",
    ),
  ),
  COOKED_SALMON(
    FoodItemDefinition(
      name: "Cooked Salmon",
      value: 20,
      restoreAmount: 21,
      xpValue: 100,
      iconAsset: "assets/icons/items/cooked_salmon.png",
    ),
  ),
  COOKED_CATFISH(
    FoodItemDefinition(
      name: "Cooked Catfish",
      value: 30,
      restoreAmount: 34,
      xpValue: 150,
      iconAsset: "assets/icons/items/cooked_catfish.png",
    ),
  ),
  COOKED_BASS(
    FoodItemDefinition(
      name: "Cooked Bass",
      value: 40,
      restoreAmount: 55,
      xpValue: 200,
      iconAsset: "assets/icons/items/cooked_bass.png",
    ),
  ),
  COOKED_WHITEFISH(
    FoodItemDefinition(
      name: "Cooked Whitefish",
      value: 50,
      restoreAmount: 89,
      xpValue: 250,
      iconAsset: "assets/icons/items/cooked_whitefish.png",
    ),
  ),
  COOKED_STURGEON(
    FoodItemDefinition(
      name: "Cooked Sturgeon",
      value: 55,
      restoreAmount: 144,
      xpValue: 275,
      iconAsset: "assets/icons/items/cooked_sturgeon.png",
    ),
  ),
  COOKED_TUNA(
    FoodItemDefinition(
      name: "Cooked Tuna",
      value: 60,
      restoreAmount: 233,
      xpValue: 300,
      iconAsset: "assets/icons/items/cooked_tuna.png",
    ),
  ),
  COOKED_SWORDFISH(
    FoodItemDefinition(
      name: "Cooked Swordfish",
      value: 100,
      restoreAmount: 377,
      xpValue: 500,
      iconAsset: "assets/icons/items/cooked_swordfish.png",
    ),
  ),
  COOKED_SHARK(
    FoodItemDefinition(
      name: "Cooked Shark",
      value: 200,
      restoreAmount: 610,
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
  // Tempest's alone: never disenchanted, and it stands in for the two
  // prisms of a grand enchant
  STORM_SHARD(
    ItemDefinition(
      name: "Storm Shard",
      value: 150,
      description: "A sliver of lightning, caught and gone glassy.",
      iconAsset: "assets/icons/items/storm_shard.png",
    ),
  ),

  // ── JEWELLERY BASES ─────────────────────────────────────────────
  GOLD_RING(
    ItemDefinition(
      name: "Gold Ring",
      value: 8,
      description: "A plain band, ready for a gem.",
      iconAsset: "assets/icons/jewellery/ring_base.png",
    ),
  ),
  GOLD_NECKLACE(
    ItemDefinition(
      name: "Gold Necklace",
      value: 16,
      description: "A plain chain, ready for a gem.",
      iconAsset: "assets/icons/jewellery/necklace_base.png",
    ),
  ),

  // ── JEWELLERY ───────────────────────────────────────────────────
  // gem x cut x setting, everything derived (see JewelleryDefinition).
  // The round cuts keep the names they had before cuts existed, so saves
  // holding them still load.
  TOPAZ_RING(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  TOPAZ_NECKLACE(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  TOPAZ_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  TOPAZ_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  TOPAZ_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  TOPAZ_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  TOPAZ_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  TOPAZ_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  TOPAZ_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  TOPAZ_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  TOPAZ_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  TOPAZ_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.TOPAZ,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  SAPPHIRE_RING(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  SAPPHIRE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  SAPPHIRE_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  SAPPHIRE_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  SAPPHIRE_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  SAPPHIRE_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  SAPPHIRE_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  SAPPHIRE_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  SAPPHIRE_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  SAPPHIRE_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  SAPPHIRE_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  SAPPHIRE_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.SAPPHIRE,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  EMERALD_RING(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  EMERALD_NECKLACE(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  EMERALD_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  EMERALD_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  EMERALD_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  EMERALD_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  EMERALD_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  EMERALD_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  EMERALD_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  EMERALD_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  EMERALD_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  EMERALD_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.EMERALD,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  RUBY_RING(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  RUBY_NECKLACE(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  RUBY_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  RUBY_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  RUBY_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  RUBY_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  RUBY_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  RUBY_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  RUBY_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  RUBY_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  RUBY_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  RUBY_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.RUBY,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DIAMOND_RING(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  DIAMOND_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DIAMOND_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  DIAMOND_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DIAMOND_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  DIAMOND_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DIAMOND_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  DIAMOND_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DIAMOND_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  DIAMOND_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DIAMOND_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  DIAMOND_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DIAMOND,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DRAGONSTONE_RING(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  DRAGONSTONE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DRAGONSTONE_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  DRAGONSTONE_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DRAGONSTONE_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  DRAGONSTONE_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DRAGONSTONE_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  DRAGONSTONE_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DRAGONSTONE_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  DRAGONSTONE_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  DRAGONSTONE_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  DRAGONSTONE_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.DRAGONSTONE,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  ONYX_RING(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.ROUND,
      setting: JewellerySetting.RING,
    ),
  ),
  ONYX_NECKLACE(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.ROUND,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  ONYX_SQUARE_RING(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.RING,
    ),
  ),
  ONYX_SQUARE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.SQUARE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  ONYX_CUSHION_RING(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.RING,
    ),
  ),
  ONYX_CUSHION_NECKLACE(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.CUSHION,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  ONYX_MARQUISE_RING(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.RING,
    ),
  ),
  ONYX_MARQUISE_NECKLACE(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.MARQUISE,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  ONYX_ASSCHER_RING(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.RING,
    ),
  ),
  ONYX_ASSCHER_NECKLACE(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.ASSCHER,
      setting: JewellerySetting.NECKLACE,
    ),
  ),
  ONYX_RADIANT_RING(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.RING,
    ),
  ),
  ONYX_RADIANT_NECKLACE(
    JewelleryDefinition(
      gem: GemType.ONYX,
      cut: GemCut.RADIANT,
      setting: JewellerySetting.NECKLACE,
    ),
  ),

  // ── FIRES ───────────────────────────────────────────────────────
  // log tier, then fire tier. Every number is a Fibonacci rung.
  //
  // A cookfire cooks and carries its own cooking + hitpoints bonus. A
  // campfire or bonfire carries nothing of its own: its wood sets its
  // power, and each fire reagent thrown on it gives that much to the
  // reagent's stat (see FireReagentDefinition). A campfire is a steady
  // timer at its wood's power. A bonfire burns on heat instead: stoked from
  // its power up the bonus ladder to two rungs above it, cooling back down
  // when the logs stop (see FireItem). A reagent burns 3 minutes on it
  // rather than 5.
  COOKFIRE(
    FireItemDefinition(
      name: "Cookfire",
      value: 4,
      skillBonus: {SkillId.COOKING: 3, SkillId.HITPOINTS: 3},
      duration: Duration(minutes: 3),
      canCook: true,
      description: "Cooks food. +3 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/cookfire.png",
    ),
  ),
  BASIC_CAMPFIRE(
    FireItemDefinition(
      name: "Campfire",
      value: 5,
      skillBonus: {},
      duration: Duration(minutes: 5),
      power: 5,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +5 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/campfire.png",
    ),
  ),
  BONFIRE(
    FireItemDefinition(
      name: "Bonfire",
      value: 18,
      skillBonus: {},
      duration: Duration(minutes: 8),
      power: 5,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +13 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/bonfire.png",
    ),
  ),
  OAK_COOKFIRE(
    FireItemDefinition(
      name: "Oak Cookfire",
      value: 10,
      skillBonus: {SkillId.COOKING: 5, SkillId.HITPOINTS: 5},
      duration: Duration(minutes: 5),
      canCook: true,
      description: "Cooks food. +5 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/oak_cookfire.png",
    ),
  ),
  OAK_CAMPFIRE(
    FireItemDefinition(
      name: "Oak Campfire",
      value: 12,
      skillBonus: {},
      duration: Duration(minutes: 8),
      power: 8,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +8 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/oak_campfire.png",
    ),
  ),
  OAK_BONFIRE(
    FireItemDefinition(
      name: "Oak Bonfire",
      value: 40,
      skillBonus: {},
      duration: Duration(minutes: 13),
      power: 8,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +21 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/oak_bonfire.png",
    ),
  ),
  // Tier 3, burnt from the willow logs that grow in Darkwood.
  WILLOW_COOKFIRE(
    FireItemDefinition(
      name: "Willow Cookfire",
      value: 22,
      skillBonus: {SkillId.COOKING: 8, SkillId.HITPOINTS: 8},
      duration: Duration(minutes: 8),
      canCook: true,
      description: "Cooks food. +8 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/willow_cookfire.png",
    ),
  ),
  WILLOW_CAMPFIRE(
    FireItemDefinition(
      name: "Willow Campfire",
      value: 26,
      skillBonus: {},
      duration: Duration(minutes: 13),
      power: 13,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +13 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/willow_campfire.png",
    ),
  ),
  WILLOW_BONFIRE(
    FireItemDefinition(
      name: "Willow Bonfire",
      value: 85,
      skillBonus: {},
      duration: Duration(minutes: 21),
      power: 13,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +34 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/willow_bonfire.png",
    ),
  ),
  // Bog, willow's side-grade from Blackmire Swamp: the same tier, one rung
  // weaker and one rung longer. Wet wood smoulders.
  BOG_COOKFIRE(
    FireItemDefinition(
      name: "Bog Cookfire",
      value: 22,
      skillBonus: {SkillId.COOKING: 5, SkillId.HITPOINTS: 5},
      duration: Duration(minutes: 13),
      canCook: true,
      description: "Cooks food. +5 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/bog_cookfire.png",
    ),
  ),
  BOG_CAMPFIRE(
    FireItemDefinition(
      name: "Bog Campfire",
      value: 26,
      skillBonus: {},
      duration: Duration(minutes: 21),
      power: 8,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +8 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/bog_campfire.png",
    ),
  ),
  BOG_BONFIRE(
    FireItemDefinition(
      name: "Bog Bonfire",
      value: 85,
      skillBonus: {},
      duration: Duration(minutes: 34),
      power: 8,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +21 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/bog_bonfire.png",
    ),
  ),
  // Tiers 4 to 6: maple, yew and magic, each one rung up the ladder from
  // the wood below it.
  MAPLE_COOKFIRE(
    FireItemDefinition(
      name: "Maple Cookfire",
      value: 45,
      skillBonus: {SkillId.COOKING: 13, SkillId.HITPOINTS: 13},
      duration: Duration(minutes: 13),
      canCook: true,
      description: "Cooks food. +13 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/maple_cookfire.png",
    ),
  ),
  MAPLE_CAMPFIRE(
    FireItemDefinition(
      name: "Maple Campfire",
      value: 55,
      skillBonus: {},
      duration: Duration(minutes: 21),
      power: 21,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +21 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/maple_campfire.png",
    ),
  ),
  MAPLE_BONFIRE(
    FireItemDefinition(
      name: "Maple Bonfire",
      value: 180,
      skillBonus: {},
      duration: Duration(minutes: 34),
      power: 21,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +55 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/maple_bonfire.png",
    ),
  ),
  YEW_COOKFIRE(
    FireItemDefinition(
      name: "Yew Cookfire",
      value: 95,
      skillBonus: {SkillId.COOKING: 21, SkillId.HITPOINTS: 21},
      duration: Duration(minutes: 21),
      canCook: true,
      description: "Cooks food. +21 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/yew_cookfire.png",
    ),
  ),
  YEW_CAMPFIRE(
    FireItemDefinition(
      name: "Yew Campfire",
      value: 115,
      skillBonus: {},
      duration: Duration(minutes: 34),
      power: 34,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +34 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/yew_campfire.png",
    ),
  ),
  YEW_BONFIRE(
    FireItemDefinition(
      name: "Yew Bonfire",
      value: 380,
      skillBonus: {},
      duration: Duration(minutes: 55),
      power: 34,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +89 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/yew_bonfire.png",
    ),
  ),
  MAGIC_COOKFIRE(
    FireItemDefinition(
      name: "Magic Cookfire",
      value: 200,
      skillBonus: {SkillId.COOKING: 34, SkillId.HITPOINTS: 34},
      duration: Duration(minutes: 34),
      canCook: true,
      description: "Cooks food. +34 cooking and hitpoints while it burns.",
      iconAsset: "assets/images/entities/magic_cookfire.png",
    ),
  ),
  MAGIC_CAMPFIRE(
    FireItemDefinition(
      name: "Magic Campfire",
      value: 240,
      skillBonus: {},
      duration: Duration(minutes: 55),
      power: 55,
      reagentBurn: Duration(minutes: 5),
      description: "Kindling thrown on gives +55 to its stat for 5 minutes.",
      iconAsset: "assets/images/entities/magic_campfire.png",
    ),
  ),
  MAGIC_BONFIRE(
    FireItemDefinition(
      name: "Magic Bonfire",
      value: 800,
      skillBonus: {},
      duration: Duration(minutes: 89),
      power: 55,
      stokes: true,
      reagentBurn: Duration(minutes: 3),
      description:
          "Stoke it hot: kindling thrown on gives up to +144 to its "
          "stat for 3 minutes, cooling back down when the logs stop.",
      iconAsset: "assets/images/entities/magic_bonfire.png",
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
      ungated: true,
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
      ungated: true,
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
      ungated: true,
    ),
  ),

  // ── ARMOUR · SKILLING GEAR ──────────────────────────────────────
  // A set per gathering and crafting skill, and one for exploration, a
  // piece in each of six slots, at five tiers. Every piece pours its whole
  // rung into its one skill — +2,
  // +3, +5, +8, +13 a common piece — and asks for 1, 20, 40, 60 or 80 in it
  // (see SkillingGearTier). By skill, then tier, then slot.
  //
  // The Fisher's set comes only out of sunken caches, each tier from the
  // caches of the waters at its level (see sunkenCacheRolls)
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
  // ── ARMOUR · WOLF DEN SET ──────────────────────────────────────
  // Heavy leather split with speed: the combat stat always leads, speed
  // rides second. The minors drop off the den's bosses, the majors from its chest.
  WOLF_DEN_HELM(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Wolf Den Helm",
      value: 200,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_coif.png",
    ),
  ),
  WOLF_DEN_CLOAK(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Wolf Den Cloak",
      value: 200,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/wool_cloak.png",
    ),
  ),
  WOLF_DEN_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Wolf Den Gloves",
      value: 200,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_gloves.png",
    ),
  ),
  WOLF_DEN_BOOTS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Wolf Den Boots",
      value: 200,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_boots.png",
    ),
  ),
  WOLF_DEN_CHESTGUARD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Wolf Den Chestguard",
      value: 600,
      statWeights: {SkillId.DEFENCE: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_chest.png",
    ),
  ),
  WOLF_DEN_LEGGUARDS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Wolf Den Legguards",
      value: 400,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      iconAsset: "assets/icons/items/heavy_leather_pants.png",
    ),
  ),
  // Hides off the den's bosses and chest, on the slots the helm-to-boots set
  // leaves bare: heavy leather with one point of a stat on top.
  BEAR_HIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Bear Hide Bracers",
      value: 200,
      statWeights: {SkillId.STRENGTH: 2, SkillId.RECOVERY: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      description: "Cave bear hide, cured stiff and laced to the elbow.",
      iconAsset: "assets/icons/items/heavy_leather_bracers.png",
    ),
  ),
  WOLF_HIDE_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Wolf Hide Bracers",
      value: 200,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      description: "Alpha wolf hide, supple enough to run in.",
      iconAsset: "assets/icons/items/heavy_leather_bracers.png",
    ),
  ),
  WOLF_HIDE_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Wolf Hide Belt",
      value: 200,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      materialId: EquipmentMaterialId.HEAVY_LEATHER,
      description: "A strip of wolf hide, pulled tight for the chase.",
      iconAsset: "assets/icons/items/heavy_leather_belt.png",
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
  // Below the metal ladder: a rung under copper, dropped by the Rotwood
  // Scarecrow rather than smithed. Defence only, like the metal shields.
  WOOD_SHIELD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.OFFHAND,
      name: "Wood Shield",
      value: 8,
      fibLevel: 1,
      statWeights: {SkillId.DEFENCE: 2, SkillId.STRENGTH: 1},
      iconAsset: "assets/icons/items/wood_shield.png",
    ),
  ),
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
  BLACK_GREATSWORD(
    WeaponItemDefinition(
      name: "Black Greatsword",
      value: 240,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.GREATSWORD,
      description: "Mithril's equal, blackened and cold to hold.",
      iconAsset: "assets/icons/items/black_greatsword.png",
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
  BLACK_SWORD(
    WeaponItemDefinition(
      name: "Black Sword",
      value: 160,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.SWORD,
      description: "Mithril's equal, blackened and cold to hold.",
      iconAsset: "assets/icons/items/black_sword.png",
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
  BLACK_DAGGER(
    WeaponItemDefinition(
      name: "Black Dagger",
      value: 150,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.DAGGER,
      description: "Mithril's equal, blackened and cold to hold.",
      iconAsset: "assets/icons/items/black_dagger.png",
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
      value: 1,
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
      value: 1,
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
      value: 1,
      weaponType: WeaponTypeId.FISHING_ROD,
      fibLevel: 0,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  COPPER_FISHING_ROD(
    WeaponItemDefinition(
      name: "Copper Fishing Rod",
      value: 10,
      materialId: EquipmentMaterialId.COPPER,
      weaponType: WeaponTypeId.FISHING_ROD,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  IRON_FISHING_ROD(
    WeaponItemDefinition(
      name: "Iron Fishing Rod",
      value: 25,
      materialId: EquipmentMaterialId.IRON,
      weaponType: WeaponTypeId.FISHING_ROD,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  STEEL_FISHING_ROD(
    WeaponItemDefinition(
      name: "Steel Fishing Rod",
      value: 60,
      materialId: EquipmentMaterialId.STEEL,
      weaponType: WeaponTypeId.FISHING_ROD,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  MITHRIL_FISHING_ROD(
    WeaponItemDefinition(
      name: "Mithril Fishing Rod",
      value: 150,
      materialId: EquipmentMaterialId.MITHRIL,
      weaponType: WeaponTypeId.FISHING_ROD,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  ADAMANT_FISHING_ROD(
    WeaponItemDefinition(
      name: "Adamant Fishing Rod",
      value: 300,
      materialId: EquipmentMaterialId.ADAMANT,
      weaponType: WeaponTypeId.FISHING_ROD,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  RUNE_FISHING_ROD(
    WeaponItemDefinition(
      name: "Rune Fishing Rod",
      value: 600,
      materialId: EquipmentMaterialId.RUNE,
      weaponType: WeaponTypeId.FISHING_ROD,
      iconAsset: "assets/icons/items/simple_fishing_rod.png",
    ),
  ),
  DRAGON_FISHING_ROD(
    WeaponItemDefinition(
      name: "Dragon Fishing Rod",
      value: 1200,
      materialId: EquipmentMaterialId.DRAGON,
      weaponType: WeaponTypeId.FISHING_ROD,
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
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      iconAsset: "assets/icons/items/chicken_charm.png",
    ),
  ),
  REDCAP_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Redcap Ring",
      value: 150,
      fibLevel: 2,
      statWeights: {SkillId.STRENGTH: 2, SkillId.RECOVERY: 1},
      description: "A band of hardened fungus, warm to the touch.",
      iconAsset: "assets/icons/items/redcap_ring.png",
    ),
  ),
  MOOD_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Mood Ring",
      value: 150,
      fibLevel: 0,
      statWeights: {SkillId.DEFENCE: 2, SkillId.STAMINA: 1},
      iconAsset: "assets/icons/items/mood_ring.png",
    ),
  ),
  GOD_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "God Ring",
      value: 1,
      description: "Dev item: +1000 to every stat.",
      statWeights: {
        SkillId.STAMINA: 1,
        SkillId.SPEED: 1,
        SkillId.STRENGTH: 1,
        SkillId.RECOVERY: 1,
        SkillId.EXPLORATION: 1,
        SkillId.HITPOINTS: 1,
        SkillId.ATTACK: 1,
        SkillId.RANGED: 1,
        SkillId.MAGIC: 1,
        SkillId.DEFENCE: 1,
        SkillId.WOODCUTTING: 1,
        SkillId.MINING: 1,
        SkillId.FISHING: 1,
        SkillId.HERBALISM: 1,
        SkillId.FIREMAKING: 1,
        SkillId.LEATHERWORKING: 1,
        SkillId.BLACKSMITHING: 1,
        SkillId.TAILORING: 1,
        SkillId.ENCHANTING: 1,
        SkillId.JEWELCRAFTING: 1,
        SkillId.FLETCHING: 1,
        SkillId.COOKING: 1,
        SkillId.ALCHEMY: 1,
      },
      fixedStats: {
        SkillId.STAMINA: 1000,
        SkillId.SPEED: 1000,
        SkillId.STRENGTH: 1000,
        SkillId.RECOVERY: 1000,
        SkillId.EXPLORATION: 1000,
        SkillId.HITPOINTS: 1000,
        SkillId.ATTACK: 1000,
        SkillId.RANGED: 1000,
        SkillId.MAGIC: 1000,
        SkillId.DEFENCE: 1000,
        SkillId.WOODCUTTING: 1000,
        SkillId.MINING: 1000,
        SkillId.FISHING: 1000,
        SkillId.HERBALISM: 1000,
        SkillId.FIREMAKING: 1000,
        SkillId.LEATHERWORKING: 1000,
        SkillId.BLACKSMITHING: 1000,
        SkillId.TAILORING: 1000,
        SkillId.ENCHANTING: 1000,
        SkillId.JEWELCRAFTING: 1000,
        SkillId.FLETCHING: 1000,
        SkillId.COOKING: 1000,
        SkillId.ALCHEMY: 1000,
      },
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
      fibLevel: 4,
      statWeights: {SkillId.ATTACK: 8, SkillId.DEFENCE: 4},
      iconAsset: "assets/icons/items/spider_silk_necklace.png",
    ),
  ),
  WEBBED_CLOAK(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Webbed Cloak",
      value: 100,
      fibLevel: 3,
      statWeights: {SkillId.DEFENCE: 2, SkillId.ATTACK: 1},
      description: "Layer on layer of spider webbing, light and tough.",
      iconAsset: "assets/icons/items/webbed_cloak.png",
    ),
  ),
  // Spider Den's speed trim: a bracer off the first boss and a shoulder
  // piece off the last, in the cloak's weave.
  WEBBED_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Webbed Bracers",
      value: 100,
      fibLevel: 3,
      statWeights: {SkillId.DEFENCE: 2, SkillId.SPEED: 1},
      description: "Webbing wound tight about the wrist, light as thread.",
      iconAsset: "assets/icons/items/heavy_leather_bracers.png",
    ),
  ),
  BROODMOTHERS_MANTLE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Broodmother's Mantle",
      value: 120,
      fibLevel: 5,
      statWeights: {SkillId.DEFENCE: 2, SkillId.SPEED: 1},
      description: "Silk spun over the shoulders of a thousand hatchlings.",
      iconAsset: "assets/icons/items/iron_pauldrons.png",
    ),
  ),
  VENOMFANG_RING(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FINGER,
      name: "Venomfang Ring",
      value: 100,
      fibLevel: 3,
      statWeights: {SkillId.ATTACK: 2, SkillId.STRENGTH: 1},
      description: "A spider's fang set in silk-wound bone.",
      iconAsset: "assets/icons/items/venomfang_ring.png",
    ),
  ),

  // Drowned Fen: Spider Den's three pieces at the same strength - two
  // trim pieces at fib 4 off the first two bosses, an epic major at fib 5
  // off the last - on the slots Spider Den leaves empty.
  CROWQUILL_BRACERS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WRIST,
      name: "Crowquill Bracers",
      value: 100,
      fibLevel: 3,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      description: "Black quills bound edge-on along the forearm.",
      iconAsset: "assets/icons/items/crowquill_bracers.png",
    ),
  ),
  OOZE_SLICK_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Ooze-Slick Belt",
      value: 100,
      fibLevel: 3,
      statWeights: {SkillId.STRENGTH: 2, SkillId.STAMINA: 1},
      description: "Hardened slime, cinched tight. Blows slide off it.",
      iconAsset: "assets/icons/items/ooze_slick_belt.png",
    ),
  ),
  MURKJAW_PAULDRONS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.SHOULDER,
      name: "Murkjaw Pauldrons",
      value: 120,
      fibLevel: 4,
      statWeights: {SkillId.DEFENCE: 8, SkillId.STRENGTH: 4},
      description: "The Matriarch's scaled shoulders, still heavy with bog.",
      iconAsset: "assets/icons/items/murkjaw_pauldrons.png",
    ),
  ),
  // Tempest Reach: a rung past the Drowned Fen. The first two bosses each
  // drop a fib 5 armour trim and a weapon at rune damage; Tempest drops a
  // fib 6 major and a weapon at dragon damage. A weapon's fibLevel is its
  // material rung plus its shape's offset, so the sword and scepter sit one
  // higher than the dagger to land on the same rung of damage.
  WARLORDS_CLEAVER(
    WeaponItemDefinition(
      name: "Warlord's Cleaver",
      value: 150,
      weaponType: WeaponTypeId.SWORD,
      fibLevel: 5,
      description: "A notched slab of steel that has ended a lot of raids.",
      iconAsset: "assets/icons/items/warlords_cleaver.png",
    ),
  ),
  WARLORDS_WARHELM(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Warlord's Warhelm",
      value: 130,
      fibLevel: 4,
      statWeights: {SkillId.DEFENCE: 2, SkillId.STRENGTH: 1},
      description: "A horned iron helm, dented from the inside out.",
      iconAsset: "assets/icons/items/warlords_warhelm.png",
    ),
  ),
  ALPHAS_FANG(
    WeaponItemDefinition(
      name: "Alpha's Fang",
      value: 150,
      weaponType: WeaponTypeId.DAGGER,
      fibLevel: 4,
      description: "The Alpha's own fang, bound to a bone grip.",
      iconAsset: "assets/icons/items/alphas_fang.png",
    ),
  ),
  ALPHAS_MANTLE(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Alpha's Mantle",
      value: 130,
      fibLevel: 4,
      statWeights: {SkillId.ATTACK: 2, SkillId.SPEED: 1},
      description: "A sabertooth pelt worn the way it wore it.",
      iconAsset: "assets/icons/items/alphas_mantle.png",
    ),
  ),
  STORMCALLERS_SCEPTER(
    WeaponItemDefinition(
      name: "Stormcaller's Scepter",
      value: 200,
      weaponType: WeaponTypeId.SCEPTER,
      fibLevel: 6,
      description: "A rod of fused sand that hums before a strike.",
      iconAsset: "assets/icons/items/stormcallers_scepter.png",
    ),
  ),
  GALEWRAP_GAUNTLETS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Galewrap Gauntlets",
      value: 180,
      fibLevel: 5,
      statWeights: {SkillId.DEFENCE: 8, SkillId.ATTACK: 4},
      description: "Strips of storm-cloth that never quite stop moving.",
      iconAsset: "assets/icons/items/galewrap_gauntlets.png",
    ),
  ),
  // ── dungeon chest and camp uniques ──────────────────────────────
  // See design/DUNGEON_LOOT_GUIDE.md: one boss owns each, and a chest's
  // exclusive takes a slot its bosses leave open.
  FARMHAND_GLOVES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Farmhand's Gloves",
      value: 40,
      fibLevel: 0,
      statWeights: {SkillId.STRENGTH: 2, SkillId.STAMINA: 1},
      description: "Cracked from a season of pitching hay.",
      iconAsset: "assets/icons/items/farmhands_gloves.png",
    ),
  ),
  SERGEANTS_SHIV(
    WeaponItemDefinition(
      name: "Sergeant's Shiv",
      value: 60,
      weaponType: WeaponTypeId.DAGGER,
      fibLevel: 1,
      description: "Short, ugly and quick. The sergeant's favourite argument.",
      iconAsset: "assets/icons/items/sergeants_shiv.png",
    ),
  ),
  WARBAND_BELT(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.WAIST,
      name: "Warband Belt",
      value: 60,
      fibLevel: 1,
      statWeights: {SkillId.ATTACK: 2, SkillId.STRENGTH: 1},
      description: "Hung with the trophies of a dozen raids.",
      iconAsset: "assets/icons/items/warband_belt.png",
    ),
  ),
  CAMP_BANNER_CLOAK(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Camp Banner Cloak",
      value: 60,
      fibLevel: 1,
      statWeights: {SkillId.DEFENCE: 2, SkillId.ATTACK: 1},
      description:
          "The goblin camp's banner, worn as a cloak by whoever took it.",
      iconAsset: "assets/icons/items/camp_banner_cloak.png",
    ),
  ),
  BROODSILK_LEGGINGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Broodsilk Leggings",
      value: 160,
      fibLevel: 4,
      statWeights: {SkillId.SPEED: 2, SkillId.STAMINA: 1},
      description: "Woven from the Broodmother's own silk. They never snag.",
      iconAsset: "assets/icons/items/broodsilk_leggings.png",
    ),
  ),
  MURKHIDE_CUIRASS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.CHEST,
      name: "Murkhide Cuirass",
      value: 160,
      fibLevel: 4,
      statWeights: {SkillId.DEFENCE: 2, SkillId.STRENGTH: 1},
      description: "Murkjaw hide, cured black in the fen's own water.",
      iconAsset: "assets/icons/items/murkhide_cuirass.png",
    ),
  ),
  STORMHIDE_LEGS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.LEGS,
      name: "Stormhide Legs",
      value: 220,
      fibLevel: 5,
      statWeights: {SkillId.STRENGTH: 2, SkillId.STAMINA: 1},
      description: "Sabertooth hide stitched with wind-mote thread.",
      iconAsset: "assets/icons/items/stormhide_legs.png",
    ),
  ),
  QUEENS_TRAIN(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Queen's Train",
      value: 260,
      fibLevel: 5,
      statWeights: {SkillId.SPEED: 2, SkillId.RECOVERY: 1},
      description: "The Goblin Queen's trailing cloak, lighter than it looks.",
      iconAsset: "assets/icons/items/queens_train.png",
    ),
  ),

  // ── ARMOUR · TATTERED CLOTH ────────────────────────────────────
  // Grave-rags off the dark forest's zombies: pure attack, and a low rung
  // whatever the slot — a rare drop worth wearing early, not a set to chase.
  TATTERED_HOOD(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HEAD,
      name: "Tattered Hood",
      value: 20,
      fibLevel: 2,
      statWeights: {SkillId.ATTACK: 1},
      iconAsset: "assets/icons/items/tattered_hood.png",
    ),
  ),
  TATTERED_CLOAK(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.BACK,
      name: "Tattered Cloak",
      value: 20,
      fibLevel: 2,
      statWeights: {SkillId.ATTACK: 1},
      iconAsset: "assets/icons/items/tattered_cloak.png",
    ),
  ),
  TATTERED_WRAPS(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.HANDS,
      name: "Tattered Wraps",
      value: 20,
      fibLevel: 2,
      statWeights: {SkillId.ATTACK: 1},
      iconAsset: "assets/icons/items/tattered_wraps.png",
    ),
  ),
  TATTERED_SHOES(
    EquipmentItemDefinition(
      armorSlot: ArmorSlots.FEET,
      name: "Tattered Shoes",
      value: 20,
      fibLevel: 2,
      statWeights: {SkillId.ATTACK: 1},
      iconAsset: "assets/icons/items/tattered_shoes.png",
    ),
  ),

  // ── SCOUTING MAPS ───────────────────────────────────────────────
  // by zone; which zone each reveals is [ScoutingMaps.zoneFor]
  SCOUTING_MAP_SOUTHWOOD_FOREST(
    ScoutingMapItemDefinition(
      name: "Scouting Map of Southwood Forest",
      value: 400,
      description:
          "A hand-drawn survey of Southwood Forest. Using it uncovers "
          "${ScoutingMapItemDefinition.discoveries} discoveries there at once.",
      iconAsset: "assets/icons/items/scouting_map.png",
    ),
  ),
  SCOUTING_MAP_DARKWOOD_FOREST(
    ScoutingMapItemDefinition(
      name: "Scouting Map of Darkwood Forest",
      value: 600,
      description:
          "A hand-drawn survey of Darkwood Forest. Using it uncovers "
          "${ScoutingMapItemDefinition.discoveries} discoveries there at once.",
      iconAsset: "assets/icons/items/scouting_map.png",
    ),
  ),
  SCOUTING_MAP_FOREST_MINE(
    ScoutingMapItemDefinition(
      name: "Scouting Map of Forest Mine",
      value: 800,
      description:
          "A hand-drawn survey of Forest Mine. Using it uncovers "
          "${ScoutingMapItemDefinition.discoveries} discoveries there at once.",
      iconAsset: "assets/icons/items/scouting_map.png",
    ),
  ),

  // sold at the Farmer's Stall; also fished out of the zone's sunken caches
  SCOUTING_MAP_TUTORIAL_FARM(
    ScoutingMapItemDefinition(
      name: "Scouting Map of Southglen Meadow",
      value: 200,
      description:
          "A hand-drawn survey of Southglen Meadow. Using it uncovers "
          "${ScoutingMapItemDefinition.discoveries} discoveries there at once.",
      iconAsset: "assets/icons/items/scouting_map.png",
    ),
  ),
  SCOUTING_MAP_SWAMP(
    ScoutingMapItemDefinition(
      name: "Scouting Map of Blackmire Swamp",
      value: 900,
      description:
          "A hand-drawn survey of Blackmire Swamp. Using it uncovers "
          "${ScoutingMapItemDefinition.discoveries} discoveries there at once.",
      iconAsset: "assets/icons/items/scouting_map.png",
    ),
  ),
  SCOUTING_MAP_MAPLEWATER_LAKE(
    ScoutingMapItemDefinition(
      name: "Scouting Map of Maplewater Lake",
      value: 1200,
      description:
          "A hand-drawn survey of Maplewater Lake. Using it uncovers "
          "${ScoutingMapItemDefinition.discoveries} discoveries there at once.",
      iconAsset: "assets/icons/items/scouting_map.png",
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
