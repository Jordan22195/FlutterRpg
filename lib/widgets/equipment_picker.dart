import 'package:flutter/material.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/armor_equipment.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/widgets/equipment_card.dart';
import '../data/item.dart';
import '../widgets/food_card.dart';

class FoodPicker {
  static void build(
    BuildContext context,
    Function(Items id) onEquip, {
    Skills skillFilter = Skills.NULL,
  }) {
    final list = PlayerDataController.instance.data!.inventory
        .getFoodItemsSortedByHealing();
    print("Opening food picker dialog with ${list.length} items");
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
                    PlayerDataController.instance.refresh();
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
    ArmorSlots slot,
    Function(Items id) onEquip, {
    Skills skillFilter = Skills.NULL,
  }) {
    final list = skillFilter == Skills.NULL
        ? PlayerDataController.instance.data!.inventory
              .getItemsListForEquipmentSlot(slot)
        : PlayerDataController.instance.data!.inventory
              .getItemListForSlotAndSkill(slot, skillFilter);
    print("Opening dialog for slot: ${slot.name}, with ${list.length} items");
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
                    PlayerDataController.instance.refresh();
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
