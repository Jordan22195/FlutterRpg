import 'package:flutter/material.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/buff_row.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/encounter_controller.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import '../data/skill_data.dart';
import '../widgets/skil_tile.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/fading_number.dart';
import '../data/ObjectStack.dart';

class EncounterScreen extends StatefulWidget {
  const EncounterScreen({super.key});

  @override
  State<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends State<EncounterScreen> {
  Widget buildPlayerStatStack(
    Map<SkillId, int> stats,
    int hp,
    SkillId attackSkillType,
  ) {
    double fontSize = 14;
    double iconSize = 20;
    int hitPoints = stats[SkillId.HITPOINTS] ?? 1;
    int defence = stats[SkillId.DEFENCE] ?? 1;
    int attack = stats[attackSkillType] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconRenderer(id: SkillId.HITPOINTS, size: iconSize),
            SizedBox(width: 4),
            Text("$hp / $hitPoints", style: TextStyle(fontSize: fontSize)),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: SkillId.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text("$defence", style: TextStyle(fontSize: fontSize)),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: attackSkillType, size: iconSize),
            SizedBox(width: 4),
            Text("$attack", style: TextStyle(fontSize: fontSize)),
          ],
        ),

        // Add more stats here, e.g. mana, stamina, etc.
      ],
    );
  }

  Widget buildEntityStatStack(EncounterEntity entity) {
    int hp = entity.hitpoints;
    int defence = entity.defence;
    bool combatEntity = entity is CombatEntity;
    int attack = 0;
    SkillId skillId = entity.entityType;
    if (combatEntity) {
      attack = entity.attack;
    }
    double fontSize = 14;
    double iconSize = 20;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (skillId != SkillId.FISHING)
              IconRenderer(id: SkillId.HITPOINTS, size: iconSize),
            if (skillId != SkillId.FISHING) SizedBox(width: 4),
            if (skillId != SkillId.FISHING)
              Text("$hp", style: TextStyle(fontSize: fontSize)),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: SkillId.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text("$defence", style: TextStyle(fontSize: fontSize)),
          ],
        ),
        if (combatEntity)
          Row(
            children: [
              IconRenderer(id: SkillId.ATTACK, size: iconSize),
              SizedBox(width: 4),
              Text("$attack", style: TextStyle(fontSize: fontSize)),
            ],
          ),

        // Add more stats here, e.g. mana, stamina, etc.
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EncounterController>();
    final entity = controller.getActiveEntity();
    final stats = controller.getPlayerStats();
    final actionResult = controller.latestActionResult;

    final bool respawning = controller.respawning();
    final String entityName = entity.name;
    final EntityId entityId = entity.id;
    final int playerHp = controller.getPlayerHp();
    final int playerDamage = actionResult.damageDone;
    final bool isCombatEntity = controller.isCombatEntity();
    final int equipedFoodItemCount = controller.getEquipedFoodItemCount();
    final ItemId equipedFoodItemId = controller.getEquipedFoodItemId();
    final ItemId equipedTool = controller.getEquipedTool();

    final List<ObjectStack> encounterItemDrops = controller.itemDrops();
    final entityCount = entity.count;
    final healthPercent = controller.getHealthPercent();
    final skillType = entity.entityType;

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
                      entityName,
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
                  child: buildPlayerStatStack(stats, playerHp, skillType),
                ),

                // Center: Item stack tile (always centered)
                Expanded(
                  child: Center(
                    child: respawning
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
                            id: entityId,
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
                      child: buildEntityStatStack(entity),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            //entity hp bar
            if (skillType != SkillId.FISHING)
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
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
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
                ItemStackTile(
                  size: 56,
                  count: 1,
                  id: equipedTool,
                  onTap: () =>
                      EquipmentPicker.build(context, ArmorSlots.TOOL, (id) {
                        controller.equipTool(id);
                        setState(() {});
                      }, skillFilter: SkillId.WOODCUTTING),
                ),

                if (isCombatEntity)
                  ItemStackTile(
                    size: 56,
                    count: equipedFoodItemCount,
                    id: equipedFoodItemId,
                    onTap: () {
                      FoodPicker.build(context, (id) {
                        controller.setEquipedFood(id);
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
                    child: InventoryGrid(items: encounterItemDrops),
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
                    label: "Action",
                    startActionFunction: () {
                      controller.startEncounterAction();
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
                      controller.eatSingleEquipedFood();
                      setState(() {});
                    },
                  ),
                ),
                SizedBox(width: 8),
                StopPrimaryButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
