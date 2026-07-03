import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/action_timing_controller.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'fill_bar.dart';
import '../catalogs/item_catalog.dart';

class ProgressBars extends StatelessWidget {
  const ProgressBars({super.key});

  static Enum iconId = ItemId.NULL;
  static int iconCount = 1;
  static bool iconIsTimer = false;
  static DateTime? iconTimerEnd = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final playerController = context.watch<PlayerDataController>();
    final timing = context.watch<ActionTimingController>();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        //Skill Icon
        iconId == ItemId.NULL
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
                builder: (_, _) => FillBar(
                  value: playerController.getStaminaPercent(),
                  foregroundColor: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),

              //Progress Bar
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: timing,
                  builder: (_, _) => FillBar(value: timing.percentMaxSpeed),
                ),
              ),
              const SizedBox(height: 8),
              //Speed Bar
              SizedBox(
                width: 50,
                child: AnimatedBuilder(
                  animation: timing,
                  builder: (_, _) => FillBar(
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
  const ActionIntervalTimer({super.key});

  @override
  Widget build(BuildContext context) {
    final timing = context.watch<ActionTimingController>();
    final intervalMs = timing.getCurrentActionDuration().inMilliseconds;
    final speedBoost = timing.getCurrentSpeedMultiplier();

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
                  '${(intervalMs / 1000).toStringAsFixed(2)}s',
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
