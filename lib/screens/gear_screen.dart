import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import '../catalogs/item_catalog.dart';
import '../widgets/equipment_card.dart';
import '../widgets/equipment_info_dialog.dart';
import '../widgets/equipment_picker.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/item_stack_tile.dart';

class GearScreen extends StatelessWidget {
  const GearScreen({super.key});

  // gathering skills that equip a tool; each has its own tool slot
  static const List<SkillId> _toolSkills = [
    SkillId.WOODCUTTING,
    SkillId.MINING,
    SkillId.FISHING,
    SkillId.HERBALISM,
  ];

  @override
  Widget build(BuildContext context) {
    final equipmentController = context.watch<EquipmentController>();
    final inventoryController = context.read<InventoryController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gear')),
      body: ListView(
        children: [
          // the shared TOOL slot is per skill; its rows are in the Tools
          // section below
          for (final slot in ArmorSlots.values)
            if (slot != ArmorSlots.TOOL)
              _armorSlotTile(
                context,
                equipmentController,
                inventoryController,
                slot,
              ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Tools',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final skill in _toolSkills)
            _toolSkillTile(context, equipmentController, skill),
        ],
      ),
    );
  }

  Widget _armorSlotTile(
    BuildContext context,
    EquipmentController equipmentController,
    InventoryController inventoryController,
    ArmorSlots slot,
  ) {
    final item = equipmentController.getItemInSlot(slot);
    return ListTile(
      title: Text(slot.name),
      subtitle: item == null ? null : Text(item.displayName),
      trailing: ItemStackTile(
        id: item?.id ?? ItemId.NULL,
        count: 1,
        size: 56,
        showInfoDialogOnTap: false,
        borderColor: item == null ? null : qualityBorderColor(item.quality),
        // tapping the equipped item's icon shows its stats; tapping
        // the row itself opens the slot's item picker
        onTap: item == null
            ? null
            : () => showEquipmentInfoDialog(context, item),
      ),
      onTap: () {
        final list = inventoryController.getSlotItemList(slot);
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
                      item: e,
                      onTap: () {
                        equipmentController.equipItem(e);
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
  }

  Widget _toolSkillTile(
    BuildContext context,
    EquipmentController equipmentController,
    SkillId skill,
  ) {
    final item = equipmentController.getToolForSkill(skill);
    return ListTile(
      leading: IconRenderer(id: skill, size: 32),
      title: Text(skill.name),
      subtitle: item == null ? null : Text(item.displayName),
      trailing: ItemStackTile(
        id: item?.id ?? ItemId.NULL,
        count: 1,
        size: 56,
        showInfoDialogOnTap: false,
        borderColor: item == null ? null : qualityBorderColor(item.quality),
        onTap: item == null
            ? null
            : () => showEquipmentInfoDialog(context, item),
      ),
      onTap: () => EquipmentPicker.build(
        context,
        const [ArmorSlots.TOOL],
        (picked) => equipmentController.equipToolForSkill(skill, picked),
        skillFilter: skill,
      ),
    );
  }
}
