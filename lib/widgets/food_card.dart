import 'package:flutter/material.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/icon_renderer.dart';
import 'package:rpg/widgets/item_stack_tile.dart';

class FoodCard extends StatelessWidget {
  FoodCard({
    super.key,
    required this.id,
    required this.onTap,
    this.maxCraftable = true,
    this.height = 68,
  });

  bool maxCraftable = true;
  final ItemId id;
  final VoidCallback? onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    print("Building EquipmentCard for item ID: $id");
    final item = ItemCatalog.definitionFor(id) as FoodItemDefinition?;

    if (item == null) {
      return Card(
        child: SizedBox(
          height: height,
          child: const Center(child: Text('Item not found')),
        ),
      );
    }

    int stats = item.restoreAmount ?? -1;
    final skill = item.restoreSkill;

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
                ItemStackTile(
                  size: 52,
                  id: id,
                  count: PlayerDataController.instance.data!.inventory.countOf(
                    id,
                  ),
                ),

                // Stats (right)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          IconRenderer(size: 16, id: skill),
                          Text(
                            "+${stats}",
                            style: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
