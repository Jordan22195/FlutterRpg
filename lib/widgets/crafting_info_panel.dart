import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/items/items.dart';
import '../controllers/buff_controller.dart';
import '../data/ObjectStack.dart';
import 'buff_row.dart';
import 'equipment_info_dialog.dart';
import 'inventory_grid.dart';
import 'item_stack_tile.dart';

/// What a crafting bench reports while you work: what this session has
/// produced, what is buffing it, and the odds behind the recipe itself. The
/// first two used to be stacked either side of the recipe card, which pushed
/// the recipe around as buffs came and went.
enum _CraftingTab { crafted, buffs, info }

/// The tabbed panel shared by every bench screen — the crafting stations and
/// the firepit — so they report a session the same way.
class CraftingInfoPanel extends StatefulWidget {
  const CraftingInfoPanel({
    super.key,
    required this.items,
    this.equipment = const [],
    this.craftedLabel = 'Crafted',
    this.emptyCraftedLabel = 'Nothing crafted this session',
  });

  /// Plain items produced this session.
  final List<ObjectStack> items;

  /// Equipment produced this session. Kept apart from [items] because a
  /// piece of equipment carries a quality border the item grid can't show.
  final List<EquipmentItem> equipment;

  /// Tab title for the output: a station crafts, a firepit cooks.
  final String craftedLabel;

  /// What the output tab says before anything has been made.
  final String emptyCraftedLabel;

  @override
  State<CraftingInfoPanel> createState() => _CraftingInfoPanelState();
}

class _CraftingInfoPanelState extends State<CraftingInfoPanel> {
  /// Height of the buffs and info bodies. The crafted body sizes to its own
  /// contents, since a long session's output is the thing worth scrolling to.
  static const double _bodyHeight = 80;

  _CraftingTab _tab = _CraftingTab.crafted;

  @override
  Widget build(BuildContext context) {
    final buffs = context.watch<BuffController>();
    final buffCount =
        buffs.getCurrentZoneBuffs().length + buffs.getGlobalBuffs().length;

    final craftedCount = widget.items.length + widget.equipment.length;

    final labels = {
      _CraftingTab.crafted: widget.craftedLabel,
      _CraftingTab.buffs: 'Buffs',
      _CraftingTab.info: 'Info',
    };
    // info has nothing to count, so its label carries no number
    final counts = {
      _CraftingTab.crafted: craftedCount,
      _CraftingTab.buffs: buffCount,
    };

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_CraftingTab>(
                segments: [
                  for (final tab in _CraftingTab.values)
                    ButtonSegment<_CraftingTab>(
                      value: tab,
                      label: Text(
                        counts[tab] == null
                            ? '${labels[tab]}'
                            : '${labels[tab]} · ${counts[tab]}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {_tab},
                // single-select: the set always holds exactly one tab
                onSelectionChanged: (selection) =>
                    setState(() => _tab = selection.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _body(context, buffCount, craftedCount),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, int buffCount, int craftedCount) {
    switch (_tab) {
      // placeholder: the craft-chance stats land here
      case _CraftingTab.info:
        return SizedBox(
          height: _bodyHeight,
          child: _empty(context, 'Craft chances coming soon'),
        );

      case _CraftingTab.buffs:
        return SizedBox(
          height: _bodyHeight,
          child: buffCount == 0
              ? _empty(context, 'No active buffs')
              : const Center(child: BuffRow(showLabel: false)),
        );

      case _CraftingTab.crafted:
        if (craftedCount == 0) {
          return SizedBox(
            height: _bodyHeight,
            child: _empty(context, widget.emptyCraftedLabel),
          );
        }
        return Column(
          children: [
            if (widget.items.isNotEmpty)
              SizedBox(
                height: _bodyHeight,
                child: InventoryGrid(items: widget.items),
              ),
            // crafted equipment carries its quality border, so it gets tiles
            // of its own rather than the grid
            if (widget.equipment.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(10),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final item in widget.equipment)
                      ItemStackTile(
                        size: 56,
                        count: item.count,
                        id: item.id,
                        showInfoDialogOnTap: false,
                        borderColor: qualityBorderColor(item.quality),
                        onTap: () => showEquipmentInfoDialog(context, item),
                      ),
                  ],
                ),
              ),
          ],
        );
    }
  }

  Widget _empty(BuildContext context, String text) {
    return Center(
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
        ),
      ),
    );
  }
}
