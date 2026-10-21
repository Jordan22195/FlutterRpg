import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import 'equipment_picker.dart';
import 'stat_chip.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';

/// The equipment controller, where the screen has one; the comparison is
/// left out where it doesn't (a bare widget test, say).
EquipmentController? _equipmentOf(BuildContext context) {
  try {
    return Provider.of<EquipmentController>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

/// Info dialog for a unique equipment instance: display name, quality,
/// effective stats (quality-scaled + enchant) and weapon speed, each set
/// against the piece the player would be taking off to wear it.
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
        final shown = current;

        // what wearing this would take off, unless this is what is worn
        final equipment = _equipmentOf(dialogContext);
        final worn = equipment?.isEquipped(shown) ?? false;
        final baseline = equipment == null || worn
            ? null
            : equipment.counterpartFor(shown);
        final compared = baseline != null;

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
                // each stat with its change against what would come off,
                // one to a line; weapon speed last, where faster is the gain
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final chip in equipmentComparisonChips(
                      shown,
                      baseline,
                      showDeltas: compared,
                      large: true,
                    )) ...[chip, const SizedBox(height: 8)],
                  ],
                ),
                // what it sells for, at the same size as the stats above
                StatChip(
                  key: const ValueKey('equipment-value'),
                  icon: IconRenderer(size: 28, id: ItemId.COINS),
                  value: '${current.value}',
                  fontSize: 20,
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
