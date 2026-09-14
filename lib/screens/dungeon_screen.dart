import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import '../controllers/dungeon_controller.dart';
import '../services/entity_screen_router_service.dart';
import '../widgets/entity_info_dialog.dart';
import '../widgets/entity_queue_card.dart';
import '../widgets/item_stack_tile.dart';
import 'encounter_screen.dart';

/// A dungeon: one ordered list of floors, first at the top. Each floor is a
/// queue of entities; tapping an unlocked one opens the ordinary encounter
/// screen against its queue, and keeps fighting that floor on a loop until
/// something else takes the action.
///
/// There is no lobby, no enter button and no leaving. Opening the list costs
/// nothing and backing out costs nothing — the floor you started keeps
/// swinging while you read the zone or the map. A floor cleared once is
/// unlocked forever; what a floor holds, and what those entities drop, is
/// read by tapping their tiles.
class DungeonScreen extends StatelessWidget {
  const DungeonScreen({super.key, required this.dungeonId});

  final DungeonId dungeonId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DungeonController>();
    if (!dungeonId.isReal) {
      return const SafeArea(child: Center(child: Text('Unknown dungeon')));
    }
    final def = dungeonId.definition;
    final slots = controller.slotsFor(dungeonId);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(context, def),
            Expanded(
              child: ListView(
                children: [
                  _banner(def.iconAsset),
                  const SizedBox(height: 12),
                  for (int i = 0; i < slots.length; i++)
                    EntityQueueCard(
                      title: slots[i].name,
                      entities: slots[i].members,
                      cleared: controller.isCleared(dungeonId, i),
                      lockReason: controller.lockReason(dungeonId, i),
                      stats: _statsLine(controller, i),
                      note: _keyNote(context, controller, i),
                      onTap: controller.startable(dungeonId, i)
                          ? () => _openSlot(context, controller, i)
                          : null,
                      onEntityTap: (entity) =>
                          _showEntityDetails(context, entity),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, DungeonDefinition def) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            // nothing is left behind by walking out, so this is an ordinary
            // pop: the floor keeps running while the player looks around
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              def.name,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// How much of this floor the player has done: everything ever, and the
  /// laps since this floor last started. Null until it has been cleared once
  /// — a floor with nothing to report says nothing.
  String? _statsLine(DungeonController controller, int index) {
    final lifetime = controller.lifetimeRuns(dungeonId, index);
    if (lifetime <= 0) return null;
    final session = controller.sessionRuns(dungeonId, index);
    final runs = '$lifetime ${lifetime == 1 ? 'run' : 'runs'}';
    if (session <= 0) return runs;
    return '$runs · $session this session';
  }

  /// The entry key a keyed dungeon's first floor is about to charge, so it
  /// never leaves the bag unannounced. Charged once, ever.
  Widget? _keyNote(
    BuildContext context,
    DungeonController controller,
    int index,
  ) {
    if (!controller.showsKeyNote(dungeonId, index)) return null;

    final paid = controller.keyPaid(dungeonId);
    final held = controller.keyCount(dungeonId);
    final label = paid
        ? 'Unlocked'
        : held > 0
        ? 'Key ready'
        : 'No key';

    return Row(
      children: [
        ItemStackTile(
          size: 28,
          count: held,
          id: controller.keyItemId(dungeonId),
          showInfoDialogOnTap: false,
          depleted: paid || held <= 0,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: paid || held > 0
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                : Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _banner(String asset) {
    return SizedBox(
      width: double.infinity,
      height: 160,
      child: asset.isEmpty
          ? const ColoredBox(color: Colors.black26)
          : Image.asset(
              asset,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Colors.black26),
            ),
    );
  }

  Future<void> _openSlot(
    BuildContext context,
    DungeonController controller,
    int i,
  ) async {
    final navigator = Navigator.of(context);

    // spending the key is irreversible, so it is never charged on a stray
    // tap — even though it only ever happens once
    if (controller.willSpendKey(dungeonId, i)) {
      final keyName = controller.keyItemId(dungeonId).definition.name;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Spend 1 $keyName?'),
          content: const Text(
            'Entering costs the key, once. After that this dungeon stays '
            'open for good.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Spend key'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    if (!controller.startSlot(dungeonId, i)) return;
    navigator.push(
      MaterialPageRoute(
        settings: RouteSettings(
          name: EntityScreenRouterService.encounterRouteName,
          arguments: i,
        ),
        builder: (_) => const EncounterScreen(),
      ),
    );
  }

  void _showEntityDetails(BuildContext context, EncounterEntity entity) {
    showEntityInfoDialog(context, entity);
  }
}
