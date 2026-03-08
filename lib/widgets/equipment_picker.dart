import 'package:flutter/material.dart';
import 'package:rpg/services/player_data_service.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/widgets/equipment_card.dart';
import '../catalogs/item_catalog.dart';
import '../widgets/food_card.dart';

class FoodPicker {
  static void build(
    BuildContext context,
    Function(ItemId id) onEquip, {
    SkillId skillFilter = SkillId.NULL,
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
    Function(ItemId id) onEquip, {
    SkillId skillFilter = SkillId.NULL,
  }) {
    final list = skillFilter == SkillId.NULL
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
