import 'package:flutter/material.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../data/skill.dart';
import '../controllers/crafting_controller.dart';
import '../controllers/buff_controller.dart';

class RecipeCard extends StatelessWidget {
  RecipeCard({
    super.key,
    required this.recipeId,
    required this.onTap,
    required this.inventory,
    this.maxCraftable = true,
    this.height = 68,
  });

  bool maxCraftable = true;
  final Inventory inventory;
  final String recipeId;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    print("Building RecipeCard for $recipeId");
    final crafting = CraftingController.instance;
    final recipe = crafting.recipeById(recipeId);

    if (recipe == null) {
      return Card(
        child: SizedBox(
          height: height,
          child: const Center(child: Text('Recipe not found')),
        ),
      );
    }

    final output = recipe.output;
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
                ItemStackTile(
                  size: 52,
                  id: output.first.id,
                  count: maxCraftable
                      ? CraftingController.instance
                            .calcMaxNumberCraftsForRecipe(recipeId)
                      : CraftingController.instance.getPlayerCount(
                          output.first.id,
                        ),
                  // Only show timer for firemaking recipes that are currently active
                  isTimerStackTile:
                      recipe.skill == Skills.FIREMAKING &&
                          BuffController.instance.campfireBuff.id ==
                              recipe.output.first.id
                      ? true
                      : false,
                  expirationTime:
                      recipe.skill == Skills.FIREMAKING &&
                          BuffController.instance.campfireBuff.id ==
                              recipe.output.first.id
                      ? BuffController.instance.campfireBuff.expirationTime
                      : null,
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
                                  : CraftingController.instance.getPlayerCount(
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
