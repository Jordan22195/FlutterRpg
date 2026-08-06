import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/player_data_controller.dart';
import '../data/player_data.dart';
import 'icon_renderer.dart';

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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final stance in stances)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _StanceSegment(
              stance: stance,
              selected: stance == selected,
              onTap: () =>
                  context.read<PlayerDataController>().setStance(stance),
            ),
          ),
      ],
    );
  }
}

class _StanceSegment extends StatelessWidget {
  const _StanceSegment({
    required this.stance,
    required this.selected,
    required this.onTap,
  });

  final Stance stance;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconRenderer(id: kStanceBoostSkill[stance], size: 18),
              const SizedBox(width: 5),
              Text(
                stanceLabel(stance),
                style: TextStyle(
                  fontSize: 13,
                  // the selected stance reads as the active one
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
