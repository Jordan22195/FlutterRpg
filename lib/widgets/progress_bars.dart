import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../utilities/util.dart';
import 'action_timer.dart';
import 'fading_number.dart';
import 'icon_renderer.dart';
import 'fill_bar.dart';

/// The status row: what the player is doing, their stamina and boost, and
/// the numbers behind them. Character-level state only — it outlives any
/// one screen, so it rides above all of them.
class ProgressBars extends StatelessWidget {
  const ProgressBars({
    super.key,
    this.onActivityTap,
    this.encounterScreenInView = false,
  });

  /// Called with the current activity's icon id when the activity
  /// button is tapped. Only invoked while an activity is running.
  final void Function(Enum activityIconId)? onActivityTap;

  /// Whether an encounter screen is currently visible to the user.
  /// When the active encounter is on screen it shows its own damage
  /// numbers, so the activity button stays quiet.
  final bool encounterScreenInView;

  /// The row's own height.
  static const double height = 48;

  /// Gap between the stacked bars.
  static const double _barGap = 5;

  /// The banner carries character-level state only: stamina and how much
  /// of the boost is built up. Per-action progress is encounter state and
  /// lives on the acting entity's row instead — see [ActionTimer] — and a
  /// trip's road takes the zone screen's progress row while the zone on
  /// screen is not where the player stands.
  static const double _staminaHeight = 8;
  static const double _thinBarHeight = 4;
  static const double _hpBarHeight = 6;

  /// In a fight three rows share the 48pt instead of two, so stamina slims
  /// down and the rows close up.
  static const double _compactStaminaHeight = 4;
  static const double _compactBarGap = 2;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = context.gameColors;
    final playerController = context.watch<PlayerDataController>();
    final timing = context.watch<ActionTimingController>();
    final encounter = context.watch<EncounterController>();

    // flash damage on the button unless the active encounter's own screen
    // is in view (it shows the numbers over the entity image instead)
    final damageOnIcon =
        !(encounterScreenInView && encounter.isViewingActiveEncounter());
    final damageDone = encounter.latestActionResult.damageDone;

    // the bars sit on a see-through track, so the art behind the row shows
    final barTrack = palette.borderStrong.withValues(alpha: 0.6);

