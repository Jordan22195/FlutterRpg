import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/crafting_controller.dart';
import '../data/skill_data.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'item_stack_tile.dart';
import 'progress_bars.dart';
import 'sprite_frame.dart';

/// One side of a recipe: a tinted frame with the item in it and a count
/// pill over its bottom-right corner. Tapping it opens the item's details;
/// the card around it keeps the rest of its area for picking the recipe.
class RecipeTile extends StatelessWidget {
  const RecipeTile({
    super.key,
    required this.id,
    required this.count,
    required this.kind,
    this.depleted = false,
    this.borderColor,
  });

  final ItemId id;

  /// What the pill says: an input's cost for one craft, or how many of the
  /// output can be made.
  final int count;
  final SpriteKind kind;

  /// Nothing can be made: the art dims and the pill drops its zero.
  final bool depleted;

  /// Overrides the frame's border, e.g. to flag an input that is short.
  final Color? borderColor;

  static const double size = 52;

  @override
  Widget build(BuildContext context) {
    final tint = SpriteFrame.tintFor(context, kind);
    final border = borderColor ?? tint.border;

    return Semantics(
      button: true,
      label: '${id.definition.name}, $count, details',
      excludeSemantics: true,
      child: GestureDetector(
        // opaque: the whole frame is the tile's own target, so a tap on it
        // reads the item rather than falling through to pick the recipe
        behavior: HitTestBehavior.opaque,
        onTap: () => showItemInfoDialog(context, id),
        child: _frame(tint.fill, border),
      ),
    );
  }

  Widget _frame(Color fill, Color border) {
    return SizedBox(
      width: size + 6,
      height: size + 6,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: borderColor != null ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Opacity(
              opacity: depleted ? 0.45 : 1,
              child: SpriteFrame.sprite(id, size: 40),
            ),
          ),
          if (!(depleted && count <= 0))
            Positioned(
              right: 0,
              bottom: 0,
              child: CountPill(count: count, borderColor: border),
            ),
          // a food says how much it heals, top-left, as on every item tile
          if (HealBadge.amountFor(id) case final heal?)
            Positioned(
              left: 3,
              top: 3,
              child: HealBadge(amount: heal, tileSize: size),
            ),
        ],
      ),
    );
  }
}

/// The recipe's product, badged with how many of it the inventory can
/// currently make. A recipe with nothing to make of it reads as depleted:
/// the art dims and the badge drops its zero.
class RecipeOutputTile extends StatelessWidget {
  const RecipeOutputTile({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);
    if (recipe.output.isEmpty) return const SizedBox.shrink();
    final craftable = crafting.getMaxNumberCraftsForRecipe(recipeId);

    return RecipeTile(
      id: recipe.output.first.id,
      count: craftable,
      kind: RecipeCard.outputKind(recipe.skill),
      depleted: craftable <= 0,
    );
  }
}

/// One recipe, read left to right: what it costs, an arrow, what it makes,
/// and the level it asks for.
///
/// The card carries the two ways a recipe can be unavailable, which are not
/// the same kind of problem:
///
/// - too low a level is permanent until the skill is trained, so a picker row
///   ([lockWhenUnderLevel]) locks it outright and refuses the tap
/// - missing materials is a shortfall you can go and fix, so the recipe greys
///   out and is flagged red down to which input is short, but stays
///   selectable: picking it is how you decide what to go and gather
class RecipeCard extends StatelessWidget {
  /// The shortfall marker. Not the scheme's error colour: on a dark theme
  /// that resolves to a pale pink, which reads as decoration rather than as
  /// the thing standing between you and the craft.
  static const Color missingMaterialColor = GameColors.missingColor;

