import 'package:flutter/material.dart';
import '../controllers/momentum_loop_controller.dart';

class MomentumPrimaryButton extends StatelessWidget {
  const MomentumPrimaryButton({
    super.key,
    required this.label,
    required this.controller,
  });

  final String label;
  final MomentumLoopController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => controller.pressDown(),
          onTapUp: (_) => controller.pressUp(),
          onTapCancel: controller.cancel,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }
}
