import 'package:flutter/material.dart';

import '../catalogs/items/items.dart';
import 'countdown_timer.dart';
import 'item_stack_tile.dart';
import 'recipe_card.dart';

/// What one toggle card needs: the 52pt tile, the switch's 48pt tap target,
/// the 18pt line under it, and the card's own padding.
const double kBuffToggleCardHeight = 52 + 48 + 18 + 16 + 2;

/// A grid of [BuffToggleCard]s, three to a row at a fixed height.
class BuffToggleGrid extends StatelessWidget {
  const BuffToggleGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      // a fixed row height rather than an aspect ratio: a card's contents
      // are a fixed stack (tile, switch, one line), so on a narrow phone a
      // ratio would squeeze the row shorter than the stack it has to hold
      // and overflow it
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: kBuffToggleCardHeight,
      ),
      children: children,
    );
  }
}

/// One stack the player keeps a buff up with - a potion they auto-drink, a
/// reagent they auto-tend: the stack, its switch, and what its buff is
/// doing. Shared so the potions card and the firepit's Reagents tab read the
/// same way.
class BuffToggleCard extends StatelessWidget {
  const BuffToggleCard({
    super.key,
    required this.id,
    required this.held,
    required this.auto,
    required this.onChanged,
    required this.dose,
    this.activeUntil,
    this.cardKey,
    this.switchKey,
  });

  final ItemId id;
  final int held;

  /// Whether the switch is on.
  final bool auto;
  final ValueChanged<bool> onChanged;

  /// How long one of [id] keeps its buff up.
  final Duration dose;

  /// When the buff [id] is putting up runs out, or null when it is down.
  final DateTime? activeUntil;

  /// On the card itself, inside its dimming.
  final Key? cardKey;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = activeUntil != null;
    // what the switch has left to give: what is left on the one that is up,
    // plus every one still in the bag behind it. Armed, that is the number
    // that matters - the next one goes on the moment this one lapses.
    final stackLasts = dose * held;
    final runwayEnds = activeUntil?.add(stackLasts);

    // an empty stack dims, but stays live: arming it is how you ask for the
    // next one to be used
    return Opacity(
      opacity: held == 0 ? 0.45 : 1,
      child: Material(
        key: cardKey,
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
              ItemStackTile<ItemId>(
                size: 52,
                id: id,
                count: held,
                alwaysShowCount: true,
                depleted: held == 0,
              ),
              Switch(key: switchKey, value: auto, onChanged: onChanged),
              SizedBox(
                height: 18,
                child: auto
                    ? (active || held > 0
                          // armed: the hourglass marks a runway rather than
                          // one dose, and it counts down live once one is up
                          // because the stack is being spent
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
                    // not armed: what is left on the one that is up
                    : active
                    ? CountdownTimer(expirationTime: activeUntil!)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
