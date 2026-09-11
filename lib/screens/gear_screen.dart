import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import '../widgets/equipment_picker.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/stat_chip.dart';
import '../widgets/potions_panel.dart';

/// Paper-doll gear screen: armor slots flank a character silhouette,
/// weapons sit below it, and a detail card shows the selected slot's
/// stats. Tapping an empty slot opens the picker directly.
class GearScreen extends StatefulWidget {
  const GearScreen({super.key});

  @override
  State<GearScreen> createState() => _GearScreenState();
}

class _GearScreenState extends State<GearScreen> {
  static const List<ArmorSlots> _leftSlots = [
    ArmorSlots.HEAD,
    ArmorSlots.SHOULDER,
    ArmorSlots.NECK,
    ArmorSlots.BACK,
    ArmorSlots.CHEST,
    ArmorSlots.WRIST,
  ];
  static const List<ArmorSlots> _rightSlots = [
    ArmorSlots.HANDS,
    ArmorSlots.WAIST,
    ArmorSlots.LEGS,
    ArmorSlots.FEET,
    ArmorSlots.FINGER,
    ArmorSlots.FINGER_2,
  ];
  static const List<ArmorSlots> _weaponSlots = [
    ArmorSlots.WEAPON_1H,
    ArmorSlots.WEAPON_2H,
    ArmorSlots.OFFHAND,
  ];

  // the taller of the two paper-doll columns, in tiles
  static final int _dollColumnSlots = _leftSlots.length > _rightSlots.length
      ? _leftSlots.length
      : _rightSlots.length;

  // gathering skills that equip a tool; each has its own tool slot
  static const List<SkillId> _toolSkills = [
    SkillId.WOODCUTTING,
    SkillId.MINING,
    SkillId.FISHING,
    SkillId.HERBALISM,
  ];

  static const Map<ArmorSlots, String> _slotLabels = {
    ArmorSlots.HEAD: 'Head',
    ArmorSlots.SHOULDER: 'Shoulder',
    ArmorSlots.BACK: 'Back',
    ArmorSlots.CHEST: 'Chest',
    ArmorSlots.WAIST: 'Waist',
    ArmorSlots.LEGS: 'Legs',
    ArmorSlots.WRIST: 'Wrist',
    ArmorSlots.HANDS: 'Hands',
    ArmorSlots.FEET: 'Feet',
    ArmorSlots.NECK: 'Neck',
    ArmorSlots.FINGER: 'Ring 1',
    ArmorSlots.FINGER_2: 'Ring 2',
    ArmorSlots.WEAPON_1H: 'Main hand',
    ArmorSlots.WEAPON_2H: 'Two-hand',
    ArmorSlots.OFFHAND: 'Offhand',
  };

  // short labels rendered inside empty slot tiles
  static const Map<ArmorSlots, String> _slotShortLabels = {
    ArmorSlots.HEAD: 'Head',
    ArmorSlots.SHOULDER: 'Shldr',
    ArmorSlots.BACK: 'Back',
    ArmorSlots.CHEST: 'Chest',
    ArmorSlots.WAIST: 'Waist',
    ArmorSlots.LEGS: 'Legs',
    ArmorSlots.WRIST: 'Wrist',
    ArmorSlots.HANDS: 'Hands',
    ArmorSlots.FEET: 'Feet',
    ArmorSlots.NECK: 'Neck',
    ArmorSlots.FINGER: 'Ring 1',
    ArmorSlots.FINGER_2: 'Ring 2',
    ArmorSlots.WEAPON_1H: '1H',
    ArmorSlots.WEAPON_2H: '2H',
    ArmorSlots.OFFHAND: 'Off',
  };

  static const Map<SkillId, String> _toolLabels = {
    SkillId.WOODCUTTING: 'Wood',
    SkillId.MINING: 'Mining',
    SkillId.FISHING: 'Fishing',
    SkillId.HERBALISM: 'Herbs',
  };

  // selection is either an armor/weapon slot or a tool skill
  ArmorSlots? _selectedSlot = ArmorSlots.HEAD;
  SkillId? _selectedTool;

  String _skillLabel(SkillId skill) {
    final name = skill.name.toLowerCase();
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }

