import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/encounter_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'fading_number.dart';
import 'icon_renderer.dart';
import 'fill_bar.dart';

class ProgressBars extends StatelessWidget {
  const ProgressBars({
    super.key,
    this.onActivityTap,
    this.encounterScreenInView = false,
  });

  /// Called with the current activity's icon id when the activity
  /// icon is tapped. Only invoked while an activity is running.
  final void Function(Enum activityIconId)? onActivityTap;

  /// Whether an encounter screen is currently visible to the user.
  /// When the active encounter is on screen it shows its own damage
  /// numbers, so the activity icon stays quiet.
  final bool encounterScreenInView;

  // the banner is sized to this row, so everything in it is kept compact
  // enough to sit inside the shortened toolbar
  static const double _activityIconSize = 36;

  /// Gap between the two stacked bars.
  static const double _barGap = 6;

  /// The banner carries character-level state only: energy, and how much of
  /// the boost is left. Both run the full width of the banner, and the count
  /// never changes, so moving between screens never resizes the banner.
  /// Per-action progress is encounter state and lives on the acting entity's
  /// row instead — see [ActionTimer].
  static const double _barHeight = 7;
  static const double _barRadius = 4;

  static const Color _energyColor = Color(0xFF188CEB);
  static const Color _boostColor = Color(0xFFB5A3DA);

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerDataController>();
    final timing = context.watch<ActionTimingController>();
    final encounter = context.watch<EncounterController>();

    // flash damage on the icon unless the active encounter's own screen
    // is in view (it shows the numbers over the entity image instead)
    final damageOnIcon =
        !(encounterScreenInView && encounter.isViewingActiveEncounter());
    final damageDone = encounter.latestActionResult.damageDone;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Current activity icon — same tile the explore screen shows for the
        // entity, with a live count badge. An empty slot is kept when idle so
        // the bars don't shift.
        AnimatedBuilder(
          animation: timing,
          builder: (_, _) {
            final iconId = timing.activityIconId;
            if (iconId == null) {
              return const SizedBox(
                width: _activityIconSize,
                height: _activityIconSize,
              );
            }
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                ItemStackTile(
                  size: _activityIconSize,
                  count: timing.activityCount,
                  id: iconId,
                  showInfoDialogOnTap: false,
                  onTap: onActivityTap == null
                      ? null
                      : () => onActivityTap!(iconId),
                ),
                // presence, not progress: the pulse says the loop is still
                // turning without repeating the action bar the acting
                // entity's own row now carries. it is what the screens
                // with no encounter on them — inventory, skills, gear —
                // are glanced at for.
                const Positioned(top: -3, left: -3, child: _ActivityPulseDot()),
                if (damageOnIcon)
                  IgnorePointer(
                    child: FadingNumber(
                      number: damageDone,
                      trigger: encounter.actionSequence,
                      autoplay: false,
                      color: damageDone > 0 ? Colors.red : Colors.blue,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Energy
              AnimatedBuilder(
                animation: timing,
                builder: (_, _) => FillBar(
                  value: playerController.getStaminaPercent(),
                  height: _barHeight,
                  borderRadius: _barRadius,
                  foregroundColor: _energyColor,
                ),
              ),
              const SizedBox(height: _barGap),

              // Boost remaining
              AnimatedBuilder(
                animation: timing,
                builder: (_, _) => FillBar(
                  value: timing.percentMaxSpeed,
                  height: _barHeight,
                  borderRadius: _barRadius,
                  foregroundColor: _boostColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 2),
        Column(
          children: [
            AnimatedBuilder(
              animation: timing,
              builder: (_, _) => StatValueLabel(
                value: playerController.getStamina(),
                max: playerController.getMaxStamina(),
              ),
            ),
            ActionIntervalTimer(),
          ],
        ),
      ],
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
  static const Color _color = Color(0xFFC0ABE9);

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
          decoration: const BoxDecoration(
            color: _ActivityPulseDot._color,
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
        IconRenderer<SkillId>(size: 15, id: skill),
        // const SizedBox(width: 4),
        Text(
          '${value.round()} / ${max.round()}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}

class ActionIntervalTimer extends StatelessWidget {
  const ActionIntervalTimer({super.key});

  @override
  Widget build(BuildContext context) {
    final timing = context.watch<ActionTimingController>();
    final intervalMs = timing.getCurrentActionDuration().inMilliseconds;
    final speedBoost = timing.getCurrentSpeedMultiplier();

    return SizedBox(
      width: 80, // Fixed width so layout doesn't shift
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 4),

              // the action-speed boost: the Speed stat's doing, so it wears
              // the Speed icon rather than a bolt
              const IconRenderer<SkillId>(size: 15, id: SkillId.SPEED),
              const SizedBox(width: 4),
              SizedBox(
                width: 40, // Fixed width for text so it doesn't resize
                child: Text(
                  '${(speedBoost).toStringAsFixed(2)}x',
                  textAlign: TextAlign.left,
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
