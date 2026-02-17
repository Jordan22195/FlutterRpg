import 'package:flutter/material.dart';
import 'package:rpg/widgets/equipment_card.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import 'explore_screen.dart';
import '../data/armor_equipment.dart';
import '../data/item.dart';
import '../widgets/item_stack_tile.dart';

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
          Items itemId = gear?.armorEquipment[slot] ?? Items.NULL;
          return ListTile(
            title: Text(slot.name),
            trailing: ItemStackTile(id: itemId, count: 1, size: 32),
            onTap: () {
              final list = controller.data!.inventory
                  .getItemsListForEquipmentSlot(slot);
              print(
                "Opening dialog for slot: ${slot.name}, with ${list.length} items",
              );
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
                              controller.refresh();
                              gear?.equipItem(e);
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