  /// Why the player cannot wear [item] yet, phrased for the picker, or null
  /// when they can. Reads the gate the equipment manager enforces rather
  /// than a second copy of it, so the two cannot disagree.
  String? _lockedReason(EquipmentController controller, EquipmentItem item) {
    if (controller.canEquip(item)) return null;
    final needed = controller.requirementFor(item);
    if (needed == null) return null;
    return 'Needs ${_skillLabel(needed.skill)} ${needed.level}';
  }

  void _openSlotPicker(ArmorSlots slot) {
    final equipmentController = context.read<EquipmentController>();
    final inventoryController = context.read<InventoryController>();
    final equipped = equipmentController.getItemInSlot(slot);
    EquipmentPicker.show(
      context,
      title: 'Change ${_slotLabels[slot]!.toLowerCase()}',
      slotLabel: _slotLabels[slot]!,
      equipped: equipped,
      available: inventoryController.getSlotItemList(slot),
      lockedReason: (item) => _lockedReason(equipmentController, item),
      onEquip: (item) {
        equipmentController.equipItem(item, toSlot: slot);
        setState(() {
          _selectedSlot = slot;
          _selectedTool = null;
        });
      },
      onUnequip: equipped == null
          ? null
          : () => equipmentController.unequipSlot(slot),
    );
  }

  void _openToolPicker(SkillId skill) {
    final equipmentController = context.read<EquipmentController>();
    final inventoryController = context.read<InventoryController>();
    final equipped = equipmentController.getToolForSkill(skill);
    EquipmentPicker.show(
      context,
      title: 'Change ${skill.name.toLowerCase()} tool',
      slotLabel: _skillLabel(skill),
      equipped: equipped,
      available: inventoryController.getSlotItemListForSkill(
        ArmorSlots.TOOL,
        skill,
      ),
      lockedReason: (item) => _lockedReason(equipmentController, item),
      onEquip: (item) {
        equipmentController.equipToolForSkill(skill, item);
        setState(() {
          _selectedTool = skill;
          _selectedSlot = null;
        });
      },
      onUnequip: equipped == null
          ? null
          : () => equipmentController.unequipToolForSkill(skill),
    );
  }

  void _onSlotTap(ArmorSlots slot, EquipmentItem? item) {
    if (item == null) {
      _openSlotPicker(slot);
    } else {
      setState(() {
        _selectedSlot = slot;
        _selectedTool = null;
      });
    }
  }