  /// The picker's mark on the row that is already in play. Exposed so the
  /// benches that build their own rows (the enchanting tiers) can mark
  /// theirs the same way.
  static ShapeBorder selectedShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: context.palette.text, width: 2),
    );
  }

  /// The fill that goes with [selectedShape].
  static Color selectedFill(BuildContext context) => context.palette.raised;

  const RecipeCard({
    super.key,
    required this.recipeId,
    required this.onTap,
    this.lockWhenUnderLevel = false,
    this.selected = false,
    this.height = 76,
  });

  final String recipeId;
  final VoidCallback? onTap;

  /// Set on rows that are a choice - the recipe picker. The card that merely
  /// displays the current selection leaves this off: its tap opens the
  /// picker, and locking that would strand the player on the recipe.
  final bool lockWhenUnderLevel;

  /// Marks this row as the recipe already in play. Set by the picker, and by
  /// screens that stack several cards at once — the firepit's firemaking and
  /// cooking pair — where the mark says which one the action button runs. A
  /// screen showing a single card leaves it off: highlighting the only choice
  /// would say nothing.
  final bool selected;

  final double height;

  /// Fires and the things cooked on them sit in the fire tint; everything
  /// else a station makes sits in the crafting tint.
  static SpriteKind outputKind(SkillId skill) =>
      skill == SkillId.FIREMAKING || skill == SkillId.COOKING
      ? SpriteKind.fire
      : SpriteKind.crafting;

  /// "25" for a whole amount, "7.5" for a fractional one.
  static String _formatXp(double xp) =>
      xp == xp.roundToDouble() ? '${xp.round()}' : xp.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);

    if (recipe.output.isEmpty) {
      return Card(
        margin: EdgeInsets.zero,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: Text(
                'Select a recipe',
                style: HearthText.rowTitle.copyWith(
                  fontSize: 15,
                  color: palette.textMuted,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final inputs = recipe.inputs.entries.toList();
    final underLevel = !crafting.meetsRecipeLevelRequirement(recipeId);
    final locked = lockWhenUnderLevel && underLevel;
    // a recipe above the player's level is unavailable on its own terms,
    // locked or not; flagging the materials too would just be noise on top
    // of that, so the red only marks a shortfall the player could go and fix
    final missingMaterials =
        !underLevel && !crafting.hasMaterialsForRecipe(recipeId);

    // both kinds of unavailable grey the recipe out. the dim is applied per
    // element rather than over the whole card, so the short input keeps its
    // red border at full strength — that marker is the one thing the player
    // is meant to read off a greyed row
    final dimmed = underLevel || missingMaterials;
    Widget dim(Widget child) =>
        dimmed ? Opacity(opacity: 0.45, child: child) : child;

    return Card(
      margin: EdgeInsets.zero,
      color: selected ? selectedFill(context) : null,
      shape: selected ? selectedShape(context) : null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        // a locked recipe cannot be picked
        onTap: locked ? null : onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 14),
            child: Row(
              children: [
                // what it costs (left)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (int i = 0; i < inputs.length; i++) ...[
                          // the input actually short of its cost is the one
                          // worth pointing at, so it is flagged red and stays
                          // undimmed while the rest of the row greys
                          if (missingMaterials &&
                              crafting.getItemCountInPlayerInventory(
                                    inputs[i].key,
                                  ) <
                                  inputs[i].value)
                            RecipeTile(
                              id: inputs[i].key,
                              count: inputs[i].value,
                              kind: SpriteKind.crafting,
                              borderColor: missingMaterialColor,
                            )
                          else
                            dim(
                              RecipeTile(
                                id: inputs[i].key,
                                count: inputs[i].value,
                                kind: SpriteKind.crafting,
                              ),
                            ),
                          if (i != inputs.length - 1)
                            dim(
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: palette.chevron,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                dim(
                  Icon(Icons.arrow_forward, size: 20, color: palette.chevron),
                ),
                const SizedBox(width: 10),

                // what it makes, badged with how many the inventory can make
                dim(RecipeOutputTile(recipeId: recipeId)),
                const Spacer(),

                // the level it asks for, and what one craft is worth
                dim(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (locked) ...[
                            Icon(Icons.lock, size: 14, color: palette.text),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            'Lv ${recipe.levelRequirement}',
                            style: HearthText.xpValue.copyWith(
                              color: palette.text,
                            ),
                          ),
                        ],
                      ),
                      // what one craft is worth, in the xp gold every xp
                      // number wears
                      Text.rich(
                        TextSpan(
                          text: '+${_formatXp(recipe.xp)}',
                          style: HearthText.xpValue.copyWith(
                            fontSize: 13,
                            color: context.gameColors.xp,
                          ),
                          children: [
                            TextSpan(
                              text: ' xp',
                              style: HearthText.xpSuffix.copyWith(
                                fontSize: 11,
                                color: context.gameColors.xp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
