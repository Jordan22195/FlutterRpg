import 'package:flutter/material.dart';

import '../catalogs/entities/entities.dart';
import '../data/skill_data.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'action_timer.dart';
import 'icon_renderer.dart';

/// A dungeon boss's stage: the floor's last fight gets the screen to itself.
/// The boss stands large in a gold-framed arena with its name over it, and
/// its hp runs along the arena's foot in one tall bar — quartered, with the
/// last hits trailing off it — over its swing timer and stats, in place of
/// the status row an ordinary member gets.
class BossArena extends StatelessWidget {
  const BossArena({
    super.key,
    required this.boss,
    required this.floorNumber,
    this.damageSlot,
    this.actionProgress,
    this.onTap,
  });

  final CombatEntity boss;

  /// 1-based, for the "BOSS · FLOOR 2" line.
  final int floorNumber;

  /// The player's last hit, floated up beside the boss — clear of its bar.
  final Widget? damageSlot;

  /// How far the boss is through its swing, 0..1, sampled per frame.
  final double Function()? actionProgress;

  final VoidCallback? onTap;

  static const double height = 300;
  static const double _radius = 22;
  static const double _border = 2;
  static const double _barHeight = 30;

  /// How long the trail of a hit takes to drain after the bar has dropped.
  static const Duration _trailDuration = Duration(milliseconds: 650);

  @override
  Widget build(BuildContext context) {
    final maxHp = boss.maxHitPoints;
    final hp = boss.hitpoints.clamp(0, maxHp);
    final fraction = maxHp <= 0 ? 0.0 : hp / maxHp;

    return Semantics(
      container: true,
      label: 'Boss: ${boss.name}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          decoration: BoxDecoration(
            color: GameColors.bossArenaFill,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: GameColors.bossFrame, width: _border),
            boxShadow: const [
              BoxShadow(color: GameColors.bossFrameOuter, spreadRadius: 1),
            ],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_radius - _border),
            border: Border.all(
              color: GameColors.bossFrameInner,
              width: _border,
            ),
          ),
          // a gradient replaces a decoration's colour rather than painting
          // over it, so the boss's glow is its own layer over the ground
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_radius - _border),
              gradient: RadialGradient(
                center: const Alignment(0, 0.16),
                radius: 0.62,
                colors: [
                  GameColors.bossGlow.withValues(alpha: 0.30),
                  GameColors.bossGlow.withValues(alpha: 0),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 14,
                  right: 12,
                  top: 12,
                  child: _heading(context),
                ),
                // the shadow the boss stands on
                Positioned(
                  left: 0,
                  right: 0,
                  top: 184,
                  child: Center(
                    child: Container(
                      width: 190,
                      height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF060403).withValues(alpha: 0.55),
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(95, 11),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 64,
                  child: Center(child: IconRenderer(id: boss.id, size: 128)),
                ),
                if (damageSlot != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 72,
                    child: Align(
                      alignment: const Alignment(0.55, 0),
                      child: IgnorePointer(child: damageSlot!),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _hpBar(context, hp, maxHp, fraction),
                      const SizedBox(height: 7),
                      Row(
                        children: [
                          Expanded(
                            child: actionProgress == null
                                ? const SizedBox.shrink()
                                : ActionTimer(
                                    actor: ActionTimerActor.enemy,
                                    progress: actionProgress!,
                                    interval: () => Duration(
                                      milliseconds: (boss.attackInterval * 1000)
                                          .round(),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 10),
                          _stat(
                            context,
                            SkillId.DEFENCE,
                            boss.defence,
                            'Defence',
                          ),
                          const SizedBox(width: 10),
                          _stat(context, SkillId.ATTACK, boss.attack, 'Attack'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(BuildContext context) {
    final palette = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'BOSS · FLOOR $floorNumber',
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
                boss.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: HearthText.title.copyWith(
                  fontSize: 28,
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
            ],
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          label: 'Level ${boss.level}',
          excludeSemantics: true,
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: palette.bg.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: GameColors.bossBarBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconRenderer(id: SkillId.ATTACK, size: 13),
                const SizedBox(width: 5),
                Text(
                  '${boss.level}',
                  style: HearthText.statusStat.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: GameColors.bossLabel,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// The boss's hp: quartered so a fight reads in phases, with what the
  /// last hits took trailing off the end of the fill before it drains.
  Widget _hpBar(BuildContext context, int hp, int maxHp, double fraction) {
    final colors = context.gameColors;
    final percent = (fraction * 100).round();

    return Semantics(
      label: 'Boss health',
      value: '$hp of $maxHp',
      excludeSemantics: true,
      child: Container(
        height: _barHeight,
        decoration: BoxDecoration(
          color: GameColors.bossBarTrack,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: GameColors.bossBarBorder, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              return Stack(
                children: [
                  // the trail: what the last hits took, draining after them
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: fraction),
                    duration: _trailDuration,
                    curve: Curves.easeIn,
                    builder: (context, value, _) => Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: width * value,
                      child: ColoredBox(
                        color: colors.hp.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: fraction),
                    duration: const Duration(milliseconds: 100),
                    builder: (context, value, _) => Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      width: width * value,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              colors.hp,
                              Color.lerp(colors.hp, Colors.black, 0.2)!,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  for (final quarter in const [0.25, 0.5, 0.75])
                    Positioned(
                      left: width * quarter - 1,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: ColoredBox(
                        color: const Color(0xFF0F0A08).withValues(alpha: 0.7),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          Text('$hp / $maxHp', style: _barText(context)),
                          const Spacer(),
                          Text('$percent%', style: _barText(context)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  TextStyle _barText(BuildContext context) => HearthText.ringNumber.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: context.gameColors.onHp,
    shadows: const [Shadow(offset: Offset(0, 1), color: Color(0x99000000))],
  );

  Widget _stat(BuildContext context, SkillId skill, int value, String name) {
    return Semantics(
      label: '$name $value',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconRenderer(id: skill, size: 14),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: HearthText.statusStat.copyWith(
              fontSize: 14,
              color: context.palette.text,
            ),
          ),
        ],
      ),
    );
  }
}
