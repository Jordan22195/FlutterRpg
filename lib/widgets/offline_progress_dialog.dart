import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/entities/entities.dart';
import '../data/offline_progress_data.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../game_session.dart';
import 'equipment_info_dialog.dart';
import 'icon_renderer.dart';
import 'inventory_grid.dart';
import 'item_stack_tile.dart';

/// What the loop paid out while the player was away, shown once on the way
/// back in. Raised by [MainShell] rather than any one screen, so it reaches
/// the player wherever the app was closed.
Future<void> showOfflineProgressDialog(
  BuildContext context,
  OfflineProgressReport report,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('While you were away'),
      content: SingleChildScrollView(
        child: SizedBox(width: 320, child: OfflineProgressBody(report: report)),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Continue'),
        ),
      ],
    ),
  );
}

/// The body of the summary: how long the loop ran, then what it produced.
class OfflineProgressBody extends StatelessWidget {
  const OfflineProgressBody({super.key, required this.report});

  final OfflineProgressReport report;

  @override
  Widget build(BuildContext context) {
    final session = context.read<GameSession>();
    final items = session.inventoryService.getObjectStackList(report.items);
    final equipment = report.items.equipment;
    final xp = report.xp.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Section(
          title: 'Away',
          children: [
            _StatRow(
              label: 'Time away',
              value: _formatDuration(report.timeAway),
            ),
            _StatRow(label: 'Actions', value: '${report.actionCount}'),
            if (report.enemiesDefeated > 0)
              _StatRow(label: 'Defeated', value: '${report.enemiesDefeated}'),
            if (report.died) _StatRow(label: 'Died', value: _death(report)),
          ],
        ),
        if (items.isNotEmpty || equipment.isNotEmpty)
          _Section(
            title: 'Gained',
            children: [
              if (items.isNotEmpty)
                InventoryGrid(items: items, shrinkWrap: true, tileSize: 48),
              // equipment carries a quality border the item grid can't show,
              // so it gets tiles of its own - the same split the crafting
              // panel makes for a session's output
              if (equipment.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final item in equipment)
                        ItemStackTile(
                          size: 48,
                          count: item.count,
                          id: item.id,
                          showInfoDialogOnTap: false,
                          quality: item.quality,
                          onTap: () => showEquipmentInfoDialog(context, item),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        if (report.entitiesDefeated.isNotEmpty)
          _Section(
            title: 'Defeated',
            children: [_EntityTiles(counts: report.entitiesDefeated)],
          ),
        if (report.entities.isNotEmpty)
          _Section(
            title: 'Discovered',
            children: [_EntityTiles(counts: report.entities)],
          ),
        if (xp.isNotEmpty)
          _Section(
            title: 'Experience',
            children: [
              for (final entry in xp) _XpRow(skill: entry.key, xp: entry.value),
            ],
          ),
      ],
    );
  }
}

/// A row of entity tiles with their counts, shared by the sections that
/// report entities by kind - what the walk turned up, and what it killed.
class _EntityTiles extends StatelessWidget {
  const _EntityTiles({required this.counts});

  final Map<EntityId, int> counts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final entry in counts.entries)
            ItemStackTile(
              size: 48,
              id: entry.key,
              count: entry.value,
              // the tile only knows how to open an item's popup
              showInfoDialogOnTap: false,
              alwaysShowCount: true,
            ),
        ],
      ),
    );
  }
}

/// "3h 20m" / "12m" / "45s" - the coarse unit is enough here, and a long
/// absence should not read as a four-part duration.
/// What killed the player and how far into the gap, for the death row.
/// Either half can be missing - a fight with no entity left to name, or a
/// settle that ended before it could time the death.
String _death(OfflineProgressReport report) {
  final killer = report.killedBy?.definition.name;
  final after = report.diedAfter;
  if (killer != null && after != null) {
    return 'to a $killer after ${_formatDuration(after)}';
  }
  if (killer != null) return 'to a $killer';
  if (after != null) return 'after ${_formatDuration(after)}';
  return 'yes';
}

String _formatDuration(Duration away) {
  if (away.inHours > 0) {
    final minutes = away.inMinutes % 60;
    return minutes == 0 ? '${away.inHours}h' : '${away.inHours}h ${minutes}m';
  }
  if (away.inMinutes > 0) return '${away.inMinutes}m';
  return '${away.inSeconds}s';
}

/// One skill's haul, with its icon so the list scans like the skills screen.
class _XpRow extends StatelessWidget {
  const _XpRow({required this.skill, required this.xp});

  final SkillId skill;
  final double xp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          IconRenderer(id: skill, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              skillLabel(skill),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '+${xp.round()} xp',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A labelled block of rows, matching the entity details dialog.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// One label/value line, values right-aligned.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
