import 'package:flutter/material.dart';
import 'package:rpg/data/armor_equipment.dart';
import 'package:rpg/data/item.dart';
import 'package:rpg/widgets/buff_row.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:rpg/widgets/progress_bars.dart';
import '../controllers/player_data_controller.dart';
import 'package:provider/provider.dart';
import '../data/entity.dart';
import '../controllers/encounter_controller.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import '../data/skill.dart';
import '../widgets/skil_tile.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/fading_number.dart';

class EncounterScreen extends StatefulWidget {
  const EncounterScreen({super.key, required this.encounter});
  final EntityEncounter encounter;

  @override
  State<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends State<EncounterScreen>
    with TickerProviderStateMixin {
  // Cache the provider so dispose() doesn't do ancestor lookup via context.
  late final PlayerDataController _playerController;
  int playerDamage = 0;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _playerController = context.read<PlayerDataController>();

    Future.microtask(() async {
      final c = _playerController;
      await c.ensureLoaded();
      if (!mounted) return;

      if (!mounted) return;
      setState(() {
        _initializing = false;
      });
    });
  }

  Widget buildPlayerStatStack(PlayerDataController controller) {
    double fontSize = 14;
    double iconSize = 20;
    final skillId = widget.encounter.getEncounterSkillType();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconRenderer(id: Skills.HITPOINTS, size: iconSize),
            SizedBox(width: 4),
            Text(
              controller.getStatTotal(Skills.HITPOINTS).toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: Skills.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text(
              controller.getStatTotal(Skills.DEFENCE).toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: skillId, size: iconSize),
            SizedBox(width: 4),
            Text(
              controller.getStatTotal(skillId).toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),

        // Add more stats here, e.g. mana, stamina, etc.
      ],
    );
  }

  Widget buildEntityStatStack(PlayerDataController controller) {
    double fontSize = 14;
    double iconSize = 20;
    final skillId = widget.encounter.getEncounterSkillType();
    final entity = widget.encounter.entity;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (skillId != Skills.FISHING)
              IconRenderer(id: Skills.HITPOINTS, size: iconSize),
            if (skillId != Skills.FISHING) SizedBox(width: 4),
            if (skillId != Skills.FISHING)
              Text(
                entity.hitpoints.toString(),
                style: TextStyle(fontSize: fontSize),
              ),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: Skills.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text(
              entity.defence.toString(),
              style: TextStyle(fontSize: fontSize),
            ),
          ],
        ),
        if (entity is CombatEntity)
          Row(
            children: [
              IconRenderer(id: Skills.ATTACK, size: iconSize),
              SizedBox(width: 4),
              Text(
                entity.attack.toString(),
                style: TextStyle(fontSize: fontSize),
              ),
            ],
          ),

        // Add more stats here, e.g. mana, stamina, etc.
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PlayerDataController>();

    if (_initializing) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final encounter = widget.encounter;
    final entity = widget.encounter.entity;
    final entityCount = widget.encounter.getEntityCount();
    final healthPercent = widget.encounter.getHealthPercent();
    final skillType = widget.encounter.getEncounterSkillType();

    final fadeKey = GlobalKey<FadingNumberState>();

    // ...

    // whenever you want to show+fade (even if count didn’t change):
    fadeKey.currentState?.replay();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      entity.name,
                      style: Theme.of(context).textTheme.titleLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                // Left: Player stats (left-justified)
                Align(
                  alignment: Alignment.centerLeft,
                  child: buildPlayerStatStack(controller),
                ),

                // Center: Item stack tile (always centered)
                Expanded(
                  child: Center(
                    child: encounter.respawning
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 200,
                                height: 200,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 10),
                            ],
                          )
                        : ItemStackTile(
                            size: 200,
                            count: entityCount,
                            id: entity.id,
                          ),
                  ),
                ),

                // Right side: Fading number centered between tile and entity stats,
                // and entity stats right-aligned
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Fading number centered in remaining space before stats
                    Center(
                      child: FadingNumber(
                        key: fadeKey,
                        number: playerDamage,
                        color: Colors.amber,
                      ),
                    ),

                    // Entity stats right-aligned
                    Align(
                      alignment: Alignment.centerRight,
                      child: buildEntityStatStack(controller),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                SizedBox(width: 50),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: healthPercent),
                    duration: const Duration(milliseconds: 100),
                    builder: (context, animatedValue, child) {
                      return FillBar(
                        value: animatedValue,
                        foregroundColor: Theme.of(context).colorScheme.tertiary,
                      );
                    },
                  ),
                ),
                SizedBox(width: 50),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                if (skillType == Skills.WOODCUTTING)
                  ItemStackTile(
                    size: 56,
                    count: 1,
                    id: EncounterController.instance.equipedAxe,
                    onTap: () =>
                        EquipmentPicker.build(context, ArmorSlots.TOOL, (id) {
                          EncounterController.instance.equipedAxe = id;
                          setState(() {});
                        }, skillFilter: Skills.WOODCUTTING),
                  ),
                if (skillType == Skills.MINING)
                  ItemStackTile(
                    size: 56,
                    count: 1,
                    id: EncounterController.instance.equipedPickaxe,
                    onTap: () =>
                        EquipmentPicker.build(context, ArmorSlots.TOOL, (id) {
                          EncounterController.instance.equipedPickaxe = id;
                          setState(() {});
                        }, skillFilter: Skills.MINING),
                  ),
                if (encounter.isCombatEntity())
                  ItemStackTile(
                    size: 56,
                    count: PlayerDataController.instance.data!.inventory
                        .countOf(EncounterController.instance.equipedFood),
                    id: EncounterController.instance.equipedFood,
                    onTap: () {
                      FoodPicker.build(context, (id) {
                        EncounterController.instance.equipedFood = id;
                        setState(() {});
                      });
                    },
                  ),

                const SizedBox(width: 8),

                Expanded(child: BuffRow()),
              ],
            ),

            const SizedBox(height: 16),
            Divider(),
            SkillTile(id: skillType),

            Card(
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: InventoryGrid(
                      items: encounter.itemDrops.getObjectStackList(),
                    ),
                  ),
                ],
              ),
            ),
            Spacer(),

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: MomentumPrimaryButton(
                    enabled: true,
                    label: controller.getActionString(skillType),
                    controller: controller.actionTimingController,
                    onFireFunction: () {
                      ProgressBars.iconId = encounter.entityId;
                      ProgressBars.iconCount = encounter.getEntityCount();
                      ProgressBars.iconIsTimer = false;
                      encounter.doPlayerEncounterAction();
                    },
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    child: Text("Eat"),
                    onPressed: () {
                      EncounterController.instance.eatSingleEquipedFood();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    child: Text("Stop"),
                    onPressed: () {
                      ProgressBars.iconId = Items.NULL;
                      encounter.endEcnounter();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
