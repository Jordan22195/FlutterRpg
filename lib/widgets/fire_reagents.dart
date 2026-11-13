import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/buff_controller.dart';
import '../controllers/fire_controller.dart';
import '../data/skill_data.dart';
import '../theme/hearth_theme.dart';
import 'countdown_timer.dart';
import 'icon_renderer.dart';

/*
fire reagents, on the firepit screen:
-the stage row: one ring per reagent buff burning on the fire, around the
 icon of the stat it buffs. the ring is the buff's time left out of the
 fire's: a buff can't outlast its fire, so a full ring lasts as long as the
 fire does. a reagent fills it; more logs on the fire lower it
-the reagent picker card and its sheet wear the same ring beside each
 reagent, so the player can see which stats are already up
reagents go on by the action button, through their recipes; nothing here
throws one
*/

/// "Strength" for [SkillId.STRENGTH].
String statName(SkillId stat) {
  final name = stat.name;
  return name[0] + name.substring(1).toLowerCase();
}

/// A stat's icon inside a ring that fills with [fullness] (0 to 1): a
/// reagent buff's time left out of its fire's. An empty ring is a stat with
/// no buff up.
class BuffRing extends StatelessWidget {
  const BuffRing({
    super.key,
    required this.stat,
    required this.fullness,
    this.size = 34,
  });

  final SkillId stat;
  final double fullness;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = context.gameColors;
    final stroke = size * 0.1;
    return Tooltip(
      message: statName(stat),
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.bg.withValues(alpha: 0.8),
                ),
              ),
            ),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: fullness.clamp(0.0, 1.0)),
                // long enough that a reagent landing reads as the ring filling
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) => CircularProgressIndicator(
                  value: value,
                  strokeWidth: stroke,
                  backgroundColor: palette.track,
                  color: colors.firemaking,
                ),
              ),
            ),
            IconRenderer<SkillId>(size: size - stroke * 4, id: stat),
          ],
        ),
      ),
    );
  }
}

/// The reagent buffs burning on the fire, as rings across the top of its
/// stage, each with a coarse time-left chip under it ("4m", "45s").
class FireReagentRings extends StatelessWidget {
  const FireReagentRings({super.key});

  @override
  Widget build(BuildContext context) {
    // the buff tick is what drains the rings and drops a spent one
    context.watch<BuffController>();
    final buffs = context.watch<FireController>().activeBuffs();

    return SingleChildScrollView(
      key: const ValueKey('fire-reagent-rings'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final buff in buffs) ...[
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BuffRing(
                  key: ValueKey('fire-reagent-ring-${buff.stat.name}'),
                  stat: buff.stat,
                  fullness: buff.fullness,
                ),
                const SizedBox(height: 3),
                _TimeChip(
                  key: ValueKey('fire-reagent-time-${buff.stat.name}'),
                  endsAt: buff.endsAt,
                ),
              ],
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

/// A reagent buff's time left, coarse ("4m", "45s"), in a small pill under
/// its ring.
class _TimeChip extends StatelessWidget {
  const _TimeChip({super.key, required this.endsAt});

  final DateTime endsAt;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: palette.track),
      ),
      alignment: Alignment.center,
      child: CountdownTimer(expirationTime: endsAt, size: 13, showIcon: false),
    );
  }
}
