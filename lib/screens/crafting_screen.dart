import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/widgets/fill_bar.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/primary_button.dart';

class CraftingScreen extends StatefulWidget {
  const CraftingScreen({super.key, required this.skill});
  final Skills skill;

  @override
  State<CraftingScreen> createState() => _CraftingScreenState();
}

class _CraftingScreenState extends State<CraftingScreen>
    with TickerProviderStateMixin {
  final crafting = CraftingController.instance;
  PlayerDataController? _player;

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

  void _showRecipePicker(BuildContext context) {
    final recipes = crafting.getVisibleRecipesForActiveSkill();

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: ListView.builder(
            itemCount: recipes.length,
            itemBuilder: (ctx, i) {
              final r = recipes[i];
              final craftable = crafting.craftableCount(r);
              final reqText = r.inputs.entries
                  .map((e) => '${e.value}× ${e.key.name}')
                  .join(', ');

              return ListTile(
                leading: _recipeIcon(r.output.id),
                title: Text(r.name),
                subtitle: Text('$reqText • can make: $craftable'),
                onTap: () {
                  crafting.selectRecipe(r);
                  Navigator.of(ctx).pop();
                  setState(() {});
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _recipeIcon(Items itemId) {
    // Use your existing asset convention if you have one.
    // If you already have an item icon asset path system, swap this out.
    return SizedBox(
      width: 48,
      height: 48,
      child: Image.asset(
        'assets/items/placeholder.png',
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.construction, size: 32),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerDataController>();

    if (player.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (player.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crafting')),
        body: Center(child: Text('Error: ${player.error}')),
      );
    }

    final active = crafting.activeRecipe;
    final canCraft = (active != null) && crafting.canCraftActive();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill.name),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AnimatedBuilder(
              animation: player.actionTimingControllerOrNull ?? player,
              builder: (_, __) {
                final ctrl = player.actionTimingControllerOrNull;
                final value = ctrl?.actionProgress ?? 0.0;
                return FillBar(value: value);
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current craft icon + picker
            GestureDetector(
              onTap: () => _showRecipePicker(context),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      if (active != null) _recipeIcon(active.output.id),
                      if (active == null)
                        const Icon(Icons.lock_outline, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          active?.name ?? 'No recipes unlocked yet',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Inputs row (show required inputs + how many you have)
            if (active != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.input),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            for (final entry in active.inputs.entries)
                              _InputChip(
                                itemId: entry.key,
                                need: entry.value,
                                have: crafting.getPlayerCount(entry.key),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Output preview + craftable count
            if (active != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.output),
                      const SizedBox(width: 12),
                      _recipeIcon(active.output.id),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Makes: ${active.output.count}× ${active.output.id}\n'
                          'You can make: ${crafting.craftableCount(active)}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Optional: show inventory snapshot (like encounter drops)
            // You can remove this if you don't want it.
            Card(
              child: SizedBox(
                height: 90,
                child: InventoryGrid(
                  items: player.data!.inventory.getObjectStackList(),
                ),
              ),
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(12),
              child: MomentumPrimaryButton(
                label: canCraft
                    ? 'Craft'
                    : (active == null ? 'No recipe' : 'Missing materials'),
                controller:
                    player.actionTimingControllerOrNull ??
                    // If timing isn’t initialized yet, disable interaction by
                    // giving the button a dummy controller? If your button
                    // requires a real controller, you can guard above.
                    player.actionTimingController,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputChip extends StatelessWidget {
  const _InputChip({
    required this.itemId,
    required this.need,
    required this.have,
  });

  final Items itemId;
  final int need;
  final int have;

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ok ? Colors.green : Colors.red, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: Image.asset(
              'assets/items/placeholder.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 16),
            ),
          ),
          const SizedBox(width: 8),
          Text('$have / $need'),
        ],
      ),
    );
  }
}
