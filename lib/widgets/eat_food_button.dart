import 'package:flutter/material.dart';
import '../catalogs/item_catalog.dart';
import 'icon_renderer.dart';

/// Consolidated eat control for combat: shows the equipped food and how
/// many are left. Tap eats one; long-press (or tap with nothing equipped)
/// opens the food picker.
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

    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: hasFood ? onEat : onPickFood,
        onLongPress: onPickFood,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasFood)
                IconRenderer(id: foodItemId, size: 24)
              else
                const Icon(Icons.restaurant, size: 20),
              const SizedBox(width: 6),
              const Text('Eat'),
              if (hasFood) ...[
                const SizedBox(width: 5),
                Text(
                  '$foodItemCount',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
