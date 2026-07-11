import 'package:flutter/material.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/buff_row.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:rpg/widgets/inventory_grid.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/action_queue_controller.dart';
import '../controllers/encounter_controller.dart';
import '../controllers/equipment_controller.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import '../widgets/queue_add_button.dart';
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
    int entityDamage,
    int entityAttackSequence,
  ) {
    double fontSize = 14;
    double iconSize = 20;
    int hitPoints = stats[SkillId.HITPOINTS] ?? 1;
    int defence = stats[SkillId.DEFENCE] ?? 1;
    int attack = stats[attackSkillType] ?? 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // current hp
        Row(
          children: [
            IconRenderer(id: SkillId.HITPOINTS, size: iconSize),
            SizedBox(width: 4),
            Text("$hp", style: TextStyle(fontSize: fontSize)),
            SizedBox(width: 6),
            // damage taken from the combat entity's attacks. fixed-width
            // slot so the flash doesn't shift the surrounding layout
            SizedBox(
              width: 28,
              child: FadingNumber(
                number: entityDamage,
                trigger: entityAttackSequence,
                autoplay: false,
                color: entityDamage > 0 ? Colors.red : Colors.blue,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        // max hp
        Row(
          children: [
            SizedBox(width: iconSize + 4),
            Text(
              "/ $hitPoints",
              style: TextStyle(
                fontSize: fontSize,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
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

  Widget buildEntityStatStack(EncounterEntity entity, int requiredLevel) {
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

    // fishing spots replenish and herbs are picked in one action, so
    // neither shows hitpoints
    final bool showsHp =
        skillId != SkillId.FISHING && skillId != SkillId.HERBALISM;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (showsHp) IconRenderer(id: SkillId.HITPOINTS, size: iconSize),
            if (showsHp) SizedBox(width: 4),
            if (showsHp) Text("$hp", style: TextStyle(fontSize: fontSize)),
          ],
        ),
        Row(
          children: [
            IconRenderer(id: SkillId.DEFENCE, size: iconSize),
            SizedBox(width: 4),
            Text("$defence", style: TextStyle(fontSize: fontSize)),
          ],
        ),
        // level needed to gather this entity (herbs)
        if (requiredLevel > 0)
          Row(
            children: [
              IconRenderer(id: skillId, size: iconSize),
              SizedBox(width: 4),
              Text("Lv $requiredLevel", style: TextStyle(fontSize: fontSize)),
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
    final equipmentController = context.watch<EquipmentController>();
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
    final skillType = entity.entityType;

    // combat entities use the equipped weapon as their 'tool'; gathering
    // entities use the tool equipped for their skill
    final EquipmentItem? equipedTool = isCombatEntity
        ? equipmentController.getEquipedWeapon()
        : equipmentController.getToolForSkill(skillType);

    final List<ObjectStack> encounterItemDrops = controller.itemDrops();
    final entityCount = entity.count;
    final healthPercent = controller.getHealthPercent();

    // damage feedback belongs only to the encounter the actions fire on
    final bool isActiveEncounter = controller.isViewingActiveEncounter();
    final int actionSequence = controller.actionSequence;

    // herbalism level gate: locked herbs stay visible but can't be picked
    final int herbRequiredLevel = controller.viewedHerbRequiredLevel();
    final bool herbLocked = controller.viewedHerbLocked();

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
            // scrollable middle so short screens don't overflow; the
            // header above and action buttons below stay pinned
            Expanded(
              child: ListView(
                children: [
                  Row(
                    children: [
                      // Left: Player stats. fixed width so growing/shrinking
                      // numbers don't re-center the entity image
                      SizedBox(
                        width: 100,
                        child: buildPlayerStatStack(
                          stats,
                          playerHp,
                          skillType,
                          controller.latestEntityDamage,
                          controller.entityAttackSequence,
                        ),
                      ),

                      // Center: Item stack tile (always centered) with the
                      // per-action damage number overlaid on the entity image.
                      // a fixed 200x200 slot that only swaps its background
                      // between tile and respawn spinner, so nothing shifts and
                      // the damage number stays mounted across respawns
                      Expanded(
                        child: Center(
                          child: SizedBox(
                            width: 200,
                            height: 200,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                if (respawning)
                                  const Positioned.fill(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                else
                                  ItemStackTile(
                                    size: 200,
                                    count: entityCount,
                                    id: entityId,
                                  ),
                                if (isActiveEncounter)
                                  FadingNumber(
                                    number: playerDamage,
                                    trigger: actionSequence,
                                    autoplay: false,
                                    color: playerDamage > 0
                                        ? Colors.red
                                        : Colors.blue,
                                    style: const TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 8,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Right: Entity stats. fixed width, mirroring the left side
                      SizedBox(
                        width: 100,
                        child: buildEntityStatStack(entity, herbRequiredLevel),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  //entity hp bar
                  if (skillType != SkillId.FISHING &&
                      skillType != SkillId.HERBALISM)
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
                        id: equipedTool?.id ?? ItemId.NULL,
                        showInfoDialogOnTap: false,
                        borderColor: equipedTool == null
                            ? null
                            : qualityBorderColor(equipedTool.quality),
                        onTap: () => EquipmentPicker.build(
                          context,
                          // combat picks a weapon; gathering picks a tool for
                          // this entity's skill (fishing, mining, ...)
                          isCombatEntity
                              ? const [
                                  ArmorSlots.WEAPON_1H,
                                  ArmorSlots.WEAPON_2H,
                                ]
                              : const [ArmorSlots.TOOL],
                          (item) {
                            if (isCombatEntity) {
                              equipmentController.equipItem(item);
                            } else {
                              equipmentController.equipToolForSkill(
                                skillType,
                                item,
                              );
                            }
                          },
                          skillFilter: isCombatEntity
                              ? SkillId.NULL
                              : skillType,
                        ),
                      ),

                      if (isCombatEntity)
                        ItemStackTile(
                          size: 56,
                          count: equipedFoodItemCount,
                          id: equipedFoodItemId,
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
                  Divider(),
                  SkillTile(id: skillType),

                  if (herbLocked)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Requires Herbalism level $herbRequiredLevel",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),

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
                ],
              ),
            ),

            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: MomentumPrimaryButton(
                    enabled: !herbLocked,
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
                    },
                  ),
                ),
                SizedBox(width: 8),
                StopPrimaryButton(),
                SizedBox(width: 8),
                QueueAddButton(
                  enabled: entityId != EntityId.NULL,
                  onQueue: () => context
                      .read<ActionQueueController>()
                      .enqueueEncounter(entityId),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
