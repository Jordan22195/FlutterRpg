import 'package:flutter/material.dart';
import '../catalogs/items/items.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'icon_renderer.dart';
import 'primary_button.dart';

/// Consolidated eat control for combat: shows the equipped food and how
/// many are left. Tap eats one; long-press (or tap with nothing equipped)
/// opens the food picker.
///
/// A quiet surface like the stop button on the other side of the bar, at
/// the shared action bar height.
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

  static String _grouped(int n) {
    final text = '$n';
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      if (i > 0 && (text.length - i) % 3 == 0) buffer.write(',');
      buffer.write(text[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final hasFood = foodItemId != ItemId.NULL;

    return Semantics(
      button: true,
      label: hasFood ? 'Eat, $foodItemCount left' : 'Pick food',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: hasFood ? onEat : onPickFood,
        onLongPress: onPickFood,
        child: Container(
          height: kActionBarButtonHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderStrong),
          ),
          // scaled down rather than laid out to the pixel: the label grows
          // with the device's text scale and the slot does not
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasFood)
                  IconRenderer(id: foodItemId, size: 24)
                else
                  Icon(
                    Icons.restaurant,
                    size: 20,
                    color: context.gameColors.exploration,
                  ),
                const SizedBox(width: 8),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Eat',
                      maxLines: 1,
                      style: HearthText.activityLabel.copyWith(
                        fontSize: 14,
                        height: 1.1,
                        color: palette.text,
                      ),
                    ),
                    if (hasFood)
                      Text(
                        _grouped(foodItemCount),
                        maxLines: 1,
                        style: HearthText.rowMeta.copyWith(
                          fontSize: 12,
                          height: 1.1,
                          color: palette.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
