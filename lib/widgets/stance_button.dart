import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/action_timing_controller.dart';
import '../controllers/player_data_controller.dart';
import '../data/bound_action.dart';
import '../data/player_data.dart';
import 'icon_renderer.dart';
import 'segmented_tabs.dart';

/// Stance picker for the combat screen. The pick sets which skill the action
/// loop boosts, so the stance is stored on the player as that skill.
/// [stances] is what the current entity offers ([stancesForEntity]); an
/// entity with only one stance has nothing to choose, so nothing renders.
///
/// Nor does it render while the loop is running something that offers no
/// stance (exploring, a craft, a fire): that action holds the stance at fast,
/// and a picker here would only set a boost the running action does not use.
class StanceButton extends StatelessWidget {
  const StanceButton({super.key, required this.stances});

  final List<Stance> stances;

  @override
  Widget build(BuildContext context) {
    if (stances.length < 2) return const SizedBox.shrink();
    final running = context.watch<ActionTimingController>().runningAction;
    if (!runningActionOffersStances(running)) return const SizedBox.shrink();

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

/// Whether the action the loop is running lets the player pick a stance.
/// Idle offers one — the pick is set before starting — as does a dungeon
/// floor, whose own floors coerce it as they fight.
bool runningActionOffersStances(BoundAction? running) {
  if (running == null) return true;
  return switch (running.kind) {
    BoundActionKind.ENCOUNTER =>
      stancesForEntityId(running.entityId).length > 1,
    BoundActionKind.DUNGEON_SLOT => true,
    // travel walks to the fight the player picked, which keeps its stance
    BoundActionKind.TRAVEL => true,
    _ => false,
  };
}
