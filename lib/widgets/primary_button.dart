import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/action_queue_controller.dart';
import '../controllers/action_timing_controller.dart';

/// Height shared by every control in the action bar. The primary button and
/// the fixed-width side buttons flanking it all sit at this height, so the
/// bar reads as one row of keys.
const double kActionBarButtonHeight = 62.0;

/// Footprint of a side button (stop on the left, eat on the right). Both are
/// this size, and the primary button takes whatever is left between them.
const double kActionBarSideButtonWidth = 76.0;

class MomentumPrimaryButton extends StatefulWidget {
  const MomentumPrimaryButton({
    required this.enabled,
    super.key,
    required this.label,
    required this.startActionFunction,
  });

  final FutureOr<void> Function() startActionFunction;
  final bool enabled;
  final String label;

  @override
  State<MomentumPrimaryButton> createState() => _MomentumPrimaryButtonState();
}

class _MomentumPrimaryButtonState extends State<MomentumPrimaryButton> {
  // the button stretches to fill the middle of the action bar; only its
  // height is fixed, so nothing shifts when the lock icon appears or the
  // play/fast-forward icon swaps out. it is the one control the player
  // holds down for minutes at a time, so it gets the widest target.
  static const double _buttonHeight = kActionBarButtonHeight;
  static const double _iconSize = 34.0;

  // how far up the button has to be dragged to commit the speed lock. the
  // drag has no visual of its own: the lock icon on the face is what says
  // it landed.
  static const double _lockDragDistance = 20.0;

  // how tall the base lip under the button face is. this is the distance the
  // face travels when pressed: it sinks until it sits flush on the base.
  static const double _pressDepth = 6.0;

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

            // button container. a disabled button keeps its footprint and
            // greys out, so the action bar doesn't reflow when the action
            // becomes available again
            child: Opacity(
              opacity: widget.enabled ? 1.0 : 0.35,
              child: RaisedSurface(
                pressed: _pressed,
                height: _buttonHeight,
                depth: _pressDepth,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
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
                          : Icons.play_arrow,
                      size: _iconSize,
                    ),
                    if (locked) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.lock, size: 18, color: Colors.white),
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

/// The row of controls at the bottom of an action screen: the stop button
/// anchored to the left edge, any screen-specific controls anchored to the
/// right, and the primary button filling everything between them.
///
/// Both side slots keep their fixed footprint whether or not anything is in
/// them — the stop button only renders while an action runs, and a screen
/// with no trailing control still reserves the slot — so the primary button
/// stays centred on every screen and never changes width mid-action.
class ActionButtonRow extends StatelessWidget {
  const ActionButtonRow({
    super.key,
    required this.actionButton,
    this.trailing = const <Widget>[],
  });

  final Widget actionButton;

  /// Screen-specific controls for the right slot, such as the eat button on
  /// a combat encounter.
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // left anchor: the stop button's slot, held open while idle
          const SizedBox(
            width: kActionBarSideButtonWidth,
            child: StopPrimaryButton(),
          ),
          const SizedBox(width: 10),

          Expanded(child: actionButton),

          // right anchor: screen-specific controls, each the same footprint
          // as the stop button. a screen with none still reserves one slot,
          // so the two sides stay symmetric and the primary button sits
          // centred on every screen rather than sliding right
          if (trailing.isEmpty)
            const SizedBox(width: 10 + kActionBarSideButtonWidth)
          else
            for (final control in trailing) ...[
              const SizedBox(width: 10),
              SizedBox(width: kActionBarSideButtonWidth, child: control),
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
    this.depth = 6.0,
    this.radius = 18.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  });

  final bool pressed;
  final double height;
  final double depth;
  final double radius;
  final Color color;
  final EdgeInsets padding;
  final Widget child;

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
          // the base. only the strip below the face is ever visible, and a
          // press swallows it.
          Positioned.fill(
            child: AnimatedContainer(
              duration: duration,
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                color: _shade(color, -0.17),
                borderRadius: BorderRadius.circular(radius),
                // the cast shortens with the travel, the way a real key's does
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: pressed ? 0.14 : 0.3),
                    blurRadius: pressed ? 3 : 8,
                    offset: Offset(0, pressed ? 1 : 3),
                  ),
                ],
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
                borderRadius: BorderRadius.circular(radius),
                // lit from above when raised, flattening out once it's down
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_shade(color, pressed ? -0.03 : 0.07), color],
                ),
                border: Border.all(color: _shade(color, 0.1), width: 1),
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
  // the same height as the primary button it sits beside, so the action bar
  // reads as one row of controls
  static const double _height = kActionBarButtonHeight;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ActionTimingController>();
    if (!controller.isRunning) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;

    return Listener(
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
        child: RaisedSurface(
          pressed: _pressed,
          height: _height,
          color: scheme.errorContainer,
          radius: 14,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Center(
            child: Icon(Icons.stop, size: 28, color: scheme.onErrorContainer),
          ),
        ),
      ),
    );
  }
}
