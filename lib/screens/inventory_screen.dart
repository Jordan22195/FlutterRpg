import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/equipment_info_dialog.dart';
import '../widgets/inventory_grid.dart';
import '../widgets/item_stack_tile.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InventoryController>();
    final items = controller.getObjectStackList();
    final equipment = controller.getEquipmentList();

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: ListView(
        children: [
          Card(child: InventoryGrid(items: items, shrinkWrap: true)),

          // unique equipment instances, each with its own quality/enchant
          if (equipment.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text('Equipment'),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in equipment)
                      ItemStackTile(
                        size: 56,
                        count: item.count,
                        id: item.id,
                        showInfoDialogOnTap: false,
                        borderColor: qualityBorderColor(item.quality),
                        onTap: () => showEquipmentInfoDialog(context, item),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
