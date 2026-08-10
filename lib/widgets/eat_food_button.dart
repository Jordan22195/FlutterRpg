import 'package:flutter/material.dart';
import '../catalogs/item_catalog.dart';
import 'icon_renderer.dart';
import 'primary_button.dart';

/// Consolidated eat control for combat: shows the equipped food and how
/// many are left. Tap eats one; long-press (or tap with nothing equipped)
/// opens the food picker.
///
/// Built on the same raised face as the stop button beside it and sized to
/// the shared action bar height, so the two side controls of the bar match.
class EatFoodButton extends StatelessWidget {
  const EatFoodButton({
    super.key,
    required this.foodItemId,
    required this.foodItemCount,
    required this.onEat,
    required this.onPickFood,
  });

  final ItemId foodItemId;
  final int foodItemCount;
  final VoidCallback onEat;
  final VoidCallback onPickFood;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFood = foodItemId != ItemId.NULL;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasFood ? onEat : onPickFood,
      onLongPress: onPickFood,
      child: RaisedSurface(
        // nothing latches here; the face only travels under a press, which
        // this control doesn't track
        pressed: false,
        height: kActionBarButtonHeight,
        color: scheme.primaryContainer,
        radius: 14,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        // the narrow slot fits the food icon over its count rather than
        // beside it. the stack is scaled down to fit rather than laid out to
        // the pixel: the face is only kActionBarButtonHeight minus its lip
        // and padding, and the label grows with the device's text scale.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasFood)
                IconRenderer(id: foodItemId, size: 24)
              else
                const Icon(Icons.restaurant, size: 22),
              const SizedBox(height: 2),
              Text(
                hasFood ? 'Eat $foodItemCount' : 'Eat',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  // the default leading would push the stack past the face
                  height: 1.0,
                  color: scheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
