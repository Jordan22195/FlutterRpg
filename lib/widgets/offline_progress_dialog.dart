import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/entities/entities.dart';
import '../data/offline_progress_data.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../game_session.dart';
import 'inventory_grid.dart';
import 'item_stack_tile.dart';
import 'skil_tile.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../catalogs/items/items.dart';

/// What the loop paid out while the player was away, shown once on the way
/// back in. Raised by [MainShell] rather than any one screen, so it reaches
/// the player wherever the app was closed.
///
/// [revision] redraws it in place: a later absence is folded into [report]
/// while the dialog is still up, and bumping it shows the two together.
Future<void> showOfflineProgressDialog(
  BuildContext context,
  OfflineProgressReport report, {
  ValueListenable<int>? revision,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('While you were away'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: revision == null
              ? OfflineProgressBody(report: report)
              : ValueListenableBuilder<int>(
                  valueListenable: revision,
                  builder: (_, _, _) => OfflineProgressBody(
                    // keyed to the revision, so every tile below is rebuilt
                    // from the merged report rather than kept from the last
                    key: ValueKey(revision.value),
                    report: report,
                  ),
                ),
        ),
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
              // one grid: the equipment tiles wear the quality they rolled
              InventoryGrid(
                items: items,
                equipment: equipment,
                shrinkWrap: true,
                tileSize: 48,
              ),
            ],
          ),
        // what the settle drank to keep its buffs up: the stack shrank,
        // and a gain list that never says so reads as a bug
        if (report.potionsUsed.isNotEmpty)
          _Section(
            title: 'Used',
            children: [_CountTiles<ItemId>(counts: report.potionsUsed)],
          ),
        if (report.entitiesDefeated.isNotEmpty)
          _Section(
            title: 'Defeated',
            children: [_CountTiles<EntityId>(counts: report.entitiesDefeated)],
          ),
        if (report.entities.isNotEmpty)
          _Section(
            title: 'Discovered',
            children: [_CountTiles<EntityId>(counts: report.entities)],
          ),
        if (xp.isNotEmpty)
          _Section(
            title: 'Experience',
            children: [
              for (final (index, entry) in xp.indexed)
                _XpRingRow(skill: entry.key, xp: entry.value, order: index),
            ],
          ),
      ],
    );
  }
}

/// A row of tiles with their counts, shared by the sections that report
/// things by kind - what the walk turned up, what it killed, what it drank.
class _CountTiles<T extends Enum> extends StatelessWidget {
  const _CountTiles({required this.counts});

