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

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Card(child: InventoryGrid(items: items)),
    );
  }
}
