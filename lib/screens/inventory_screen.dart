import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/inventory_controller.dart';
import '../widgets/inventory_grid.dart';

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
          // stackables first, then each unique piece of equipment with its
          // own quality and enchant — one bag, one grid
          Card(
            child: InventoryGrid(
              items: items,
              equipment: equipment,
              shrinkWrap: true,
              showActiveBuffTimers: true,
            ),
          ),
        ],
      ),
    );
  }
}
