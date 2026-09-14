import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/crafting_recipe.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Blacksmithing. Smelting ore into bars, then bars into armour and weapons.
///
/// The unit of content here is the *tier*, not the recipe. A metal states the
/// level it opens at and what its bar is smelted from; a piece states how far
/// over that level its shape sits and how many bars it eats. Every forging
/// recipe in the skill is one (metal, piece) pair, so the whole ladder is
/// [_tiers] × [_pieces] and a new metal is one row rather than sixteen
/// hand-written recipes that can drift apart — which is exactly how the
/// mithril bar came to cost no coal while the comment over it said two.
///
/// Recipe ids are the save format, so the generated `smelt_<metal>_bar` and
/// `forge_<metal>_<piece>` must keep spelling the ids the catalog already
/// shipped. That is what pins [_Piece.suffix] to the [ItemId] suffix and
/// [_Tier.name] to the metal's lowercase name.
final List<CraftingRecipe> blacksmithingRecipes = [
  for (final tier in _tiers) ...[
    _smelt(tier),
    for (final piece in _pieces) _forge(tier, piece),
  ],

  // ── GOLD (jewellery line) ───────────────────────────────────────
  // Gold is too soft for armour, so it is not a tier: its bar exists to be
  // turned into ring and necklace bases by Jewelcrafting, not forged into
  // gear here. Smelting the bar stays in this skill; shaping it into a band
  // does not — see jc_gold_ring / jc_gold_necklace in jewelcrafting_recipes.
  CraftingRecipe(
    id: 'smelt_gold_bar',
    name: 'Gold Bar',
    skill: SkillId.BLACKSMITHING,
    levelRequirement: 25,
    xp: 4,
    inputs: {ItemId.GOLD_ORE: 1},
    output: [WeightedDropTableEntry(id: ItemId.GOLD_BAR, count: 1, weight: 1)],
  ),
];

/// The thirteen rungs a tier is forged across, in [_Piece.rung] order.
///
/// A rung is an offset over the metal's own level, never an absolute one, so
/// the same spacing can be reused by every tier that has the same amount of
/// room above it.
///
/// The three bottom metals are spaced at two levels a rung. They have a
/// twenty-level gap to fill and only thirteen pieces to fill it with, so a
/// single-level spread would finish a tier six levels short of the next one
/// opening and leave the player with nothing left to forge. At this spacing
/// the tail of a tier runs past the head of the one above it, which is the
/// overlap the ladder is supposed to have.
const _stretchedRungs = <int>[1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21, 23, 25];

/// Mithril and up sit ten levels apart, so a rung a level is already more
/// than enough to overlap the tier above: mithril's greatsword (73) is only
/// reached well after adamant's tools (71) have opened.
const _tightRungs = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13];

/// Dragon opens at 90 and the skill caps at 99 ([SkillData] builds a
/// 99-level xp table), so the top tier has nine levels of room for thirteen
/// pieces. The rungs are squeezed to fit rather than allowed to run past the
/// cap — a recipe at 103 is a recipe nobody can ever reach — which means a
/// few dragon pieces share a level. The order is untouched.
const _cappedRungs = <int>[1, 2, 2, 3, 4, 4, 5, 6, 6, 7, 8, 8, 9];

/// A metal: where its ladder starts, and what its bar is made of.
class _Tier {
  const _Tier({
    required this.name,
    required this.itemPrefix,
    required this.baseLevel,
    required this.bar,
    required this.smeltInputs,
    required this.smeltXp,
    required this.xpPerBar,
    required this.rungs,
  });

  /// The metal's lowercase name. Half of every recipe id in the tier.
  final String name;

  /// The metal's [ItemId] prefix. Usually [name] uppercased, but the bar and
  /// ore for two tiers were named for the mineral rather than the metal
  /// (`ADAMANTITE_BAR`, `RUNITE_BAR`) and those names are save format.
  final String itemPrefix;

  /// The level the metal opens at: what it costs to smelt its bar, and the
  /// floor every piece's rung is measured from.
  final int baseLevel;

  final ItemId bar;

  /// What one bar is smelted from. Steel is the one alloy — coal and iron
  /// *ore*, not an iron bar, so a steel bar is one trip through the furnace
  /// and not two. Every other metal smelts from its own ore alone.
  final Map<ItemId, int> smeltInputs;

  final double smeltXp;

  /// What forging one bar's worth of a piece pays. A piece's award is this
  /// times [_Piece.bars], so the heavy shapes pay for the bars they eat.
  final double xpPerBar;

  final List<int> rungs;
}

/// A shape, and what it costs in bars. Shared by every metal.
class _Piece {
  const _Piece({required this.suffix, required this.rung, required this.bars});

  /// The [ItemId] suffix, e.g. `HELMET` in `MITHRIL_HELMET`. Lowercased, it
  /// is also the second half of the recipe id, so this cannot be renamed
  /// without orphaning saved craft queues.
  final String suffix;

  /// Which of the thirteen rungs the shape sits on, 1-based.
  final int rung;

  final int bars;
}

