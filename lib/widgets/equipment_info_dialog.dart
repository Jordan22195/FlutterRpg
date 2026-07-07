import 'package:flutter/material.dart';
import '../catalogs/item_catalog.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';

/// Info dialog for a unique equipment instance: display name, quality,
/// effective stats (quality-scaled + enchant), and weapon speed.
void showEquipmentInfoDialog(BuildContext context, EquipmentItem item) {
  final qualityColor = qualityBorderColor(item.quality);
  final stats = item.effectiveSkillBonus;
  final currentItem = item;
  final Duration? attackInterval = currentItem is WeaponItem
      ? currentItem.actionInterval
      : null;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(item.displayName, style: TextStyle(color: qualityColor)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: ItemStackTile(
              size: 80,
              count: 1,
              id: item.id,
              showInfoDialogOnTap: false,
              borderColor: qualityColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.quality.label.isEmpty ? 'Common' : item.quality.label,
            style: TextStyle(color: qualityColor ?? Colors.grey),
          ),
          if (item.enchantName.isNotEmpty)
            Text('Enchanted: of the ${item.enchantName}'),
          const SizedBox(height: 8),
          for (final entry in stats.entries)
            Row(
              children: [
                IconRenderer(size: 24, id: entry.key),
                const SizedBox(width: 6),
                Text('+${entry.value}'),
              ],
            ),
          if (attackInterval != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, size: 18),
                const SizedBox(width: 6),
                Text(
                  '${(attackInterval.inMilliseconds / 1000).toStringAsFixed(1)}s',
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              IconRenderer(size: 24, id: ItemId.COINS),
              const SizedBox(width: 6),
              Text('${item.value}'),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
