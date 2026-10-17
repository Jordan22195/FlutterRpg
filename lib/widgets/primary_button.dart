import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/action_queue_controller.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/player_data_controller.dart';
import '../controllers/world_controller.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// Height shared by every control in the action bar. The primary button's
/// face and the side buttons flanking it all sit at this height, so the bar
/// reads as one row of keys; the primary button's lip hangs below it.
const double kActionBarButtonHeight = 52.0;

/// The primary button's lip: how far its face sits above the base, and how
/// far it travels when pressed.
const double kActionBarLip = 4.0;

/// Footprint of the stop button on the left: a square.
const double kActionBarSideButtonWidth = 52.0;

/// Footprint of a screen-specific control on the right, such as Eat.
const double kActionBarTrailingWidth = 92.0;

class MomentumPrimaryButton extends StatefulWidget {
  const MomentumPrimaryButton({
    required this.enabled,
    super.key,
    required this.label,
    required this.startActionFunction,
    this.color,
    this.idleIcon,
    this.showLabel = false,
  });

  final FutureOr<void> Function() startActionFunction;

  /// Draw [label] on the face between the icon and the lock. A station's
  /// button names its action ("Light Fire"), since which action it runs is
  /// the point of the screen; elsewhere the icon says enough.
  final bool showLabel;
  final bool enabled;
  final String label;

  /// The face colour. Defaults to the zone's accent — the one place the
  /// accent appears; travel passes its own blue, which is the whole tell
  /// that the button will walk you somewhere rather than work what's in
  /// front of you.
  final Color? color;

  /// What the face shows at rest. Defaults to play; travel walks instead.
  /// Held, every button shows fast-forward — the boost works the same way
  /// whatever is being boosted.
  final IconData? idleIcon;

  @override
  State<MomentumPrimaryButton> createState() => _MomentumPrimaryButtonState();
}

class _MomentumPrimaryButtonState extends State<MomentumPrimaryButton> {
  // the button stretches to fill the middle of the action bar; only its
  // height is fixed, so nothing shifts when the lock icon appears or the
  // play/fast-forward icon swaps out. it is the one control the player
  // holds down for minutes at a time, so it gets the widest target.
  static const double _buttonHeight = kActionBarButtonHeight + kActionBarLip;
  static const double _iconSize = 28.0;

  // how far up the button has to be dragged to commit the speed lock. the
  // drag has no visual of its own: the lock icon on the face is what says
  // it landed.
  static const double _lockDragDistance = 20.0;

  // how tall the base lip under the button face is. this is the distance the
  // face travels when pressed: it sinks until it sits flush on the base.
  static const double _pressDepth = kActionBarLip;

  bool _lockTriggeredThisDrag = false;

  /// Whether a finger is currently on the button. Driven by raw pointer
  /// events rather than the recognizers below: a tap competing in the arena
  /// doesn't report onTapDown until the 100ms deadline, and the face has to
  /// sink the instant it's touched or the press doesn't feel connected.
  bool _fingerDown = false;

  /// The face sits down while a finger is on it, and stays down while the
  /// speed lock is engaged: the lock is a latch, so the button reads as
  /// held rather than merely pressed.
  bool get _pressed => widget.enabled && (_fingerDown || _latched);

  /// Mirror of the controller's speed lock, refreshed in build. It only feeds
  /// the resting depth of the face, and the controller rebuilds us whenever it
  /// changes, so it needs no setState of its own.
  bool _latched = false;

  void _setFingerDown(bool down) {
    if (_fingerDown == down) return;
    final was = _pressed;
    _fingerDown = down;
    if (_pressed != was) {
      // the tick under the finger, so the travel is felt as well as seen
      if (_pressed) HapticFeedback.lightImpact();
      setState(() {});
    }
  }

