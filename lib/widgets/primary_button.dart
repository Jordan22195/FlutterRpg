import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../controllers/action_queue_controller.dart';
import '../controllers/action_timing_controller.dart';

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
  // fixed size so the button doesn't resize when the lock icon appears
  // or the play/pause/fast-forward icon swaps out. it is the one control
  // the player holds down for minutes at a time, so it is sized to be an
  // easy thumb target at the centre of the action bar.
  static const double _buttonWidth = 168.0;
  // icon plus padding either side, plus the base lip the face sits on and
  // slack so a larger icon theme can't overflow the fixed box
  static const double _buttonHeight = 76.0;
  static const double _iconSize = 34.0;

  // how far above the button the empty lock slot sits. this doubles as the
  // drag distance: dragging the button the full offset seats it in the slot
  // and commits the lock.
  static const double _lockSlotOffset = 20.0;

  // how quickly the button springs back down when a drag is abandoned
  static const Duration _snapDuration = Duration(milliseconds: 160);

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

  /// How far the button has been dragged from its resting spot, negative
  /// upward, clamped to the slot offset. Zero whenever no drag is in flight.
  double _dragOffsetY = 0.0;

  /// Cumulative drag distance for the pan path, which only reports deltas.
  double _panDy = 0.0;

  /// True while a finger is dragging, so the slide tracks 1:1 instead of
  /// animating behind the finger.
  bool _dragging = false;

  /// Drives the slide for both drag paths. [dy] is cumulative displacement
  /// from where the press started, so a slow drag works as well as a flick.
  void _onDragTo(ActionTimingController controller, double dy) {
    if (!widget.enabled) return;
    if (controller.getActionSpeedLockState()) return;
    if (_lockTriggeredThisDrag) return;

    final offset = dy.clamp(-_lockSlotOffset, 0.0);

    // seated in the slot: commit the lock. a drag that never pressed long
    // enough to start anything still needs something running for the lock
    // to hold onto.
    if (offset <= -_lockSlotOffset) {
      _lockTriggeredThisDrag = true;
      if (!controller.isRunning) {
        widget.startActionFunction();
      }
      controller.lockActionSpeed();
      // the button stays seated in the slot under the finger. it only
      // springs back down to rest once the finger comes off, in _onDragEnd,
      // so the lock lands where you put it rather than snapping away
      // mid-gesture.
      setState(() => _dragOffsetY = -_lockSlotOffset);
      return;
    }

    if (offset != _dragOffsetY) {
      setState(() => _dragOffsetY = offset);
    }
  }

  /// Ends a drag: wherever the button was left, including seated in the lock
  /// slot, it springs back down to rest. Called on release from both the pan
  /// recognizer and the pointer handler, since a gesture that never travelled
  /// far enough to become a pan still has to put the button back.
  void _onDragEnd() {
    _lockTriggeredThisDrag = false;
    _panDy = 0.0;
    setState(() {
      _dragging = false;
      _dragOffsetY = 0.0;
    });
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
        // the button rides in a stack under an empty slot: dragging it up
        // seats it in the slot and locks the speed there.
        return SizedBox(
          width: _buttonWidth,
          height: _buttonHeight + _lockSlotOffset,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // nothing to lock when the action can't be taken at all, and
              // nothing to drag into once the lock is committed
              if (widget.enabled && !locked)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _buttonHeight,
                  child: _buildLockSlot(context),
                ),

              AnimatedPositioned(
                // 1:1 with the finger while dragging, eased when springing
                // back. committing the lock springs it back too: the button
                // rests where it always does and the lock icon on its face
                // is what says the speed is held
                duration: _dragging ? Duration.zero : _snapDuration,
                curve: Curves.easeOut,
                top: _lockSlotOffset + _dragOffsetY,
                left: 0,
                right: 0,
                height: _buttonHeight,
                // the face tracks the finger itself, ahead of any recognizer
                // claiming the gesture, so the button is down the moment it
                // is touched and back up the moment it is let go
                child: Listener(
                  // press and release drive the whole interaction, straight
                  // off the raw pointer: pressing down starts the action and
                  // begins the boost, and letting go lets the boost fall.
                  // there is no hold timer to wait out.
                  onPointerDown: (_) => _onPressed(controller, locked),
                  onPointerUp: (_) => _onReleased(controller),
                  onPointerCancel: (_) => _onReleased(controller),
                  child: RawGestureDetector(
                    behavior: HitTestBehavior.opaque,
                    gestures: <Type, GestureRecognizerFactory>{
                      // Drag up to lock: the button follows the finger toward the empty
                      // slot above it and stays seated there once it commits the lock,
                      // so the boost holds after the finger comes off.
                      PanGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            PanGestureRecognizer
                          >(() => PanGestureRecognizer(debugOwner: this), (
                            recognizer,
                          ) {
                            recognizer
                              ..onStart = (_) {
                                _lockTriggeredThisDrag = false;
                                _panDy = 0.0;
                                _dragging = true;
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
                          }),
                    },

                    // button container. a disabled button keeps its footprint
                    // and greys out, so the action bar doesn't reflow when the
                    // action becomes available again
                    child: Opacity(
                      opacity: widget.enabled ? 1.0 : 0.35,
                      child: RaisedSurface(
                        pressed: _pressed,
                        height: _buttonHeight,
                        depth: _pressDepth,
                        color: Theme.of(context).colorScheme.primaryContainer,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 16,
                        ),
                        // the button is a fixed width, so the icons center in it
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
                              const Icon(
                                Icons.lock,
                                size: 18,
                                color: Colors.white,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The empty slot the button drags up into. Its lock icon sits in the strip
  /// left exposed above the button. Once the lock commits the slot is gone
  /// and the button drops back to rest.
  Widget _buildLockSlot(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.primaryContainer.withValues(alpha: 0.55),
          width: 1.5,
        ),
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Icon(
            Icons.lock,
            size: 14,
            color: scheme.onSurface.withValues(alpha: 0.45),
          ),
        ),
      ),
    );
  }
}

/// The row of controls at the bottom of an action screen: the primary button
/// centred, the stop button to its left, and any screen-specific controls to
/// its right.
///
/// The two side slots are equal-width flexes, so the primary button holds the
/// centre of the row whatever the sides happen to be showing — including the
/// stop button appearing and disappearing with the action. Everything is
/// bottom aligned, so the controls line up along one baseline even though the
/// primary button carries the taller lock slot above it.
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
          Expanded(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: const StopPrimaryButton(),
              ),
            ),
          ),

          actionButton,

          Expanded(
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: trailing,
                ),
              ),
            ),
          ),
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
  // shorter than the primary button, and bottom aligned against it, so the
  // action bar reads as one row of controls with the big one at the centre
  static const double _height = 56.0;
  static const double _width = 72.0;

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
        child: SizedBox(
          width: _width,
          child: RaisedSurface(
            pressed: _pressed,
            height: _height,
            color: scheme.errorContainer,
            radius: 14,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Icon(Icons.stop, size: 26, color: scheme.onErrorContainer),
          ),
        ),
      ),
    );
  }
}
