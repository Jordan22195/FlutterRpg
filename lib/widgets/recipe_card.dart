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
/// - missing materials is a shortfall you can go and fix, so the recipe stays
///   selectable and is only flagged red, down to which input is short
class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipeId,
    required this.onTap,
    this.lockWhenUnderLevel = false,
    this.height = 68,
  });

  final String recipeId;
  final VoidCallback? onTap;

  /// Set on rows that are a choice - the recipe picker. The card that merely
  /// displays the current selection leaves this off: its tap opens the
  /// picker, and locking that would strand the player on the recipe.
  final bool lockWhenUnderLevel;

  final double height;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);
    final scheme = Theme.of(context).colorScheme;

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

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: missingMaterials
            ? BorderSide(color: scheme.error, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        // a locked recipe cannot be picked
        onTap: locked ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: locked ? 0.45 : 1.0,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Output (left)
                  RecipeOutputTile(recipeId: recipeId),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_back, size: 18),
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
                              ItemStackTile(
                                size: 44,
                                id: inputs[i].key,
                                count: inputs[i].value,
                                // the input actually short of its cost is the
                                // one worth pointing at
                                borderColor:
                                    missingMaterials &&
                                        crafting.getItemCountInPlayerInventory(
                                              inputs[i].key,
                                            ) <
                                            inputs[i].value
                                    ? scheme.error
                                    : null,
                              ),
                              if (i != inputs.length - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.add, size: 18),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (locked) ...[
                    const Icon(Icons.lock, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text("Lv. ${recipe.levelRequirement}"),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