  /// Finger down: start the action if nothing is running yet, then boost it
  /// for as long as the finger stays put.
  ///
  /// Touching a locked button releases the lock, and the press then carries
  /// on as any other press does: unlocking only clears the flag, so the boost
  /// picks up from wherever the lock was holding it, keeps building while the
  /// finger stays down, and falls once it comes off.
  void _onPressed(ActionTimingController controller, bool locked) {
    if (!widget.enabled) return;
    _setFingerDown(true);

    if (locked) {
      controller.unlockActionSpeed();
    }
    // the action function has to be bound before the boost can build on it
    // rebind everytime you press the button to catch new action if the screen changes.
    widget.startActionFunction();
    controller.onPrimaryButtonPressed();
  }

  /// Finger up: the action keeps running, but nothing is feeding the boost
  /// any more, so the speed bar falls back on its own. Stopping outright is
  /// the stop button's job.
  void _onReleased(ActionTimingController controller) {
    _setFingerDown(false);
    _onDragEnd();
    controller.onPrimaryButtonReleased();
  }

  /// Cumulative drag distance for the pan path, which only reports deltas.
  double _panDy = 0.0;

  /// Watches the drag for both paths. [dy] is cumulative displacement from
  /// where the press started, negative upward, so a slow drag works as well
  /// as a flick. Dragging up past [_lockDragDistance] commits the lock; the
  /// button itself never moves.
  void _onDragTo(ActionTimingController controller, double dy) {
    if (!widget.enabled) return;
    if (controller.getActionSpeedLockState()) return;
    if (_lockTriggeredThisDrag) return;
    if (dy > -_lockDragDistance) return;

    // far enough up: commit the lock. a drag that never pressed long enough
    // to start anything still needs something running for the lock to hold
    // onto.
    _lockTriggeredThisDrag = true;
    if (!controller.isRunning) {
      widget.startActionFunction();
    }
    controller.lockActionSpeed();
  }

  /// Ends a drag. Called on release from both the pan recognizer and the
  /// pointer handler, since a gesture that never travelled far enough to
  /// become a pan still has to clear the drag state.
  void _onDragEnd() {
    _lockTriggeredThisDrag = false;
    _panDy = 0.0;
  }

  // a 'start' action is bound to the button. The start action
  // action is specific to the aciton that is being performed
  // (explore, ecounter, craft, ect). The start action that is
  // bound to the button checks the conditions for the action,
  // binds the actualy action method to the action controller
  // loop and starts the periodc action controller.

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ActionTimingController>();
    final locked = controller.getActionSpeedLockState();
    _latched = locked;

    // the accent is the zone's, and this is the only place it is used. a
    // disabled button is a plain surface with no lip, so it reads as not
    // there yet rather than as a dimmed version of the live one
    final palette = context.palette;
    final custom = widget.color;
    final Color face;
    final Color lip;
    final Color content;
    if (!widget.enabled) {
      face = palette.surface;
      lip = Colors.transparent;
      content = palette.textMuted;
    } else if (custom == null) {
      face = palette.accent;
      lip = palette.accentLip;
      content = palette.onAccent;
    } else {
      face = custom;
      lip = _shade(custom, -0.2);
      content = palette.bg;
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // the face tracks the finger itself, ahead of any recognizer
        // claiming the gesture, so the button is down the moment it is
        // touched and back up the moment it is let go
        return Listener(
          // press and release drive the whole interaction, straight off the
          // raw pointer: pressing down starts the action and begins the
          // boost, and letting go lets the boost fall. there is no hold
          // timer to wait out.
          onPointerDown: (_) => _onPressed(controller, locked),
          onPointerUp: (_) => _onReleased(controller),
          onPointerCancel: (_) => _onReleased(controller),
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              // Drag up to lock: dragging the button upward holds the boost
              // after the finger comes off. The gesture is invisible — the
              // lock icon on the face is the only thing that reports it.
              PanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                    () => PanGestureRecognizer(debugOwner: this),
                    (recognizer) {
                      recognizer
                        ..onStart = (_) {
                          _lockTriggeredThisDrag = false;
                          _panDy = 0.0;
                        }
                        ..onUpdate = (details) {
                          _panDy += details.delta.dy;
                          _onDragTo(controller, _panDy);
                        }
                        ..onEnd = (_) {
                          _onDragEnd();
                        }
                        ..onCancel = () {
                          _onDragEnd();
                        };
                    },
                  ),
            },

