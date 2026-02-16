import 'package:flutter/material.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/inventory.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/data/zone_location.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../data/skill.dart';
import '../controllers/crafting_controller.dart';

class EquipmentCard extends StatelessWidget {
  EquipmentCard({
    super.key,
    required this.id,
    required this.onTap,
    this.maxCraftable = true,
    this.height = 68,
  });

  bool maxCraftable = true;
  final Items id;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    print("Building EquipmentCard for item ID: $id");
    final item = ItemController.buildItem(id) as EquipmentItem?;
    double actionInterval = 0;
    if (item is WeaponItem) {
      actionInterval = item.actionInterval.inSeconds.toDouble();
    }

    if (item == null) {
      return Card(
        child: SizedBox(
          height: height,
          child: const Center(child: Text('Item not found')),
        ),
      );
    }

    final stats = item.skillBonus;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Icon (left)
                ItemStackTile(size: 52, id: item.id, count: 1),

                // Stats (right)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final entry in stats.entries) ...[
                            IconRenderer(size: 16, id: entry.key),
                            Text(
                              "${entry.value}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 2),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

                if (actionInterval > 0) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.timer, size: 16, color: Colors.grey),
                  Text(
                    "${actionInterval.toStringAsFixed(1)}s",
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
