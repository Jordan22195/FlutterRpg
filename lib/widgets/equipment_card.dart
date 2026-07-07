import 'package:flutter/material.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

/// Card for a unique equipment instance: shows its (quality/enchant
/// aware) display name, effective stats, and a quality-colored tile.
class EquipmentCard extends StatelessWidget {
  const EquipmentCard({
    super.key,
    required this.item,
    required this.onTap,
    this.height = 68,
  });

  final EquipmentItem item;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    double actionInterval = 0;
    final currentItem = item;
    if (currentItem is WeaponItem) {
      actionInterval = currentItem.actionInterval.inMilliseconds / 1000.0;
    }

    final stats = item.effectiveSkillBonus;
    final qualityColor = qualityBorderColor(item.quality);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Icon (left); count badge shows the stack size
                ItemStackTile(
                  size: 52,
                  id: item.id,
                  count: item.count,
                  showInfoDialogOnTap: false,
                  borderColor: qualityColor,
                ),
                const SizedBox(width: 8),

                // Name + stats
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: qualityColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final entry in stats.entries) ...[
                              IconRenderer(size: 16, id: entry.key),
                              Text(
                                "${entry.value}",
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 2),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (actionInterval > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.timer, size: 16, color: Colors.grey),
                  Text(
                    "${actionInterval.toStringAsFixed(1)}s",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
