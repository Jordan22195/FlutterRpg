import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  // or the play/pause/fast-forward icon swaps out
  static const double _buttonWidth = 120.0;
  // 24px icon + 14px padding either side, plus slack so a larger icon
  // theme can't overflow the fixed box
  static const double _buttonHeight = 56.0;

  // how far above the button the empty lock slot sits. this doubles as the
  // drag distance: dragging the button the full offset seats it in the slot
  // and commits the lock.
  static const double _lockSlotOffset = 30.0;

  // how long the button must be held before the momentum boost kicks in.
  // GestureDetector hardcodes kLongPressTimeout (500ms), which felt sluggish,
  // so the recognizers are built by hand below to set this.
  static const Duration _longPressDuration = Duration(milliseconds: 200);

  // how quickly the button springs back down when a drag is abandoned
  static const Duration _snapDuration = Duration(milliseconds: 160);

  bool _lockTriggeredThisDrag = false;

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

    // seated in the slot: commit the lock. a drag that beat the hold timer
    // may never have started the action, so make sure something is running
    // for the lock to hold onto.
    if (offset <= -_lockSlotOffset) {
      _lockTriggeredThisDrag = true;
      if (!controller.isRunning) {
        widget.startActionFunction();
      }
      controller.lockActionSpeed();
      setState(() => _dragOffsetY = 0.0);
      return;
    }

    if (offset != _dragOffsetY) {
      setState(() => _dragOffsetY = offset);
    }
  }

  /// Ends a drag from either path: the button falls back to rest unless the
  /// lock caught it on the way up.
  void _onDragEnd(ActionTimingController controller) {
    _lockTriggeredThisDrag = false;
    _panDy = 0.0;
    setState(() {
      _dragging = false;
      _dragOffsetY = 0.0;
    });
    controller.onPrimaryButtonReleased();
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
              // nothing to lock when the action can't be taken at all
              if (widget.enabled)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: _buttonHeight,
                  child: _buildLockSlot(context),
                ),

              AnimatedPositioned(
                // 1:1 with the finger while dragging, eased when springing
                // back or settling into the slot
                duration: _dragging ? Duration.zero : _snapDuration,
                curve: Curves.easeOut,
                top: locked ? 0.0 : _lockSlotOffset + _dragOffsetY,
                left: 0,
                right: 0,
                height: _buttonHeight,
                child: RawGestureDetector(
                  behavior: HitTestBehavior.opaque,
                  gestures: <Type, GestureRecognizerFactory>{
                    // Tap toggles lock state when locked; otherwise it behaves like the
                    // normal momentum press interaction: a tap starts the action at
                    // the idle rate, and only an ongoing HOLD boosts the speed.
                    TapGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          TapGestureRecognizer
                        >(() => TapGestureRecognizer(debugOwner: this), (
                          recognizer,
                        ) {
                          recognizer.onTapDown = (_) {
                            if (!widget.enabled) return;
                            if (locked) {
                              controller.unlockActionSpeed();
                              return;
                            }
                            if (controller.isRunning) {
                              controller.stop();
                            } else {
                              widget.startActionFunction();
                            }
                          };
                        }),

                    LongPressGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          LongPressGestureRecognizer
                        >(
                          () => LongPressGestureRecognizer(
                            debugOwner: this,
                            duration: _longPressDuration,
                          ),
                          (recognizer) {
                            recognizer
                              // start the momentum loop and accelerate the actions
                              ..onLongPress = () {
                                if (!widget.enabled) return;
                                // the action function needs to be bound first
                                if (!controller.isRunning) {
                                  widget.startActionFunction();
                                }
                                controller.onPrimaryButtonPressed();
                              }
                              // the hold wins the arena before the pan recognizer
                              // ever sees a move, so dragging up out of a hold has
                              // to be handled here as well as in onUpdate below
                              ..onLongPressMoveUpdate = (details) {
                                _dragging = true;
                                _onDragTo(
                                  controller,
                                  details.localOffsetFromOrigin.dy,
                                );
                              }
                              // declerate the actions
                              ..onLongPressEnd = (_) {
                                _onDragEnd(controller);
                              };
                          },
                        ),

                    // Drag up to lock: the button follows the finger toward the empty
                    // slot above it, and seating it there commits the lock. This is
                    // the path for a drag that starts before the hold timer fires.
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
                              // lifting the finger after a drag also ends the hold
                              _onDragEnd(controller);
                            };
                        }),
                  },

                  // button container. a disabled button keeps its footprint
                  // and greys out, so the action bar doesn't reflow when the
                  // action becomes available again
                  child: Opacity(
                    opacity: widget.enabled ? 1.0 : 0.35,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        // the button is a fixed width, so the icons center in it
                        alignment: Alignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // holding the button boosts the speed, so the icon shows
                              // fast forward for as long as the hold lasts
                              if (controller.isButtonHeld)
                                Icon(Icons.fast_forward)
                              else if (controller.isRunning)
                                Icon(Icons.pause)
                              else
                                Icon(Icons.play_arrow),
                              if (locked) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.lock,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ],
                            ],
                          ),

                          // corner hint that holding the button fast forwards. it drops
                          // away during the hold, when the main icon says the same thing.
                          if (!controller.isButtonHeld)
                            Positioned(
                              top: -9,
                              right: -9,
                              child: Icon(
                                Icons.fast_forward,
                                size: 12,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.55),
                              ),
                            ),
                        ],
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
  /// left exposed above the button, so it stays visible until the button
  /// slides up and fills the outline.
  Widget _buildLockSlot(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
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

class StopPrimaryButton extends StatelessWidget {
  const StopPrimaryButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  // builds a stop button for the action button.
  // when pressed it clear the app bar icon and stops
  // the timing controller.
  //
  // the onTap parameter can be used to add more functinality.
  Widget build(BuildContext context) {
    final controller = context.watch<ActionTimingController>();

    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextButton(
        child: Text("Stop"),
        onPressed: () {
          // a user stop cancels the action queue too; otherwise the
          // queue would treat the stop as a finished task and advance
          context.read<ActionQueueController>().stopQueue();
          controller.stop();
          onTap?.call();
        },
      ),
    );
  }
}
