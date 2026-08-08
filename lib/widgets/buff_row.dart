import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/controllers/buff_controller.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'overflow_chip.dart';

/// Active buffs as a labeled tile row. Shows at most [maxVisible] tiles;
/// the rest fold into a +N chip that opens a sheet with every buff.
/// Renders nothing when no buffs are active, unless [reserveWhenEmpty].
class BuffRow extends StatelessWidget {
  const BuffRow({
    super.key,
    this.maxVisible = 5,
    this.reserveWhenEmpty = false,
  });

  final int maxVisible;

  /// Holds the row's slot open when no buffs are active. Screens where a
  /// buff comes and goes while the player is looking at them — a firepit,
  /// whose fire is the buff — would otherwise shove everything below down
  /// by [height] the moment it appears.
  final bool reserveWhenEmpty;

  static const double _tileSize = 48;
  static const double _labelHeight = 20;

  /// The row's height whether or not any buff is active, so callers can
  /// reason about the space it occupies.
  static const double height = _labelHeight + _tileSize;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BuffController>();
    final buffs = <BuffItem>[
      ...controller.getCurrentZoneBuffs(),
      ...controller.getGlobalBuffs(),
    ];

    if (buffs.isEmpty) {
      return reserveWhenEmpty
          ? const SizedBox(height: height, width: double.infinity)
          : const SizedBox.shrink();
    }

    final overflowing = buffs.length > maxVisible;
    final visible = overflowing ? buffs.sublist(0, maxVisible - 1) : buffs;
    final hidden = buffs.length - visible.length;

    // fixed height so the populated and empty rows measure the same
    return SizedBox(
      height: height,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _labelHeight,
            child: Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Buffs · ${buffs.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final buff in visible)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buffTile(buff, _tileSize),
                ),
              if (hidden > 0)
                OverflowChip(
                  count: hidden,
                  size: _tileSize,
                  onTap: () => _showAllBuffs(context, buffs),
                ),
            ],
          ),
        ],
      ),
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
