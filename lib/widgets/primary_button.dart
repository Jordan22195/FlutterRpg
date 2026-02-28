import 'dart:async';

import 'package:flutter/material.dart';
import 'package:rpg/widgets/progress_bars.dart';
import '../controllers/momentum_loop_controller.dart';
import '../controllers/player_data_controller.dart';
import '../widgets/item_stack_tile.dart';
import '../data/item.dart';

class MomentumPrimaryButton extends StatefulWidget {
  const MomentumPrimaryButton({
    required this.enabled,
    super.key,
    required this.label,
    required this.controller,
    required this.onFireFunction,
    required this.appBarTile,
    required this.maxInterval,
  });

  final Duration maxInterval;

  final FutureOr<void> Function() onFireFunction;
  final bool enabled;
  final String label;
  final MomentumLoopController controller;
  final Widget appBarTile;

  @override
  State<MomentumPrimaryButton> createState() => _MomentumPrimaryButtonState();
}

class _MomentumPrimaryButtonState extends State<MomentumPrimaryButton> {
  static const double _lockDragThresholdPx = 24.0;

  bool _locked = false;
  bool _lockTriggeredThisDrag = false;

  void _populateAppBarIconIfNeeded() {
    if (widget.appBarTile is ItemStackTile) {
      final tile = widget.appBarTile as ItemStackTile;
      ProgressBars.iconId = tile.id ?? Items.NULL;
      ProgressBars.iconCount = tile.count;
      ProgressBars.iconIsTimer = tile.isTimerStackTile;
      ProgressBars.iconTimerEnd = tile.expirationTime;
    }
  }

  void _unlock() {
    widget.controller.pressUp();
    widget.controller.speedLocked = false;
    setState(() {
      _locked = false;
    });
  }

  void _startPressed() {
    _populateAppBarIconIfNeeded();
    widget.controller.onFire = widget.onFireFunction;
    widget.controller.pressDown();
  }

  Future<void> _lockAndFireOnce() async {
    _populateAppBarIconIfNeeded();

    widget.controller.speedLocked = true;

    if (mounted) {
      setState(() {
        _locked = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    widget.controller.maxInterval = widget.maxInterval;
    _locked = widget.controller.speedLocked;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,

          // Tap toggles lock state when locked; otherwise it behaves like the
          // normal momentum press interaction.
          onTapDown: (_) {
            if (!widget.enabled) return;
            if (_locked) {
              _unlock();
              return;
            }
            _startPressed();
          },
          onTapUp: (_) {
            if (!widget.enabled) return;
            if (_locked) return; // locked keeps the press held
            widget.controller.pressUp();
          },
          onTapCancel: () {
            _lockTriggeredThisDrag = false;
            if (_locked) return;
            widget.controller.cancel();
          },

          // Drag up to lock: once the user drags upward past a threshold,
          // execute once immediately and lock the button.
          onPanStart: (_) {
            _lockTriggeredThisDrag = false;
          },
          onPanUpdate: (details) {
            if (!widget.enabled) return;
            if (_locked) return;
            if (_lockTriggeredThisDrag) return;

            if (details.delta.dy <= -_lockDragThresholdPx) {
              _lockTriggeredThisDrag = true;
              // Fire once immediately and lock.
              _lockAndFireOnce();
            }
          },
          onPanEnd: (_) {
            // If we did not lock, release like a normal press.
            if (!_locked && !_lockTriggeredThisDrag) {
              widget.controller.pressUp();
            }
            _lockTriggeredThisDrag = false;
          },

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
                if (_locked) ...[
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
  StopPrimaryButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  // builds a stop button for the action button.
  // when pressed it clear the app bar icon and stops
  // the timing controller.
  //
  // the onTap parameter can be used to add more functinality.
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextButton(
        child: Text("Stop"),
        onPressed: () {
          PlayerDataController.instance.actionTimingController.stopNow();
        },
      ),
    );
  }
}
