import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import '../data/equipment_data.dart';
import '../catalogs/item_catalog.dart';
import '../widgets/equipment_card.dart';
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
        children: ArmorSlots.values.map((slot) {
          ItemId itemId = equipmentController.getItemInSlot(slot);
          return ListTile(
            title: Text(slot.name),
            trailing: ItemStackTile(id: itemId, count: 1, size: 56),
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
                            id: e,
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
