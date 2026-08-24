import 'package:flutter/material.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/widgets/crafting_info_panel.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/skill_ring_row.dart';

class CraftingScreen extends StatefulWidget {
  const CraftingScreen({super.key});

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

/*
crafting screen contents:
-center screen image of craftin screen location
-header with crafting skill name and back button
-recipe card that shows currently selected recipe, and opens recipe picker dialog on tap
-skill progress tile for the active crafting skill
-inventory grid of currently crafted items
*/

class _CraftingScreenState extends State<CraftingScreen>
    with TickerProviderStateMixin {
  void _showRecipePicker(
    BuildContext context,
    CraftingController controller,
    List<CraftingRecipe> recipes,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Recipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: recipes.length,
              itemBuilder: (context, i) {
                final r = recipes[i];
                return RecipeCard(
                  recipeId: r.id,
                  lockWhenUnderLevel: true,
                  selected: r.id == controller.selectedRecipeId,
                  onTap: () {
                    controller.selectRecipe(r.id);
                    Navigator.of(ctx).pop();
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CraftingController>();
    final skillName = controller.skillName();
    final skillId = controller.getCraftingEntitySkillId();
    final entityIconAsset = controller.entityIconAsset();
    final selectedRecipeId = controller.selectedRecipeId;
    final recipeList = controller.availableRecipes();
    final canCraft =
        selectedRecipeId.isNotEmpty &&
        controller.getMaxNumberCraftsForRecipe(selectedRecipeId) > 0;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        // header column
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  // navigation arrow
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  // title text
                  Expanded(
                    child: Text(
                      skillName,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  // main center image
                  SizedBox(
                    height: 160,
                    child: entityIconAsset.isEmpty
                        ? const Icon(Icons.help_outline, size: 80)
                        : Image.asset(
                            entityIconAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              size: 80,
                            ),
                          ),
                  ),
                  SizedBox(height: 12),

                  // the station has no target and no health, so the action
                  // timer is a row of its own above the rings — the same
                  // slot the explore screen gives it
                  ActionTimerRow(
                    label: 'Crafting',
                    progress: controller.craftProgress,
                    interval: controller.craftInterval,
                  ),
                  const SizedBox(height: 8),

                  // the skills this station trains stay in view whichever
                  // tab is open
                  ActivitySkillRingRow(skills: [skillId]),
                  const SizedBox(height: 4),

                  // selectable recipe card
                  RecipeCard(
                    recipeId: selectedRecipeId,
                    onTap: () =>
                        _showRecipePicker(context, controller, recipeList),
                  ),

                  // this session's output, the active buffs and the recipe
                  // stats share one slot, switched by tab
                  CraftingInfoPanel(
                    items: controller.craftedItems(),
                    equipment: controller.craftedEquipment(),
                    recipeId: selectedRecipeId,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            ActionButtonRow(
              actionButton: MomentumPrimaryButton(
                enabled: canCraft,
                label: "Craft",
                startActionFunction: () {
                  controller.startCraftingAction();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
