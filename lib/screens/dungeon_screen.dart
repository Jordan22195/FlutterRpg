import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeon_catalog.dart';
import '../catalogs/entity_catalog.dart';
import '../catalogs/item_catalog.dart';
import '../controllers/dungeon_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/player_data_controller.dart';
import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import '../widgets/buff_row.dart';
import '../widgets/equipment_picker.dart';
import '../widgets/fading_number.dart';
import '../widgets/fill_bar.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/inventory_grid.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/skil_tile.dart';

/// A dungeon's screen. When no run is active it's a free inspect/lobby
/// (floors, boss, rewards, entry cost, Enter). Once a run is active it
/// shows the auto-advancing fight and the run's loot.
class DungeonScreen extends StatelessWidget {
  const DungeonScreen({super.key, required this.dungeonId});

  final DungeonId dungeonId;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DungeonController>();
    // player hp/stamina changes should re-render the active run view
    context.watch<PlayerDataController>();

    final def = controller.definitionFor(dungeonId);
    final showRun =
        controller.hasActiveRun && controller.activeDungeonId == dungeonId;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(context, def?.name ?? 'Dungeon'),
            Expanded(
              child: def == null
                  ? const Center(child: Text('Unknown dungeon'))
                  : showRun
                  ? _RunView(controller: controller, def: def)
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
                _floorCard(context, def.floors[i], isBossFloor: i == def.floors.length - 1),

              const SizedBox(height: 12),
              Text('Boss rewards', style: Theme.of(context).textTheme.titleMedium),
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
                'A kill guarantees one of these.',
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
    DungeonFloor floor,
    {required bool isBossFloor}) {
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

// Mirrors the world-combat encounter screen (entity image with damage
// numbers, hp bar, weapon/food/buff row, skill tile, drops grid) with the
// floor progression list added. Fights auto-advance, so there is no
// action/stop/eat button, and no player stat stack.
class _RunView extends StatelessWidget {
  const _RunView({required this.controller, required this.def});

  final DungeonController controller;
  final DungeonDefinition def;

  @override
  Widget build(BuildContext context) {
    final equipmentController = context.watch<EquipmentController>();

    final entity = controller.currentEntity;
    final hpPercent = controller.currentEntityHealthPercent();
    final loot = controller.runLoot();

    final equipedWeapon = equipmentController.getEquipedWeapon();
    final foodItemId = controller.getEquipedFoodItemId();
    final foodItemCount = controller.getEquipedFoodItemCount();

    return Column(
      children: [
        Expanded(
          child: ListView(
            children: [
              // floor progression (the dungeon-specific part of the screen)
              for (int i = 0; i < def.floors.length; i++)
                _floorRow(context, i, def.floors[i].name),
              const SizedBox(height: 8),

              Row(
                children: [
                  // left spacer where the encounter screen shows player
                  // stats, so the entity image stays centered the same way
                  const SizedBox(width: 100),

                  // current enemy with the per-hit damage number overlaid
                  Expanded(
                    child: Center(
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ItemStackTile(
                              size: 200,
                              count: entity?.count ?? 0,
                              id: entity?.id ?? EntityId.NULL,
                              showInfoDialogOnTap: false,
                            ),
                            FadingNumber(
                              number:
                                  controller.latestActionResult.damageDone,
                              trigger: controller.actionSequence,
                              autoplay: false,
                              color:
                                  controller.latestActionResult.damageDone > 0
                                  ? Colors.red
                                  : Colors.blue,
                              style: const TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 8, color: Colors.black),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // entity stats, mirroring the encounter screen's right side
                  SizedBox(width: 100, child: _entityStatStack(context, entity)),
                ],
              ),
              const SizedBox(height: 8),

              // enemy hp bar
              Row(
                children: [
                  const SizedBox(width: 50),
                  Expanded(
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(end: hpPercent),
                      duration: const Duration(milliseconds: 100),
                      builder: (context, v, child) => FillBar(
                        value: v,
                        foregroundColor: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),
              const SizedBox(height: 8),

              // equipped weapon and food pickers + buffs, as in world combat.
              // food matters here: auto-eat draws from the equipped stack
              Row(
                children: [
                  ItemStackTile(
                    size: 56,
                    count: 1,
                    id: equipedWeapon?.id ?? ItemId.NULL,
                    showInfoDialogOnTap: false,
                    borderColor: equipedWeapon == null
                        ? null
                        : qualityBorderColor(equipedWeapon.quality),
                    onTap: () => EquipmentPicker.build(
                      context,
                      const [ArmorSlots.WEAPON_1H, ArmorSlots.WEAPON_2H],
                      (item) => equipmentController.equipItem(item),
                    ),
                  ),
                  ItemStackTile(
                    size: 56,
                    count: foodItemCount,
                    id: foodItemId,
                    onTap: () {
                      FoodPicker.build(
                        context,
                        (id) => equipmentController.setEquipedFood(id),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: BuffRow()),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              SkillTile(id: entity?.entityType ?? SkillId.ATTACK),

              Card(
                child: Column(
                  children: [
                    SizedBox(height: 80, child: InventoryGrid(items: loot)),
                  ],
                ),
              ),
            ],
          ),
        ),

        _controls(context),
      ],
    );
  }

  // entity hp / defence / attack, matching the encounter screen's stack
  Widget _entityStatStack(BuildContext context, EncounterEntity? entity) {
    const double fontSize = 14;
    const double iconSize = 20;
    final combatEntity = entity is CombatEntity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconRenderer(id: SkillId.HITPOINTS, size: iconSize),
            const SizedBox(width: 4),
            Text(
              '${entity?.hitpoints ?? 0}',
              style: const TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: SkillId.DEFENCE, size: iconSize),
            const SizedBox(width: 4),
            Text(
              '${entity?.defence ?? 0}',
              style: const TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        if (combatEntity)
          Row(
            children: [
              IconRenderer(id: SkillId.ATTACK, size: iconSize),
              const SizedBox(width: 4),
              Text(
                '${entity.attack}',
                style: const TextStyle(fontSize: fontSize),
              ),
            ],
          ),
      ],
    );
  }

  Widget _floorRow(BuildContext context, int index, String name) {
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

  Widget _controls(BuildContext context) {
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
          onPressed: () => _confirmLeave(context),
          child: const Text('Leave'),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
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
