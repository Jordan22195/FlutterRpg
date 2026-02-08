import 'package:flutter/material.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import 'explore_screen.dart';
import '../data/armor_equipment.dart';
import '../data/item.dart';

class GearScreen extends StatelessWidget {
  const GearScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();
    final gear = controller.data?.gear;

    return Scaffold(
      appBar: AppBar(title: const Text('Gear')),
      body: ListView(
        children: ArmorSlots.values.map((slot) {
          final item = gear?.armorEquipment[slot] ?? Items.NULL;
          return ListTile(
            title: Text(slot.name),
            trailing: Text(item.name),
            onTap: () {
              // open equip menu (modal)
              showModalBottomSheet(
                context: context,
                builder: (_) => Text("menu"), //EquipMenu(slot: slot),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