const _tiers = <_Tier>[
  _Tier(
    name: 'copper',
    itemPrefix: 'COPPER',
    baseLevel: 1,
    bar: ItemId.COPPER_BAR,
    smeltInputs: {ItemId.COPPER_ORE: 1},
    smeltXp: 1,
    xpPerBar: 2,
    rungs: _stretchedRungs,
  ),
  _Tier(
    name: 'iron',
    itemPrefix: 'IRON',
    baseLevel: 20,
    bar: ItemId.IRON_BAR,
    smeltInputs: {ItemId.IRON_ORE: 1},
    smeltXp: 5,
    xpPerBar: 5,
    rungs: _stretchedRungs,
  ),
  _Tier(
    name: 'steel',
    itemPrefix: 'STEEL',
    baseLevel: 40,
    bar: ItemId.STEEL_BAR,
    smeltInputs: {ItemId.COAL: 1, ItemId.IRON_ORE: 1},
    smeltXp: 7.5,
    xpPerBar: 7.5,
    rungs: _stretchedRungs,
  ),
  _Tier(
    name: 'mithril',
    itemPrefix: 'MITHRIL',
    baseLevel: 60,
    bar: ItemId.MITHRIL_BAR,
    smeltInputs: {ItemId.MITHRIL_ORE: 1},
    smeltXp: 8,
    xpPerBar: 10,
    rungs: _tightRungs,
  ),
  _Tier(
    name: 'adamant',
    itemPrefix: 'ADAMANT',
    baseLevel: 70,
    bar: ItemId.ADAMANTITE_BAR,
    smeltInputs: {ItemId.ADAMANTITE_ORE: 1},
    smeltXp: 12.5,
    xpPerBar: 12.5,
    rungs: _tightRungs,
  ),
  _Tier(
    name: 'rune',
    itemPrefix: 'RUNE',
    baseLevel: 80,
    bar: ItemId.RUNITE_BAR,
    smeltInputs: {ItemId.RUNEITE_ORE: 1},
    smeltXp: 15,
    xpPerBar: 15,
    rungs: _tightRungs,
  ),
  _Tier(
    name: 'dragon',
    itemPrefix: 'DRAGON',
    baseLevel: 90,
    bar: ItemId.DRAGON_BAR,
    smeltInputs: {ItemId.DRAGON_ORE: 1},
    smeltXp: 17.5,
    xpPerBar: 17.5,
    rungs: _cappedRungs,
  ),
];

/// Every shape a tier is forged into, in the order it opens.
///
/// The three gathering tools share rung 1 deliberately: pickaxe, axe and
/// sickle are one step, and there is no reason a tier should open mining
/// before herbalism.
const _pieces = <_Piece>[
  _Piece(suffix: 'PICKAXE', rung: 1, bars: 1),
  _Piece(suffix: 'AXE', rung: 1, bars: 1),
  _Piece(suffix: 'SICKLE', rung: 1, bars: 1),
  _Piece(suffix: 'DAGGER', rung: 2, bars: 1),
  _Piece(suffix: 'HELMET', rung: 3, bars: 1),
  _Piece(suffix: 'BRACERS', rung: 4, bars: 1),
  _Piece(suffix: 'CHESTPLATE', rung: 5, bars: 3),
  _Piece(suffix: 'GLOVES', rung: 6, bars: 1),
  _Piece(suffix: 'SWORD', rung: 7, bars: 2),
  _Piece(suffix: 'BELT', rung: 8, bars: 1),
  _Piece(suffix: 'LEGS', rung: 9, bars: 2),
  _Piece(suffix: 'BOOTS', rung: 10, bars: 1),
  _Piece(suffix: 'PAULDRONS', rung: 11, bars: 2),
  _Piece(suffix: 'SHIELD', rung: 12, bars: 2),
  _Piece(suffix: 'GREATSWORD', rung: 13, bars: 3),
];

CraftingRecipe _smelt(_Tier tier) => CraftingRecipe(
  id: 'smelt_${tier.name}_bar',
  name: tier.bar.definition.name,
  skill: SkillId.BLACKSMITHING,
  levelRequirement: tier.baseLevel,
  xp: tier.smeltXp,
  inputs: tier.smeltInputs,
  output: [WeightedDropTableEntry(id: tier.bar, count: 1, weight: 1)],
);

CraftingRecipe _forge(_Tier tier, _Piece piece) {
  final item = _itemFor(tier, piece);
  return CraftingRecipe(
    id: 'forge_${tier.name}_${piece.suffix.toLowerCase()}',
    name: item.definition.name,
    skill: SkillId.BLACKSMITHING,
    levelRequirement: tier.baseLevel + tier.rungs[piece.rung - 1],
    xp: tier.xpPerBar * piece.bars,
    inputs: {tier.bar: piece.bars},
    output: [WeightedDropTableEntry(id: item, count: 1, weight: 1)],
  );
}

/// The piece a (metal, shape) pair forges. Throws rather than silently
/// dropping a recipe, so a tier that is missing an item id fails loudly at
/// startup instead of quietly shipping with a hole in its ladder.
ItemId _itemFor(_Tier tier, _Piece piece) {
  final name = '${tier.itemPrefix}_${piece.suffix}';
  return ItemId.values.firstWhere(
    (id) => id.name == name,
    orElse: () => throw StateError(
      'blacksmithing wants to forge $name, which is not in the item catalog',
    ),
  );
}
