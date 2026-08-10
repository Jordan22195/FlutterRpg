import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/crafting_controller.dart';

/// The recipe's product, badged with how many of it the inventory can
/// currently make. A recipe with nothing to make of it reads as depleted:
/// the art dims and the badge holds the zero, which is the whole point.
class RecipeOutputTile extends StatelessWidget {
  const RecipeOutputTile({super.key, required this.recipeId});

  final String recipeId;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);
    if (recipe.output.isEmpty) {
      return ItemStackTile(size: 1, count: 1, id: ItemId.NULL);
    }
    final output = recipe.output;
    final craftable = crafting.getMaxNumberCraftsForRecipe(recipeId);

    // a fire's burn time belongs to the firepit it is burning in, not to the
    // recipe, so the countdown lives on the firepit screen's hero tile
    return ItemStackTile(
      size: 52,
      id: output.first.id,
      count: craftable,
      depleted: craftable <= 0,
      // the badge is the count of craftable, so it has to hold a 1
      alwaysShowCount: true,
    );
  }
}

/// One recipe: what it makes on the left, what it costs on the right.
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
  static const Color missingMaterialColor = Color(0xFFE53935);

  /// The picker's mark on the row that is already in play. Exposed so the
  /// benches that build their own rows (the enchanting tiers) can mark
  /// theirs the same way.
  static ShapeBorder selectedShape(BuildContext context) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
    );
  }

  /// The fill that goes with [selectedShape].
  static Color selectedFill(BuildContext context) {
    return Theme.of(
      context,
    ).colorScheme.primaryContainer.withValues(alpha: 0.35);
  }

  const RecipeCard({
    super.key,
    required this.recipeId,
    required this.onTap,
    this.lockWhenUnderLevel = false,
    this.selected = false,
    this.height = 68,
  });

  final String recipeId;
  final VoidCallback? onTap;

  /// Set on rows that are a choice - the recipe picker. The card that merely
  /// displays the current selection leaves this off: its tap opens the
  /// picker, and locking that would strand the player on the recipe.
  final bool lockWhenUnderLevel;

  /// Marks this row as the recipe already in play. Only the picker sets it:
  /// the card that displays the current selection is always showing it, so
  /// highlighting there would say nothing.
  final bool selected;

  final double height;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);

    if (recipe.output.isEmpty) {
      return Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: const Center(child: Text('Select a recipe')),
          ),
        ),
      );
    }

    final inputs = recipe.inputs.entries.toList();
    final locked =
        lockWhenUnderLevel && !crafting.meetsRecipeLevelRequirement(recipeId);
    // a locked recipe is already unavailable on its own terms; flagging the
    // materials too would just be noise on top of that
    final missingMaterials =
        !locked && !crafting.hasMaterialsForRecipe(recipeId);

    // both kinds of unavailable grey the recipe out. the dim is applied per
    // element rather than over the whole card, so the short input keeps its
    // red border at full strength — that marker is the one thing the player
    // is meant to read off a greyed row
    final dimmed = locked || missingMaterials;
    Widget dim(Widget child) =>
        dimmed ? Opacity(opacity: 0.45, child: child) : child;

    // the shortfall is marked on the input that is actually short, not on
    // the whole card: outlining the row says only that something is wrong,
    // where the tile says which thing. the card's own outline is the
    // picker's mark for the recipe already in play.
    return Card(
      color: selected ? selectedFill(context) : null,
      shape: selected ? selectedShape(context) : null,
      child: InkWell(
        // a locked recipe cannot be picked
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Output (left)
                dim(RecipeOutputTile(recipeId: recipeId)),
                const SizedBox(width: 12),
                dim(const Icon(Icons.arrow_back, size: 18)),
                const SizedBox(width: 12),

                // Inputs (right)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (int i = 0; i < inputs.length; i++) ...[
                            // the input actually short of its cost is the one
                            // worth pointing at, so it is flagged red and
                            // stays undimmed while the rest of the row greys
                            if (missingMaterials &&
                                crafting.getItemCountInPlayerInventory(
                                      inputs[i].key,
                                    ) <
                                    inputs[i].value)
                              ItemStackTile(
                                size: 44,
                                id: inputs[i].key,
                                count: inputs[i].value,
                                borderColor: missingMaterialColor,
                                alwaysShowCount: true,
                              )
                            else
                              dim(
                                ItemStackTile(
                                  size: 44,
                                  id: inputs[i].key,
                                  count: inputs[i].value,
                                  alwaysShowCount: true,
                                ),
                              ),
                            if (i != inputs.length - 1)
                              dim(
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.add, size: 18),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                if (locked) ...[
                  dim(const Icon(Icons.lock, size: 14)),
                  const SizedBox(width: 4),
                ],
                dim(Text("Lv. ${recipe.levelRequirement}")),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
