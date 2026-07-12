import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'overflow_chip.dart';

/// Active buffs as a labeled tile row. Shows at most [maxVisible] tiles;
/// the rest fold into a +N chip that opens a sheet with every buff.
/// Renders nothing when no buffs are active.
class BuffRow extends StatelessWidget {
  const BuffRow({super.key, this.maxVisible = 5});

  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BuffController>();
    final buffs = <BuffItem>[
      ...controller.getCurrentZoneBuffs(),
      ...controller.getGlobalBuffs(),
    ];

    if (buffs.isEmpty) return const SizedBox.shrink();

    final overflowing = buffs.length > maxVisible;
    final visible = overflowing ? buffs.sublist(0, maxVisible - 1) : buffs;
    final hidden = buffs.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 4),
          child: Text(
            'Buffs · ${buffs.length}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ),
        Row(
          children: [
            for (final buff in visible)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buffTile(buff, 48),
              ),
            if (hidden > 0)
              OverflowChip(
                count: hidden,
                size: 48,
                onTap: () => _showAllBuffs(context, buffs),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buffTile(BuffItem buff, double size) {
    return ItemStackTile(
      size: size,
      count: 0,
      id: buff.id,
      isTimerStackTile: true,
      expirationTime: buff.expirationTime,
    );
  }

  void _showAllBuffs(BuildContext context, List<BuffItem> buffs) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final buff in buffs) _buffTile(buff, 56)],
          ),
        ),
      ),
    );
  }
}
