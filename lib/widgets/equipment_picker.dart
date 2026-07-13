import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/inventory_controller.dart';
import 'package:rpg/data/skill_data.dart';
import '../catalogs/item_catalog.dart';
import '../widgets/food_card.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';
import 'stat_chip.dart';

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

/// Bottom-sheet equipment picker for one slot: shows what's currently
/// equipped, then every candidate with per-stat deltas vs. the equipped
/// item (green = higher, red = lower). Tapping a candidate equips it.
class EquipmentPicker {
  static void show(
    BuildContext context, {
    required String title,
    required String slotLabel,
    required EquipmentItem? equipped,
    required List<EquipmentItem> available,
    required void Function(EquipmentItem item) onEquip,
    VoidCallback? onUnequip,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _SlotPill(label: slotLabel),
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
                          Navigator.of(ctx).pop();
                        },
                )
              else
                const _EmptySlotCard(),
              const SizedBox(height: 12),
              const _SectionLabel('Available — tap to equip'),
              const SizedBox(height: 6),
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
                    itemBuilder: (_, i) => _PickerCard(
                      item: available[i],
                      baseline: equipped,
                      onTap: () {
                        onEquip(available[i]);
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
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
    required this.item,
    required this.baseline,
    this.isEquipped = false,
    this.onTap,
    this.onUnequip,
  });

  final EquipmentItem item;
  final EquipmentItem? baseline;
  final bool isEquipped;
  final VoidCallback? onTap;
  final VoidCallback? onUnequip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final qualityColor = qualityBorderColor(item.quality);

    return Material(
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
                showInfoDialogOnTap: false,
                borderColor: qualityColor,
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
                        color: qualityColor,
                      ),
                    ),
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
    );
  }

  /// One chip per stat in the union of this item's and the baseline's
  /// stats, so a stat the candidate lacks still shows as a red loss.
  List<Widget> _statChips(BuildContext context) {
    final mine = item.effectiveSkillBonus;
    final base = baseline?.effectiveSkillBonus ?? const <SkillId, int>{};
    final keys = {...mine.keys, ...base.keys}.toList()
      ..sort((a, b) => a.index.compareTo(b.index));

    final chips = <Widget>[];
    for (final key in keys) {
      final value = mine[key] ?? 0;
      final delta = value - (base[key] ?? 0);
      if (value == 0 && delta == 0) continue;
      chips.add(
        StatChip(
          icon: IconRenderer(size: 14, id: key),
          value: '$value',
          deltaText: delta == 0 ? null : (delta > 0 ? '+$delta' : '−${-delta}'),
          deltaColor: delta > 0 ? statGainColor : statLossColor,
        ),
      );
    }

    // weapon speed; lower interval is better, so faster = green
    final currentItem = item;
    if (currentItem is WeaponItem) {
      final mySpeed = currentItem.actionInterval.inMilliseconds / 1000.0;
      final baselineItem = baseline;
      final baseSpeed = baselineItem is WeaponItem
          ? baselineItem.actionInterval.inMilliseconds / 1000.0
          : null;
      final diff = baseSpeed == null ? null : mySpeed - baseSpeed;
      chips.add(
        StatChip(
          icon: const Icon(Icons.timer, size: 14, color: Colors.grey),
          value: '${mySpeed.toStringAsFixed(1)}s',
          deltaText: (diff == null || diff == 0)
              ? null
              : (diff > 0
                    ? '+${diff.toStringAsFixed(1)}s'
                    : '−${(-diff).toStringAsFixed(1)}s'),
          deltaColor: (diff != null && diff < 0) ? statGainColor : statLossColor,
        ),
      );
    }
    return chips;
  }
}
