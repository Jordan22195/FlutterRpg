import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import '../data/equipment_data.dart';
import '../catalogs/item_catalog.dart';
import '../widgets/equipment_card.dart';
import '../widgets/equipment_info_dialog.dart';
import '../widgets/item_stack_tile.dart';

class GearScreen extends StatelessWidget {
  const GearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final equipmentController = context.watch<EquipmentController>();
    final inventoryController = context.read<InventoryController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gear')),
      body: ListView(
        // tools are equipped per skill from the encounter screens,
        // so the shared TOOL slot is not shown here
        children: ArmorSlots.values.where((s) => s != ArmorSlots.TOOL).map((
          slot,
        ) {
          final item = equipmentController.getItemInSlot(slot);
          return ListTile(
            title: Text(slot.name),
            subtitle: item == null ? null : Text(item.displayName),
            trailing: ItemStackTile(
              id: item?.id ?? ItemId.NULL,
              count: 1,
              size: 56,
              showInfoDialogOnTap: false,
              borderColor: item == null
                  ? null
                  : qualityBorderColor(item.quality),
              // tapping the equipped item's icon shows its stats; tapping
              // the row itself opens the slot's item picker
              onTap: item == null
                  ? null
                  : () => showEquipmentInfoDialog(context, item),
            ),
            onTap: () {
              final list = inventoryController.getSlotItemList(slot);
              showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: const Text('Select Item'),
                    content: SizedBox(
                      width: double.maxFinite,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, i) {
                          final e = list[i];
                          return EquipmentCard(
                            item: e,
                            onTap: () {
                              equipmentController.equipItem(e);
                              Navigator.of(ctx).pop();
                            },
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Close'),
                      ),
                    ],
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
