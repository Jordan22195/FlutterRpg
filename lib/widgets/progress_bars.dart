import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/momentum_loop_controller.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../controllers/player_data_controller.dart';
import 'fill_bar.dart';
import '../data/item.dart';

class ProgressBars extends StatelessWidget {
  ProgressBars({super.key});

  static Enum iconId = Items.NULL;
  static int iconCount = 1;
  static bool iconIsTimer = false;
  static DateTime? iconTimerEnd = DateTime.now();

  @override
  Widget build(BuildContext context) {
    PlayerDataController controller = PlayerDataController.instance;
    const double speedBarPadding = 120;
    final timing = controller.actionTimingControllerOrNull;

    if (timing == null) {
      // Build can run before async init finishes. Show placeholders.
      return Column(
        children: [
          const FillBar(value: 0),
          const SizedBox(height: 8),
          Row(
            children: const [
              SizedBox(width: speedBarPadding),
              Expanded(child: FillBar(value: 0)),
              SizedBox(width: speedBarPadding),
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        //Skill Icon
        iconId == Items.NULL
            ? const SizedBox(width: 36)
            : ItemStackTile(
                size: 36,
                count: iconCount,
                id: iconId,
                isTimerStackTile: iconIsTimer,
                expirationTime: iconTimerEnd,
              ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //Stamina Bar
              AnimatedBuilder(
                animation: timing,
                builder: (_, __) => FillBar(
                  value: PlayerDataController.instance.getStaminaPercent(),
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),

              //Progress Bar
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: timing,
                  builder: (_, __) => FillBar(value: timing.percentMaxSpeed),
                ),
              ),
              const SizedBox(height: 8),
              //Speed Bar
              SizedBox(
                width: 50,
                child: AnimatedBuilder(
                  animation: timing,
                  builder: (_, __) => FillBar(
                    value: timing.actionProgress,
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(children: [SizedBox(height: 28), ActionIntervalTimer()]),
      ],
    );
  }
}

class ActionIntervalTimer extends StatelessWidget {
  ActionIntervalTimer({super.key});

  @override
  Widget build(BuildContext context) {
    PlayerDataController controller = PlayerDataController.instance;
    final timing = controller.actionTimingControllerOrNull;
    final intervalMs = timing?.getCurrentActionDuration().inMilliseconds ?? 0;
    final percentSpeed = timing?.percentMaxSpeed ?? 0;
    final speedBoost = timing?.getCurrentSpeedMultiplier() ?? 1.0;
    context.watch<MomentumLoopController>();

    return SizedBox(
      width: 80, // Fixed width so layout doesn't shift
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 4),

              const Icon(Icons.bolt, size: 15),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(width: 4),

              const Icon(Icons.bolt, size: 15),
              const SizedBox(width: 4),
              SizedBox(
                width: 40, // Fixed width for text so it doesn't resize
                child: Text(
                  '${(intervalMs).toStringAsFixed(2)}s',
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
