import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/world_controller.dart';
import '../theme/hearth_theme.dart';
import 'action_timer.dart';

/// The road to the zone on screen, from where the player stands, as an
/// activity row: "Travel" in the travel blue while the trip is only on
/// offer, "Travelling" once it is under way. The chip reads the whole trip,
/// boost and all, as an action row's chip reads a whole action; the bar is
/// what fills.
///
/// A screen shows it in place of its own progress row whenever the zone on
/// screen is not the one the player is in — there is nothing to work there
/// until they have walked there.
class TravelRow extends StatelessWidget {
  const TravelRow({super.key});

  @override
  Widget build(BuildContext context) {
    final world = context.watch<WorldController>();
    return ActionTimerRow(
      label: world.isTravelling ? 'Travelling' : 'Travel',
      color: context.gameColors.travel,
      progress: world.travelProgress,
      interval: world.travelInterval,
      barKey: kTravelBarKey,
    );
  }
}
