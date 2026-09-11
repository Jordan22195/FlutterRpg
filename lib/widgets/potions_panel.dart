import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../controllers/potion_controller.dart';
import 'countdown_timer.dart';
import 'item_stack_tile.dart';
import 'recipe_card.dart';

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
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                // a fixed row height rather than an aspect ratio: a card's
                // contents are a fixed stack (tile, switch, one line), so on
                // a narrow phone a ratio would squeeze the row shorter than
                // the stack it has to hold and overflow it
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: _potionCardHeight,
                ),
                itemCount: potions.length,
                itemBuilder: (_, i) => _PotionCard(id: potions[i]),
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

/// What one potion card needs: the 52pt tile, the switch's 48pt tap target,
/// the 18pt line under it, and the card's own padding.
const double _potionCardHeight = 52 + 48 + 18 + 16 + 2;

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
    // what auto-drink has left to give: what is left on the dose that is up,
    // plus every dose still in the bag behind it. Armed, that is the number
    // that matters — not how long this one potion has to run, because the
    // next one goes down the moment it lapses.
    final dose = (id.definition as BuffItemDefinition).duration;
    final stackLasts = dose * held;
    final runwayEnds = buff?.expirationTime.add(stackLasts);

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
                child: auto
                    ? (active || held > 0
                          // armed: the hourglass marks a runway rather than
                          // one dose, and it counts down live once a potion
                          // is up because the stack is being spent
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.hourglass_bottom,
                                  size: 14,
                                  color: scheme.primary,
                                ),
                                const SizedBox(width: 4),
                                if (runwayEnds != null)
                                  DefaultTextStyle.merge(
                                    style: TextStyle(color: scheme.primary),
                                    child: CountdownTimer(
                                      expirationTime: runwayEnds,
                                      size: 15,
                                      showIcon: false,
                                    ),
                                  )
                                else
                                  Text(
                                    CountdownTimer.formatDuration(stackLasts),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: scheme.primary,
                                    ),
                                  ),
                              ],
                            )
                          : null)
                    // not armed: what is left on the one potion that is up
                    : active
                    ? CountdownTimer(expirationTime: buff.expirationTime)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