  void _onToolTap(SkillId skill, EquipmentItem? item) {
    if (item == null) {
      _openToolPicker(skill);
    } else {
      setState(() {
        _selectedTool = skill;
        _selectedSlot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final equipmentController = context.watch<EquipmentController>();
    // the buff tick is what moves the buff column as a potion runs down
    context.watch<BuffController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gear')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _statsTable(context, equipmentController.getStatBreakdown()),
          _paperDoll(context, equipmentController),
          _weaponRow(context, equipmentController),
          _detailCard(context, equipmentController),
          _sectionHeader(context, 'Tools'),
          _toolsRow(context, equipmentController),
          _sectionHeader(context, 'Potions'),
          const PotionsPanel(),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          letterSpacing: 0.6,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  /// Where every stat comes from: the levels the player has earned, the gear
  /// they are wearing, the potions they have drunk, and the stance they are
  /// holding — then the total the game actually plays by.
  ///
  /// Only stats something other than a level touches get a row. A gear screen
  /// listing every skill the player has would bury the paper doll under a
  /// wall of numbers that never move; the interesting rows are the ones gear
  /// or a potion is changing, and those carry their skill column with them.
  Widget _statsTable(
    BuildContext context,
    ({
      Map<SkillId, int> skills,
      Map<SkillId, int> gear,
      Map<SkillId, int> buffs,
      Map<SkillId, int> stance,
      Map<SkillId, int> total,
    })
    stats,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final hasStance = stats.stance.values.any((v) => v != 0);

    // a row per stat that gear, a potion or the stance is moving
    final rows = {
      ...stats.gear.keys.where((k) => (stats.gear[k] ?? 0) != 0),
      ...stats.buffs.keys.where((k) => (stats.buffs[k] ?? 0) != 0),
      ...stats.stance.keys.where((k) => (stats.stance[k] ?? 0) != 0),
    }.toList()..sort((a, b) => a.index.compareTo(b.index));

    Widget cell(
      String text, {
      required Color color,
      bool bold = false,
      SkillId? icon,
      int flex = 1,
    }) {
      final label = Text(
        text,
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      return Expanded(
        flex: flex,
        child: icon == null
            ? label
            : Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconRenderer(size: 16, id: icon),
                  const SizedBox(width: 5),
                  label,
                ],
              ),
      );
    }

    Widget heading(String text, {bool bold = false, int flex = 1}) {
      return Expanded(
        flex: flex,
        child: Text(
          text.toUpperCase(),
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 9,
            letterSpacing: 0.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: scheme.outline,
          ),
        ),
      );
    }

    /// A contribution reads as what it adds, so a zero is a dash rather than
    /// a 0 the eye has to add up.
    String plus(int value) => value == 0 ? '—' : '+$value';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STATS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 0.6,
              color: scheme.outline,
            ),
          ),
          const SizedBox(height: 6),
          if (rows.isEmpty)
            Text(
              'Nothing equipped — your stats are your skill levels',
              style: TextStyle(fontSize: 12, color: scheme.outline),
            )
          else ...[
            Row(
              key: const ValueKey('gear-stats-heading'),
              children: [
                heading('skill'),
                heading('gear'),
                heading('buff'),
                if (hasStance) heading('stance'),
                heading('total', bold: true, flex: 2),
              ],
            ),
            const SizedBox(height: 2),
            for (final stat in rows)
              Padding(
                key: ValueKey('gear-stat-row-${stat.name}'),
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    cell('${stats.skills[stat] ?? 0}', color: scheme.outline),
                    cell(plus(stats.gear[stat] ?? 0), color: statGainColor),
                    cell(plus(stats.buffs[stat] ?? 0), color: scheme.primary),
                    if (hasStance)
                      cell(
                        plus(stats.stance[stat] ?? 0),
                        color: scheme.tertiary,
                      ),
                    cell(
                      '${stats.total[stat] ?? 0}',
                      color: scheme.onSurface,
                      bold: true,
                      icon: stat,
                      flex: 2,
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _paperDoll(
    BuildContext context,
    EquipmentController equipmentController,
  ) {
    Widget slotColumn(List<ArmorSlots> slots) {
      return Column(
        children: [
          for (final slot in slots) ...[
            _slotTile(
              context,
              item: equipmentController.getItemInSlot(slot),
              selected: _selectedSlot == slot,
              emptyLabel: _slotShortLabels[slot]!,
              onTap: () =>
                  _onSlotTap(slot, equipmentController.getItemInSlot(slot)),
            ),
            if (slot != slots.last) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          slotColumn(_leftSlots),
          Expanded(
            child: SizedBox(
              // matches the taller slot column so the figure centers
              height: _dollColumnSlots * 52 + (_dollColumnSlots - 1) * 10,
              child: Center(
                child: CustomPaint(
                  size: const Size(110, 227),
                  painter: _SilhouettePainter(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.08),
                  ),
                ),
              ),
            ),
          ),
          slotColumn(_rightSlots),
        ],
      ),
    );
  }

  Widget _weaponRow(
    BuildContext context,
    EquipmentController equipmentController,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final slot in _weaponSlots) ...[
            _slotTile(
              context,
              item: equipmentController.getItemInSlot(slot),
              selected: _selectedSlot == slot,
              emptyLabel: _slotShortLabels[slot]!,
              onTap: () =>
                  _onSlotTap(slot, equipmentController.getItemInSlot(slot)),
            ),
            if (slot != _weaponSlots.last) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }

  Widget _toolsRow(
    BuildContext context,
    EquipmentController equipmentController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          for (final skill in _toolSkills)
            Expanded(
              child: Column(
                children: [
                  _slotTile(
                    context,
                    item: equipmentController.getToolForSkill(skill),
                    selected: _selectedTool == skill,
                    emptyLabel: _toolLabels[skill]!,
                    onTap: () => _onToolTap(
                      skill,
                      equipmentController.getToolForSkill(skill),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _toolLabels[skill]!,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _slotTile(
    BuildContext context, {
    required EquipmentItem? item,
    required bool selected,
    required String emptyLabel,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final qualityColor = item == null ? null : rarityBorderColor(item.quality);
    final borderColor = qualityColor ?? scheme.outline.withOpacity(0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: qualityColor != null ? 2 : 1,
          ),
          // selection ring around the tile, on top of the quality border
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.7),
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: item != null
            ? Center(child: IconRenderer(size: 44, id: item.id))
            : Center(
                child: Text(
                  emptyLabel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.4,
                    color: scheme.outline.withOpacity(0.8),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _detailCard(
    BuildContext context,
    EquipmentController equipmentController,
  ) {
    final scheme = Theme.of(context).colorScheme;

    final String slotLabel;
    final EquipmentItem? item;
    final VoidCallback onChange;
    final selectedTool = _selectedTool;
    if (selectedTool != null) {
      slotLabel = '${_skillLabel(selectedTool)} tool';
      item = equipmentController.getToolForSkill(selectedTool);
      onChange = () => _openToolPicker(selectedTool);
    } else {
      final slot = _selectedSlot ?? ArmorSlots.HEAD;
      slotLabel = _slotLabels[slot]!;
      item = equipmentController.getItemInSlot(slot);
      onChange = () => _openSlotPicker(slot);
    }

    final qualityColor = item == null ? null : rarityBorderColor(item.quality);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.35),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: scheme.outline.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            ItemStackTile(
              size: 46,
              id: item?.id ?? ItemId.NULL,
              count: 1,
              showInfoDialogOnTap: false,
              borderColor: qualityColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${slotLabel.toUpperCase()} — SELECTED',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.6,
                      color: scheme.outline,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item?.displayName ?? 'Empty',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: item == null ? scheme.outline : qualityColor,
                    ),
                  ),
                  if (item != null) ...[
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: _detailStatChips(item),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: onChange,
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: Text(item == null ? 'Equip' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _detailStatChips(EquipmentItem item) {
    final chips = <Widget>[
      for (final entry in item.effectiveSkillBonus.entries)
        StatChip(
          icon: IconRenderer(size: 14, id: entry.key),
          value: '${entry.value}',
        ),
    ];
    final currentItem = item;
    if (currentItem is WeaponItem) {
      chips.add(
        StatChip(
          icon: const Icon(Icons.timer, size: 14, color: Colors.grey),
          value:
              '${(currentItem.actionInterval.inMilliseconds / 1000).toStringAsFixed(1)}s',
        ),
      );
    }
    return chips;
  }
}

/// Simple front-facing character outline behind the slot columns.
class _SilhouettePainter extends CustomPainter {
  const _SilhouettePainter({required this.color});

  final Color color;

  // drawn in a 64 x 132 design space and scaled to the canvas
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final sx = size.width / 64;
    final sy = size.height / 132;
    canvas.scale(sx, sy);

    canvas.drawCircle(const Offset(32, 17), 13, paint);

    final torso = Path()
      ..moveTo(14, 42)
      ..quadraticBezierTo(32, 33, 50, 42)
      ..lineTo(46, 60)
      ..lineTo(42, 58)
      ..lineTo(40, 96)
      ..lineTo(36, 96)
      ..lineTo(34, 128)
      ..lineTo(30, 128)
      ..lineTo(28, 96)
      ..lineTo(24, 96)
      ..lineTo(22, 58)
      ..lineTo(18, 60)
      ..close();
    canvas.drawPath(torso, paint);

    final leftArm = Path()
      ..moveTo(14, 42)
      ..lineTo(10, 82)
      ..lineTo(17, 84)
      ..lineTo(20, 52)
      ..close();
    canvas.drawPath(leftArm, paint);

    final rightArm = Path()
      ..moveTo(50, 42)
      ..lineTo(54, 82)
      ..lineTo(47, 84)
      ..lineTo(44, 52)
      ..close();
    canvas.drawPath(rightArm, paint);
  }

  @override
  bool shouldRepaint(_SilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}
