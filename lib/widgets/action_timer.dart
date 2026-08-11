import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/action_timing_controller.dart';
import 'fill_bar.dart';

/// The width every encounter row's label sits in, so the bars below the
/// labels all start on the same x — on the combat screen, the gathering
/// screen and the explore screen alike.
const double kEncounterRowLabelWidth = 58;

/// Who an [ActionTimer] belongs to. The two are drawn identically; only the
/// fill hue differs, so a glance reads which timer is which without reading
/// either one as more important than the other.
enum ActionTimerActor {
  /// The player's own action loop. Lilac, matching the banner's boost bar.
  player,

  /// A hostile entity winding up its swing. Amber, against combat's red.
  enemy,
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

  /// How long this screen's action takes, shown on the chip and sampled per
  /// frame so it follows stance, boost and gear changes mid-action.
  final Duration Function() interval;

  /// A hairline, not a headline: the same height for both actors.
  static const double _barHeight = 5;
  static const double _barRadius = 3;

  /// Gap between the bar and the interval chip.
  static const double _gap = 7;

  static const Color _trackColor = Color(0xFF27212B);
  static const Color _playerFill = Color(0xFFC2A7F4);
  static const Color _enemyFill = Color(0xFFEBA941);

  static const Color _chipTextColor = Color(0xFFA8A1AE);
  static const Color _chipBackgroundColor = Color(0xFF211D24);

  Color get _fillColor =>
      actor == ActionTimerActor.enemy ? _enemyFill : _playerFill;

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: _trackColor,
              foregroundColor: _fillColor,
            ),
          ),
          const SizedBox(width: _gap),
          _IntervalChip(interval: interval()),
        ],
      ),
    );
  }
}

/// The interval the bar is currently filling over, beside the bar it belongs
/// to. Monospaced and fixed to two decimals so the digits don't jitter as the
/// boost moves the interval underneath it.
class _IntervalChip extends StatelessWidget {
  const _IntervalChip({required this.interval});

  final Duration interval;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ActionTimer._chipBackgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          '${(interval.inMilliseconds / 1000).toStringAsFixed(2)}s',
          style: const TextStyle(
            fontSize: 9,
            fontFamily: 'monospace',
            fontFamilyFallback: ['Menlo', 'Courier New'],
            color: ActionTimer._chipTextColor,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// Who a row belongs to, in the fixed-width slot every encounter row starts
/// with so the bars and rings below it all line up on the same x.
///
/// The column is a fixed width and the label is held to one line inside it:
/// a long one ('Exploring') shrinks to fit rather than wrapping, which would
/// make its row taller than the rows it is supposed to line up with.
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
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }
}

/// An action timer as a row of its own, for a screen with no target and no
/// health to hang it under — explore, where the timer is the only bar there
/// is. Same label column as the combat and gathering rows, so the three
/// screens' timers land in the same place.
class ActionTimerRow extends StatelessWidget {
  const ActionTimerRow({
    super.key,
    required this.label,
    required this.progress,
    required this.interval,
    this.actor = ActionTimerActor.player,
  });

  final String label;
  final double Function() progress;
  final Duration Function() interval;
  final ActionTimerActor actor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        EncounterRowLabel(label),
        Expanded(
          child: ActionTimer(
            actor: actor,
            progress: progress,
            interval: interval,
          ),
        ),
      ],
    );
  }
}
