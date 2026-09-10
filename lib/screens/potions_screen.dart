import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../controllers/potion_controller.dart';
import '../widgets/countdown_timer.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/recipe_card.dart';

/*
potions screen contents:
-a grid of the potions the player holds or has armed, three to a row
-each card: the potion with its held count, an auto-drink switch, and
 under it what is left on the buff when it is up, or how long the stack
 could keep it up when it is armed
-a card with its buff up takes the recipe picker's selected outline
-a note that auto-drink only runs while an action is going, shown while
 nothing is
*/

class PotionsScreen extends StatelessWidget {
  const PotionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // the buff tick is what counts the timers down and clears a card's
    // outline when its potion lapses
    context.watch<BuffController>();
    final controller = context.watch<PotionController>();
    final potions = controller.potions();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Potions')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (potions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No potions yet. Brew one at an alchemy station and it '
                'will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.outline),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.8,
              children: [for (final id in potions) _PotionCard(id: id)],
            ),
          if (!controller.actionRunning)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Auto-drink only runs while an action is going',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: scheme.outline),
              ),
            ),
        ],
      ),
    );
  }
}

/// One potion: the stack, its auto-drink switch, and what its buff is doing.
class _PotionCard extends StatelessWidget {
  const _PotionCard({required this.id});

  final ItemId id;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<PotionController>();
    final scheme = Theme.of(context).colorScheme;
    final held = controller.heldCount(id);
    final auto = controller.isAutoDrink(id);
    final buff = controller.activeBuff(id);
    final active = buff != null;
    // what the stack is worth once it is armed: every dose back to back
    final dose = (id.definition as BuffItemDefinition).duration;
    final stackLasts = dose * held;

    // an empty stack dims, but stays live: arming it is how you ask for the
    // next one brewed to be drunk
    return Opacity(
      opacity: held == 0 ? 0.45 : 1,
      child: Material(
        key: ValueKey('potion-card-${id.name}'),
        color: active
            ? RecipeCard.selectedFill(context)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        shape: active
            ? RecipeCard.selectedShape(context)
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
              ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // the tile's own dialog is where a potion is drunk by hand
              ItemStackTile<ItemId>(
                size: 52,
                id: id,
                count: held,
                alwaysShowCount: true,
                depleted: held == 0,
              ),
              Switch(
                key: ValueKey('auto-drink-${id.name}'),
                value: auto,
                onChanged: (on) => controller.setAutoDrink(id, on),
              ),
              SizedBox(
                height: 18,
                child: active
                    ? CountdownTimer(expirationTime: buff.expirationTime)
                    : auto && held > 0
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.hourglass_bottom,
                            size: 14,
                            color: scheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            CountdownTimer.formatDuration(stackLasts),
                            style: TextStyle(
                              fontSize: 12,
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
