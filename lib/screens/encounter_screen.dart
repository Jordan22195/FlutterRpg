import 'package:flutter/material.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/buff_row.dart';
import 'package:rpg/widgets/eat_food_button.dart';
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
import '../widgets/skill_ring_row.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/fading_number.dart';
import '../data/ObjectStack.dart';

/// Snapshot of everything the shared combat layout renders for one frame.
/// World encounters and dungeon runs each build one from their own
/// controller, so the layout itself is defined exactly once, in
/// [CombatScreenState.build].
class CombatViewState {
  final String title;
  final EncounterEntity entity;
  final bool respawning;

  final int playerHp;
  final Map<SkillId, int> playerStats;

  // per-action feedback: damage the player dealt, and damage taken from
  // the entity, each with a sequence so the ui can replay repeats
  final int playerDamage;
  final int actionSequence;
  final int entityDamage;
  final int entityAttackSequence;

  /// Whether per-action damage numbers belong on this screen right now.
  final bool showActionFeedback;

  /// Drops collected this session (world) or this run (dungeon).
  final List<ObjectStack> drops;

  final ItemId foodItemId;
  final int foodItemCount;

  /// Skill level gate for gathering the entity (herbs); 0 = no gate.
  final int requiredLevel;
  final bool locked;

  const CombatViewState({
    required this.title,
    required this.entity,
    required this.respawning,
    required this.playerHp,
    required this.playerStats,
    required this.playerDamage,
    required this.actionSequence,
    required this.entityDamage,
    required this.entityAttackSequence,
    required this.showActionFeedback,
    required this.drops,
    required this.foodItemId,
    required this.foodItemCount,
    this.requiredLevel = 0,
    this.locked = false,
  });
}

/// The combat screen layout, defined once. The world encounter screen and
/// the dungeon run screen both extend this; a subclass supplies its data
/// snapshot ([resolveView]), its bottom bar ([buildActionBar]), and any
/// extra content above the fight ([buildAboveFight]). Changing the layout
/// here changes every combat screen.
///
/// Layout, top to bottom: skill rings for the skills the activity trains,
/// the centered entity portrait, the entity hp bar with a stat chip row
/// under it, active buffs, session drops. Combat pins a player hp strip
/// above the action bar; gathering shows no player state at all. Weapons
/// and tools are equipped on the gear screen, not here.
abstract class CombatScreenState<T extends StatefulWidget> extends State<T> {
  /// Builds this frame's data snapshot. Watch the owning controller here
  /// so the screen rebuilds with it.
  CombatViewState resolveView(BuildContext context);

  /// The pinned bottom controls (world: Action/Eat/Stop/Queue; dungeon:
  /// floor name + Leave or the loop/continue choice).
  Widget buildActionBar(BuildContext context, CombatViewState view);

  /// Optional content at the top of the scrollable area (dungeon: the
  /// floor progression list).
  Widget? buildAboveFight(BuildContext context) => null;

