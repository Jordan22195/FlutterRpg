import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/recipe_card.dart';
import 'package:rpg/widgets/primary_button.dart';
import 'package:rpg/widgets/skil_tile.dart';

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

  Widget buildProgressBars(PlayerDataController controller) {
    const double speedBarPadding = 120;
    final timing = controller.actionTimingControllerOrNull;

    if (_initializing || timing == null) {
      // Build can run before async init finishes. Show placeholders.
      return Column(
        children: [
          const FillBar(value: 0),
          const SizedBox(height: 8),
          Row(
            children: const [
              SizedBox(width: speedBarPadding),
              Expanded(child: FillBar(value: 0)),
              SizedBox(width: speedBarPadding),
            ],
          ),
        ],
      );
    }
    return Column(
      children: [
        AnimatedBuilder(
          animation: timing,
          builder: (_, __) => FillBar(value: timing.actionProgress),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const SizedBox(width: speedBarPadding),
            Expanded(
              child: AnimatedBuilder(
                animation: timing,
                builder: (_, __) => FillBar(
                  value: timing.speed,
                  foregroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
            const SizedBox(width: speedBarPadding),
          ],
        ),
      ],
    );
  }

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

      // Hook into timing loop (same idea as encounter)
      c.initActionTiming(this);
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
    // Don’t touch inherited widgets in dispose; use cached controller reference.
    final p = _player;
    final timing = p?.actionTimingControllerOrNull;

    // Prevent any late ticks from trying to call setState after this widget unmounts.
    if (timing != null) {
      //timing.onFire = () => {};
      timing.stopNowSilently();
    }

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

    final active = crafting.activeRecipe;
    final canCraft = (active != null) && crafting.canCraftActive();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: buildProgressBars(playerDataController),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ItemStackTile(size: 160, count: 0, id: widget.imageId),
            SizedBox(height: 12),

            SkillTile(id: widget.skill),

            RecipeCard(
              maxCraftable: false,
              inventory: playerDataController.data!.inventory,
              recipeId: active?.id ?? '',
              onTap: () => _showRecipePicker(context, playerDataController),
            ),

            const SizedBox(height: 12),
            Spacer(),
            Padding(
              padding: const EdgeInsets.all(12),
              child: MomentumPrimaryButton(
                enabled: canCraft,
                label: "Craft",
                controller: playerDataController.actionTimingController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
