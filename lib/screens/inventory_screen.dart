import 'package:flutter/material.dart';
import 'package:rpg/controllers/crafting_controller.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import '../widgets/inventory_grid.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final craftingController = context.watch<CraftingController>();
    final items = controller.data?.inventory.getObjectStackList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Card(child: InventoryGrid(items: items)),
    );
  }
}
