import 'package:flutter/material.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import '../widgets/inventory_grid.dart';
import '../data/skill.dart';
import '../screens/skill_detail_screen.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final items = controller.data?.inventory.getObjectStackList() ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Card(child: InventoryGrid(items: items)),
    );
  }
}