            // button container. a disabled button keeps its footprint but
            // drops to a plain surface with no lip, so the action bar
            // doesn't reflow when the action becomes available again
            child: Semantics(
              button: true,
              enabled: widget.enabled,
              label: locked ? '${widget.label}, locked' : widget.label,
              excludeSemantics: true,
              child: RaisedSurface(
                pressed: _pressed,
                height: _buttonHeight,
                depth: _pressDepth,
                color: face,
                lipColor: lip,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                // the button fills the middle of the bar, so the icons
                // center in it
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // holding the button boosts the speed, so the icon shows
                    // fast forward for as long as the hold lasts. the button
                    // no longer stops anything, so it never shows a pause.
                    Icon(
                      controller.isButtonHeld || locked
                          ? Icons.fast_forward
                          : (widget.idleIcon ?? Icons.play_arrow),
                      size: _iconSize,
                      color: content,
                    ),
                    if (widget.showLabel) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HearthText.rowTitle.copyWith(
                            fontWeight: FontWeight.w800,
                            color: content,
                          ),
                        ),
                      ),
                    ],
                    if (locked) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.lock, size: 18, color: content),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The screen's own action button, or a travel button when the screen is
/// showing somewhere the player isn't standing.
///
/// This is the whole of how travel is started. A zone screen reached through
/// the map's Enter can be a place you have not walked to yet, and there is
/// nothing to work there until you have — so the purple button is replaced
/// rather than disabled, and the thing it offers instead is the trip.
///
/// A screen passes the same action it always passes and never learns that
/// travelling exists. The trip does not take that action with it: arriving
/// puts the player here and stops, and the button — purple again, because
/// this is now where they are standing — is what starts the work.
class ActionOrTravelButton extends StatelessWidget {
  const ActionOrTravelButton({
    super.key,
    required this.enabled,
    required this.label,
    required this.startActionFunction,
    this.showLabel = false,
  });

  final FutureOr<void> Function() startActionFunction;
  final bool enabled;
  final String label;

  /// See [MomentumPrimaryButton.showLabel]. The travel button always names
  /// itself by its walking icon alone.
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final world = context.watch<WorldController>();
    // stamina decides whether the trip can be afforded, and it moves every
    // frame, so the button has to be re-priced as it does
    context.watch<PlayerDataController>();

    if (world.isViewingCurrentZone) {
      return MomentumPrimaryButton(
        enabled: enabled,
        label: label,
        startActionFunction: startActionFunction,
        showLabel: showLabel,
      );
    }

    final target = world.viewedZoneId;
    return MomentumPrimaryButton(
      // a trip already under way keeps the button live, so holding it keeps
      // boosting the walk; otherwise it greys out until the stamina is there
      enabled: world.travelTarget == target || world.canTravelTo(target),
      label: 'Travel',
      color: context.gameColors.travel,
      idleIcon: Icons.directions_walk,
      startActionFunction: () => world.startTravelTo(target),
    );
  }
}

/// The row of controls at the bottom of an action screen: the stop button
/// anchored to the left edge, any screen-specific controls anchored to the
/// right, and the primary button filling everything between them.
///
/// The stop slot keeps its footprint whether or not the button is showing —
/// it only renders while an action runs — so the primary button never
/// changes width mid-action.
class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({
    super.key,
    required this.actionButton,
    this.trailing = const <Widget>[],
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 12),
    this.trailingWidth = kActionBarTrailingWidth,
  });

  /// The width each trailing control gets: Eat's 92 by default, or a
  /// square for an icon-only control.
  final double trailingWidth;

  final Widget actionButton;

  /// Room around the row. A screen that puts the row in an action dock
  /// passes zero and lets the dock pad it.
  final EdgeInsets padding;

  /// Screen-specific controls for the right slot, such as the eat button on
  /// a combat encounter.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        // tops aligned: the primary button's lip hangs below the row of faces
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // left anchor: the stop button's slot, held open while idle so the
          // primary button never changes width as an action starts
          const SizedBox(
            width: kActionBarSideButtonWidth,
            height: kActionBarButtonHeight,
            child: StopPrimaryButton(),
          ),
          const SizedBox(width: 10),

          Expanded(child: actionButton),

          // right anchor: screen-specific controls such as Eat
          for (final control in trailing) ...[
            const SizedBox(width: 10),
            SizedBox(width: trailingWidth, child: control),
          ],
        ],
      ),
    );
  }
}

