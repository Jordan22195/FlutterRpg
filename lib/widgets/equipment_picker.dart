import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/widgets/equipment_card.dart';
import '../catalogs/item_catalog.dart';
import '../widgets/food_card.dart';

class FoodPicker {
  static void build(
    BuildContext context,
    Function(ItemId id) onEquip, {
    SkillId skillFilter = SkillId.NULL,
  }) {
    final controller = context.read<InventoryController>();
    final list = controller.getFoodItems();
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
                final id = list[i];
                return FoodCard(
                  id: id,
                  onTap: () {
                    onEquip(id);
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
  }
}

class EquipmentPicker {
  static void build(
    BuildContext context,
    List<ArmorSlots> slots,
    Function(ItemId id) onEquip, {
    SkillId skillFilter = SkillId.NULL,
  }) {
    final controller = context.read<InventoryController>();
    final list = [
      for (final slot in slots)
        ...(skillFilter == SkillId.NULL
            ? controller.getSlotItemList(slot)
            : controller.getSlotItemListForSkill(slot, skillFilter)),
    ];
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
                    onEquip(e);
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
  }
}
