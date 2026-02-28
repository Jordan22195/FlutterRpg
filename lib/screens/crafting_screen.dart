import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/skil_tile.dart';
import '../controllers/buff_controller.dart';

class CraftingScreen extends StatefulWidget {
  CraftingScreen({super.key, required this.skill, required this.imageId});
  final Skills skill;
  final Enum imageId;

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen>
    with TickerProviderStateMixin {
  final crafting = CraftingController.instance;
  PlayerDataController? _player;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final c = context.read<PlayerDataController>();
      _player = c;
      await c.ensureLoaded();
      if (!mounted) return;

      // Bind controller references
      crafting.initForSkill(skill: widget.skill, controller: c);

      setState(() {
        _initializing = false;
      });
    });
  }

  void bindActionButton() {
    Future.microtask(() async {
      final c = context.read<PlayerDataController>();
      _player = c;
      await c.ensureLoaded();
      if (!mounted) return;

      // Bind controller references
      crafting.initForSkill(skill: widget.skill, controller: c);

      // Hook into timing loop (same idea as encounter)
      //c.initActionTiming(this);
      if (!mounted) return;
      c.actionTimingController.onFire = () {
        if (!mounted) return;
        setState(() {
          crafting.craftOnce();
        });
      };
      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
      setState(() {});
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showRecipePicker(
    BuildContext context,
    PlayerDataController playerDataController,
  ) {
    final recipes = crafting.getVisibleRecipesForActiveSkill();
    print("Showing recipe picker with ${recipes.length} recipes");
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
                  inventory: playerDataController.data!.inventory,
                  recipeId: r.id,
                  onTap: () {
                    crafting.selectRecipe(r);
                    Navigator.of(ctx).pop();
                    setState(() {});
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
    final playerDataController = context.watch<PlayerDataController>();

    if (playerDataController.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (playerDataController.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crafting')),
        body: Center(child: Text('Error: ${playerDataController.error}')),
      );
    }

    final activeRecipe = crafting.activeRecipe;
    final canCraft = (activeRecipe != null) && crafting.canCraftActive();

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
                      CraftingController.instance.activeSkill.name ?? "Error",
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ItemStackTile(size: 160, count: 0, id: widget.imageId),
            SizedBox(height: 12),

            SkillTile(id: widget.skill),

            RecipeCard(
              maxCraftable: false,
              inventory: playerDataController.data!.inventory,
              recipeId: activeRecipe?.id ?? '',
              onTap: () => _showRecipePicker(context, playerDataController),
            ),

            Card(
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: InventoryGrid(
                      items: CraftingController.instance.craftedItems
                          .getObjectStackList(),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Spacer(),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: MomentumPrimaryButton(
                    maxInterval: Duration(seconds: 2),
                    enabled: canCraft,
                    label: "Craft",
                    controller: playerDataController.actionTimingController,
                    onFireFunction: () {
                      print("CraftingScreen: Craft button fired!");
                      crafting.craftOnce();
                    },
                    appBarTile: ItemStackTile(
                      size: 52,
                      id: activeRecipe?.output.first.id,
                      count: CraftingController.instance.getPlayerCount(
                        activeRecipe?.output.first.id,
                      ),
                      // Only show timer for firemaking recipes that are currently active
                      isTimerStackTile:
                          activeRecipe?.skill == Skills.FIREMAKING &&
                              BuffController.instance.campfireBuff.id ==
                                  activeRecipe?.output.first.id
                          ? true
                          : false,
                      expirationTime:
                          activeRecipe?.skill == Skills.FIREMAKING &&
                              BuffController.instance.campfireBuff.id ==
                                  activeRecipe?.output.first.id
                          ? BuffController.instance.campfireBuff.expirationTime
                          : null,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    child: Text("Stop"),
                    onPressed: () {
                      PlayerDataController.instance.actionTimingController
                          .stopNow();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
