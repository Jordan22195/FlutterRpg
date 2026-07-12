import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/dungeon_controller.dart';
import '../data/skill_data.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/item_stack_tile.dart';
import 'encounter_screen.dart';

/// A dungeon's screen. When no run is active it's a free inspect/lobby
/// (floors, boss, rewards, entry cost, Enter). An active run renders as a
/// combat encounter screen — the same shared layout world combat uses —
/// with the floor progression added.
class DungeonScreen extends StatelessWidget {
  const DungeonScreen({super.key, required this.dungeonId});

  final DungeonId dungeonId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DungeonController>();

    final def = controller.definitionFor(dungeonId);
    final showRun =
        controller.hasActiveRun && controller.activeDungeonId == dungeonId;

    if (def != null && showRun) {
      return _DungeonRunScreen(def: def);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(context, def?.name ?? 'Dungeon'),
            Expanded(
              child: def == null
                  ? const Center(child: Text('Unknown dungeon'))
                  : _InspectView(controller: controller, def: def),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 4, 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- inspect / lobby ----

class _InspectView extends StatelessWidget {
  const _InspectView({required this.controller, required this.def});

  final DungeonController controller;
  final DungeonDefinition def;

  @override
  Widget build(BuildContext context) {
    final canEnter = controller.canEnter(def.id);
    final keyCount = controller.keyCount(def.id);
    final rewards = controller.bossRewardItemIds(def.id);

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              _banner(def.iconAsset),
              const SizedBox(height: 12),

              // floors and their packs, boss last
              for (int i = 0; i < def.floors.length; i++)
                _floorCard(
                  context,
                  def.floors[i],
                  isBossFloor: i == def.floors.length - 1,
                ),

              const SizedBox(height: 12),
              Text(
                'Boss rewards',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in rewards)
                    ItemStackTile(size: 48, count: 1, id: id),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Possible boss drops.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // entry cost + enter
        Row(
          children: [
            if (def.isKeyed)
              Row(
                children: [
                  ItemStackTile(
                    size: 40,
                    count: keyCount,
                    id: def.keyItemId,
                    showInfoDialogOnTap: false,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    keyCount > 0 ? 'Key ready' : 'No key',
                    style: TextStyle(
                      color: keyCount > 0
                          ? null
                          : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            const Spacer(),
            FilledButton(
              onPressed: canEnter
                  ? () => controller.enterDungeon(def.id)
                  : null,
              child: Text(def.isKeyed ? 'Enter (uses key)' : 'Enter'),
            ),
          ],
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

  Widget _floorCard(
    BuildContext context,
    DungeonFloor floor, {
    required bool isBossFloor,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(floor.name, style: Theme.of(context).textTheme.titleSmall),
                if (isBossFloor) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.star,
                    size: 16,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final pack in floor.packs)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconRenderer<EntityId>(id: pack.entityId, size: 28),
                      const SizedBox(width: 2),
                      Text('x${pack.count}'),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- active run ----

/// The active run IS the world combat screen: it extends the shared
/// [CombatScreenState] layout from encounter_screen.dart, so any layout
/// change there applies here too. The dungeon overrides only:
/// - the data source (the dungeon run instead of a world encounter)
/// - floor progression above the fight
/// - the bottom bar (Leave / loop-continue; fights auto-advance, so there
///   is no action/stop/eat button)
/// The shared layout's player hp strip shows during fights (the entity is
/// a combat entity) and hides between floors.
class _DungeonRunScreen extends StatefulWidget {
  const _DungeonRunScreen({required this.def});

  final DungeonDefinition def;

  @override
  State<_DungeonRunScreen> createState() => _DungeonRunScreenState();
}

class _DungeonRunScreenState extends CombatScreenState<_DungeonRunScreen> {
  DungeonDefinition get def => widget.def;

  @override
  CombatViewState resolveView(BuildContext context) {
    final controller = context.watch<DungeonController>();

    final entity =
        controller.currentEntity ??
        EncounterEntity(
          id: EntityId.NULL,
          name: "",
          count: 0,
          entityType: SkillId.ATTACK,
          defence: 0,
          hitpoints: 0,
        );

    return CombatViewState(
      title: def.name,
      entity: entity,
      // dungeon packs never respawn; the next enemy spawns instantly
      respawning: false,
      playerHp: controller.getPlayerHp(),
      playerStats: controller.getPlayerStats(),
      playerDamage: controller.latestActionResult.damageDone,
      actionSequence: controller.actionSequence,
      entityDamage: controller.latestEntityDamage,
      entityAttackSequence: controller.entityAttackSequence,
      showActionFeedback: true,
      drops: controller.runLoot(),
      foodItemId: controller.getEquipedFoodItemId(),
      foodItemCount: controller.getEquipedFoodItemCount(),
    );
  }

  @override
  Widget? buildAboveFight(BuildContext context) {
    final controller = context.watch<DungeonController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < def.floors.length; i++)
          _floorRow(context, controller, i, def.floors[i].name),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _floorRow(
    BuildContext context,
    DungeonController controller,
    int index,
    String name,
  ) {
    final status = controller.floorStatus(index);
    late final IconData icon;
    late final Color? color;
    switch (status) {
      case FloorStatus.cleared:
        icon = Icons.check_circle;
        color = Theme.of(context).colorScheme.primary;
        break;
      case FloorStatus.current:
        icon = Icons.play_arrow;
        color = Theme.of(context).colorScheme.tertiary;
        break;
      case FloorStatus.upcoming:
        icon = Icons.circle_outlined;
        color = Theme.of(context).colorScheme.onSurface.withOpacity(0.4);
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Text(
            name,
            style: TextStyle(
              fontWeight: status == FloorStatus.current
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildActionBar(BuildContext context, CombatViewState view) {
    final controller = context.watch<DungeonController>();

    if (controller.awaitingFloorChoice) {
      final atBoss = controller.atBossFloorChoice;
      return Row(
        children: [
          FilledButton(
            onPressed: controller.loopFloor,
            child: const Text('Loop floor'),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: controller.continueFloor,
            child: Text(atBoss ? 'Finish' : 'Continue'),
          ),
        ],
      );
    }

    return Row(
      children: [
        Text(
          controller.currentFloorName,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const Spacer(),
        OutlinedButton(
          onPressed: () => _confirmLeave(context, controller),
          child: const Text('Leave'),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    DungeonController controller,
  ) async {
    final keyed = def.isKeyed;
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave dungeon?'),
        content: Text(
          keyed
              ? 'Your progress is lost and the key is already spent.'
              : 'Your progress resets to the first floor.',
        ),
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
    if (leave == true) {
      controller.leaveDungeon();
    }
  }
}
