import 'package:flutter/material.dart';

import '../catalogs/items/items.dart';
import '../data/ObjectStack.dart';
import 'empty_state.dart';
import 'inventory_grid.dart';
import 'recipe_info_body.dart';
import 'segmented_tabs.dart';

/// What a crafting bench reports while you work: what this session has
/// produced, and the odds behind the recipe itself.
enum _CraftingTab { crafted, info }

/// The tabbed panel shared by every bench screen — the crafting stations and
/// the firepit — so they report a session the same way.
class CraftingInfoPanel extends StatefulWidget {
  const CraftingInfoPanel({
    super.key,
    required this.items,
    required this.recipeId,
    this.equipment = const [],
    this.craftedLabel = 'Crafted',
    this.emptyCraftedLabel = 'Nothing crafted this session',
    this.emptyIcon = Icons.inventory_2_outlined,
  });

  /// Plain items produced this session.
  final List<ObjectStack> items;

  /// The recipe the info tab describes. Passed in rather than read off the
  /// controller: the firepit runs two skills at one station, so only the
  /// screen knows which section's selection the tab should follow.
  final String recipeId;

  /// Equipment produced this session. Kept apart from [items] since it's a
  /// different type — a piece carries its own rolled quality — but the grid
  /// draws both as one run of tiles.
  final List<EquipmentItem> equipment;

  /// Tab title for the output: a station crafts, a firepit cooks.
  final String craftedLabel;

  /// What the output tab says before anything has been made.
  final String emptyCraftedLabel;

  /// Beside [emptyCraftedLabel] in the empty state.
  final IconData emptyIcon;

  @override
  State<CraftingInfoPanel> createState() => _CraftingInfoPanelState();
}

class _CraftingInfoPanelState extends State<CraftingInfoPanel> {
  /// Height of the empty crafted body. A session's output sizes to its own
  /// contents, since a long session's output is the thing worth scrolling to.
  static const double _bodyHeight = 80;

  _CraftingTab _tab = _CraftingTab.crafted;

  @override
  Widget build(BuildContext context) {
    final craftedCount = widget.items.length + widget.equipment.length;

    final labels = {
      _CraftingTab.crafted: widget.craftedLabel,
      _CraftingTab.info: 'Info',
    };
    // info has nothing to count, so its label carries no number
    final counts = {_CraftingTab.crafted: craftedCount};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedTabs<_CraftingTab>(
          segments: [
            for (final tab in _CraftingTab.values)
              TabSegment(
                value: tab,
                label: counts[tab] == null
                    ? '${labels[tab]}'
                    : '${labels[tab]} · ${counts[tab]}',
              ),
          ],
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 12),
        _body(context, craftedCount),
      ],
    );
  }

  Widget _body(BuildContext context, int craftedCount) {
    switch (_tab) {
      // sizes to its own contents rather than the fixed body height: the
      // odds table is the thing worth scrolling to, and the screens around
      // it already scroll. the page scrolls to reach its foot, so it keeps room under it for
      // the dock's fade to fall on
      case _CraftingTab.info:
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: RecipeInfoBody(recipeId: widget.recipeId),
        );

      case _CraftingTab.crafted:
        if (craftedCount == 0) {
          return SizedBox(
            height: _bodyHeight,
            child: _empty(context, widget.emptyCraftedLabel, widget.emptyIcon),
          );
        }
        // items and equipment share one grid; the equipment tiles wear
        // their rolled quality and open the equipment dialog
        return InventoryGrid(
          items: widget.items,
          equipment: widget.equipment,
          shrinkWrap: true,
        );
    }
  }

  Widget _empty(BuildContext context, String text, IconData icon) {
    return EmptyState(message: text, icon: icon, height: _bodyHeight);
  }
}
