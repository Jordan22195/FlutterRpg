import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/enchantment_catalog.dart';
import '../controllers/enchanting_controller.dart';
import '../data/skill_data.dart';
import '../widgets/equipment_card.dart';
import '../widgets/equipment_info_dialog.dart';
import '../widgets/inventory_grid.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/primary_button.dart';
import '../widgets/skil_tile.dart';

/// The enchanting bench. Follows the crafting screen format: pick a
/// recipe (an enchant tier or disenchant), pick a target item from the
/// inventory, then run the action with the Action/Stop buttons.
class EnchantingScreen extends StatelessWidget {
  const EnchantingScreen({super.key});

  // recipe picker dialog, same format as the crafting recipe picker.
  // selecting a recipe only selects it
  void _showRecipePicker(
    BuildContext context,
    EnchantingController controller,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Recipe'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView(
              shrinkWrap: true,
              children: [
                _DisenchantRecipeCard(
                  onTap: () {
                    controller.selectRecipe(
                      EnchantingController.disenchantRecipeId,
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
                for (final recipe in controller.recipes())
                  _EnchantRecipeCard(
                    recipe: recipe,
                    onTap: () {
                      controller.selectRecipe(recipe.id);
                      Navigator.of(ctx).pop();
                    },
                  ),
              ],
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

  // target picker dialog, same format as the equipment selection dialog.
  // selecting an item only selects it
  void _showTargetPicker(
    BuildContext context,
    EnchantingController controller,
  ) {
    final equipment = controller.equipmentList();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Item'),
          content: SizedBox(
            width: double.maxFinite,
            child: equipment.isEmpty
                ? const Text('No equipment in inventory.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: equipment.length,
                    itemBuilder: (context, i) {
                      final item = equipment[i];
                      return EquipmentCard(
                        item: item,
                        onTap: () {
                          controller.selectTarget(item);
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
    final controller = context.watch<EnchantingController>();
    final selectedRecipe = controller.selectedRecipe;
    final disenchantSelected = controller.disenchantSelected;
    final target = controller.selectedTarget;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Enchanting Bench',
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
                  SkillTile(id: SkillId.ENCHANTING),

                  // material counts
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (final material
                              in EnchantingController.materials)
                            ItemStackTile(
                              size: 48,
                              count: controller.materialCount(material),
                              id: material,
                            ),
                        ],
                      ),
                    ),
                  ),

                  // selected recipe card; tap opens the recipe picker
                  if (disenchantSelected)
                    _DisenchantRecipeCard(
                      onTap: () => _showRecipePicker(context, controller),
                    )
                  else if (selectedRecipe != null)
                    _EnchantRecipeCard(
                      recipe: selectedRecipe,
                      onTap: () => _showRecipePicker(context, controller),
                    )
                  else
                    Card(
                      child: InkWell(
                        onTap: () => _showRecipePicker(context, controller),
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          height: 68,
                          width: double.infinity,
                          child: Center(child: Text('Select a recipe')),
                        ),
                      ),
                    ),

                  // selected target item; tap opens the item picker
                  if (target != null)
                    EquipmentCard(
                      item: target,
                      onTap: () => _showTargetPicker(context, controller),
                    )
                  else
                    Card(
                      child: InkWell(
                        onTap: () => _showTargetPicker(context, controller),
                        borderRadius: BorderRadius.circular(12),
                        child: const SizedBox(
                          height: 68,
                          width: double.infinity,
                          child: Center(child: Text('Select an item')),
                        ),
                      ),
                    ),

                  // yield preview while disenchanting is selected
                  if (disenchantSelected && target != null)
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Text('Yields per action:  '),
                          ItemStackTile(
                            size: 40,
                            count:
                                controller.previewDisenchant(target)?.count ??
                                0,
                            id: controller.previewDisenchant(target)?.id,
                            showInfoDialogOnTap: false,
                          ),
                        ],
                      ),
                    ),

                  // results of this bench session (materials gained,
                  // items enchanted)
                  Card(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: InventoryGrid(
                            items: controller.sessionResults(),
                          ),
                        ),
                        if (controller.sessionEquipment().isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                for (final item
                                    in controller.sessionEquipment())
                                  ItemStackTile(
                                    size: 56,
                                    count: item.count,
                                    id: item.id,
                                    showInfoDialogOnTap: false,
                                    borderColor: qualityBorderColor(
                                      item.quality,
                                    ),
                                    onTap: () => showEquipmentInfoDialog(
                                      context,
                                      item,
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

            const SizedBox(height: 12),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: MomentumPrimaryButton(
                    enabled: controller.selectionReady(),
                    label: disenchantSelected ? 'Disenchant' : 'Enchant',
                    startActionFunction: () {
                      controller.startEnchantingAction();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const StopPrimaryButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Recipe card for an enchant tier, in the crafting recipe card format:
/// effect on the left, material costs on the right, level requirement.
class _EnchantRecipeCard extends StatelessWidget {
  const _EnchantRecipeCard({required this.recipe, required this.onTap});

  final EnchantRecipe recipe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 68,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '+${recipe.statTotal} random stats',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                for (final input in recipe.inputs.entries)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: ItemStackTile(
                      size: 44,
                      count: input.value,
                      id: input.key,
                      showInfoDialogOnTap: false,
                    ),
                  ),
                const SizedBox(width: 8),
                Text('Lv. ${recipe.levelRequirement}'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recipe card for the disenchant action.
class _DisenchantRecipeCard extends StatelessWidget {
  const _DisenchantRecipeCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: const SizedBox(
          height: 68,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.auto_fix_off),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Disenchant'),
                      Text(
                        'Destroy an item for enchanting materials',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text('Lv. 1'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
