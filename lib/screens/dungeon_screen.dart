import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/dungeon_controller.dart';
import '../data/ObjectStack.dart';
import '../game_session.dart';
import '../services/entity_screen_router_service.dart';
import '../widgets/entity_info_dialog.dart';
import '../widgets/entity_queue_card.dart';
import '../widgets/inventory_grid.dart';
import '../widgets/item_stack_tile.dart';
import 'encounter_screen.dart';

/// A dungeon: one ordered list of cards, first at the top. Each card is a
/// queue of entities; tapping an unlocked one opens the ordinary encounter
/// screen against its queue. A card stays sealed until the card above it is
/// cleared, unless it opts out of that.
///
/// There is no lobby and no enter button — the list is the dungeon. What a
/// card holds, and what those entities drop, is read by tapping their
/// tiles. Backing out is what ends a run, and what that costs depends on
/// the dungeon's type.
class DungeonScreen extends StatefulWidget {
  const DungeonScreen({super.key, required this.dungeonId});

  final DungeonId dungeonId;

  @override
  State<DungeonScreen> createState() => _DungeonScreenState();
}

/// The two things a dungeon has to show: the cards, and what the run has
/// paid out so far.
enum _DungeonTab { floors, loot }

class _DungeonScreenState extends State<DungeonScreen> {
  _DungeonTab _tab = _DungeonTab.floors;

  @override
  void initState() {
    super.initState();
    // opening the list is entering the dungeon. deferred a frame because
    // it can start a run, and a run start notifies
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<DungeonController>().openDungeon(widget.dungeonId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DungeonController>();
    final def = controller.definitionFor(widget.dungeonId);

    if (def == null) {
      return const SafeArea(child: Center(child: Text('Unknown dungeon')));
    }

    final onThisDungeon =
        controller.hasActiveRun &&
        controller.activeDungeonId == widget.dungeonId;
    final slots = onThisDungeon ? controller.slots : const [];
    final loot = onThisDungeon ? controller.runLoot() : const <ObjectStack>[];

    return PopScope(
      // backing out abandons the run, so the pop has to be confirmed first
      canPop: !onThisDungeon,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave(context, controller, def.id);
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _header(context, controller, def),
              Expanded(
                child: ListView(
                  children: [
                    _banner(def.iconAsset),
                    const SizedBox(height: 12),
                    _tabBar(context, slots.length, loot.length),
                    const SizedBox(height: 8),
                    if (_tab == _DungeonTab.floors)
                      for (int i = 0; i < slots.length; i++)
                        EntityQueueCard(
                          title: slots[i].name,
                          entities: slots[i].members,
                          cleared: controller.isCleared(i),
                          lockReason: controller.lockReason(i),
                          note: _keyNote(context, controller, i),
                          // a one-shot card already cleared can't be run
                          // again, so it offers no play button either
                          onTap: controller.startable(i)
                              ? () => _openSlot(context, controller, i)
                              : null,
                          onEntityTap: (entity) =>
                              _showEntityDetails(context, entity),
                        )
                    else if (loot.isEmpty)
                      _emptyLoot(context)
                    else
                      Card(child: InventoryGrid(items: loot, shrinkWrap: true)),
                  ],
                ),
              ),
              _autoAdvanceToggle(context, controller),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    DungeonController controller,
    DungeonDefinition def,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _leave(context, controller, def.id),
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

  /// Floors or loot, in the explore screen's segmented style so the two
  /// list screens read the same way.
  Widget _tabBar(BuildContext context, int floorCount, int lootCount) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<_DungeonTab>(
        segments: [
          ButtonSegment(
            value: _DungeonTab.floors,
            label: Text('Floors · $floorCount'),
          ),
          ButtonSegment(
            value: _DungeonTab.loot,
            label: Text('Loot · $lootCount'),
          ),
        ],
        selected: {_tab},
        // single-select: the set always holds exactly one tab
        onSelectionChanged: (selection) =>
            setState(() => _tab = selection.first),
        showSelectedIcon: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          textStyle: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _emptyLoot(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(
          'Nothing dropped this run yet',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ),
    );
  }

  /// The entry key a keyed dungeon's first card is about to charge, so it
  /// never leaves the bag unannounced.
  Widget? _keyNote(
    BuildContext context,
    DungeonController controller,
    int index,
  ) {
    if (!controller.showsKeyNote(index)) return null;

    final spent = controller.keySpent;
    final held = controller.keyCount(controller.activeDungeonId);
    final label = spent
        ? 'Key spent'
        : held > 0
        ? 'Key ready'
        : 'No key';

    return Row(
      children: [
        ItemStackTile(
          size: 28,
          count: held,
          id: controller.keyItemId,
          showInfoDialogOnTap: false,
          depleted: spent || held <= 0,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: spent || held > 0
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

  /// Whether clearing a card drops back to this list or runs straight into
  /// the next one. A preference, so it holds across runs.
  Widget _autoAdvanceToggle(
    BuildContext context,
    DungeonController controller,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Continue to next floor',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Switch(
          value: controller.autoAdvance,
          onChanged: (value) => controller.autoAdvance = value,
        ),
      ],
    );
  }

  Future<void> _openSlot(
    BuildContext context,
    DungeonController controller,
    int i,
  ) async {
    final navigator = Navigator.of(context);

    // spending the key is irreversible and re-entering costs another one,
    // so it is never charged on a stray tap
    if (controller.willSpendKey(i)) {
      final keyName =
          context
              .read<GameSession>()
              .catalogBundle
              .itemCatalog
              .definitionFor(controller.keyItemId)
              ?.name ??
          'key';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Spend 1 $keyName?'),
          content: const Text(
            'Entering costs the key. Leaving the dungeon — or dying in it '
            '— will cost another one to come back.',
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

    if (!controller.startSlot(i)) return;
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

  Future<void> _leave(
    BuildContext context,
    DungeonController controller,
    DungeonId dungeonId,
  ) async {
    final navigator = Navigator.of(context);

    // pop, never maybePop: this method is itself what PopScope calls when
    // the back is refused, and the PopScope above still reads canPop false
    // until the next frame — asking again would come straight back here
    void popNow() {
      if (navigator.canPop()) navigator.pop();
    }

    if (!controller.hasActiveRun || controller.activeDungeonId != dungeonId) {
      popNow();
      return;
    }

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave dungeon?'),
        content: Text(controller.leaveWarningFor(dungeonId)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (leave != true) return;
    controller.leaveDungeon();
    popNow();
  }
}