  final Map<T, int> counts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (final entry in counts.entries)
            ItemStackTile<T>(
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

/// One skill's haul, played back: the ring as it stood before the player
/// left, the xp popping in beside it, then the ring filling by that much —
/// wrapping and ticking the level over for every level it crosses — so the
/// player watches themselves level up.
///
/// The settle has already paid the xp in by the time the dialog opens, so
/// the start is worked back from the skill's xp now. That is read once:
/// the loop keeps running under the dialog, and a ring chasing it would
/// never settle on what the report says.
class _XpRingRow extends StatefulWidget {
  const _XpRingRow({
    required this.skill,
    required this.xp,
    required this.order,
  });

  final SkillId skill;
  final double xp;

  /// Place in the list; each row starts a beat after the one above.
  final int order;

  static const double ringSize = 44;

  /// Held before the first row moves, so the dialog has landed first.
  static const int leadInMs = 500;
  static const int staggerMs = 250;
  static const int appearMs = 250;
  static const int popStartMs = 350;
  static const int popMs = 350;
  static const int fillStartMs = 750;
  static const int badgeMs = 300;

  @override
  State<_XpRingRow> createState() => _XpRingRowState();
}

class _XpRingRowState extends State<_XpRingRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final int _startLevel;
  late final int _endLevel;
  late final double _endProgress;

  /// Where the ring stands as one number: level plus progress into it.
  /// Animating this rather than xp gives every level the same time on
  /// screen, where xp would race through the cheap early ones.
  late final double _startPos;
  late final double _endPos;

  // the row's timeline, as fractions of the controller
  late final Interval _appear;
  late final Interval _pop;
  late final Interval _fill;
  late final Interval _badge;

  @override
  void initState() {
    super.initState();
    final player = context.read<GameSession>().playerDataController;
    final endXp = player.getSkillXp(widget.skill);
    final startXp = max(0.0, endXp - widget.xp);

    _startLevel = player.getSkillLevelAtXp(widget.skill, startXp);
    _endLevel = player.getSkillLevelAtXp(widget.skill, endXp);
    _endProgress = player.getSkillProgressAtXp(widget.skill, endXp);
    _startPos =
        _startLevel + player.getSkillProgressAtXp(widget.skill, startXp);
    _endPos = _endLevel + _endProgress;

    // a sliver of a level fills briskly; each level crossed adds a beat,
    // capped so a long absence doesn't hold the dialog hostage
    final fillMs = (700 + 500 * (_endPos - _startPos)).clamp(700, 3000).round();
    final delay = _XpRingRow.leadInMs + widget.order * _XpRingRow.staggerMs;
    final fillStart = delay + _XpRingRow.fillStartMs;
    final total = fillStart + fillMs + _XpRingRow.badgeMs;

    Interval at(int from, int length, Curve curve) =>
        Interval(from / total, (from + length) / total, curve: curve);
    _appear = at(delay, _XpRingRow.appearMs, Curves.easeOut);
    _pop = at(
      delay + _XpRingRow.popStartMs,
      _XpRingRow.popMs,
      Curves.easeOutBack,
    );
    _fill = at(fillStart, fillMs, Curves.easeInOutCubic);
    _badge = at(fillStart + fillMs, _XpRingRow.badgeMs, Curves.easeOutBack);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: total),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _controller.isCompleted) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final levelsGained = _endLevel - _startLevel;

    return Semantics(
      label:
          '${skillLabel(widget.skill)}, plus ${widget.xp.round()} xp'
          '${levelsGained > 0 ? ', level $_startLevel to $_endLevel' : ', level $_endLevel'}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          final appear = _appear.transform(t);
          final pop = _pop.transform(t);
          final badge = _badge.transform(t);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Opacity(
                  opacity: appear,
                  child: Transform.scale(
                    scale: 0.8 + 0.2 * appear,
                    child: _ring(context, _fill.transform(t)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: appear,
                        child: Text(
                          skillLabel(widget.skill),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                      ),
                      Opacity(
                        opacity: pop.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: pop,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '+${widget.xp.round()} xp',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: skillRingColor(widget.skill),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (levelsGained > 0 && badge > 0)
                  Opacity(
                    opacity: badge.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: badge,
                      child: Text(
                        levelsGained == 1
                            ? 'Level up!'
                            : '+$levelsGained levels',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: skillRingColor(widget.skill),
                            ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// The ring part-way through its fill, [fill] running 0 to 1.
  Widget _ring(BuildContext context, double fill) {
    final palette = context.palette;
    final pos = _startPos + (_endPos - _startPos) * fill;

    // the end is read exactly, so a maxed skill closes its ring rather than
    // reading as level 99 with nothing in it
    final int level;
    final double progress;
    if (fill >= 1) {
      level = _endLevel;
      progress = _endProgress;
    } else {
      level = min(pos.floor(), _endLevel);
      progress = pos - level;
    }

    // a level just crossed: the ring swells and settles back
    final intoLevel = pos - pos.floor();
    final bump = level > _startLevel && intoLevel < 0.2
        ? 1 - intoLevel / 0.2
        : 0.0;

    const size = _XpRingRow.ringSize;
    const strokeWidth = size * 0.075;
    return Transform.scale(
      scale: 1 + 0.12 * bump,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: SkillRingPainter(
            progress: progress,
            color: skillRingColor(widget.skill),
            track: palette.borderStrong,
            fill: palette.surface,
            strokeWidth: strokeWidth,
          ),
          child: Center(
            child: Text(
              '$level',
              style: HearthText.ringNumber.copyWith(
                color: palette.text,
                fontSize: size * 0.325,
              ),
            ),
          ),
        ),
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