/// Nudges a colour's lightness, so a raised button derives its base and
/// highlight from whatever container colour it is given.
Color _shade(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

/// A button face floating [depth] above a solid base block, which is what
/// gives the action-bar buttons their physical travel. Pressing sinks the
/// face onto the base, closing the lip and pulling in the drop shadow, so it
/// reads as a key being pushed down rather than a rectangle changing colour.
///
/// Takes [height] rather than sizing to its child: the face has to be shorter
/// than the whole control by exactly the lip it sits on.
class RaisedSurface extends StatelessWidget {
  const RaisedSurface({
    super.key,
    required this.pressed,
    required this.height,
    required this.color,
    required this.child,
    this.depth = kActionBarLip,
    this.radius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.lipColor,
  });

  final bool pressed;
  final double height;
  final double depth;
  final double radius;
  final Color color;
  final EdgeInsets padding;
  final Widget child;

  /// The base showing below the face. Defaults to a darker shade of
  /// [color]; the primary button passes its zone's accent lip.
  final Color? lipColor;

  // the face drops fast and springs back a touch slower, which is what makes
  // the travel read as a real button rather than a colour swap
  static const Duration _downDuration = Duration(milliseconds: 45);
  static const Duration _upDuration = Duration(milliseconds: 110);

  @override
  Widget build(BuildContext context) {
    final duration = pressed ? _downDuration : _upDuration;

    return SizedBox(
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // the base: a hard lip with no blur. only the strip below the
          // face is ever visible, and a press swallows it.
          Positioned.fill(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: lipColor ?? _shade(color, -0.17),
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),

          AnimatedPositioned(
            duration: duration,
            // a hair of overshoot on the way up sells the spring back
            curve: pressed ? Curves.easeIn : Curves.easeOutBack,
            top: pressed ? depth : 0,
            left: 0,
            right: 0,
            height: height - depth,
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              padding: padding,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(radius),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

/// Stops whatever action is running. The primary button only ever starts and
/// boosts, so this is the one way to end an action.
///
/// It renders nothing at all while nothing is running, so screens can drop it
/// into the action bar unconditionally and it appears with the action.
class StopPrimaryButton extends StatefulWidget {
  const StopPrimaryButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<StopPrimaryButton> createState() => _StopPrimaryButtonState();
}

class _StopPrimaryButtonState extends State<StopPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ActionTimingController>();
    if (!controller.isRunning) return const SizedBox.shrink();

    final palette = context.palette;

    // deliberately quiet: a plain surface with a small square, so stopping
    // is always there without the bar reading as a warning
    return Semantics(
      button: true,
      label: 'Stop',
      excludeSemantics: true,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            // a user stop cancels the action queue too; otherwise the
            // queue would treat the stop as a finished task and advance
            context.read<ActionQueueController>().stopQueue();
            controller.stop();
            widget.onTap?.call();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: kActionBarSideButtonWidth,
            height: kActionBarButtonHeight,
            decoration: BoxDecoration(
              color: _pressed ? palette.raised : palette.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: palette.borderStrong),
            ),
            alignment: Alignment.center,
            // the rounded glyph's square is half its box: 16pt, radius ~3
            child: Icon(
              Icons.stop_rounded,
              size: 32,
              color: context.gameColors.stop,
            ),
          ),
        ),
      ),
    );
  }
}
