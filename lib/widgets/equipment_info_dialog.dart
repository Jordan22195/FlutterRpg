import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/inventory_controller.dart';
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

  final inventoryController = context.read<InventoryController>();
  final devCountController = TextEditingController(
    text: '${inventoryController.getEquipmentCount(item)}',
  );

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(item.displayName, style: TextStyle(color: qualityColor)),
      content: SingleChildScrollView(
        child: Column(
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

            // dev tool: force the player-inventory stack count for this
            // exact item identity (base + quality + enchant)
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: devCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Dev: stack count',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final count = int.tryParse(devCountController.text);
                    if (count != null) {
                      inventoryController.devSetEquipmentCount(item, count);
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Set'),
                ),
              ],
            ),
          ],
        ),
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
