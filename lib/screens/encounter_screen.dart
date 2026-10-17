import 'package:flutter/material.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/encounter_info_panel.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
import 'package:rpg/widgets/eat_food_button.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:provider/provider.dart';
import '../catalogs/entities/entities.dart';
import '../controllers/encounter_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/player_data_controller.dart';
import '../controllers/world_controller.dart';
import '../data/skill_category.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../widgets/action_dock.dart';
import '../widgets/art_header.dart';
import '../widgets/fill_bar.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/stage_panel.dart';
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

  /// Equipment dropped alongside [drops], kept as instances so the loot tab
  /// frames each piece in the quality it rolled.
  final List<EquipmentItem> equipmentDrops;

  /// Entities still queued behind the one on screen, in queue order. Empty
  /// for a world encounter, which has no queue behind it.
  final List<EncounterEntity> queueRemaining;

  final ItemId foodItemId;
  final int foodItemCount;

  /// Skill level gate for gathering the entity (herbs); 0 = no gate.
  final int requiredLevel;
  final bool locked;

  /// How far the entity is through its attack windup, 0..1. A getter rather
  /// than a value: the swing runs on wall clock between the attacks that
  /// notify, so the bar samples it every frame.
  final double Function()? entityActionProgress;

  /// The player's action timer on this screen, sampled per frame like the
  /// entity's. Both read zero unless the action loop is firing on the entity
  /// in view, so a run against one target draws nothing on another's screen.
  final double Function() playerActionProgress;
  final Duration Function() playerActionInterval;

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
    this.equipmentDrops = const [],
    required this.foodItemId,
    required this.foodItemCount,
    required this.playerActionProgress,
    required this.playerActionInterval,
    this.queueRemaining = const [],
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
  static const double _labelGap = 12;
  static const double _statIconSize = 16;
  static const double _statTextWidth = 30;
  static const double _statGap = 8;

  /// Height of a status row's hp bar. Tall enough to carry its own hp
  /// counter legibly.
  static const double _hpBarHeight = 22;

  /// Gap between a row's hp bar and the action timer beneath it.
  static const double _timerGap = 6;

  /// Gap between the two participant rows.
  static const double _rowGap = 10;

  /// The band at the top of a gathering row's column that the timer is
  /// centred in — as tall as the hp bar on the row above, so the label, the
  /// timer and the stat chip all read as sitting on one line.
  static const double _gatheringTimerBand = _hpBarHeight;

  /// The bar colour for an encounter: hp for anything that fights back, and
  /// the gathering skill's own colour for a node's durability, so the bar
  /// says what kind of screen you are on before you have read a word of it.
  static Color entityBarColor(BuildContext context, EncounterEntity entity) {
    if (entity is CombatEntity) return context.gameColors.hp;
    return skillRingColor(entity.entityType);
  }

  /// Damage dealt or taken, flashed over an hp bar: hp-coloured for a hit,
  /// muted for a miss.
  Widget buildDamageNumber(BuildContext context, int damage, int sequence) {
    return FadingNumber(
      number: damage,
      trigger: sequence,
      autoplay: false,
      color: damage > 0 ? context.gameColors.hp : context.palette.textMuted,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        shadows: [Shadow(blurRadius: 4, color: context.palette.titleShadow)],
      ),
    );
  }

  /// Who a row belongs to, in the fixed-width slot every row starts with so
  /// the bars and rings below it all line up on the same x — here and on the
  /// explore screen, which shares the column.
  Widget buildRowLabel(BuildContext context, String label) =>
      EncounterRowLabel(label);

  /// One stat chip on a status row: icon plus a fixed-width value.
  Widget buildStatChip(BuildContext context, SkillId icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: _statGap),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconRenderer(id: icon, size: _statIconSize),
          const SizedBox(width: 4),
          SizedBox(
            width: _statTextWidth,
            child: Text(
              text,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: HearthText.statusStat.copyWith(
                fontSize: 15,
                color: context.palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The shared status strip layout: who the row belongs to, the hp bar
  /// carrying its own counter with the row's attack timer under it, then
  /// stat chips. Both the entity's row and the player's row are built from
  /// this so they stay identical. Pass a null [hp] for entities without
  /// hitpoints; the bar collapses and the stats stay right-aligned.
  ///
  /// [damageSlot] flashes over the right end of the bar: the damage the
  /// other side dealt this action.
  Widget buildStatusRow(
    BuildContext context, {
    required String label,
    int? hp,
    int? maxHp,
    Widget? damageSlot,
    Color? barColor,
    Widget? timer,
    required List<Widget> stats,
  }) {
    final double hpPercent = (hp == null || maxHp == null || maxHp <= 0)
        ? 0.0
        : (hp / maxHp).clamp(0.0, 1.0);
    final palette = context.palette;
    final colors = context.gameColors;

    return Padding(
      padding: const EdgeInsets.only(bottom: _rowGap),
      child: Row(
        children: [
          buildRowLabel(context, label),
          const SizedBox(width: _labelGap),
          if (hp != null)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween<double>(end: hpPercent),
                        duration: const Duration(milliseconds: 100),
                        builder: (context, animatedValue, child) {
                          return FillBar(
                            value: animatedValue,
                            height: _hpBarHeight,
                            borderRadius: 7,
                            backgroundColor: palette.track,
                            foregroundColor: barColor ?? colors.hp,
                            // the counter rides in the bar, so the bar can
                            // be as wide as the row allows
                            child: Text(
                              '$hp / $maxHp',
                              style: HearthText.ringNumber.copyWith(
                                color: colors.onHp,
                                shadows: [
                                  Shadow(
                                    blurRadius: 3,
                                    color: palette.titleShadow,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      if (damageSlot != null)
                        Positioned(
                          right: 6,
                          top: 0,
                          bottom: 0,
                          child: IgnorePointer(
                            child: Center(child: damageSlot),
                          ),
                        ),
                    ],
                  ),
                  if (timer != null) ...[
                    const SizedBox(height: _timerGap),
                    timer,
                  ],
                ],
              ),
            )
          else
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
      barColor: context.gameColors.hp,
      // the player's own action timer, in the same slot under the hp bar the
      // entity's sits in on the row above — the two are read against each
      // other, so they are drawn identically
      timer: ActionTimer(
        actor: ActionTimerActor.player,
        progress: view.playerActionProgress,
        interval: view.playerActionInterval,
      ),
      // damage taken from the entity's attacks, flashed over the bar
      damageSlot: buildDamageNumber(
        context,
        view.entityDamage,
        view.entityAttackSequence,
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
  ///
  /// With no hp bar to hang it under, the action timer takes the bar slot at
  /// the top of the column — the same place on the row combat's player timer
  /// sits, so moving between the two screens never moves the timer.
  Widget buildGatheringStatusRow(
    BuildContext context,
    CombatViewState view,
    SkillId gatheringSkill,
    List<SkillId> trainedSkills,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: _rowGap - 2),
      child: Row(
        // the rings make this column far taller than the combat row's, so the
        // label and stat chip are pinned to the top band the timer sits in
        // rather than centred against the whole thing — centred, the label
        // drifts down beside the rings and the timer reads as the target's
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: _gatheringTimerBand,
            child: buildRowLabel(context, 'You'),
          ),
          // the same gap the bar rows keep, so this column starts where the
          // target's bar above it does
          const SizedBox(width: _labelGap),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _gatheringTimerBand,
                  child: Center(
                    child: ActionTimer(
                      progress: view.playerActionProgress,
                      interval: view.playerActionInterval,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ActivitySkillRingRow(skills: trainedSkills),
              ],
            ),
          ),
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
      // only a combat entity has a swing to wind up. a gathering target has
      // no timer of its own: the timer on this screen belongs to the player,
      // and is drawn on the player's row
      timer: entity is CombatEntity && actionProgress != null
          ? ActionTimer(
              actor: ActionTimerActor.enemy,
              progress: actionProgress,
              interval: () => Duration(
                milliseconds: (entity.attackInterval * 1000).round(),
              ),
            )
          : null,
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

  /// The entity being worked, standing in a stage panel tinted for what it
  /// is, with how many are left in the corner and the rest of its queue
  /// down the left edge.
  ///
  /// The rail runs bottom-up: the next entity sits at the bottom, closest
  /// to the fight it is about to join, and the tail of the queue climbs away
  /// from it. Tiles open their details, which is how a boss's drops are
  /// read before you reach it.
  Widget buildPortrait(BuildContext context, CombatViewState view) {
    final entity = view.entity;
    final kind = entity is CombatEntity
        ? SpriteKind.combat
        : SpriteKind.gathering;
    final tint = SpriteFrame.tintFor(context, kind);

    Widget sprite = IconRenderer(size: 124, id: entity.id);
    // nothing left to gather or fight: the action conditions already reject
    // it, so the sprite reads as spent
    if (entity.count <= 0) {
      sprite = ColorFiltered(
        colorFilter: ColorFilter.mode(
          context.palette.bg.withValues(alpha: 0.65),
          BlendMode.srcATop,
        ),
        child: sprite,
      );
    }

    return StagePanel(
      tint: tint,
      sprite: sprite,
      onTap: portraitTap(context, entity),
      corner: StageCountPill(count: entity.count, borderColor: tint.border),
      leading: view.queueRemaining.isEmpty
          ? null
          : SizedBox(
              width: 40,
              child: ListView(
                reverse: true,
                padding: EdgeInsets.zero,
                children: [
                  for (final queued in view.queueRemaining)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: SpriteFrame(
                        id: queued.id,
                        kind: SpriteKind.combat,
                        size: 40,
                        spriteSize: 30,
                        radius: 10,
                        onTap: () => showEntityInfoDialog(context, queued),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = resolveView(context);

    final entity = view.entity;
    final SkillId skillType = entity.entityType;
    final bool isCombatEntity = entity is CombatEntity;
    final EntityId entityId = entity.id;

    // skills this encounter trains on its own: combat awards xp to the
    // weapon skill, hitpoints, and defence - which of the two damage skills
    // is paid depends on the stance, so both get a ring. gathering trains
    // its own skill. the action loop's own three are added by
    // ActivitySkillRingRow
    final trainedSkills = isCombatEntity
        ? [skillType, SkillId.HITPOINTS, SkillId.DEFENCE]
        : [skillType];

    // combat picks an attack style; mining and woodcutting pick strong or
    // fast; everything else is locked to fast by the encounter start
    final stances = stancesForEntity(entity);

    final aboveFight = buildAboveFight(context);

    final zone = context.watch<WorldController>().viewedZoneDefinition();
    final topPadding = MediaQuery.paddingOf(context).top;
    final level = entity is CombatEntity ? entity.level : entity.defence;

    // the top is left open: the zone's art strip runs up behind the status
    // bar, as on the zone screen this one opens from
    return SafeArea(
      top: false,
      child: Column(
        children: [
          SizedBox(
            height: ArtHeader.collapsedHeight(topPadding),
            child: ArtHeader(
              title: view.title,
              subtitle: zone.name,
              collapse: 1,
              artAsset: zone.iconAsset.isEmpty ? null : zone.iconAsset,
              backLabel: 'Back to ${zone.name}',
              trailing: entityId == EntityId.NULL
                  ? null
                  : ArtHeaderChip(
                      label: 'Lv $level',
                      semanticsLabel: 'Level $level',
                    ),
            ),
          ),
          // scrollable middle so short screens don't overflow; the header
          // above and the dock below stay pinned
          Expanded(
            child: ListView(
              // room at the bottom for the dock's fade to fall on
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                if (aboveFight != null) aboveFight,

                // the entity, with whatever is queued behind it. the damage
                // the player deals reports on the entity's hp bar below, and
                // the damage coming back on the player's, so the stage
                // carries nothing but the entity
                buildPortrait(context, view),
                const SizedBox(height: 16),

                buildEntityStatusRow(
                  context,
                  entity,
                  view.requiredLevel,
                  // damage the player dealt this action, mirroring the
                  // entity's damage on the player's row below
                  damageSlot: view.showActionFeedback
                      ? buildDamageNumber(
                          context,
                          view.playerDamage,
                          view.actionSequence,
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
                      style: HearthText.rowMeta.copyWith(
                        color: context.gameColors.hp,
                      ),
                    ),
                  ),
                const SizedBox(height: 6),

                // loot, active buffs and (per screen) trained skills or the
                // entity's details share one slot, switched by tab
                EncounterInfoPanel(
                  // gathering draws its rings above the panel, so the tab
                  // would only repeat them; it gets the entity's details in
                  // that slot instead of reaching them by popup. the
                  // placeholder entity a screen falls back to has no details
                  // to build, so it gets neither
                  skills: isCombatEntity ? trainedSkills : null,
                  infoEntity: entityId == EntityId.NULL ? null : entity,
                  drops: view.drops,
                  equipment: view.equipmentDrops,
                  lootLabel: isCombatEntity ? 'Loot' : 'Gathered',
                  emptyLootLabel: isCombatEntity
                      ? 'No loot this session'
                      : 'Nothing gathered this session',
                ),
              ],
            ),
          ),

          // the style switch rides in the dock with the buttons, so it stays
          // reachable mid-action. an entity with a single stance offers no
          // choice, so the row is left out entirely
          ActionDock(
            topRow: stances.length > 1 ? StanceButton(stances: stances) : null,
            buttons: buildActionBar(context, view),
          ),
        ],
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
      equipmentDrops: controller.equipmentDrops(),
      // a dungeon card's queue; empty for a zone entity
      queueRemaining: controller.queueRemaining(),
      foodItemId: controller.getEquipedFoodItemId(),
      foodItemCount: controller.getEquipedFoodItemCount(),
      // herbalism level gate: locked herbs stay visible but can't be picked
      requiredLevel: controller.viewedHerbRequiredLevel(),
      locked: controller.viewedHerbLocked(),
      entityActionProgress: controller.entityAttackProgress,
      // both gated on this screen being the one the actions fire on
      playerActionProgress: controller.playerActionProgress,
      playerActionInterval: controller.playerActionInterval,
    );
  }

  @override
  Widget buildActionBar(BuildContext context, CombatViewState view) {
    final controller = context.read<EncounterController>();

    return ActionButtonRow(
      // the dock pads the row
      padding: EdgeInsets.zero,
      actionButton: ActionOrTravelButton(
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