    final inCombat = encounter.isInCombat();
    final hp = encounter.getPlayerHp();
    final maxHp = playerController.getMaxHitpoints();
    final staminaHeight = inCombat ? _compactStaminaHeight : _staminaHeight;

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: timing,
            builder: (_, _) {
              final iconId = timing.activityIconId;
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  ActivityButton(
                    activityId: iconId,
                    count: timing.activityCount,
                    onTap: iconId == null || onActivityTap == null
                        ? null
                        : () => onActivityTap!(iconId),
                  ),
                  // presence, not progress: the pulse says the loop is
                  // still turning without repeating the action bar the
                  // acting entity's own row carries. it is what the screens
                  // with no encounter on them — inventory, skills, gear —
                  // are glanced at for.
                  if (iconId != null)
                    const Positioned(
                      top: -3,
                      left: -3,
                      child: _ActivityPulseDot(),
                    ),
                  if (iconId != null && damageOnIcon)
                    IgnorePointer(
                      child: FadingNumber(
                        number: damageDone,
                        trigger: encounter.actionSequence,
                        autoplay: false,
                        color: damageDone > 0 ? colors.hp : palette.textMuted,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(blurRadius: 6, color: palette.titleShadow),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Hitpoints, on top while a fight is running: the one number
                // a fight can end on, so it rides above everything else.
                // Out of combat it isn't moving, and the row stays as it was
                if (inCombat) ...[
                  _BarRow(
                    key: const ValueKey('status-hp'),
                    bar: FillBar(
                      value: maxHp <= 0 ? 0 : hp / maxHp,
                      height: _hpBarHeight,
                      borderRadius: _hpBarHeight / 2,
                      backgroundColor: barTrack,
                      foregroundColor: colors.hp,
                    ),
                    label: StatValueLabel(
                      value: hp.toDouble(),
                      max: maxHp.toDouble(),
                      skill: SkillId.HITPOINTS,
                      compact: true,
                    ),
                  ),
                  const SizedBox(height: _compactBarGap),
                ],

                // Stamina — slimmer while the hp row needs the room
                AnimatedBuilder(
                  animation: timing,
                  builder: (_, _) => _BarRow(
                    key: const ValueKey('status-stamina'),
                    bar: FillBar(
                      value: playerController.getStaminaPercent(),
                      height: staminaHeight,
                      borderRadius: staminaHeight / 2,
                      backgroundColor: barTrack,
                      foregroundColor: colors.stamina,
                    ),
                    label: StatValueLabel(
                      value: playerController.getStamina(),
                      max: playerController.getMaxStamina(),
                      compact: inCombat,
                    ),
                  ),
                ),
                SizedBox(height: inCombat ? _compactBarGap : _barGap),

                // Boost built up by holding the action button
                AnimatedBuilder(
                  animation: timing,
                  builder: (_, _) => _BarRow(
                    key: const ValueKey('status-boost'),
                    bar: FillBar(
                      value: timing.percentMaxSpeed,
                      height: _thinBarHeight,
                      borderRadius: _thinBarHeight / 2,
                      backgroundColor: barTrack,
                      foregroundColor: colors.secondaryBar,
                    ),
                    label: const ActionIntervalTimer(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One bar of the status row with its readout beside it, on the bar's own
/// line. The readout gets a fixed slot, so every bar runs the same length
/// and every readout starts at the same x whatever its digits.
class _BarRow extends StatelessWidget {
  const _BarRow({super.key, required this.bar, required this.label});

  final Widget bar;
  final Widget label;

  /// Room for the widest readout, the boost's two-icon stance.
  static const double labelWidth = 96;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: bar),
        const SizedBox(width: 12),
        SizedBox(
          width: labelWidth,
          // a big text scale shrinks the readout rather than pushing the
          // row past its 48pt
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: label,
          ),
        ),
      ],
    );
  }
}

/// The status row's activity button: a 44pt square showing what the player
/// is doing — a compass while exploring, or the target's sprite with how
/// many are left in a pill across its bottom edge. Empty while idle.
class ActivityButton extends StatelessWidget {
  const ActivityButton({
    super.key,
    required this.activityId,
    required this.count,
    this.onTap,
  });

  final Enum? activityId;
  final int count;
  final VoidCallback? onTap;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final id = activityId;

    final Widget? face;
    if (id == null) {
      face = null;
    } else if (id == SkillId.EXPLORATION) {
      face = Icon(
        Icons.explore_outlined,
        size: 24,
        color: context.gameColors.exploration,
      );
    } else {
      face = IconRenderer(size: 32, id: id);
    }

    return Semantics(
      button: onTap != null,
      label: id == null
          ? 'No activity'
          : id == SkillId.EXPLORATION
          ? 'Current activity: exploring'
          : 'Current activity, $count left',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: palette.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: palette.borderOverArt),
                  ),
                  child: face == null ? null : Center(child: face),
                ),
              ),
              // the count only means something on a target
              if (id != null && id != SkillId.EXPLORATION && count > 0)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: -7,
                  child: Center(child: CountPill(count: count)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small count laid over the edge of a sprite frame ("181k"), shortened
/// so a six-digit stack doesn't cover the art it counts.
class CountPill extends StatelessWidget {
  const CountPill({
    super.key,
    required this.count,
    this.borderColor,
    this.height = 16,
    this.fontSize = 11,
  });

  final int count;

  /// 16 tall with 11pt figures over a sprite; a discovery tile's line sets
  /// it a touch larger, where it sits on its own.
  final double height;
  final double fontSize;

  /// Matches the frame the pill sits on; defaults to the over-art border.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: height * 5 / 16),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: borderColor ?? palette.borderOverArt),
      ),
      alignment: Alignment.center,
      child: Text(
        Util.formatShortCount(count),
        style: HearthText.timer.copyWith(
          fontSize: fontSize,
          height: 1.0,
          color: palette.text,
        ),
      ),
    );
  }
}

/// The heartbeat on the activity tile: a dot pulsing once per action, so the
/// banner still answers "am I still working?" from a screen that has no
/// encounter on it. Deliberately not a progress readout — one action's worth
/// of progress belongs to the acting entity's row, and drawing it twice was
/// what put the player's timer 900px from the enemy's.
class _ActivityPulseDot extends StatefulWidget {
  const _ActivityPulseDot();

  static const double _size = 8;

  /// The trough of the pulse. Never fully out: the dot is presence, and
  /// blinking it off would read as stopped.
  static const double _minOpacity = 0.35;

  @override
  State<_ActivityPulseDot> createState() => _ActivityPulseDotState();
}

