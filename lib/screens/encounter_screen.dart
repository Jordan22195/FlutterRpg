import 'package:flutter/material.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/widgets/encounter_info_panel.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
import 'package:rpg/widgets/eat_food_button.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:rpg/widgets/item_stack_tile.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/encounter_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/player_data_controller.dart';
import '../widgets/fill_bar.dart';
import '../widgets/primary_button.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../widgets/stance_button.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/fading_number.dart';
import '../widgets/skill_ring_row.dart';
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

  /// How far the entity is through its attack windup, 0..1. A getter rather
  /// than a value: the swing runs on wall clock between the attacks that
  /// notify, so the bar samples it every frame.
  final double Function()? entityActionProgress;

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
    this.entityActionProgress,
  });
}

/// The combat screen layout, defined once. The world encounter screen and
/// the dungeon run screen both extend this; a subclass supplies its data
/// snapshot ([resolveView]), its bottom bar ([buildActionBar]), and any
/// extra content above the fight ([buildAboveFight]). Changing the layout
/// here changes every combat screen.
///
/// Layout, top to bottom: the centered entity portrait, the entity status
/// row (hp chip, hp bar, stat chips), then the tabbed info panel holding
/// session drops, trained skill rings and active buffs. Combat adds a
/// matching player status strip below the entity's; gathering shows no
/// player state at all. Weapons and tools are equipped on the gear screen,
/// not here.
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
  static const double _rowLabelWidth = 50;
  static const double _damageSlotWidth = 28;
  static const double _statTextWidth = 28;
  static const double _statGap = 10;

  /// Height of a status row's hp bar. Tall enough to carry its own hp
  /// counter legibly.
  static const double _hpBarHeight = 20;

  /// The enemy's swing timer under the hp bar: a hairline, since it is a
  /// warning rather than a headline.
  static const double _actionBarHeight = 4;

  /// The player's own hp bar. Red like a hostile entity's — it is the same
  /// kind of bar, measuring the same thing — but a deeper shade, so the two
  /// rows never read as one.
  static const Color _playerHpColor = Color(0xFFA33636);

  /// The hp bar colour for an encounter, keyed on what is being worked:
  /// hostile red for anything that fights back, and the material's own
  /// colour for each gathering skill, so the bar says what kind of screen
  /// you are on before you have read a word of it.
  static Color entityBarColor(BuildContext context, EncounterEntity entity) {
    if (entity is CombatEntity) return const Color(0xFFE05252);

    switch (entity.entityType) {
      case SkillId.MINING:
        return const Color(0xFF8FA3B0); // ore grey
      case SkillId.WOODCUTTING:
        // deep forest green, against herbalism's brighter leaf: the two
        // gathering greens have to stay apart at a glance
        return const Color(0xFF3F8F4E);
      case SkillId.HERBALISM:
        return const Color(0xFF7FC24B); // leaf
      case SkillId.FISHING:
        return const Color(0xFF3FA9C9); // water
      default:
        return Theme.of(context).colorScheme.tertiary;
    }
  }

  /// Who a row belongs to, in the fixed-width slot every row starts with so
  /// the bars and rings below it all line up on the same x.
  Widget buildRowLabel(BuildContext context, String label) {
    return SizedBox(
      width: _rowLabelWidth,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }

  /// One stat chip on a status row: icon plus a fixed-width value.
  Widget buildStatChip(BuildContext context, SkillId icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: _statGap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconRenderer(id: icon, size: 22),
          const SizedBox(width: 4),
          SizedBox(
            width: _statTextWidth,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The shared status strip layout: who the row belongs to, the hp bar
  /// carrying its own counter, then stat chips. Both the entity's row and
  /// the player's row are built from this so they stay identical. Pass a
  /// null [hp] for entities without hitpoints; the bar collapses and the
  /// stats stay right-aligned.
  ///
  /// [actionProgress], when given, adds a hairline under the hp bar tracking
  /// the entity's swing timer. It is sampled every frame off the action
  /// timing loop rather than read once at build.
  Widget buildStatusRow(
    BuildContext context, {
    required String label,
    int? hp,
    int? maxHp,
    Widget? damageSlot,
    Color? barColor,
    double Function()? actionProgress,
    required List<Widget> stats,
  }) {
    final double hpPercent = (hp == null || maxHp == null || maxHp <= 0)
        ? 0.0
        : (hp / maxHp).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        children: [
          SizedBox(width: 10),
          buildRowLabel(context, label),
          if (hp != null) ...[
            SizedBox(width: _damageSlotWidth, child: damageSlot),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(end: hpPercent),
                    duration: const Duration(milliseconds: 100),
                    builder: (context, animatedValue, child) {
                      return FillBar(
                        value: animatedValue,
                        height: _hpBarHeight,
                        foregroundColor: barColor,
                        // the counter rides in the bar, so the bar can be
                        // as wide as the row allows
                        child: Text(
                          '$hp / $maxHp',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                              Shadow(blurRadius: 3, color: Colors.black87),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (actionProgress != null) ...[
                    const SizedBox(height: 3),
                    _EntityActionProgressBar(progress: actionProgress),
                  ],
                ],
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
      label: 'Player',
      hp: view.playerHp,
      maxHp: maxHp,
      barColor: _playerHpColor,
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

  /// The player's side of a gathering screen, in place of the hp strip
  /// combat gets: the rings for what the activity trains, between the same
  /// row label and stat slots the rows above it use. Nothing gathered fights
  /// back, so the only stat that applies is the level being rolled — the
  /// total with gear and buffs, which is what the roll actually uses.
  Widget buildGatheringStatusRow(
    BuildContext context,
    CombatViewState view,
    SkillId gatheringSkill,
    List<SkillId> trainedSkills,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Row(
        children: [
          buildRowLabel(context, 'You'),
          Expanded(child: ActivitySkillRingRow(skills: trainedSkills)),
          buildStatChip(
            context,
            gatheringSkill,
            '${view.playerStats[gatheringSkill] ?? 1}',
          ),
        ],
      ),
    );
  }

  /// Entity hp/def/atk strip, laid out like [buildPlayerStatusRow]: the two
  /// rows mirror each other, each carrying the damage the other one dealt.
  Widget buildEntityStatusRow(
    BuildContext context,
    EncounterEntity entity,
    int requiredLevel, {
    Widget? damageSlot,
    double Function()? actionProgress,
  }) {
    final SkillId skillId = entity.entityType;
    final bool isCombatEntity = entity is CombatEntity;

    // fishing spots replenish and herbs are picked in one action, so
    // neither shows hitpoints
    final bool showsHp =
        skillId != SkillId.FISHING && skillId != SkillId.HERBALISM;

    return buildStatusRow(
      context,
      // only something that fights back is an enemy; everything else on
      // this screen is being gathered
      label: isCombatEntity ? 'Enemy' : 'Target',
      hp: showsHp ? entity.hitpoints : null,
      maxHp: entity.maxHitPoints,
      // damage the player's action dealt, in the same fixed-width slot the
      // player's row keeps for the damage coming back the other way
      damageSlot: damageSlot,
      barColor: entityBarColor(context, entity),
      // only a combat entity has a swing to wind up
      actionProgress: isCombatEntity ? actionProgress : null,
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

    // skills this encounter trains on its own: combat awards xp to the weapon
    // skill, hitpoints, and defence (blocked hits); gathering trains its own
    // skill. the action loop's own three are added by ActivitySkillRingRow
    final trainedSkills = isCombatEntity
        ? [skillType, SkillId.HITPOINTS, SkillId.DEFENCE]
        : [skillType];

    // combat picks an attack style; mining and woodcutting pick strong or
    // fast; everything else is locked to fast by the encounter start
    final stances = stancesForEntity(entity);

    final aboveFight = buildAboveFight(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(1),
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

                  // Centered entity portrait. The damage the player deals
                  // reports beside the entity's hp bar below, where the
                  // damage coming back reports beside the player's, so the
                  // portrait itself carries nothing but the entity.
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: ItemStackTile(
                        size: 200,
                        count: entityCount,
                        id: entityId,
                        onTap: portraitTap(context, entity),
                        // nothing left to gather or fight: the action
                        // conditions already reject it, so the portrait
                        // reads as spent
                        depleted: entityCount <= 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  buildEntityStatusRow(
                    context,
                    entity,
                    view.requiredLevel,
                    // damage the player dealt this action, mirroring the
                    // entity's damage on the player's row below
                    damageSlot: view.showActionFeedback
                        ? FadingNumber(
                            number: view.playerDamage,
                            trigger: view.actionSequence,
                            autoplay: false,
                            color: view.playerDamage > 0
                                ? Colors.red
                                : Colors.blue,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                    actionProgress: view.entityActionProgress,
                  ),
                  // combat needs the player's own hp and stats in view;
                  // nothing gathered fights back, so that strip gives way to
                  // the rings for the skills the activity trains
                  if (isCombatEntity)
                    buildPlayerStatusRow(context, view, skillType)
                  else
                    buildGatheringStatusRow(
                      context,
                      view,
                      skillType,
                      trainedSkills,
                    ),

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

                  // loot, active buffs and (per screen) trained skills or the
                  // entity's details share one slot, switched by tab
                  EncounterInfoPanel(
                    // gathering draws its rings above the panel, so the tab
                    // would only repeat them; it gets the entity's details
                    // in that slot instead of reaching them by popup. the
                    // placeholder entity a screen falls back to has no
                    // details to build, so it gets neither
                    skills: isCombatEntity ? trainedSkills : null,
                    infoEntity: isCombatEntity || entityId == EntityId.NULL
                        ? null
                        : entity,
                    drops: view.drops,
                    lootLabel: isCombatEntity ? 'Loot' : 'Gathered',
                    emptyLootLabel: isCombatEntity
                        ? 'No loot this session'
                        : 'Nothing gathered this session',
                  ),
                ],
              ),
            ),

            // stance, pinned with the action bar so it stays reachable
            // mid-action. an entity with a single stance offers no choice,
            // so the row is left out entirely
            if (stances.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: StanceButton(stances: stances),
              ),

            buildActionBar(context, view),
          ],
        ),
      ),
    );
  }
}

/// The enemy's swing timer, drawn under its hp bar. The windup runs on wall
/// clock between the attacks that notify, so the bar rides the action timing
/// loop's per-frame ticks and re-samples [progress] on each one — and only
/// this hairline rebuilds, not the screen around it.
class _EntityActionProgressBar extends StatelessWidget {
  const _EntityActionProgressBar({required this.progress});

  final double Function() progress;

  @override
  Widget build(BuildContext context) {
    final timing = context.read<ActionTimingController>();

    return AnimatedBuilder(
      animation: timing,
      builder: (context, _) => FillBar(
        value: progress(),
        height: CombatScreenState._actionBarHeight,
        // amber rather than red: it sits directly under a red combat hp bar,
        // and a winding-up swing has to read as its own thing
        foregroundColor: const Color(0xFFF2A93B),
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
    // a gathering screen carries the same details in its info tab, so the
    // popup is combat's way in only
    if (entity is! CombatEntity) return null;
    return () => showEntityInfoDialog(context, entity);
  }

  @override
  CombatViewState resolveView(BuildContext context) {
    final controller = context.watch<EncounterController>();
    // the stat chips read player totals, which the stance (and gear, xp,
    // buffs) move without the encounter controller ever notifying
    context.watch<PlayerDataController>();
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
      entityActionProgress: controller.entityAttackProgress,
    );
  }

  @override
  Widget buildActionBar(BuildContext context, CombatViewState view) {
    final controller = context.read<EncounterController>();

    return ActionButtonRow(
      actionButton: MomentumPrimaryButton(
        // a depleted entity has nothing left to take: the action
        // conditions reject it, so the button says so up front
        enabled: !view.locked && view.entity.count > 0,
        label: "Action",
        startActionFunction: () {
          controller.startEncounterAction();
        },
      ),
      trailing: [
        // gathering entities don't fight back, so there is nothing to eat
        // through; the eat control is combat-only
        if (view.entity is CombatEntity)
          EatFoodButton(
            foodItemId: view.foodItemId,
            foodItemCount: view.foodItemCount,
            onEat: controller.eatSingleEquipedFood,
            onPickFood: () => FoodPicker.build(
              context,
              (id) => context.read<EquipmentController>().setEquipedFood(id),
            ),
          ),
      ],
    );
  }
}
