import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/player_data_controller.dart';
import '../data/player_data.dart';
import 'icon_renderer.dart';
import 'segmented_tabs.dart';

/// Stance picker for the combat screen. The pick sets which skill the action
/// loop boosts, so the stance is stored on the player as that skill.
/// [stances] is what the current entity offers ([stancesForEntity]); an
/// entity with only one stance has nothing to choose, so nothing renders.
class StanceButton extends StatelessWidget {
  const StanceButton({super.key, required this.stances});

  final List<Stance> stances;

  @override
  Widget build(BuildContext context) {
    if (stances.length < 2) return const SizedBox.shrink();

    final controller = context.watch<PlayerDataController>();
    final selected = controller.getStance();

    // the same segmented control as the tabs, at the style switch's 44pt
    return SegmentedTabs<Stance>(
      height: 44,
      segments: [
        for (final stance in stances)
          TabSegment(
            value: stance,
            label: stanceLabel(stance),
            icon: IconRenderer(id: kStanceBoostSkill[stance], size: 18),
          ),
      ],
      selected: selected,
      onChanged: (stance) =>
          context.read<PlayerDataController>().setStance(stance),
    );
  }
}
