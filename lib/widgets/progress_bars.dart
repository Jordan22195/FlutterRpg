import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
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

  /// The banner carries character-level state only: stamina, how much of
  /// the boost is built up, and — only while there is a trip to show — the
  /// road. Per-action progress is encounter state and lives on the acting
  /// entity's row instead — see [ActionTimer].
  ///
  /// A trip belongs here rather than on a screen for the same reason
  /// stamina does: it outlives whatever screen you happen to be reading,
  /// and no one screen owns it. It is the one bar here that comes and goes,
  /// and it can, because the row's height is set by the activity button
  /// beside these bars rather than by the bars themselves — all three still
  /// measure short of it, so the row never moves.
  static const double _staminaHeight = 8;
  static const double _thinBarHeight = 4;

  /// Identifies the trip bar, which is the only one of the three that is not
  /// always there.
  static const Key travelBarKey = Key('travel-progress');

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = context.gameColors;
    final playerController = context.watch<PlayerDataController>();
    final timing = context.watch<ActionTimingController>();
    final encounter = context.watch<EncounterController>();
    final world = context.watch<WorldController>();

    // flash damage on the button unless the active encounter's own screen
    // is in view (it shows the numbers over the entity image instead)
    final damageOnIcon =
        !(encounterScreenInView && encounter.isViewingActiveEncounter());
    final damageDone = encounter.latestActionResult.damageDone;

    // the bars sit on a see-through track, so the art behind the row shows
    final barTrack = palette.borderStrong.withValues(alpha: 0.6);

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
                // Stamina
                AnimatedBuilder(
                  animation: timing,
                  builder: (_, _) => FillBar(
                    value: playerController.getStaminaPercent(),
                    height: _staminaHeight,
                    borderRadius: _staminaHeight / 2,
                    backgroundColor: barTrack,
                    foregroundColor: colors.stamina,
                  ),
                ),
                const SizedBox(height: _barGap),

                // Boost built up by holding the action button
                AnimatedBuilder(
                  animation: timing,
                  builder: (_, _) => FillBar(
                    value: timing.percentMaxSpeed,
                    height: _thinBarHeight,
                    borderRadius: _thinBarHeight / 2,
                    backgroundColor: barTrack,
                    foregroundColor: colors.secondaryBar,
                  ),
                ),

                // The road, while there is one to walk. Off the bottom
                // rather than in among the two that are always there, so
                // neither of those ever changes position as it comes and
                // goes. The only bar here that carries a number, because it
                // is the only one counting down to something.
                if (world.isShowingTravel)
                  AnimatedBuilder(
                    animation: timing,
                    builder: (_, _) => Padding(
                      padding: const EdgeInsets.only(top: _barGap),
                      child: Row(
                        children: [
                          Expanded(
                            child: FillBar(
                              key: travelBarKey,
                              value: world.travelProgress(),
                              height: _thinBarHeight,
                              borderRadius: _thinBarHeight / 2,
                              backgroundColor: barTrack,
                              foregroundColor: colors.travel,
                            ),
                          ),
                          const SizedBox(width: ActionTimer.gap),
                          ActionTimeChip(duration: world.travelRemaining()),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedBuilder(
                animation: timing,
                builder: (_, _) => StatValueLabel(
                  value: playerController.getStamina(),
                  max: playerController.getMaxStamina(),
                ),
              ),
              const SizedBox(height: 2),
              const ActionIntervalTimer(),
            ],
          ),
        ],
      ),
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
  const CountPill({super.key, required this.count, this.borderColor});

  final int count;

  /// Matches the frame the pill sits on; defaults to the over-art border.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      height: 16,
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: palette.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? palette.borderOverArt),
      ),
      alignment: Alignment.center,
      child: Text(
        Util.formatShortCount(count),
        style: HearthText.timer.copyWith(
          fontSize: 11,
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
  });

  final double value;
  final double max;
  final SkillId skill;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconRenderer<SkillId>(size: 16, id: skill),
        const SizedBox(width: 4),
        Text(
          '${value.round()} / ${max.round()}',
          maxLines: 1,
          softWrap: false,
          style: HearthText.statusStat.copyWith(color: context.palette.text),
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
    // strength stance adds flat stat points, so it shows +n stepping in
    // whole points; the fast stance buys rate, so it stays a multiplier.
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
