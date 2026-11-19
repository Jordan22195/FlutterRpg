import 'dart:async';

import 'package:flutter/material.dart';

import '../data/ObjectStack.dart';
import '../data/floor_clear_summary.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'item_stack_tile.dart';
import 'loot_pop.dart';
import 'primary_button.dart';
import 'sprite_frame.dart';

/// A floor just cleared, in the arena the boss stood in: what was beaten,
/// the lap's time and damage against the floor's bests, its clears, and
/// everything it dropped.
class FloorClearPanel extends StatelessWidget {
  const FloorClearPanel({super.key, required this.summary});

  final FloorClearSummary summary;

  static const double _radius = 22;
  static const double _border = 2;
  static const double _lootTile = 52;

  /// "4:12" — minutes and seconds, the way a lap is read.
  static String formatLapTime(Duration time) {
    final seconds = time.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final floor = summary.floorIndex + 1;
    return Semantics(
      container: true,
      label: 'Floor $floor cleared summary',
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
        decoration: BoxDecoration(
          color: context.palette.bossArenaFill,
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(color: GameColors.bossFrame, width: _border),
          boxShadow: const [
            BoxShadow(color: GameColors.bossFrameOuter, spreadRadius: 1),
          ],
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.2,
            colors: [
              Color.alphaBlend(
                GameColors.bossFrame.withValues(alpha: 0.18),
                context.palette.bossArenaFill,
              ),
              context.palette.bossArenaFill,
            ],
            stops: const [0, 0.6],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading(context, floor),
            const SizedBox(height: 14),
            _stats(context),
            const SizedBox(height: 14),
            _loot(context),
          ],
        ),
      ),
    );
  }

  Widget _heading(BuildContext context, int floor) {
    final palette = context.palette;
    return Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            SpriteFrame(
              id: summary.lastMemberId,
              kind: SpriteKind.combat,
              size: 52,
              spriteSize: 36,
              radius: 10,
              isBoss: true,
              depleted: true,
            ),
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: GameColors.clearedColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.palette.bossArenaFill,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(Icons.check_rounded, size: 12, color: palette.bg),
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FLOOR $floor CLEARED',
                style: HearthText.sectionLabel.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  color: GameColors.bossLabel,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                summary.floorName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HearthText.title.copyWith(
                  fontSize: 26,
                  height: 1,
                  color: GameColors.bossName,
                  shadows: [
                    Shadow(
                      offset: const Offset(0, 2),
                      color: palette.titleShadow,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${summary.lastMemberName} defeated',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HearthText.rowMeta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.palette.bossMuted,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stats(BuildContext context) {
    final time = summary.time;
    final timeBefore = summary.bestTimeBefore;
    final damage = summary.damageTaken;
    final damageBefore = summary.leastDamageBefore;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _StatTile(
              label: 'TIME',
              value: time == null ? '—' : formatLapTime(time),
              note: time == null
                  ? 'Not timed'
                  : timeBefore == null
                  ? 'First timed'
                  : summary.newBestTime
                  ? 'Was ${formatLapTime(timeBefore)}'
                  : 'Best ${formatLapTime(timeBefore)}',
              newBest: summary.newBestTime,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              label: 'DAMAGE TAKEN',
              value: damage == null ? '—' : '$damage',
              note: damage == null
                  ? 'Not tracked'
                  : damageBefore == null
                  ? 'First tracked'
                  : summary.newLeastDamage
                  ? 'Was $damageBefore'
                  : 'Best $damageBefore',
              newBest: summary.newLeastDamage,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _StatTile(
              label: 'CLEARS',
              value: '${summary.clears}',
              note: '+${summary.sessionClears} this session',
            ),
          ),
        ],
      ),
    );
  }

  /// The boss's drops first, revealed one at a time, then the rest of the
  /// floor's. A floor with no boss has only the floor's row.
  Widget _loot(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.boss) ...[
          _lootRow(
            context,
            label: 'BOSS LOOT',
            labelColor: GameColors.bossLabel,
            loot: summary.bossLoot,
            empty: '${summary.lastMemberName} dropped nothing',
            reveal: true,
          ),
          const SizedBox(height: 14),
        ],
        _lootRow(
          context,
          label: 'FLOOR LOOT',
          labelColor: context.palette.bossMuted,
          loot: summary.loot,
          empty: 'Nothing else dropped this lap',
        ),
      ],
    );
  }

  Widget _lootRow(
    BuildContext context, {
    required String label,
    required Color labelColor,
    required List<ObjectStack> loot,
    required String empty,
    bool reveal = false,
  }) {
    final total = loot.fold<int>(0, (sum, stack) => sum + stack.count);
    final tiles = [
      for (final stack in loot)
        ItemStackTile(
          size: _lootTile,
          id: stack.id as Enum,
          count: stack.count,
          alwaysShowCount: true,
        ),
    ];

    return Semantics(
      container: true,
      label: label.toLowerCase(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: HearthText.sectionLabel.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                    color: labelColor,
                  ),
                ),
              ),
              Text(
                '$total ${total == 1 ? 'item' : 'items'}',
                style: HearthText.rowMeta.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: context.palette.bossFaint,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (loot.isEmpty)
            Text(
              empty,
              style: HearthText.rowMeta.copyWith(
                color: context.palette.bossFaint,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                // five to a row, spread to the panel's edges as the mockup
                // lays them out
                final gap = ((constraints.maxWidth - _lootTile * 5) / 4).clamp(
                  6.0,
                  double.infinity,
                );
                return Wrap(
                  spacing: gap,
                  runSpacing: 12,
                  children: [
                    for (var i = 0; i < tiles.length; i++)
                      reveal
                          ? LootPop(
                              // the same summary keeps its key across rebuilds; a new one replays
                              key: ValueKey((summary, i)),
                              order: i,
                              child: tiles[i],
                            )
                          : tiles[i],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// One figure of the floor summary: its label, the lap's value, how it
/// stands against the floor's record, and a NEW BEST tag when it beat it.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.note,
    this.newBest = false,
  });

  final String label;
  final String value;
  final String note;
  final bool newBest;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.palette.bossTileFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: newBest
              ? GameColors.bossBarBorder
              : context.palette.bossTileEdge,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HearthText.sectionLabel.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: context.palette.bossMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: HearthText.statusStat.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HearthText.rowMeta.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: context.palette.bossFaint,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 16,
            child: newBest
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: GameColors.bossLabel,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'NEW BEST',
                      style: HearthText.sectionLabel.copyWith(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        height: 1,
                        color: context.palette.bossFrameInner,
                      ),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// The dock's top row while the loop pauses on a cleared floor: a ring
/// counting down to the next floor, which floor that is, and whether the
/// loop runs on to the next floor or repeats this one.
class FloorCountdownRow extends StatefulWidget {
  const FloorCountdownRow({
    super.key,
    required this.endsAt,
    required this.total,
    required this.nextFloorNumber,
    required this.nextFloorName,
    required this.repeats,
    required this.loopsDungeon,
    required this.onLoopDungeonChanged,
  });

  final DateTime endsAt;

  /// The whole pause, which the ring drains over.
  final Duration total;

  /// 1-based.
  final int nextFloorNumber;
  final String nextFloorName;

  /// The next floor is the one just cleared, run again.
  final bool repeats;

  /// Next (Loop dungeon) or Repeat (Loop floor).
  final bool loopsDungeon;
  final ValueChanged<bool> onLoopDungeonChanged;

  @override
  State<FloorCountdownRow> createState() => _FloorCountdownRowState();
}

class _FloorCountdownRowState extends State<FloorCountdownRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // the ring is the only thing moving, so it keeps its own clock rather
    // than redrawing the screen
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted) return;
      setState(() {});
      if (!DateTime.now().isBefore(widget.endsAt)) _timer?.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final remaining = widget.endsAt.difference(DateTime.now());
    final remainingMs = remaining.isNegative ? 0 : remaining.inMilliseconds;
    final totalMs = widget.total.inMilliseconds;
    final seconds = (remainingMs / 1000).ceil();
    final fraction = totalMs <= 0 ? 0.0 : remainingMs / totalMs;
    final title = widget.repeats
        ? 'Floor ${widget.nextFloorNumber} again in ${seconds}s'
        : 'Floor ${widget.nextFloorNumber} starts in ${seconds}s';

    return Semantics(
      container: true,
      liveRegion: true,
      label: widget.repeats
          ? 'Floor ${widget.nextFloorNumber} starts again in $seconds seconds'
          : 'Next floor starts in $seconds seconds',
      child: Row(
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: fraction.clamp(0.0, 1.0),
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: palette.track,
                    color: palette.accent,
                  ),
                ),
                ExcludeSemantics(
                  child: Text(
                    '$seconds',
                    style: HearthText.title.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ExcludeSemantics(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HearthText.rowTitle.copyWith(
                      fontSize: 14,
                      height: 1.1,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.nextFloorName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: HearthText.rowMeta.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _loopSwitch(context),
        ],
      ),
    );
  }

  /// Next / Repeat: the dungeon's loop mode, from where it bites.
  Widget _loopSwitch(BuildContext context) {
    final palette = context.palette;
    Widget option(String label, bool value) {
      final selected = widget.loopsDungeon == value;
      return Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => widget.onLoopDungeonChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: selected ? palette.raised : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: (selected ? HearthText.chipActive : HearthText.chip)
                  .copyWith(
                    fontSize: 12,
                    color: selected ? palette.text : palette.textMuted,
                  ),
            ),
          ),
        ),
      );
    }

    return Semantics(
      container: true,
      label: 'After this floor',
      child: Container(
        height: 36,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: palette.surfaceSunken,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            option('Next', true),
            const SizedBox(width: 3),
            option('Repeat', false),
          ],
        ),
      ),
    );
  }
}

