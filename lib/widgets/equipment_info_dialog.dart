import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import '../data/equipment_data.dart';
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

/// Where [item] is worn, as the info dialog names it. A weapon says how many
/// hands it takes, so a greatsword reads apart from a sword and a shield.
String equipmentSlotLabel(EquipmentItem item) =>
    switch (item.definition.armorSlot) {
      ArmorSlots.HEAD => 'Head',
      ArmorSlots.SHOULDER => 'Shoulder',
      ArmorSlots.BACK => 'Back',
      ArmorSlots.CHEST => 'Chest',
      ArmorSlots.WAIST => 'Waist',
      ArmorSlots.LEGS => 'Legs',
      ArmorSlots.WRIST => 'Wrist',
      ArmorSlots.HANDS => 'Hands',
      ArmorSlots.FEET => 'Feet',
      ArmorSlots.NECK => 'Neck',
      ArmorSlots.FINGER || ArmorSlots.FINGER_2 => 'Ring',
      ArmorSlots.WEAPON_1H => 'One-handed weapon',
      ArmorSlots.WEAPON_2H => 'Two-handed weapon',
      ArmorSlots.OFFHAND => 'Off-hand',
      ArmorSlots.TOOL => 'Tool',
    };

/// Info dialog for a unique equipment instance: name and rarity, then one
/// row per stat with its change against the piece the player would be
/// taking off to wear it, then what it sells for.
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
        final shown = current;

        // what wearing this would take off, unless this is what is worn
        final equipment = _equipmentOf(dialogContext);
        final worn = equipment?.isEquipped(shown) ?? false;
        final baseline = equipment == null || worn
            ? null
            : equipment.counterpartFor(shown);

        final lines = equipmentStatLines(
          shown,
          baseline,
          showDeltas: baseline != null,
        );
        // the swing figures first, then the stats, each in the order
        // equipmentStatLines lists them — a stat it takes away stays in
        // its place
        final weaponLines = [
          for (final l in lines)
            if (l.weapon) l,
        ];
        final statLines = [
          for (final l in lines)
            if (!l.weapon) l,
        ];

        return AlertDialog(
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ItemStackTile(
                      size: 56,
                      count: 1,
                      id: shown.id,
                      showInfoDialogOnTap: false,
                      borderColor: rarityBorderColor(shown.quality),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shown.displayName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: rarityTextColor(shown.quality),
                            ),
                          ),
                          Text(
                            shown.quality.label.isEmpty
                                ? 'Common'
                                : shown.quality.label,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            equipmentSlotLabel(shown),
                            key: const ValueKey('equipment-slot'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (final line in weaponLines) EquipmentStatRow(line: line),
                if (weaponLines.isNotEmpty && statLines.isNotEmpty)
                  const Divider(height: 13),
                for (final line in statLines) EquipmentStatRow(line: line),
                // a preview of a tier rather than a rolled piece: the
                // secondaries are rolled per piece, so show how many and how
                // big, not which
                if (shown.needsSecondaryRolls)
                  _StatRowLayout(
                    key: const ValueKey('equipment-secondary-preview'),
                    icon: const Icon(
                      Icons.casino_outlined,
                      size: _statIconSize,
                      color: Colors.grey,
                    ),
                    value: Text(
                      '+${shown.definition.secondaryRollValue} '
                      '×${shown.quality.secondaryRolls}',
                      style: const TextStyle(
                        fontSize: _statFontSize,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  key: const ValueKey('equipment-value'),
                  children: [
                    IconRenderer(size: 16, id: ItemId.COINS),
                    const SizedBox(width: 6),
                    Text(
                      '${shown.value}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),

                // dev tools, folded away so they don't shape the dialog
                Theme(
                  data: Theme.of(
                    dialogContext,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    dense: true,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    title: const Text(
                      'Dev tools',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    children: [
                      // re-roll the whole stack's quality. quality is part
                      // of the stack identity, so there is no way to move
                      // part of a stack — the stack goes over whole
                      const Text('Dev: rarity'),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final rarity in Rarity.ladder)
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

                      // force the player-inventory stack count for this
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
                              final count = int.tryParse(
                                devCountController.text,
                              );
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

const double _statIconSize = 20;
const double _statFontSize = 16;

/// One stat in the details popup: icon, value, and its change against what
/// wearing the piece would take off, lined up on the right. A stat the
/// piece takes away entirely shows its loss where the value would be, with
/// the icon dimmed, rather than a bare "0".
class EquipmentStatRow extends StatelessWidget {
  EquipmentStatRow({required this.line}) : super(key: line.key);

  final EquipmentStatLine line;

  @override
  Widget build(BuildContext context) {
    if (line.lost) {
      return _StatRowLayout(
        icon: Opacity(opacity: 0.35, child: line.icon(_statIconSize)),
        value: Text(
          line.delta ?? '',
          style: const TextStyle(
            fontSize: _statFontSize,
            fontWeight: FontWeight.w600,
            color: statLossColor,
          ),
        ),
      );
    }
    final delta = line.delta;
    return _StatRowLayout(
      icon: line.icon(_statIconSize),
      value: Text(
        line.value,
        style: const TextStyle(
          fontSize: _statFontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      delta: delta == null
          ? null
          : Text(
              delta,
              style: TextStyle(
                fontSize: 14,
                color: line.gain ? statGainColor : statLossColor,
              ),
            ),
    );
  }
}

class _StatRowLayout extends StatelessWidget {
  const _StatRowLayout({
    super.key,
    required this.icon,
    required this.value,
    this.delta,
  });

  final Widget icon;
  final Widget value;
  final Widget? delta;

  @override
  Widget build(BuildContext context) {
    final delta = this.delta;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Align(alignment: Alignment.centerLeft, child: icon),
          ),
          Expanded(child: value),
          if (delta != null) delta,
        ],
      ),
    );
  }
}
