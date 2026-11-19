import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/buff_controller.dart';
import '../data/active_buff.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'countdown_timer.dart';
import 'empty_state.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';

/// The timer under a buff icon turns this colour in its last minute.
const Color _expiringColor = Color(0xFFF2B866);

/// Under a minute left: the timer warns.
const Duration _expiringBelow = Duration(minutes: 1);

/// The buffs on the player as small square icons, pinned in a stage
/// panel's top-right corner and filling right to left: each in a frame of
/// its main stat's colour, darkened clockwise as its time runs down, with
/// what is left under it. A fire outranked on every stat dims.
///
/// Tapping anywhere on the row opens [showActiveBuffsSheet]; long-pressing
/// one icon shows what that buff is doing. Draws nothing with no buffs up.
///
/// Rebuilds on [BuffController]'s one-second tick, which is what moves the
/// sweeps and timers.
class StageBuffIcons extends StatelessWidget {
  const StageBuffIcons({super.key, this.maxVisible = 5, this.fromLeft = false});

  /// The icons for a stage, or null while no buff is up — so a stage can
  /// leave its slot empty and keep its hit number where it usually floats.
  /// Selects on whether any are up rather than watching: the icons tick
  /// themselves, and the screen around them needn't rebuild every second.
  static Widget? ifAny(BuildContext context, {bool fromLeft = false}) {
    final any = context.select<BuffController, bool>(
      (buffs) => buffs.getActiveBuffs().isNotEmpty,
    );
    return any ? StageBuffIcons(fromLeft: fromLeft) : null;
  }

  /// The most icons shown; past it the last slot becomes a "+N" box.
  final int maxVisible;

  /// Fill left to right, for a top-left corner (the boss arena's, whose
  /// right corner holds the level). Right to left by default.
  final bool fromLeft;

  static const double iconSize = 24;
  static const double _gap = 4;

  /// Padding around the row, so even a single icon is a 44pt tap target.
  static const double _pad = 4;

  /// Pinning [StageBuffIcons] at this inset from a stage's top-right
  /// corner lines its icons up with the panel's other 10-12pt insets.
  static const double insetTop = 10 - _pad;
  static const double insetRight = 12 - _pad;

  /// The row's own padding, for a parent pinning it by its icons.
  static const double pad = _pad;

  @override
  Widget build(BuildContext context) {
    final buffs = context.watch<BuffController>().getActiveBuffs();
    if (buffs.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final overflowing = buffs.length > maxVisible;
    final visible = overflowing ? buffs.sublist(0, maxVisible - 1) : buffs;
    final hidden = buffs.length - visible.length;

    return Semantics(
      button: true,
      label:
          '${buffs.length} active buff${buffs.length == 1 ? '' : 's'}. '
          'Show all',
      child: GestureDetector(
        key: const ValueKey('stage-buff-icons'),
        behavior: HitTestBehavior.opaque,
        onTap: () => showActiveBuffsSheet(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.all(_pad),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              // the first buff takes the corner, the rest run away from it
              textDirection: fromLeft ? TextDirection.ltr : TextDirection.rtl,
              children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  StageBuffIcon(buff: visible[i], now: now),
                ],
                if (hidden > 0) ...[
                  const SizedBox(width: _gap),
                  _OverflowBox(count: hidden),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One buff's icon: the item in a frame of its main stat's colour, a dark
/// sweep over the time already used, and the time left beneath it.
class StageBuffIcon extends StatelessWidget {
  const StageBuffIcon({super.key, required this.buff, required this.now});

  final ActiveBuff buff;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = buff.primary;
    final frame = buff.outranked || primary == null
        ? palette.borderStrong
        : skillRingColor(primary.stat);
    final remaining = buff.remaining(now);
    const size = StageBuffIcons.iconSize;

    final icon = Column(
      key: ValueKey('stage-buff-${buff.id.name}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: palette.bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: frame),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              fit: StackFit.expand,
              children: [
                IconRenderer(id: buff.id, size: size - 2),
                CustomPaint(
                  painter: BuffSweepPainter(used: 1 - buff.fractionLeft(now)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          CountdownTimer.formatDuration(remaining),
          style: HearthText.timer.copyWith(
            fontSize: 11,
            height: 1.1,
            color: remaining < _expiringBelow ? _expiringColor : palette.text,
            shadows: [Shadow(color: palette.titleShadow, blurRadius: 2)],
          ),
        ),
      ],
    );

    return Tooltip(
      triggerMode: TooltipTriggerMode.longPress,
      preferBelow: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.borderStrong),
      ),
      richMessage: _tooltip(context, remaining),
      child: Opacity(opacity: buff.outranked ? 0.4 : 1, child: icon),
    );
  }

  InlineSpan _tooltip(BuildContext context, Duration remaining) {
    final palette = context.palette;
    final muted = TextStyle(color: palette.textMuted, fontSize: 11);
    return TextSpan(
      style: HearthText.rowMeta.copyWith(color: palette.text, fontSize: 13),
      children: [
        TextSpan(
          text: buff.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        TextSpan(
          text:
              '\n${scopeLabel(buff)} · '
              '${CountdownTimer.formatDuration(remaining)} left',
          style: muted,
        ),
        for (final effect in buff.effects)
          TextSpan(
            text: '\n${effectLabel(effect)}',
            style: TextStyle(
              color: effect.counted
                  ? skillRingColor(effect.stat)
                  : palette.textMuted,
              decoration: effect.counted ? null : TextDecoration.lineThrough,
            ),
          ),
        if (buff.outranked)
          TextSpan(text: '\nA stronger fire is burning', style: muted),
      ],
    );
  }
}

/// "+8 Speed".
String effectLabel(BuffEffect effect) =>
    '+${effect.amount} ${skillDisplayName(effect.stat)}';

/// Where a buff applies, as the tooltip and sheet word it.
String scopeLabel(ActiveBuff buff) =>
    buff.outranked ? 'Outranked' : (buff.zoneBuff ? 'This zone' : 'Everywhere');

/// Darkens the [used] share of an icon clockwise from twelve o'clock, the
/// way a cooldown clock reads.
class BuffSweepPainter extends CustomPainter {
  BuffSweepPainter({required this.used});

  /// 0 (fresh) to 1 (all used).
  final double used;

  @override
  void paint(Canvas canvas, Size size) {
    if (used <= 0) return;
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.55);
    if (used >= 1) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    // a circle big enough to cover the square's corners
    final radius = size.longestSide * math.sqrt2 / 2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: radius,
    );
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * used, true, paint);
  }

  @override
  bool shouldRepaint(BuffSweepPainter old) => old.used != used;
}

class _OverflowBox extends StatelessWidget {
  const _OverflowBox({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: StageBuffIcons.iconSize,
      height: StageBuffIcons.iconSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: palette.borderOverArt),
      ),
      child: Text(
        '+$count',
        style: HearthText.timer.copyWith(
          fontSize: 11,
          color: palette.textSubtitle,
        ),
      ),
    );
  }
}

/// Opens every buff on the player in a bottom sheet, live: it keeps
/// counting down while open, and drops a buff the moment it runs out.
Future<void> showActiveBuffsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    builder: (_) => const SafeArea(child: ActiveBuffList()),
  );
}