  /// Player hp/def/atk strip pinned above the action bar. Only combat
  /// needs it: gathering entities don't fight back.
  Widget buildPlayerStatusRow(
    BuildContext context,
    CombatViewState view,
    SkillId attackSkillType,
  ) {
    final stats = view.playerStats;
    final int maxHp = stats[SkillId.HITPOINTS] ?? 1;
    final int defence = stats[SkillId.DEFENCE] ?? 1;
    final int attack = stats[attackSkillType] ?? 1;
    final double hpPercent = maxHp <= 0
        ? 0.0
        : (view.playerHp / maxHp).clamp(0.0, 1.0);
    final muted = TextStyle(
      fontSize: 12,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 10),
      child: Row(
        children: [
          IconRenderer(id: SkillId.HITPOINTS, size: 18),
          const SizedBox(width: 4),
          Text(
            '${view.playerHp} / $maxHp',
            style: const TextStyle(fontSize: 13),
          ),
          // damage taken from the entity's attacks. fixed-width slot so
          // the flash doesn't shift the hp bar
          SizedBox(
            width: 28,
            child: FadingNumber(
              number: view.entityDamage,
              trigger: view.entityAttackSequence,
              autoplay: false,
              color: view.entityDamage > 0 ? Colors.red : Colors.blue,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: hpPercent),
              duration: const Duration(milliseconds: 100),
              builder: (context, animatedValue, child) {
                return FillBar(value: animatedValue);
              },
            ),
          ),
          const SizedBox(width: 12),
          IconRenderer(id: SkillId.DEFENCE, size: 16),
          const SizedBox(width: 3),
          Text('$defence', style: muted),
          const SizedBox(width: 10),
          IconRenderer(id: attackSkillType, size: 16),
          const SizedBox(width: 3),
          Text('$attack', style: muted),
        ],
      ),
    );
  }

  /// Entity stats as a centered chip row under the hp bar.
  Widget buildEntityStatChips(EncounterEntity entity, int requiredLevel) {
    const double fontSize = 14;
    const double iconSize = 20;
    final SkillId skillId = entity.entityType;

    // fishing spots replenish and herbs are picked in one action, so
    // neither shows hitpoints
    final bool showsHp =
        skillId != SkillId.FISHING && skillId != SkillId.HERBALISM;

    Widget chip(SkillId icon, String text) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconRenderer(id: icon, size: iconSize),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: fontSize)),
        ],
      );
    }

    final chips = <Widget>[
      if (showsHp) chip(SkillId.HITPOINTS, '${entity.hitpoints}'),
      chip(SkillId.DEFENCE, '${entity.defence}'),
      // level needed to gather this entity (herbs)
      if (requiredLevel > 0) chip(skillId, 'Lv $requiredLevel'),
      if (entity is CombatEntity) chip(SkillId.ATTACK, '${entity.attack}'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 16),
          chips[i],
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = resolveView(context);

    final entity = view.entity;
    final SkillId skillType = entity.entityType;
    final bool isCombatEntity = entity is CombatEntity;
    final EntityId entityId = entity.id;
    final int entityCount = entity.count;
    final double healthPercent = entity.maxHitPoints <= 0
        ? 0.0
        : (entity.hitpoints / entity.maxHitPoints).clamp(0.0, 1.0);

    // skills this activity trains: combat awards xp to the weapon skill,
    // hitpoints, and defence (blocked hits); gathering trains its own skill
    final trainedSkills = isCombatEntity
        ? [skillType, SkillId.HITPOINTS, SkillId.DEFENCE]
        : [skillType];

    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    final aboveFight = buildAboveFight(context);

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
                      view.title,
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
                  if (aboveFight != null) aboveFight,

                  SkillRingRow(skills: trainedSkills),
                  const SizedBox(height: 8),

                  // Centered entity portrait with the per-action damage
                  // number overlaid. a fixed 200x200 slot that only swaps
                  // its background between tile and respawn spinner, so
                  // nothing shifts and the damage number stays mounted
                  // across respawns
                  Center(
                    child: SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (view.respawning)
                            const Positioned.fill(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            ItemStackTile(
                              size: 200,
                              count: entityCount,
                              id: entityId,
                            ),
                          if (view.showActionFeedback)
                            FadingNumber(
                              number: view.playerDamage,
                              trigger: view.actionSequence,
                              autoplay: false,
                              color: view.playerDamage > 0
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
                  const SizedBox(height: 12),

                  //entity hp bar
                  if (skillType != SkillId.FISHING &&
                      skillType != SkillId.HERBALISM) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
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
                    const SizedBox(height: 8),
                  ],

                  buildEntityStatChips(entity, view.requiredLevel),

                  if (view.locked)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        "Requires Herbalism level ${view.requiredLevel}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),

                  BuffRow(),

                  Padding(
                    padding: const EdgeInsets.only(left: 2, top: 12, bottom: 4),
                    child: Text(
                      isCombatEntity
                          ? 'Loot this session'
                          : 'Gathered this session',
                      style: labelStyle,
                    ),
                  ),
                  Card(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 80,
                          child: InventoryGrid(items: view.drops),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (isCombatEntity) buildPlayerStatusRow(context, view, skillType),
            buildActionBar(context, view),
          ],
        ),
      ),
    );
  }
}

class EncounterScreen extends StatefulWidget {
  const EncounterScreen({super.key});

  @override
  State<EncounterScreen> createState() => _EncounterScreenState();
}

class _EncounterScreenState extends CombatScreenState<EncounterScreen> {
  @override
  CombatViewState resolveView(BuildContext context) {
    final controller = context.watch<EncounterController>();
    final entity = controller.getActiveEntity();

    return CombatViewState(
      title: entity.name,
      entity: entity,
      respawning: controller.respawning(),
      playerHp: controller.getPlayerHp(),
      playerStats: controller.getPlayerStats(),
      playerDamage: controller.latestActionResult.damageDone,
      actionSequence: controller.actionSequence,
      entityDamage: controller.latestEntityDamage,
      entityAttackSequence: controller.entityAttackSequence,
      // damage feedback belongs only to the encounter the actions fire on
      showActionFeedback: controller.isViewingActiveEncounter(),
      drops: controller.itemDrops(),
      foodItemId: controller.getEquipedFoodItemId(),
      foodItemCount: controller.getEquipedFoodItemCount(),
      // herbalism level gate: locked herbs stay visible but can't be picked
      requiredLevel: controller.viewedHerbRequiredLevel(),
      locked: controller.viewedHerbLocked(),
    );
  }

  @override
  Widget buildActionBar(BuildContext context, CombatViewState view) {
    final controller = context.read<EncounterController>();

    return Row(
      children: [
        MomentumPrimaryButton(
          enabled: !view.locked,
          label: "Action",
          startActionFunction: () {
            controller.startEncounterAction();
          },
        ),
        const SizedBox(width: 8),
        // gathering entities don't fight back, so there is nothing to eat
        // through; the eat control is combat-only
        if (view.entity is CombatEntity) ...[
          EatFoodButton(
            foodItemId: view.foodItemId,
            foodItemCount: view.foodItemCount,
            onEat: controller.eatSingleEquipedFood,
            onPickFood: () => FoodPicker.build(
              context,
              (id) => context.read<EquipmentController>().setEquipedFood(id),
            ),
          ),
          const SizedBox(width: 8),
        ],
        StopPrimaryButton(),
        const SizedBox(width: 8),
        QueueAddButton(
          enabled: view.entity.id != EntityId.NULL,
          onQueue: () => context.read<ActionQueueController>().enqueueEncounter(
            view.entity.id,
          ),
        ),
      ],
    );
  }
}
