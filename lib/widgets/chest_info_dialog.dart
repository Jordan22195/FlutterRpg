import 'package:flutter/material.dart';

import '../catalogs/items/items.dart';
import '../data/item_drop_type.dart';
import '../services/weighted_drop_table_service.dart';
import 'item_stack_tile.dart';

/// What a dungeon's full-clear chest can hold: each roll the chest makes,
/// how likely that roll is, and every line in it with its stack size and its
/// share of the roll. Each tile opens the usual item dialog.
void showChestInfoDialog(
  BuildContext context, {
  required String title,
  required List<DropRoll> rolls,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (index, roll) in rolls.indexed) ...[
                if (index > 0) const Divider(height: 24),
                _RollSection(key: ValueKey('chest-roll-$index'), roll: roll),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

class _RollSection extends StatelessWidget {
  const _RollSection({super.key, required this.roll});

  final DropRoll roll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final lines = roll.entries.flattened;
    final total = lines.fold<double>(0, (sum, e) => sum + e.weight);
    final header = roll.chance >= 1
        ? 'Every chest'
        : '${_percent(roll.chance)} of chests';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          header,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        for (final (index, line) in lines.indexed)
          Padding(
            // by position as well: a roll built from several bosses' tables
            // can hold the same item at the same rarity more than once
            key: ValueKey(
              'chest-drop-$index-${line.id.name}-${line.rarity.name}',
            ),
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                ItemStackTile<ItemId>(
                  size: 36,
                  id: line.id,
                  count: 0,
                  quality: line.rarity,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    line.id.definition.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_count(line)),
                    // one line alone in its roll is not a share of anything
                    if (lines.length > 1 && total > 0)
                      Text(
                        _percent(line.weight / total),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: muted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _count(ItemDropType line) => line.highCount > line.lowCount
      ? '${line.lowCount}–${line.highCount}'
      : '${line.lowCount}';

  static String _percent(double fraction) {
    final percent = fraction * 100;
    return percent >= 10 || percent == percent.roundToDouble()
        ? '${percent.round()}%'
        : '${percent.toStringAsFixed(1)}%';
  }
}
