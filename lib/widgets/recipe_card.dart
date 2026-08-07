import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/crafting_controller.dart';

class RecipeOutputTile extends StatelessWidget {
  const RecipeOutputTile({
    super.key,
    required this.recipeId,
    this.maxCraftable = false,
  });

  final String recipeId;
  final bool maxCraftable;

  @override
  Widget build(BuildContext context) {
    final crafting = context.watch<CraftingController>();
    final recipe = crafting.getRecipe(recipeId);
    if (recipe.output.isEmpty) {
      return ItemStackTile(size: 1, count: 1, id: ItemId.NULL);
    }
    final output = recipe.output;

    // a fire's burn time belongs to the firepit it is burning in, not to the
    // recipe, so the countdown lives on the firepit screen's hero tile
    return ItemStackTile(
      size: 52,
      id: output.first.id,
      count: maxCraftable
          ? crafting.getMaxNumberCraftsForRecipe(recipeId)
          : crafting.getItemCountInPlayerInventory(output.first.id),
    );
  }
}

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.recipeId,
    required this.onTap,
    this.maxCraftable = true,
    this.height = 68,
  });

  final bool maxCraftable;
  final String recipeId;
  final VoidCallback? onTap;
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

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Output (left)
                RecipeOutputTile(
                  recipeId: recipeId,
                  maxCraftable: maxCraftable,
                ),
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
                              count: maxCraftable
                                  ? inputs[i].value
                                  : crafting.getItemCountInPlayerInventory(
                                      inputs[i].key,
                                    ),
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
                Text("Lv. ${recipe.levelRequirement}"),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
