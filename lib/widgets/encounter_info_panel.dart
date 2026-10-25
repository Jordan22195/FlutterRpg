import 'package:flutter/material.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/items/items.dart';
import '../data/ObjectStack.dart';
import '../data/skill_data.dart';
import 'empty_state.dart';
import 'entity_info_dialog.dart';
import 'inventory_grid.dart';
import 'segmented_tabs.dart';
import 'skill_ring_row.dart';

/// Which body the panel is showing. Not every screen offers every one:
/// combat carries its trained skills here, while gathering hoists them above
/// the panel and shows the entity's details in their place.
enum _PanelTab { loot, skills, info }

/// The one panel under the fight that holds everything the encounter has to
/// report: what dropped, what the activity trains, and what the entity
/// itself is. All of it used to be stacked, which pushed the action bar
/// around; as tabs they occupy one slot.
class EncounterInfoPanel extends StatefulWidget {
  const EncounterInfoPanel({
    super.key,
    required this.drops,
    this.equipment = const [],
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

  /// Equipment dropped alongside [drops], as instances so each tile can
  /// wear the quality it rolled.
  final List<EquipmentItem> equipment;

  /// Tab title for the drops: combat loots, gathering gathers.
  final String lootLabel;

  /// What the drops tab says before anything has dropped.
  final String emptyLootLabel;

  @override
  State<EncounterInfoPanel> createState() => _EncounterInfoPanelState();
}

class _EncounterInfoPanelState extends State<EncounterInfoPanel> {
  /// The height of the compact bodies — the skill rings and the empty
  /// states — so switching between them never resizes the panel.
  /// A loot haul and the info page are exempt: each sizes to its content,
  /// and the screen around them scrolls.
  static const double _bodyHeight = 80;

  _PanelTab _tab = _PanelTab.loot;

  @override
  Widget build(BuildContext context) {
    final tabs = <_PanelTab>[
      _PanelTab.loot,
      if (widget.skills != null) _PanelTab.skills,
      if (widget.infoEntity != null) _PanelTab.info,
    ];

    // a tab that this screen doesn't offer (or that just went away) falls
    // back to the drops, which every screen has
    if (!tabs.contains(_tab)) _tab = _PanelTab.loot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedTabs<_PanelTab>(
          segments: [
            for (final tab in tabs) TabSegment(value: tab, label: _label(tab)),
          ],
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: 12),
        _body(context),
      ],
    );
  }

  String _label(_PanelTab tab) {
    switch (tab) {
      case _PanelTab.loot:
        return widget.lootLabel;
      case _PanelTab.skills:
        return 'Skills';
      case _PanelTab.info:
        return 'Info';
    }
  }

  Widget _body(BuildContext context) {
    switch (_tab) {
      case _PanelTab.skills:
        return SizedBox(
          height: _bodyHeight,
          child: Center(
            child: ActivitySkillRingRow(skills: widget.skills ?? const []),
          ),
        );

      // the details page, at whatever height it needs: the screen around it
      // scrolls, so there is nothing to fit it into
      case _PanelTab.info:
        // the entity already stands on the stage above the tabs. the page
        // scrolls to reach the foot of it, so it keeps room under it for the
        // dock's fade to fall on
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: EntityInfoBody(entity: widget.infoEntity!, showImage: false),
        );

      case _PanelTab.loot:
        if (widget.drops.isEmpty && widget.equipment.isEmpty) {
          return SizedBox(
            height: _bodyHeight,
            child: _empty(context, widget.emptyLootLabel, Icons.lock_outline),
          );
        }
        // the whole haul at its own height, every row of it: the screen
        // around it scrolls, so the grid never scrolls inside its card
        return InventoryGrid(
          items: widget.drops,
          equipment: widget.equipment,
          shrinkWrap: true,
        );
    }
  }

  Widget _empty(BuildContext context, String text, IconData icon) {
    return EmptyState(message: text, icon: icon, height: _bodyHeight);
  }
}
