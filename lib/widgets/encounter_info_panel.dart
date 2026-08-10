import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/buff_controller.dart';
import '../data/ObjectStack.dart';
import '../data/skill_data.dart';
import 'buff_row.dart';
import 'entity_info_dialog.dart';
import 'inventory_grid.dart';
import 'skill_ring_row.dart';

/// Which body the panel is showing. Not every screen offers every one:
/// combat carries its trained skills here, while gathering hoists them above
/// the panel and shows the entity's details in their place.
enum _PanelTab { loot, skills, buffs, info }

/// The one panel under the fight that holds everything the encounter has to
/// report: what dropped, what the activity trains, what is buffing you, and
/// what the entity itself is. All of it used to be stacked, which pushed the
/// action bar around as buffs came and went; as tabs they occupy one slot.
class EncounterInfoPanel extends StatefulWidget {
  const EncounterInfoPanel({
    super.key,
    required this.drops,
    required this.lootLabel,
    required this.emptyLootLabel,
    this.skills,
    this.infoEntity,
  });

  /// Skills the activity trains on its own; the action loop's three are
  /// added by [ActivitySkillRingRow]. Null drops the skills tab, for screens
  /// that show the rings themselves.
  final List<SkillId>? skills;

  /// The entity whose details fill the info tab. Null drops the tab, for
  /// screens that reach the same details through the portrait popup.
  final EncounterEntity? infoEntity;

  /// Drops collected this session (world) or this run (dungeon).
  final List<ObjectStack> drops;

  /// Tab title for the drops: combat loots, gathering gathers.
  final String lootLabel;

  /// What the drops tab says before anything has dropped.
  final String emptyLootLabel;

  @override
  State<EncounterInfoPanel> createState() => _EncounterInfoPanelState();
}

class _EncounterInfoPanelState extends State<EncounterInfoPanel> {
  /// Tallest of the compact bodies (the loot grid: a 56 tile plus its 12
  /// padding on both sides), so switching between them never resizes the
  /// panel. The info body is exempt: it is a page of detail, and sizes to
  /// its content.
  static const double _bodyHeight = 80;

  _PanelTab _tab = _PanelTab.loot;

  @override
  Widget build(BuildContext context) {
    final buffs = context.watch<BuffController>();
    final buffCount =
        buffs.getCurrentZoneBuffs().length + buffs.getGlobalBuffs().length;

    final tabs = <_PanelTab>[
      _PanelTab.loot,
      if (widget.skills != null) _PanelTab.skills,
      _PanelTab.buffs,
      if (widget.infoEntity != null) _PanelTab.info,
    ];

    // a tab that this screen doesn't offer (or that just went away) falls
    // back to the drops, which every screen has
    if (!tabs.contains(_tab)) _tab = _PanelTab.loot;

    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<_PanelTab>(
                segments: [
                  for (final tab in tabs)
                    ButtonSegment<_PanelTab>(
                      value: tab,
                      label: Text(
                        _label(tab, buffCount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                selected: {_tab},
                // single-select: the set always holds exactly one tab
                onSelectionChanged: (selection) =>
                    setState(() => _tab = selection.first),
                // the counts in the labels need the width the checkmark
                // would take
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
            _body(context, buffCount),
          ],
        ),
      ),
    );
  }

  String _label(_PanelTab tab, int buffCount) {
    switch (tab) {
      case _PanelTab.loot:
        return '${widget.lootLabel} · ${widget.drops.length}';
      case _PanelTab.skills:
        return 'Skills';
      case _PanelTab.buffs:
        return 'Buffs · $buffCount';
      case _PanelTab.info:
        return 'Info';
    }
  }

  Widget _body(BuildContext context, int buffCount) {
    switch (_tab) {
      case _PanelTab.skills:
        return SizedBox(
          height: _bodyHeight,
          child: Center(
            child: ActivitySkillRingRow(skills: widget.skills ?? const []),
          ),
        );

      case _PanelTab.buffs:
        return SizedBox(
          height: _bodyHeight,
          child: buffCount == 0
              ? _empty(context, 'No active buffs')
              : const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Center(child: BuffRow(showLabel: false)),
                ),
        );

      // the details page, at whatever height it needs: the screen around it
      // scrolls, so there is nothing to fit it into
      case _PanelTab.info:
        return EntityInfoBody(entity: widget.infoEntity!);

      case _PanelTab.loot:
        return SizedBox(
          height: _bodyHeight,
          child: widget.drops.isEmpty
              ? _empty(context, widget.emptyLootLabel)
              : InventoryGrid(items: widget.drops),
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
