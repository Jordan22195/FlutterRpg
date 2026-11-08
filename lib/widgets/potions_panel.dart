import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../controllers/potion_controller.dart';
import 'buff_toggle_card.dart';

/*
potions card contents:
-a summary line: how many potions are armed and how many are up
-a grid of the potions the player holds or has armed, three to a row
-each card: the potion with its held count, an auto-drink switch, and
 under it what is left on the buff when it is up, or how long the stack
 could keep it up when it is armed
-a card with its buff up takes the recipe picker's selected outline
-a note that auto-drink only runs while an action is going, shown while
 nothing is
*/

/// The potions card: everything the player does with potions outside of
/// drinking one by hand, in one card. It sits inline at the foot of the gear
/// screen rather than behind a tap, so arming a potion is a scroll away from
/// the gear it is being drunk to support.
class PotionsPanel extends StatelessWidget {
  const PotionsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // the buff tick is what counts the timers down and clears a card's
    // outline when its potion lapses
    context.watch<BuffController>();
    final controller = context.watch<PotionController>();
    final potions = controller.potions();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        key: const ValueKey('gear-potions-card'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, size: 20, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${controller.autoCount} auto · '
                  '${controller.activeCount} active',
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (potions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No potions yet. Brew one at an alchemy station and it '
                  'will show up here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: scheme.outline),
                ),
              )
            else
              BuffToggleGrid(
                children: [for (final id in potions) _PotionCard(id: id)],
              ),
            if (!controller.actionRunning)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: Text(
                    'Auto-drink only runs while an action is going',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: scheme.outline),
                  ),
                ),
              ),
          ],
        ),
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
    return BuffToggleCard(
      cardKey: ValueKey('potion-card-${id.name}'),
      switchKey: ValueKey('auto-drink-${id.name}'),
      id: id,
      held: controller.heldCount(id),
      auto: controller.isAutoDrink(id),
      onChanged: (on) => controller.setAutoDrink(id, on),
      dose: (id.definition as BuffItemDefinition).duration,
      activeUntil: controller.activeBuff(id)?.expirationTime,
    );
  }
}