/// Every buff on the player as rows — icon, name, where it applies, a chip
/// per stat it lends, and a bar draining with its time — under a header
/// adding up what they come to. The sheet's body; a screen with room for
/// the whole list can use it on its own.
class ActiveBuffList extends StatelessWidget {
  const ActiveBuffList({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final buffs = context.watch<BuffController>().getActiveBuffs();
    final now = DateTime.now();

    if (buffs.isEmpty) {
      return const EmptyState(
        message: 'No active buffs',
        icon: Icons.auto_awesome_outlined,
        height: 120,
      );
    }

    // what they come to, by the same rule the stat totals use
    final totals = <String>[];
    final byStat = <SkillId, int>{};
    for (final buff in buffs) {
      for (final effect in buff.effects.where((e) => e.counted)) {
        byStat[effect.stat] = (byStat[effect.stat] ?? 0) + effect.amount;
      }
    }
    final sorted = byStat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in sorted) {
      totals.add('+${entry.value} ${skillDisplayName(entry.key)}');
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Text(
          'Active buffs · ${buffs.length}',
          style: HearthText.rowTitle.copyWith(color: palette.text),
        ),
        const SizedBox(height: 2),
        Text(
          totals.join(' · '),
          style: HearthText.rowMeta.copyWith(color: palette.textMuted),
        ),
        const SizedBox(height: 8),
        for (final buff in buffs) _ActiveBuffRow(buff: buff, now: now),
      ],
    );
  }
}

class _ActiveBuffRow extends StatelessWidget {
  const _ActiveBuffRow({required this.buff, required this.now});

  final ActiveBuff buff;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final primary = buff.primary;
    final color = buff.outranked || primary == null
        ? palette.textMuted
        : skillRingColor(primary.stat);

    return Opacity(
      key: ValueKey('buff-row-${buff.id.name}'),
      opacity: buff.outranked ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: palette.divider)),
        ),
        child: Row(
          children: [
            IconRenderer(id: buff.id, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      text: buff.name,
                      style: HearthText.rowTitle.copyWith(
                        fontSize: 14,
                        color: palette.text,
                      ),
                      children: [
                        TextSpan(
                          text: '  ${scopeLabel(buff)}',
                          style: HearthText.rowMeta.copyWith(
                            fontSize: 11,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final effect in buff.effects)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: palette.track,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            effectLabel(effect),
                            style: HearthText.rowMeta.copyWith(
                              fontSize: 11,
                              color: effect.counted
                                  ? skillRingColor(effect.stat)
                                  : palette.textMuted,
                              decoration: effect.counted
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: buff.fractionLeft(now),
                      minHeight: 3,
                      color: color,
                      backgroundColor: palette.track,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              CountdownTimer.formatDuration(buff.remaining(now)),
              style: HearthText.timer.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
