import 'package:flutter/material.dart';

import '../catalogs/entities/entities.dart';
import '../catalogs/zones/zones.dart';
import '../data/scouting_result.dart';
import 'item_stack_tile.dart';

/// What a scouting map uncovered: every entity it turned up, as tiles with
/// the number found, most plentiful first.
void showScoutingResultDialog(BuildContext context, ScoutingResult result) {
  final found = [...result.entities]..sort((a, b) => b.count - a.count);
  final total = found.fold<int>(0, (sum, e) => sum + e.count);

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('Scouted ${result.zone.definition.name}'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You discovered $total ${total == 1 ? 'entity' : 'entities'}:',
                key: const ValueKey('scouting-total'),
              ),
              const SizedBox(height: 12),
              for (final entity in found)
                Padding(
                  key: ValueKey('scouted-${entity.id.name}'),
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      ItemStackTile<EntityId>(
                        size: 44,
                        id: entity.id,
                        count: entity.count,
                        alwaysShowCount: true,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entity.id.definition.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// The map had nothing to uncover, and was not used up.
void showNothingToScoutDialog(BuildContext context, ZoneId zone) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(zone.definition.name),
      content: const Text(
        'There is nothing here for you to discover yet. The map is kept.',
        key: ValueKey('scouting-nothing'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
