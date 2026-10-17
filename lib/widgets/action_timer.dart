import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/action_timing_controller.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'fill_bar.dart';

/// The width every encounter row's label sits in, so the bars below the
/// labels all start on the same x — on the combat screen, the gathering
/// screen and the explore screen alike.
const double kEncounterRowLabelWidth = 56;

/// Travel's colour, on the button that starts a trip and on the bar that
/// counts it down. The theme's [GameColors.travel]; kept as a constant for
/// the callers that compare against it.
const Color kTravelColor = GameColors.travelColor;

/// Who an [ActionTimer] belongs to. The player's and the enemy's are drawn
/// identically, so neither reads as more important than the other; travel
/// takes its own colour, because while it fills nothing is being worked.
enum ActionTimerActor {
  /// The player's own action loop.
  player,

  /// A hostile entity winding up its swing.
  enemy,

  /// The player walking somewhere.
  travel,
}

/// The action progress bar, drawn on the row of whoever is acting.
///
/// This is encounter-level state — it exists only while an action is running
/// against a target — so it lives with the actor rather than in the global
/// banner, which carries character-level state that outlives any one screen.
/// Combat stacks the player's under the enemy's so the two racing timers can
/// be read against each other; gathering and explore show the player's alone.
///
/// The fill rides the action timing loop's per-frame ticks: [progress] and
/// [interval] are re-sampled on every one rather than read once at build, so
/// only this row rebuilds, and the fill advances linearly over the interval.
///
/// Both are supplied by the screen and neither falls back to the action
/// loop's raw state: the loop runs one action at a time and knows nothing
/// about which entity is on screen, so reading it directly would fill every
/// timer in the app from whichever single entity happened to be acting.
/// Each caller passes a getter already gated on owning that action.
class ActionTimer extends StatelessWidget {
  const ActionTimer({
    super.key,
    this.actor = ActionTimerActor.player,
    required this.progress,
    required this.interval,
  });

  final ActionTimerActor actor;

  /// How far through this screen's action, 0..1, sampled per frame. Reads
  /// zero whenever the action running is not this screen's.
  final double Function() progress;

  /// How long this screen's action takes, shown beside the bar and sampled
  /// per frame so it follows stance, boost and gear changes mid-action.
  final Duration Function() interval;

  /// A hairline, not a headline: the same height for both actors.
  static const double _barHeight = 4;
  static const double _barRadius = 2;

  /// Gap between a bar and the timer beside it. Public so a bar built
  /// somewhere other than here — the banner's road — can sit its timer at
  /// the same distance.
  static const double gap = 8;

  @override
  Widget build(BuildContext context) {
    final colors = context.gameColors;
    final fill = actor == ActionTimerActor.travel
        ? colors.travel
        : colors.timerFill;

    // the loop is the frame clock here, not the data source: it ticks every
    // frame an action is running, which is when the bar has to be re-sampled
    final timing = context.read<ActionTimingController>();

    return AnimatedBuilder(
      animation: timing,
      builder: (context, _) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: FillBar(
              value: progress(),
              height: _barHeight,
              borderRadius: _barRadius,
              backgroundColor: context.palette.track,
              foregroundColor: fill,
            ),
          ),
          const SizedBox(width: gap),
          ActionTimeChip(duration: interval()),
        ],
      ),
    );
  }
}

/// A span of seconds, read beside the bar it belongs to ("2.00s").
///
/// Tabular figures fixed to two decimals, so the digits don't jitter as the
/// boost moves the number underneath them. What the number *means* is the
/// caller's business: on an action row it is the interval the bar is filling
/// over, and on the banner's road it is how much of the trip is left.
class ActionTimeChip extends StatelessWidget {
  const ActionTimeChip({super.key, required this.duration});

  final Duration duration;

  static String format(Duration duration) =>
      '${(duration.inMilliseconds / 1000).toStringAsFixed(2)}s';

  @override
  Widget build(BuildContext context) {
    return Text(
      format(duration),
      style: HearthText.timer.copyWith(
        fontSize: 12,
        color: context.palette.textMuted,
      ),
    );
  }
}

/// Who a row belongs to, in the fixed-width slot every encounter row starts
/// with so the bars and rings below it all line up on the same x.
///
/// The column is a fixed width and the label is held to one line inside it:
/// a long one shrinks to fit rather than wrapping, which would make its row
/// taller than the rows it is supposed to line up with.
class EncounterRowLabel extends StatelessWidget {
  const EncounterRowLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kEncounterRowLabelWidth,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            maxLines: 1,
            softWrap: false,
            style: HearthText.activityLabel.copyWith(
              fontSize: 14,
              color: context.palette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

/// An activity's progress as a row of its own (the Hearth ProgressRow): the
/// label in the activity's colour with the interval on the right, and a 6px
/// bar in the same colour underneath. Used where the timer has no target's
/// row to hang under — exploring, a station's craft.
class ActionTimerRow extends StatelessWidget {
  const ActionTimerRow({
    super.key,
    required this.label,
    required this.progress,
    required this.interval,
    this.color,
  });

  final String label;
  final double Function() progress;
  final Duration Function() interval;

  /// The activity's colour — exploration gold for "Exploring", firemaking
  /// orange for "Tending". Defaults to the neutral timer fill.
  final Color? color;

  static const double _barHeight = 6;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fill = color ?? context.gameColors.timerFill;
    final timing = context.read<ActionTimingController>();

    return AnimatedBuilder(
      animation: timing,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: HearthText.activityLabel.copyWith(color: fill),
                ),
              ),
              const SizedBox(width: 8),
              ActionTimeChip(duration: interval()),
            ],
          ),
          const SizedBox(height: 6),
          FillBar(
            value: progress(),
            height: _barHeight,
            borderRadius: _barHeight / 2,
            backgroundColor: palette.track,
            foregroundColor: fill,
          ),
        ],
      ),
    );
  }
}
