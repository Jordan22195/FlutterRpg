import 'package:flutter/material.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import '../controllers/player_data_controller.dart';
import 'fill_bar.dart';
import '../data/item.dart';

class ProgressBars extends StatelessWidget {
  ProgressBars({super.key});

  static Enum iconId = Items.NULL;
  static int iconCount = 1;
  static bool iconIsTimer = false;
  static DateTime iconTimerEnd = DateTime.now();

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
                builder: (_, __) => FillBar(value: .5),
              ),
              const SizedBox(height: 8),

              //Progress Bar
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: timing,
                  builder: (_, __) => FillBar(value: timing.actionProgress),
                ),
              ),
              const SizedBox(height: 8),
              //Speed Bar
              SizedBox(
                width: 50,
                child: AnimatedBuilder(
                  animation: timing,
                  builder: (_, __) => FillBar(
                    value: timing.speed,
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        //Entity Icon
        const SizedBox(width: 36),
      ],
    );
  }
}
