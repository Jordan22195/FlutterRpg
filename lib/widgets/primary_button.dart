import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  static const double _lockDragThresholdPx = 24.0;

  bool _lockTriggeredThisDrag = false;

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
        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          // Tap toggles lock state when locked; otherwise it behaves like the
          // normal momentum press interaction.
          onTapDown: (_) {
            if (!widget.enabled) return;
            if (locked) {
              controller.unlockActionSpeed();
              return;
            }
            controller.onPrimaryButtonPressed();
            widget.startActionFunction();
          },
          onTapUp: (_) {},

          // Drag up to lock: once the user drags upward past a threshold,
          // execute once immediately and lock the button.
          onPanStart: (_) {
            _lockTriggeredThisDrag = false;
          },
          onPanUpdate: (details) {
            if (!widget.enabled) return;
            if (locked) return;
            if (_lockTriggeredThisDrag) return;

            if (details.delta.dy <= -_lockDragThresholdPx) {
              _lockTriggeredThisDrag = true;
              controller.lockActionSpeed();
            }
          },
          onPanEnd: (_) {
            _lockTriggeredThisDrag = false;
          },

          // button container
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.label, style: const TextStyle(color: Colors.white)),
                if (locked) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.lock, size: 16, color: Colors.white),
                ],
              ],
            ),
          ),
        );
      },
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
          controller.stop();
        },
      ),
    );
  }
}