/// The dock's buttons while the loop pauses on a cleared floor: Cancel
/// stops it there, Go now starts the next floor without waiting.
class FloorClearButtons extends StatelessWidget {
  const FloorClearButtons({
    super.key,
    required this.onCancel,
    required this.onGoNow,
  });

  final VoidCallback onCancel;
  final VoidCallback onGoNow;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 10,
          child: _PressButton(
            onTap: onCancel,
            color: palette.surface,
            lipColor: palette.border,
            child: Text(
              'Cancel',
              style: HearthText.rowTitle.copyWith(
                fontSize: 16,
                color: palette.text,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 14,
          child: _PressButton(
            onTap: onGoNow,
            color: palette.accent,
            lipColor: palette.accentLip,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Go now',
                  style: HearthText.rowTitle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: palette.onAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: palette.onAccent,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A raised dock button with the action bar's travel.
class _PressButton extends StatefulWidget {
  const _PressButton({
    required this.onTap,
    required this.color,
    required this.lipColor,
    required this.child,
  });

  final VoidCallback onTap;
  final Color color;
  final Color lipColor;
  final Widget child;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: RaisedSurface(
          pressed: _pressed,
          height: kActionBarButtonHeight,
          color: widget.color,
          lipColor: widget.lipColor,
          padding: EdgeInsets.zero,
          child: Center(child: widget.child),
        ),
      ),
    );
  }
}
