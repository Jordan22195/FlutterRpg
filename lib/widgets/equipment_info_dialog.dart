import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/inventory_controller.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';

/// Info dialog for a unique equipment instance: display name, quality,
/// effective stats (quality-scaled + enchant), and weapon speed.
void showEquipmentInfoDialog(BuildContext context, EquipmentItem item) {
  final inventoryController = context.read<InventoryController>();

  // the piece the dialog is currently describing. the dev tools below
  // rewrite the inventory under it — setting the quality re-keys the stack
  // and can merge it into another one — so this tracks whichever stack is
  // live rather than holding the instance the caller tapped
  EquipmentItem current = item;

  final devCountController = TextEditingController(
    text: '${inventoryController.getEquipmentCount(item)}',
  );

  showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setDialogState) {
        final qualityColor = rarityBorderColor(current.quality);
        final stats = current.effectiveSkillBonus;
        final shown = current;
        final Duration? attackInterval = shown is WeaponItem
            ? shown.actionInterval
            : null;

        return AlertDialog(
          title: Text(
            current.displayName,
            style: TextStyle(color: qualityColor),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ItemStackTile(
                    size: 80,
                    count: 1,
                    id: current.id,
                    showInfoDialogOnTap: false,
                    borderColor: qualityColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  current.quality.label.isEmpty
                      ? 'Common'
                      : current.quality.label,
                  style: TextStyle(color: qualityColor ?? Colors.grey),
                ),
                if (current.enchantName.isNotEmpty)
                  Text('Enchanted: of the ${current.enchantName}'),
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
                    Text('${current.value}'),
                  ],
                ),

                // dev tool: re-roll the whole stack's quality. quality is
                // part of the stack identity, so there is no way to move
                // part of a stack — the stack goes over whole
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Dev: rarity'),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    for (final rarity in Rarity.values)
                      ChoiceChip(
                        label: Text(
                          rarity.label.isEmpty ? 'Common' : rarity.label,
                        ),
                        selected: current.quality == rarity,
                        onSelected: (_) {
                          final moved = inventoryController
                              .devSetEquipmentQuality(current, rarity);
                          if (moved == null) return;
                          devCountController.text =
                              '${inventoryController.getEquipmentCount(moved)}';
                          setDialogState(() => current = moved);
                        },
                      ),
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
                          inventoryController.devSetEquipmentCount(
                            current,
                            count,
                          );
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
        );
      },
    ),
  );
}
