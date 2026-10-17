import 'package:flutter/material.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/widgets/crafting_info_panel.dart';
import 'package:rpg/widgets/picker_list.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/skill_ring_row.dart';

import '../controllers/world_controller.dart';
import '../data/skill_category.dart';
import '../theme/hearth_theme.dart';
import '../widgets/action_dock.dart';
import '../widgets/art_header.dart';
import '../widgets/explore_card.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/stage_panel.dart';

class CraftingScreen extends StatefulWidget {
  const CraftingScreen({super.key});

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

/*
crafting screen contents:
-the zone's art strip, naming the station and the skill it trains
-the station on a stage
-recipe card that shows currently selected recipe, and opens recipe picker dialog on tap
-the crafting timer and the skill rings
-tabbed panel of items crafted this session, active buffs, and recipe stats
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
            child: PickerList(
              itemCount: recipes.length,
              // opens on the recipe already selected rather than at the top
              selectedIndex: recipes.indexWhere(
                (r) => r.id == controller.selectedRecipeId,
              ),
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
    final skillId = controller.getCraftingEntitySkillId();
    final station = controller.stationEntityId;
    final selectedRecipeId = controller.selectedRecipeId;
    final recipeList = controller.availableRecipes();
    final canCraft =
        selectedRecipeId.isNotEmpty &&
        controller.getMaxNumberCraftsForRecipe(selectedRecipeId) > 0;

    final zone = context.watch<WorldController>().viewedZoneDefinition();
    final topPadding = MediaQuery.paddingOf(context).top;

    // the top is left open: the zone's art strip runs up behind the status
    // bar, as on the zone screen this one opens from
    return SafeArea(
      top: false,
      child: Column(
        children: [
          SizedBox(
            height: ArtHeader.collapsedHeight(topPadding),
            child: ArtHeader(
              title: station.definition.name,
              subtitle: zone.name,
              collapse: 1,
              artAsset: zone.iconAsset.isEmpty ? null : zone.iconAsset,
              backLabel: 'Back to ${zone.name}',
              // the skill this station trains
              trailing: ArtHeaderChip(
                icon: IconRenderer(size: 16, id: skillId),
                label: skillDisplayName(skillId),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              // room at the bottom for the dock's fade to fall on
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                // the station itself, on a crafting-tinted stage
                StagePanel(
                  tint: context.gameColors.craftingTint,
                  height: 148,
                  shadow: false,
                  sprite: SpriteFrame.sprite(station, size: 116),
                ),
                const SizedBox(height: 12),

                // selectable recipe card
                RecipeCard(
                  recipeId: selectedRecipeId,
                  onTap: () =>
                      _showRecipePicker(context, controller, recipeList),
                ),
                const SizedBox(height: 16),

                // the station has no target and no health, so the action
                // timer is a row of its own above the rings — the same slot
                // the explore screen gives it
                ActionTimerRow(
                  label: 'Crafting',
                  color: skillRingColor(skillId),
                  progress: controller.craftProgress,
                  interval: controller.craftInterval,
                ),
                const SizedBox(height: 12),

                // the skills this station trains stay in view whichever tab
                // is open
                ActivitySkillRingRow(skills: [skillId], spacing: 14),
                const SizedBox(height: 16),

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

          ActionDock(
            buttons: ActionButtonRow(
              padding: EdgeInsets.zero,
              actionButton: ActionOrTravelButton(
                enabled: canCraft,
                label: "Craft",
                showLabel: true,
                startActionFunction: () {
                  controller.startCraftingAction();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
