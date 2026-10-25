import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/inventory_controller.dart';
import '../data/equipment_data.dart';
import '../data/gear_set.dart';
import '../data/skill_data.dart';
import '../services/equipment_service.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
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

  /// One-handed and two-handed weapons share a single tile: only one is
  /// ever held, so [ArmorSlots.WEAPON_1H] stands for whichever it is — see
  /// [_slotItem] and [_slotCandidates].
  static const List<ArmorSlots> _weaponSlots = [
    ArmorSlots.WEAPON_1H,
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
    ArmorSlots.WEAPON_1H: 'Weapon',
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
    ArmorSlots.WEAPON_1H: 'Weapon',
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

  /// What the tile for [slot] shows: the weapon in hand, one- or
  /// two-handed, for the weapon tile; the slot's own piece otherwise.
  EquipmentItem? _slotItem(EquipmentController controller, ArmorSlots slot) =>
      slot == ArmorSlots.WEAPON_1H
      ? controller.getEquipedWeapon()
      : controller.getItemInSlot(slot);

  /// What the bag can put in [slot]: both kinds of weapon for the weapon
  /// tile, so one picker swaps between them.
  List<EquipmentItem> _slotCandidates(ArmorSlots slot) {
    final inventory = context.read<InventoryController>();
    if (slot != ArmorSlots.WEAPON_1H) return inventory.getSlotItemList(slot);
    return [
      ...inventory.getSlotItemList(ArmorSlots.WEAPON_1H),
      ...inventory.getSlotItemList(ArmorSlots.WEAPON_2H),
    ];
  }

  void _openSlotPicker(ArmorSlots slot) {
    final equipmentController = context.read<EquipmentController>();
    final equipped = _slotItem(equipmentController, slot);
    final isWeapon = slot == ArmorSlots.WEAPON_1H;
    EquipmentPicker.show(
      context,
      title: 'Change ${_slotLabels[slot]!.toLowerCase()}',
      slotLabel: _slotLabels[slot]!,
      equipped: equipped,
      available: _slotCandidates(slot),
      lockedReason: (item) => _lockedReason(equipmentController, item),
      onEquip: (item) {
        // a weapon goes to its own hand slot; the equip rules clear the
        // other one, so the tile only ever holds one
        equipmentController.equipItem(item, toSlot: isWeapon ? null : slot);
        setState(() {
          _selectedSlot = slot;
          _selectedTool = null;
        });
      },
      onUnequip: equipped == null
          ? null
          : () => equipmentController.unequipSlot(
              isWeapon ? equipped.armorSlot : slot,
            ),
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
    // the bag, so a slot's upgrade dot comes and goes with what is picked up
    context.watch<InventoryController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Gear')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          _combatLevelRow(context, equipmentController.getCombatLevel()),
          _statsTable(context, equipmentController.getStatBreakdown()),
          _paperDoll(context, equipmentController),
          _weaponRow(context, equipmentController),
          _detailCard(context, equipmentController),
          _sectionHeader(context, 'Gear sets'),
          _gearSetsPanel(context, equipmentController),
          _sectionHeader(context, 'Tools'),
          _toolsRow(context, equipmentController),
          _sectionHeader(context, 'Potions'),
          const PotionsPanel(),
        ],
      ),
    );
  }

  /// The player's combat level, read off what they are wearing — the number
  /// a creature's level on the zone screen is coloured against.
  Widget _combatLevelRow(BuildContext context, int level) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Semantics(
        label: 'Combat level $level',
        excludeSemantics: true,
        child: Row(
          children: [
            const IconRenderer(size: 20, id: SkillId.ATTACK),
            const SizedBox(width: 8),
            Text(
              'Combat level',
              style: HearthText.rowTitle.copyWith(
                fontSize: 15,
                color: palette.text,
              ),
            ),
            const Spacer(),
            Text(
              '$level',
              style: HearthText.xpValue.copyWith(
                fontSize: 20,
                color: palette.text,
              ),
            ),
          ],
        ),
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
              key: ValueKey('gear-slot-${slot.name}'),
              item: _slotItem(equipmentController, slot),
              selected: _selectedSlot == slot,
              emptyLabel: _slotShortLabels[slot]!,
              upgrade: _slotHasUpgrade(equipmentController, slot),
              onTap: () =>
                  _onSlotTap(slot, _slotItem(equipmentController, slot)),
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
              key: ValueKey('gear-slot-${slot.name}'),
              item: _slotItem(equipmentController, slot),
              selected: _selectedSlot == slot,
              emptyLabel: _slotShortLabels[slot]!,
              upgrade: _slotHasUpgrade(equipmentController, slot),
              onTap: () =>
                  _onSlotTap(slot, _slotItem(equipmentController, slot)),
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
                    key: ValueKey('gear-tool-${skill.name}'),
                    item: equipmentController.getToolForSkill(skill),
                    selected: _selectedTool == skill,
                    emptyLabel: _toolLabels[skill]!,
                    upgrade: equipmentController.hasUpgrade(
                      equipmentController.getToolForSkill(skill),
                      context
                          .read<InventoryController>()
                          .getSlotItemListForSkill(ArmorSlots.TOOL, skill),
                    ),
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

  /// Whether the bag holds something wearable for [slot] that adds up to
  /// more than what is in it — the same list the slot's picker offers.
  bool _slotHasUpgrade(EquipmentController controller, ArmorSlots slot) =>
      controller.hasUpgrade(_slotItem(controller, slot), _slotCandidates(slot));

  /// [upgrade] puts a dot in the corner: something in the bag would do
  /// better here.
  Widget _slotTile(
    BuildContext context, {
    Key? key,
    required EquipmentItem? item,
    required bool selected,
    required String emptyLabel,
    required VoidCallback onTap,
    bool upgrade = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final qualityColor = item == null ? null : rarityBorderColor(item.quality);
    final borderColor = qualityColor ?? scheme.outline.withOpacity(0.5);

    final tile = InkWell(
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

    return Semantics(
      label: upgrade ? 'Upgrade available' : null,
      child: Stack(
        key: key,
        clipBehavior: Clip.none,
        children: [
          tile,
          if (upgrade)
            Positioned(
              top: -3,
              right: -3,
              child: Container(
                key: const ValueKey('upgrade-dot'),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: context.gameColors.upgrade,
                  shape: BoxShape.circle,
                  // a ring in the background colour lifts it off the tile
                  border: Border.all(color: context.palette.bg, width: 2),
                ),
              ),
            ),
        ],
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
      item = _slotItem(equipmentController, slot);
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

  /// The saved outfits: one row each with a button to change into it and a
  /// menu to rename, re-save or delete it, then a button to save what is
  /// worn as a new one.
  Widget _gearSetsPanel(
    BuildContext context,
    EquipmentController equipmentController,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final sets = equipmentController.gearSets;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (sets.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'Save what you are wearing to swap back into it in one tap',
                style: TextStyle(fontSize: 12, color: scheme.outline),
              ),
            ),
          for (var i = 0; i < sets.length; i++)
            _gearSetRow(context, equipmentController, i, sets[i]),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('gear-set-save'),
              onPressed: equipmentController.canSaveGearSet
                  ? () => _saveGearSet(equipmentController)
                  : null,
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                equipmentController.canSaveGearSet
                    ? 'Save current gear'
                    : 'Set list full (${EquipmentService.maxGearSets})',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gearSetRow(
    BuildContext context,
    EquipmentController equipmentController,
    int index,
    GearSet set,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final worn = equipmentController.isWearingGearSet(index);
    final pieces =
        set.armor.length + (set.includesTools ? set.tools.length : 0);
    return Container(
      key: ValueKey('gear-set-row-$index'),
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: worn ? scheme.primary : scheme.outline.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  set.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$pieces ${pieces == 1 ? 'piece' : 'pieces'}'
                  '${set.includesTools ? ' · with tools' : ''}',
                  style: TextStyle(fontSize: 11, color: scheme.outline),
                ),
              ],
            ),
          ),
          FilledButton.tonal(
            key: ValueKey('gear-set-wear-$index'),
            onPressed: worn ? null : () => _swapToGearSet(index),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child: Text(worn ? 'Worn' : 'Wear'),
          ),
          PopupMenuButton<String>(
            key: ValueKey('gear-set-menu-$index'),
            tooltip: 'Set options',
            onSelected: (choice) {
              switch (choice) {
                case 'rename':
                  _renameGearSet(equipmentController, index, set);
                case 'overwrite':
                  equipmentController.overwriteGearSet(
                    index,
                    includeTools: set.includesTools,
                  );
                case 'delete':
                  _deleteGearSet(equipmentController, index, set);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'rename', child: Text('Rename')),
              PopupMenuItem(
                value: 'overwrite',
                child: Text('Save current gear here'),
              ),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }

  void _swapToGearSet(int index) {
    final equipmentController = context.read<EquipmentController>();
    final name = equipmentController.gearSets[index].name;
    final skipped = equipmentController.swapToGearSet(index);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          skipped.isEmpty
              ? 'Wearing $name'
              : 'Wearing $name — left out '
                    '${skipped.map(_skipText).join(', ')}',
        ),
      ),
    );
  }

  String _skipText(GearSetSkip skip) {
    final label = skip.piece.label.isEmpty ? 'a piece' : skip.piece.label;
    final needed = skip.requirement;
    return switch (skip.reason) {
      GearSetSkipReason.missing => '$label (no longer owned)',
      GearSetSkipReason.locked when needed != null =>
        '$label (needs ${_skillLabel(needed.skill)} ${needed.level})',
      GearSetSkipReason.locked => '$label (level too low)',
      GearSetSkipReason.wrongSlot => '$label (no longer fits)',
    };
  }

  /// Asks for a name (and whether tools come along) and saves what is worn.
  Future<void> _saveGearSet(EquipmentController equipmentController) async {
    final result = await _gearSetNameDialog(
      title: 'Save gear set',
      initialName: equipmentController.defaultGearSetName(),
      askIncludeTools: true,
    );
    if (result == null || !mounted) return;
    equipmentController.saveGearSet(
      name: result.name,
      includeTools: result.includeTools,
    );
  }

  Future<void> _renameGearSet(
    EquipmentController equipmentController,
    int index,
    GearSet set,
  ) async {
    final result = await _gearSetNameDialog(
      title: 'Rename gear set',
      initialName: set.name,
      askIncludeTools: false,
    );
    if (result == null || !mounted) return;
    equipmentController.renameGearSet(index, result.name);
  }

  Future<void> _deleteGearSet(
    EquipmentController equipmentController,
    int index,
    GearSet set,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${set.name}?'),
        content: const Text('The gear itself stays where it is.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('gear-set-delete-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      equipmentController.deleteGearSet(index);
    }
  }

  Future<({String name, bool includeTools})?> _gearSetNameDialog({
    required String title,
    required String initialName,
    required bool askIncludeTools,
  }) {
    return showDialog<({String name, bool includeTools})>(
      context: context,
      builder: (_) => _GearSetNameDialog(
        title: title,
        initialName: initialName,
        askIncludeTools: askIncludeTools,
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
    if (currentItem is WeaponItem && currentItem.definition.usesDamage) {
      chips.add(
        StatChip(
          icon: const Icon(Icons.gavel, size: 14, color: Colors.grey),
          value: formatDamage(currentItem.damage),
        ),
      );
    }
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

/// Asks for a gear set's name and, when saving a new one, whether the
/// gathering tools come along. Pops a record of both, or null on cancel.
class _GearSetNameDialog extends StatefulWidget {
  const _GearSetNameDialog({
    required this.title,
    required this.initialName,
    required this.askIncludeTools,
  });

  final String title;
  final String initialName;
  final bool askIncludeTools;

  @override
  State<_GearSetNameDialog> createState() => _GearSetNameDialogState();
}

class _GearSetNameDialogState extends State<_GearSetNameDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.initialName,
  );
  bool _includeTools = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() =>
      Navigator.pop(context, (name: _name.text, includeTools: _includeTools));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const ValueKey('gear-set-name-field'),
            controller: _name,
            autofocus: true,
            maxLength: GearSet.maxNameLength,
            decoration: const InputDecoration(labelText: 'Name'),
            onSubmitted: (_) => _submit(),
          ),
          if (widget.askIncludeTools)
            CheckboxListTile(
              key: const ValueKey('gear-set-include-tools'),
              contentPadding: EdgeInsets.zero,
              value: _includeTools,
              onChanged: (v) => setState(() => _includeTools = v ?? false),
              title: const Text('Include gathering tools'),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const ValueKey('gear-set-dialog-confirm'),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
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
