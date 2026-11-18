import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import '../catalogs/items/items.dart';
import '../widgets/food_card.dart';
import 'icon_renderer.dart';
import 'equipment_info_dialog.dart';
import 'item_stack_tile.dart';
import 'stat_chip.dart';

/// The food dialog: which food fights are fed with, and when auto-eat eats
/// it. Food lists most healing first — the order auto-eat moves down when a
/// stack runs out.
class FoodPicker {
  /// The auto-eat slider's range, as a share of max hp. Below 5% the next
  /// hit would usually land first; above 95% it eats on every scratch.
  static const double minThreshold = 0.05;
  static const double maxThreshold = 0.95;

  static void build(
    BuildContext context,
    Function(ItemId id) onEquip, {
    SkillId skillFilter = SkillId.NULL,
  }) {
    final controller = context.read<InventoryController>();
    final player = context.read<PlayerDataController>();
    final list = controller.getFoodItems();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Select Food'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _AutoEatHelp(),
                const SizedBox(height: 4),
                // StatefulBuilder: the dialog is built once, but the slider
                // has to move as it is dragged
                StatefulBuilder(
                  builder: (context, setState) {
                    final threshold = player.getAutoEatThreshold().clamp(
                      minThreshold,
                      maxThreshold,
                    );
                    return _AutoEatSlider(
                      threshold: threshold,
                      onChanged: (value) {
                        player.setAutoEatThreshold(value);
                        setState(() {});
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: list.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text('No food in the bag')),
                        )
                      : ListView.builder(
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
              ],
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

/// How auto-eat works, in a line or two above its slider.
class _AutoEatHelp extends StatelessWidget {
  const _AutoEatHelp();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Auto-eat: during a fight, one of the selected food is eaten whenever '
      'your HP drops to the threshold below. When a stack runs out, the next '
      'food down this list is selected, wrapping back to the top.',
      key: const ValueKey('auto-eat-help'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}

/// The share of max hp auto-eat eats at, in 5% steps.
class _AutoEatSlider extends StatelessWidget {
  const _AutoEatSlider({required this.threshold, required this.onChanged});

  final double threshold;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final percent = (threshold * 100).round();
    return Row(
      children: [
        Expanded(
          child: Slider(
            key: const ValueKey('auto-eat-slider'),
            value: threshold,
            min: FoodPicker.minThreshold,
            max: FoodPicker.maxThreshold,
            divisions: 18,
            label: '$percent%',
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 92,
          child: Text(
            'Eat at $percent%',
            key: const ValueKey('auto-eat-threshold'),
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}

/// Bottom-sheet equipment picker for one slot: shows what's currently
/// equipped, then every candidate with per-stat deltas vs. the equipped
/// item (green = higher, red = lower). Tapping a candidate equips it. A row
/// of chips above the list sorts the candidates by any stat they carry.
class EquipmentPicker {
  static void show(
    BuildContext context, {
    required String title,
    required String slotLabel,
    required EquipmentItem? equipped,
    required List<EquipmentItem> available,
    required void Function(EquipmentItem item) onEquip,
    VoidCallback? onUnequip,
    String? Function(EquipmentItem item)? lockedReason,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _EquipmentPickerSheet(
        title: title,
        slotLabel: slotLabel,
        equipped: equipped,
        available: available,
        onEquip: onEquip,
        onUnequip: onUnequip,
        lockedReason: lockedReason,
      ),
    );
  }
}

/// One way the picker can order its candidates: a stat, read off each
/// piece, highest first.
class EquipmentSortKey {
  const EquipmentSortKey({
    required this.id,
    required this.label,
    required this.icon,
    required this.valueOf,
  });

  /// Stable name, used for the chip's key: `equipment-sort-$id`.
  final String id;
  final String label;
  final Widget icon;

  /// The piece's value for this stat; higher sorts first.
  final double Function(EquipmentItem item) valueOf;

  /// The keys worth offering for [items], in the order the stat lines run:
  /// damage, dps and swing speed where any piece has them, then every
  /// skill stat any of them carries in [statDisplayOrder], then xp.
  static List<EquipmentSortKey> forItems(Iterable<EquipmentItem> items) {
    final list = items.toList();
    final skills = <SkillId>{
      for (final item in list)
        for (final e in item.effectiveSkillBonus.entries)
          if (e.value != 0) e.key,
    }.toList()..sort(compareStatOrder);

    final keys = <EquipmentSortKey>[];
    bool swings(EquipmentItem item) =>
        item is WeaponItem && item.definition.usesDamage;
    if (list.any(swings)) {
      keys.add(
        EquipmentSortKey(
          id: 'damage',
          label: 'Damage',
          icon: const Icon(Icons.gavel, size: 14, color: Colors.grey),
          valueOf: (item) => swings(item) ? (item as WeaponItem).damage : 0,
        ),
      );
      keys.add(
        EquipmentSortKey(
          id: 'dps',
          label: 'DPS',
          icon: const Icon(Icons.bolt, size: 14, color: Colors.grey),
          valueOf: (item) =>
              swings(item) ? (item as WeaponItem).damagePerSecond : 0,
        ),
      );
    }
    if (list.any((item) => item is WeaponItem)) {
      // faster is better: the shorter interval sorts first, and anything
      // that is not a weapon after every weapon
      keys.add(
        EquipmentSortKey(
          id: 'speed',
          label: 'Speed',
          icon: const Icon(Icons.timer, size: 14, color: Colors.grey),
          valueOf: (item) => item is WeaponItem
              ? -item.actionInterval.inMilliseconds.toDouble()
              : double.negativeInfinity,
        ),
      );
    }

    keys.addAll([
      for (final skill in skills)
        EquipmentSortKey(
          id: skill.name,
          label: _titleCase(skill.name),
          icon: IconRenderer(size: 14, id: skill),
          valueOf: (item) => (item.effectiveSkillBonus[skill] ?? 0).toDouble(),
        ),
    ]);

    if (list.any((item) => _xpPercentOf(item) != 0)) {
      keys.add(
        EquipmentSortKey(
          id: 'xp',
          label: 'XP',
          icon: const Icon(Icons.auto_graph, size: 14, color: Colors.grey),
          valueOf: (item) => _xpPercentOf(item).toDouble(),
        ),
      );
    }
    return keys;
  }

  /// [items] ordered by this stat, highest first; ties keep their order.
  List<EquipmentItem> sort(List<EquipmentItem> items) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final byValue = valueOf(b.$2).compareTo(valueOf(a.$2));
      return byValue != 0 ? byValue : a.$1.compareTo(b.$1);
    });
    return [for (final e in indexed) e.$2];
  }
}

String _titleCase(String name) {
  final lower = name.toLowerCase();
  return '${lower[0].toUpperCase()}${lower.substring(1)}';
}

int _xpPercentOf(EquipmentItem? piece) {
  final def = piece?.definition;
  return def is JewelleryDefinition ? def.xpPercentAt(piece!.quality) : 0;
}

class _EquipmentPickerSheet extends StatefulWidget {
  const _EquipmentPickerSheet({
    required this.title,
    required this.slotLabel,
    required this.equipped,
    required this.available,
    required this.onEquip,
    this.onUnequip,
    this.lockedReason,
  });

  final String title;
  final String slotLabel;
  final EquipmentItem? equipped;
  final List<EquipmentItem> available;
  final void Function(EquipmentItem item) onEquip;
  final VoidCallback? onUnequip;
  final String? Function(EquipmentItem item)? lockedReason;

  @override
  State<_EquipmentPickerSheet> createState() => _EquipmentPickerSheetState();
}

class _EquipmentPickerSheetState extends State<_EquipmentPickerSheet> {
  late final List<EquipmentSortKey> _sortKeys = EquipmentSortKey.forItems(
    widget.available,
  );

  /// The stat the list is sorted by, or null for the bag's own order.
  EquipmentSortKey? _sortBy;

  @override
  Widget build(BuildContext context) {
    final equipped = widget.equipped;
    final onUnequip = widget.onUnequip;
    final sortBy = _sortBy;
    final available = sortBy == null
        ? widget.available
        : sortBy.sort(widget.available);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _SlotPill(label: widget.slotLabel),
            ],
          ),
          const SizedBox(height: 12),
          const _SectionLabel('Currently equipped'),
          const SizedBox(height: 6),
          if (equipped != null)
            _PickerCard(
              item: equipped,
              baseline: equipped,
              isEquipped: true,
              onUnequip: onUnequip == null
                  ? null
                  : () {
                      onUnequip();
                      Navigator.of(context).pop();
                    },
            )
          else
            const _EmptySlotCard(),
          const SizedBox(height: 12),
          const _SectionLabel('Available — tap to equip'),
          const SizedBox(height: 6),
          if (available.length > 1 && _sortKeys.isNotEmpty) ...[
            _sortRow(context),
            const SizedBox(height: 8),
          ],
          if (available.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No items for this slot',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: available.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final candidate = available[i];
                  final locked = widget.lockedReason?.call(candidate);
                  return _PickerCard(
                    key: ObjectKey(candidate),
                    item: candidate,
                    baseline: equipped,
                    lockedReason: locked,
                    onTap: locked != null
                        ? null
                        : () {
                            widget.onEquip(candidate);
                            Navigator.of(context).pop();
                          },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// "Sort" then one chip per stat; tapping the chosen one again goes back
  /// to the bag's order.
  Widget _sortRow(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      key: const ValueKey('equipment-sort-row'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          Icon(Icons.sort, size: 16, color: scheme.outline),
          const SizedBox(width: 6),
          for (final key in _sortKeys) ...[
            ChoiceChip(
              key: ValueKey('equipment-sort-${key.id}'),
              avatar: key.icon,
              label: Text(key.label, style: const TextStyle(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              showCheckmark: false,
              selected: identical(_sortBy, key),
              onSelected: (on) => setState(() => _sortBy = on ? key : null),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        letterSpacing: 0.6,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

class _SlotPill extends StatelessWidget {
  const _SlotPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 0.6,
          color: scheme.outline,
        ),
      ),
    );
  }
}

class _EmptySlotCard extends StatelessWidget {
  const _EmptySlotCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: scheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          ItemStackTile(
            size: 52,
            id: ItemId.NULL,
            count: 1,
            showInfoDialogOnTap: false,
          ),
          const SizedBox(width: 11),
          Text(
            'Nothing equipped',
            style: TextStyle(color: scheme.outline, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// One item row in the picker. When [isEquipped], the card is tinted
/// and shows plain stats plus an optional Unequip action; otherwise it
/// shows stats with deltas against [baseline] and equips on tap.
class _PickerCard extends StatelessWidget {
  const _PickerCard({
    super.key,
    required this.item,
    required this.baseline,
    this.isEquipped = false,
    this.lockedReason,
    this.onTap,
    this.onUnequip,
  });

  final EquipmentItem item;
  final EquipmentItem? baseline;
  final bool isEquipped;

  /// Why this piece cannot be worn yet, or null when it can. A locked card
  /// still shows its stats — seeing what the tier is worth is the point of
  /// the requirement — but it does not equip on tap.
  final String? lockedReason;
  final VoidCallback? onTap;
  final VoidCallback? onUnequip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qualityColor = rarityBorderColor(item.quality);
    final locked = lockedReason;

    return Opacity(
      opacity: locked == null ? 1 : 0.55,
      child: Material(
        color: isEquipped
            ? scheme.primary.withOpacity(0.08)
            : scheme.surfaceContainerHighest.withOpacity(0.35),
        borderRadius: BorderRadius.circular(13),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: isEquipped
                    ? scheme.primary.withOpacity(0.4)
                    : scheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                ItemStackTile(
                  size: 52,
                  id: item.id,
                  count: isEquipped ? 1 : item.count,
                  borderColor: qualityColor,
                  onTap: () => showEquipmentInfoDialog(context, item),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: rarityTextColor(item.quality),
                        ),
                      ),
                      // where it goes: one hand, two or the off-hand, so a
                      // greatsword's trade against sword and shield is plain
                      Text(
                        equipmentSlotLabel(item),
                        key: const ValueKey('equipment-card-slot'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      if (locked != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 12,
                              color: scheme.error,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locked,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _statChips(context),
                      ),
                    ],
                  ),
                ),
                if (isEquipped) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'EQUIPPED',
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            fontWeight: FontWeight.w600,
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (onUnequip != null)
                        TextButton(
                          onPressed: onUnequip,
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          child: const Text(
                            'Unequip',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _statChips(BuildContext context) =>
      equipmentComparisonChips(item, baseline);
}

/// One stat of a piece as the comparisons draw it: its icon, its value and
/// its change against what wearing it would take off. The picker draws
/// these as chips; the details popup as plain rows.
class EquipmentStatLine {
  const EquipmentStatLine({
    this.key,
    required this.icon,
    required this.value,
    this.delta,
    this.gain = false,
    this.lost = false,
    this.weapon = false,
  });

  final Key? key;

  /// The stat's icon at the given size.
  final Widget Function(double size) icon;
  final String value;

  /// The change against the baseline ("+2", "−1.0s"); null when there is
  /// none or nothing to measure against.
  final String? delta;

  /// Whether [delta] is for the better.
  final bool gain;

  /// A stat the baseline has and this piece lacks entirely: wearing it
  /// takes the stat away. Its [value] is "0".
  final bool lost;

  /// One of a weapon's swing figures (dps, damage, speed) rather than a stat.
  final bool weapon;
}

/// The order gear lists its stats in: the combat stats first, then the
/// stance and stamina stats, then every other skill in enum order.
const List<SkillId> statDisplayOrder = [
  SkillId.ATTACK,
  SkillId.DEFENCE,
  SkillId.STRENGTH,
  SkillId.SPEED,
  SkillId.STAMINA,
  SkillId.RECOVERY,
];

/// Sorts skills by [statDisplayOrder], the rest after in enum order.
int compareStatOrder(SkillId a, SkillId b) {
  int rank(SkillId s) {
    final i = statDisplayOrder.indexOf(s);
    return i < 0 ? statDisplayOrder.length + s.index : i;
  }

  return rank(a).compareTo(rank(b));
}

/// One line per stat in the union of [item]'s and [baseline]'s stats, each
/// with its change against [baseline] — so a stat [item] lacks still shows
/// as a loss. A weapon's swing figures lead (damage, dps, swing speed —
/// where faster is the gain), then the stats in [statDisplayOrder].
/// With no [baseline] every stat reads as a plain gain over an empty slot.
///
/// [showDeltas] off leaves the changes out, for a piece with nothing to be
/// measured against (the one being worn, say).
List<EquipmentStatLine> equipmentStatLines(
  EquipmentItem item,
  EquipmentItem? baseline, {
  bool showDeltas = true,
}) {
  final lines = <EquipmentStatLine>[];

  final baselineItem = baseline;
  final swinging = item;
  if (swinging is WeaponItem) {
    final theirsDamages =
        baselineItem is WeaponItem && baselineItem.definition.usesDamage;
    String? signed(double? diff) =>
        (!showDeltas || diff == null || diff.abs() < 0.05)
        ? null
        : (diff > 0 ? '+${formatDamage(diff)}' : '−${formatDamage(-diff)}');

    if (swinging.definition.usesDamage) {
      // what one swing deals before the attack multiplier; more is the gain
      final damage = swinging.damage;
      final damageDiff = theirsDamages ? damage - baselineItem.damage : null;
      lines.add(
        EquipmentStatLine(
          key: const ValueKey('stat-chip-damage'),
          icon: (size) => Icon(Icons.gavel, size: size, color: Colors.grey),
          value: formatDamage(damage),
          delta: signed(damageDiff),
          gain: (damageDiff ?? 0) > 0,
          weapon: true,
        ),
      );

      // damage per second at the swing's own pace: what the damage and the
      // speed below add up to, so a slow heavy weapon and a quick light one
      // can be read against each other. more is the gain
      final dps = swinging.damagePerSecond;
      final dpsDiff = theirsDamages ? dps - baselineItem.damagePerSecond : null;
      lines.add(
        EquipmentStatLine(
          key: const ValueKey('stat-chip-dps'),
          icon: (size) => Icon(Icons.bolt, size: size, color: Colors.grey),
          value: '${formatDamage(dps)} dps',
          delta: signed(dpsDiff),
          gain: (dpsDiff ?? 0) > 0,
          weapon: true,
        ),
      );
    }

    // weapon speed; lower interval is better, so faster = green
    final mySpeed = swinging.actionInterval.inMilliseconds / 1000.0;
    final baseSpeed = baselineItem is WeaponItem
        ? baselineItem.actionInterval.inMilliseconds / 1000.0
        : null;
    final diff = baseSpeed == null ? null : mySpeed - baseSpeed;
    lines.add(
      EquipmentStatLine(
        key: const ValueKey('stat-chip-speed'),
        icon: (size) => Icon(Icons.timer, size: size, color: Colors.grey),
        value: '${mySpeed.toStringAsFixed(1)}s',
        delta: (!showDeltas || diff == null || diff == 0)
            ? null
            : (diff > 0
                  ? '+${diff.toStringAsFixed(1)}s'
                  : '−${(-diff).toStringAsFixed(1)}s'),
        gain: diff != null && diff < 0,
        weapon: true,
      ),
    );
  }

  final mine = item.effectiveSkillBonus;
  final base = baseline?.effectiveSkillBonus ?? const <SkillId, int>{};
  final keys = {...mine.keys, ...base.keys}.toList()..sort(compareStatOrder);

  for (final key in keys) {
    final value = mine[key] ?? 0;
    final delta = value - (base[key] ?? 0);
    if (value == 0 && delta == 0) continue;
    // a stat only the baseline has: off the board unless deltas are shown
    if (value == 0 && !showDeltas) continue;
    lines.add(
      EquipmentStatLine(
        key: ValueKey('stat-${key.name}'),
        icon: (size) => IconRenderer(size: size, id: key),
        value: '$value',
        delta: !showDeltas || delta == 0
            ? null
            : (delta > 0 ? '+$delta' : '−${-delta}'),
        gain: delta > 0,
        lost: value == 0 && delta < 0,
      ),
    );
  }

  // onyx's bonus to every skill's xp. it is not a stat, so the stats above
  // never show it; more is the gain
  final xpMine = _xpPercentOf(item);
  final xpDelta = xpMine - _xpPercentOf(baseline);
  if (xpMine != 0 || (showDeltas && xpDelta != 0)) {
    lines.add(
      EquipmentStatLine(
        key: const ValueKey('stat-chip-xp'),
        icon: (size) => Icon(Icons.auto_graph, size: size, color: Colors.grey),
        value: '+$xpMine% xp',
        delta: !showDeltas || xpDelta == 0
            ? null
            : (xpDelta > 0 ? '+$xpDelta%' : '−${-xpDelta}%'),
        gain: xpDelta > 0,
        lost: xpMine == 0 && xpDelta < 0,
      ),
    );
  }
  return lines;
}

/// [equipmentStatLines] as the picker's compact chips.
List<Widget> equipmentComparisonChips(
  EquipmentItem item,
  EquipmentItem? baseline, {
  bool showDeltas = true,
}) => [
  for (final line in equipmentStatLines(item, baseline, showDeltas: showDeltas))
    StatChip(
      key: line.key,
      icon: line.icon(14),
      value: line.value,
      deltaText: line.delta,
      deltaColor: line.gain ? statGainColor : statLossColor,
    ),
];

/// A swing's damage as the chips print it: whole when it is, one place when
/// a rarity roll has scaled it ("3", "3.6").
String formatDamage(double damage) {
  final rounded = (damage * 10).round() / 10;
  return rounded == rounded.roundToDouble()
      ? '${rounded.round()}'
      : rounded.toStringAsFixed(1);
}
