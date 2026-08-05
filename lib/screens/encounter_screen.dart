import 'package:flutter/material.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/buff_row.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
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
/// the centered entity portrait, the entity status row (hp chip, hp bar,
/// stat chips), active buffs, session drops. Combat adds a matching player
/// status strip below it; gathering shows no player state at all. Weapons
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

  /// Tapping the entity portrait. World encounters open the entity details
  /// popup; a dungeon fight has no zone entity behind it, so it stays inert.
  VoidCallback? portraitTap(BuildContext context, EncounterEntity entity) =>
      null;

  /// Every slot on a status row except the bar itself is a fixed width, so
  /// the entity's bar and the player's bar start and end at the same x no
  /// matter how many digits their numbers run to.
  static const double _hpTextWidth = 58;
  static const double _damageSlotWidth = 28;
  static const double _statTextWidth = 24;
  static const double _statGap = 12;

  /// One stat chip on a status row: icon plus a fixed-width value.
  Widget buildStatChip(BuildContext context, SkillId icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: _statGap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconRenderer(id: icon, size: 16),
          const SizedBox(width: 3),
          SizedBox(
            width: _statTextWidth,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The shared status strip layout: hp chip, hp bar, then stat chips.
  /// Both the entity's row and the player's row are built from this so
  /// they stay identical. Pass a null [hp] for entities without
  /// hitpoints; the chip and bar collapse and the stats stay right-aligned.
  Widget buildStatusRow(
    BuildContext context, {
    int? hp,
    int? maxHp,
    Widget? damageSlot,
    Color? barColor,
    required List<Widget> stats,
  }) {
    final double hpPercent = (hp == null || maxHp == null || maxHp <= 0)
        ? 0.0
        : (hp / maxHp).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        children: [
          if (hp != null) ...[
            IconRenderer(id: SkillId.HITPOINTS, size: 18),
            const SizedBox(width: 4),
            SizedBox(
              width: _hpTextWidth,
              child: Text('$hp / $maxHp', style: const TextStyle(fontSize: 13)),
            ),
            SizedBox(width: _damageSlotWidth, child: damageSlot),
            Expanded(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(end: hpPercent),
                duration: const Duration(milliseconds: 100),
                builder: (context, animatedValue, child) {
                  return FillBar(
                    value: animatedValue,
                    foregroundColor: barColor,
                  );
                },
              ),
            ),
          ] else
            const Spacer(),
          ...stats,
        ],
      ),
    );
  }

  /// Player hp/def/atk strip pinned above the action bar. Only combat
  /// needs it: gathering entities don't fight back.
  Widget buildPlayerStatusRow(
    BuildContext context,
    CombatViewState view,
    SkillId attackSkillType,
  ) {
    final stats = view.playerStats;
    final int maxHp = stats[SkillId.HITPOINTS] ?? 1;

    return buildStatusRow(
      context,
      hp: view.playerHp,
      maxHp: maxHp,
      // damage taken from the entity's attacks. the slot is fixed-width so
      // the flash doesn't shift the hp bar
      damageSlot: FadingNumber(
        number: view.entityDamage,
        trigger: view.entityAttackSequence,
        autoplay: false,
        color: view.entityDamage > 0 ? Colors.red : Colors.blue,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
      stats: [
        buildStatChip(
          context,
          SkillId.DEFENCE,
          '${stats[SkillId.DEFENCE] ?? 1}',
        ),
        buildStatChip(
          context,
          attackSkillType,
          '${stats[attackSkillType] ?? 1}',
        ),
      ],
    );
  }

  /// Entity hp/def/atk strip, laid out like [buildPlayerStatusRow].
  Widget buildEntityStatusRow(
    BuildContext context,
    EncounterEntity entity,
    int requiredLevel,
  ) {
    final SkillId skillId = entity.entityType;

    // fishing spots replenish and herbs are picked in one action, so
    // neither shows hitpoints
    final bool showsHp =
        skillId != SkillId.FISHING && skillId != SkillId.HERBALISM;

    return buildStatusRow(
      context,
      hp: showsHp ? entity.hitpoints : null,
      maxHp: entity.maxHitPoints,
      barColor: Theme.of(context).colorScheme.tertiary,
      stats: [
        buildStatChip(context, SkillId.DEFENCE, '${entity.defence}'),
        // level needed to gather this entity (herbs)
        if (requiredLevel > 0)
          buildStatChip(context, skillId, 'Lv $requiredLevel'),
        if (entity is CombatEntity)
          buildStatChip(context, SkillId.ATTACK, '${entity.attack}'),
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
            // scrollable middle so short screens don't overflow; the
            // header above and action buttons below stay pinned
            Expanded(
              child: ListView(
                children: [
                  Row(
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
                  if (aboveFight != null) aboveFight,

                  const SizedBox(height: 8),

                  // Centered entity portrait with the per-action damage
                  // number overlaid. a fixed 200x200 slot that only swaps
                  // its background between tile and respawn spinner, so
                  // nothing shifts and the damage number stays mounted
                  // across respawns
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ItemStackTile(
                            size: 200,
                            count: entityCount,
                            id: entityId,
                            onTap: portraitTap(context, entity),
                            // nothing left to gather or fight: the action
                            // conditions already reject it, so the portrait
                            // reads as spent
                            depleted: entityCount <= 0,
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

                  buildEntityStatusRow(context, entity, view.requiredLevel),
                  buildPlayerStatusRow(context, view, skillType),

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
                  const SizedBox(height: 6),

                  BuffRow(),
                  SkillRingRow(skills: trainedSkills),

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
  VoidCallback? portraitTap(BuildContext context, EncounterEntity entity) {
    return () => showEntityInfoDialog(context, entity);
  }

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
          // a depleted entity has nothing left to take: the action
          // conditions reject it, so the button says so up front
          enabled: !view.locked && view.entity.count > 0,
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
        QueueAddButton(
          enabled: false,
          onQueue: () => context.read<ActionQueueController>().enqueueEncounter(
            view.entity.id,
          ),
        ),
      ],
    );
  }
}