class _ActivityPulseDotState extends State<_ActivityPulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  ActionTimingController? _timing;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final timing = context.read<ActionTimingController>();
    if (identical(timing, _timing)) return;
    _timing?.removeListener(_onTick);
    _timing = timing..addListener(_onTick);
    _onTick();
  }

  // the interval is re-read off the loop's own ticks rather than in build:
  // restarting an animation mid-build is a good way to fight the framework
  void _onTick() => _matchInterval(_timing!.getCurrentActionDuration());

  @override
  void dispose() {
    _timing?.removeListener(_onTick);
    _pulse.dispose();
    super.dispose();
  }

  /// One full 0.35 -> 1 -> 0.35 cycle spans the action interval, so the dot
  /// visibly speeds up as the boost does. The controller runs half of that
  /// and mirrors, and is only restarted when the interval has actually
  /// moved — otherwise every frame's re-read would reset the phase.
  void _matchInterval(Duration interval) {
    final half = Duration(microseconds: interval.inMicroseconds ~/ 2);
    if (half <= Duration.zero) return;
    if ((half - _pulse.duration!).abs() < const Duration(milliseconds: 20)) {
      return;
    }
    _pulse.duration = half;
    _pulse.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: FadeTransition(
        opacity: Tween<double>(
          begin: _ActivityPulseDot._minOpacity,
          end: 1.0,
        ).animate(_pulse),
        child: Container(
          width: _ActivityPulseDot._size,
          height: _ActivityPulseDot._size,
          decoration: BoxDecoration(
            color: context.palette.text,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// "xx / yy" readout next to a stat bar (e.g. current/max stamina),
/// matching the icon + fixed-width text style of ActionIntervalTimer.
///
/// The icon is the stat's own skill sprite. Three different numbers used to
/// share one lightning bolt up here, which read as three kinds of stamina;
/// each now wears the face of the thing it actually measures.
class StatValueLabel extends StatelessWidget {
  const StatValueLabel({
    super.key,
    required this.value,
    required this.max,
    this.skill = SkillId.STAMINA,
    this.compact = false,
  });

  final double value;
  final double max;
  final SkillId skill;

  /// The smaller readout a fight's three-row status bar uses.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconRenderer<SkillId>(size: compact ? 12 : 16, id: skill),
        SizedBox(width: compact ? 3 : 4),
        Text(
          '${value.round()} / ${max.round()}',
          maxLines: 1,
          softWrap: false,
          style: HearthText.statusStat.copyWith(
            fontSize: compact ? 11 : null,
            height: compact ? 1.0 : null,
            color: context.palette.text,
          ),
        ),
      ],
    );
  }
}

class ActionIntervalTimer extends StatelessWidget {
  const ActionIntervalTimer({super.key});

  static const double _iconSize = 16;
  static const double _iconGap = 4;

  /// Room for the label plus the widest icon run: the strong stance's two.
  static const double _labelWidth = 46;
  static const double _width =
      _iconGap + (_iconSize + _iconGap) * 2 + _labelWidth;

  @override
  Widget build(BuildContext context) {
    final timing = context.watch<ActionTimingController>();
    final player = context.watch<PlayerDataController>();
    final boostSkill = player.getBoostSkill();

    // in the strong stance the points are spent on another stat entirely,
    // so two icons are needed: strength says where they come from, the
    // second says where they land. the fast stance spends speed on speed,
    // so there is nothing to add and the row stays one icon wide.
    final boostedStat = player.getBoostedStat();
    final showsTarget = boostedStat != boostSkill;

    // the two stances buy different things, so they read differently: a
    // strength stance lends points to the stat it is spent on, so it shows
    // +n; the fast stance buys rate, so it stays a multiplier.
    //
    // the speed multiplier is the total - the cut the speed stat already
    // makes to the interval times the momentum on top - so standing still
    // it reads the stat's own cut instead of a flat 1.00x. both sides
    // therefore show what the stance is worth at rest rather than nothing.
    final label = boostSkill == SkillId.SPEED
        ? '${timing.getTotalSpeedMultiplier().toStringAsFixed(2)}x'
        : '+${player.getStrengthBoostPoints()}';

    return SizedBox(
      // Fixed width so layout doesn't shift - wide enough for the two-icon
      // strong stance, so switching stance doesn't resize the column either
      width: _width,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // wears the icon of whichever stat is actually being trained
              IconRenderer<SkillId>(size: _iconSize, id: boostSkill),
              if (showsTarget) ...[
                const SizedBox(width: _iconGap),
                IconRenderer<SkillId>(size: _iconSize, id: boostedStat),
              ],
              const SizedBox(width: _iconGap),
              SizedBox(
                width: _labelWidth, // Fixed so the text doesn't resize
                // one line, always: a wrapped label would push the row past
                // its 48pt, so a big text scale shrinks it instead
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    style: HearthText.statusStat.copyWith(
                      color: context.palette.text,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
