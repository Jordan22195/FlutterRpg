import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/widgets/action_timer.dart';
import 'package:rpg/widgets/encounter_info_panel.dart';
import 'package:rpg/widgets/entity_info_dialog.dart';
import 'package:rpg/widgets/eat_food_button.dart';
import 'package:rpg/widgets/equipment_picker.dart';
import 'package:provider/provider.dart';
import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/zones/zones.dart';
import '../controllers/action_timing_controller.dart';
import '../controllers/dungeon_controller.dart';
import '../controllers/encounter_controller.dart';
import '../controllers/equipment_controller.dart';
import '../controllers/player_data_controller.dart';
import '../controllers/world_controller.dart';
import '../data/entity_queue.dart';
import '../data/skill_category.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../widgets/action_dock.dart';
import '../widgets/art_header.dart';
import '../widgets/boss_arena.dart';
import '../widgets/floor_clear_panel.dart';
import '../data/floor_clear_summary.dart';
import '../widgets/dungeon_floor_track.dart';
import '../widgets/explore_card.dart';
import '../widgets/fill_bar.dart';
import '../widgets/sprite_frame.dart';
import '../widgets/stage_panel.dart';
import '../widgets/travel_row.dart';
import '../widgets/primary_button.dart';
import '../data/combat_tuning.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../widgets/stance_button.dart';
import '../widgets/icon_renderer.dart';
import '../widgets/item_stack_tile.dart';
import '../widgets/fading_number.dart';
import '../widgets/skill_ring_row.dart';
import '../data/ObjectStack.dart';
import '../data/item_drop_type.dart';

/// How a hit the player deals rolled, which is what colours its number.
enum HitTier {
  /// Nothing landed.
  miss,

  /// Below the average hit.
  low,

  /// At or above the average hit.
  high,

  /// The top of the range.
  max;

  /// Classifies [damage] against a swing whose range tops out at [maxRoll]:
  /// hits roll evenly from 1 to [maxRoll], so the average is halfway along.
  /// [maxHit] is the roll's own word that it hit the top. With no range to
  /// read ([maxRoll] zero), any hit counts as high.
  static HitTier of(int damage, {required int maxRoll, bool maxHit = false}) {
    if (damage <= 0) return HitTier.miss;
    if (maxHit || (maxRoll > 0 && damage >= maxRoll)) return HitTier.max;
    if (maxRoll <= 0) return HitTier.high;
    return damage * 2 >= maxRoll + 1 ? HitTier.high : HitTier.low;
  }
}

/// The dungeon floor a combat screen is fighting through: which floor of
/// which dungeon, its live queue, and how many of each member it starts
/// with.
class DungeonFloorView {
  final DungeonId id;
  final int index;
  final EntityQueue floor;
  final List<int> fullCounts;

  /// Loop dungeon rather than Loop floor.
  final bool loopsDungeon;

  /// The floor just cleared, while the loop pauses on its summary before
  /// the next one. Null the rest of the time.
  final FloorClearSummary? cleared;

  /// Where the loop runs on to after this floor, and that floor's name.
  final int nextIndex;
  final String nextName;

  const DungeonFloorView({
    required this.id,
    required this.index,
    required this.floor,
    required this.fullCounts,
    required this.loopsDungeon,
    this.cleared,
    int? nextIndex,
    this.nextName = '',
  }) : nextIndex = nextIndex ?? index;

  /// How many of the member being fought the floor started with.
  int get currentFullCount =>
      floor.index < fullCounts.length ? fullCounts[floor.index] : 0;
}

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

  /// What the player's last fishing cast landed: the times it rolled the
  /// catch table, and whether its damage was the top of its range.
  final int playerCatches;
  final bool playerMaxHit;

  /// The top of the player's swing range, for reading their last hit as low
  /// or high against its average. Zero when the action rolls no range.
  final int playerMaxRoll;

  /// The fish the last cast brought up, for the catch chip's icon. Null on
  /// a miss.
  final ItemId? playerCatchItem;

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

  /// The dungeon floor being fought through; null for a world encounter.
  /// With one, the screen is the floor's: its name heads the screen, its
  /// track sits over the fight, and the entity's name moves onto the stage.
  final DungeonFloorView? dungeonFloor;

  final ItemId foodItemId;
  final int foodItemCount;

  /// Skill level gate for gathering the entity (herbs); 0 = no gate.
  final int requiredLevel;
  final bool locked;

  /// The gathering skill whose tool the entity needs and the player hasn't
  /// equipped — an axe for a tree. Null when nothing is missing.
  final SkillId? missingTool;

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
    this.playerCatches = 0,
    this.playerMaxHit = false,
    this.playerMaxRoll = 0,
    this.playerCatchItem,
    required this.showActionFeedback,
    required this.drops,
    this.equipmentDrops = const [],
    required this.foodItemId,
    required this.foodItemCount,
    required this.playerActionProgress,
    required this.playerActionInterval,
    this.queueRemaining = const [],
    this.dungeonFloor,
    this.requiredLevel = 0,
    this.locked = false,
    this.missingTool,
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

  /// How long a cast's catch chip stays up at full strength before it
  /// fades: long enough to read the fish and the count, where a damage
  /// number is a single figure taken in at a glance.
  static const Duration catchChipHold = Duration(milliseconds: 800);

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

  /// The player's hit on the target, floated up beside its sprite on the
  /// stage, clear of every bar. Its colour says how it rolled — blue for a
  /// miss, yellow below the average hit, red at or above it — and a max hit
  /// comes up bigger and heavier, in dark red.
  Widget buildHitNumber(BuildContext context, CombatViewState view) {
    final palette = context.palette;
    final damage = view.playerDamage;
    final tier = HitTier.of(
      damage,
      maxRoll: view.playerMaxRoll,
      maxHit: view.playerMaxHit,
    );
    final isMax = tier == HitTier.max;
    return FadingNumber(
      key: const ValueKey('hit-number'),
      number: damage,
      trigger: view.actionSequence,
      autoplay: false,
      rise: isMax ? 24 : 18,
      color: switch (tier) {
        HitTier.miss => GameColors.hitMiss,
        HitTier.low => GameColors.hitLow,
        HitTier.high => GameColors.hitHigh,
        HitTier.max => GameColors.hitMax,
      },
      style: HearthText.title.copyWith(
        fontSize: 26,
        height: 1,
        shadows: [
          Shadow(offset: const Offset(0, 2), color: palette.titleShadow),
          Shadow(blurRadius: 6, color: palette.titleShadow),
        ],
      ),
      // a max hit is set in the heavy body face, which holds its shape at
      // size where the pixel face smears
      child: isMax ? _maxHitNumber(context, damage) : null,
    );
  }

  Widget _maxHitNumber(BuildContext context, int damage) {
    return Text(
      '$damage',
      style: TextStyle(
        fontFamily: HearthText.body,
        fontSize: 32,
        fontWeight: FontWeight.w800,
        height: 1.1,
        color: GameColors.hitMax,
        fontFeatures: const [FontFeature.tabularFigures()],
        shadows: [
          Shadow(
            offset: const Offset(0, 2),
            color: context.palette.titleShadow,
          ),
        ],
      ),
    );
  }

  /// What an action did, flashed in the band of a row with no bar — an
  /// herb picked. Hp-coloured for a hit, muted for a miss.
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

  /// Damage the player took, flashed under their row's label — beside the
  /// hp bar it came off rather than over it. Hp-coloured for a hit, muted
  /// for a miss.
  Widget buildDamageTaken(BuildContext context, int damage, int sequence) {
    final palette = context.palette;
    final color = damage > 0 ? context.gameColors.hp : palette.textMuted;
    return FadingNumber(
      key: const ValueKey('damage-taken'),
      number: damage,
      trigger: sequence,
      autoplay: false,
      child: Text(
        damage > 0 ? '−$damage' : '0',
        style: HearthText.statusStat.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          height: 1.1,
          color: color,
          shadows: [Shadow(blurRadius: 4, color: palette.titleShadow)],
        ),
      ),
    );
  }

  /// A fishing cast's catches, flashed where the damage number sits on the
  /// other screens: the fish's icon and how many it rolled, muted for a
  /// miss, in [GameColors.maxHit] for a max-hit cast. A miss brought nothing
  /// up, so it shows the spot's first fish.
  Widget buildCatchChip(
    BuildContext context,
    EncounterEntity entity,
    ItemId? fish,
    int catches,
    bool maxHit,
    int sequence,
  ) {
    final palette = context.palette;
    final colors = context.gameColors;
    final color = catches <= 0
        ? palette.textMuted
        : maxHit
        ? colors.maxHit
        : palette.text;
    return FadingNumber(
      key: const ValueKey('catch-chip'),
      number: catches,
      trigger: sequence,
      autoplay: false,
      hold: catchChipHold,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: palette.track,
          borderRadius: BorderRadius.circular(_hpBarHeight / 2),
          border: Border.all(
            color: maxHit && catches > 0 ? colors.maxHit : palette.track,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconRenderer(id: fish ?? _firstFish(entity), size: _statIconSize),
            const SizedBox(width: 3),
            Text(
              '$catches',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
                shadows: [Shadow(blurRadius: 4, color: palette.titleShadow)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static ItemId? _firstFish(EncounterEntity entity) {
    final def = entity.id.definition;
    if (def is! EncounterEntityDefinition) return null;
    final drops = def.itemDrops.flattened;
    return drops.isEmpty ? null : drops.first.id;
  }

  /// Who a row belongs to, in the fixed-width slot every row starts with so
  /// the bars and rings below it all line up on the same x — here and on the
  /// explore screen, which shares the column.
  Widget buildRowLabel(BuildContext context, String label) =>
      EncounterRowLabel(label);

  /// One stat chip on a status row: icon plus a fixed-width value.
  ///
  /// [boost] tints the value while a strength stance is lending to it: one
  /// colour while the bar is part way up, a hotter one held full.
  Widget buildStatChip(
    BuildContext context,
    SkillId icon,
    String text, {
    StatBoost? boost,
  }) {
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
                color: switch (boost) {
                  StatBoost.partial => context.gameColors.boostPartial,
                  StatBoost.full => context.gameColors.boostFull,
                  null => context.palette.text,
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One of the player's own stat chips. It rebuilds with the action loop
  /// rather than with the screen, so the value and its boost tint follow the
  /// strength stance's bar frame by frame as it fills and drains.
  Widget buildPlayerStatChip(BuildContext context, SkillId skill) => Builder(
    key: ValueKey('playerStat-${skill.name}'),
    builder: (context) {
      context.watch<ActionTimingController>();
      final player = context.read<PlayerDataController>();
      return buildStatChip(
        context,
        skill,
        '${player.getStatTotal(skill)}',
        boost: player.statBoosts()[skill],
      );
    },
  );

  /// The shared status strip layout: who the row belongs to, the hp bar
  /// carrying its own counter with the row's attack timer under it, then
  /// stat chips. Both the entity's row and the player's row are built from
  /// this so they stay identical. Pass a null [hp] for entities without
  /// hitpoints; the bar collapses and the stats stay right-aligned.
  ///
  /// [damageSlot] stands in the bar's band on a row with no bar: what a
  /// cast caught, or an herb picked. [labelHit] flashes under the row's
  /// label: the damage the other side dealt this action, beside the bar
  /// rather than over it.
  Widget buildStatusRow(
    BuildContext context, {
    required String label,
    int? hp,
    int? maxHp,
    Widget? damageSlot,
    Widget? labelHit,
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
          if (labelHit == null)
            buildRowLabel(context, label)
          else
            SizedBox(
              width: kEncounterRowLabelWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildRowLabel(context, label),
                  IgnorePointer(child: labelHit),
                ],
              ),
            ),
          const SizedBox(width: _labelGap),
          if (hp != null)
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
                              Shadow(blurRadius: 3, color: palette.titleShadow),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (timer != null) ...[
                    const SizedBox(height: _timerGap),
                    timer,
                  ],
                ],
              ),
            )
          else if (damageSlot != null)
            // no bar, so the slot keeps the bar's band, at its right end
            Expanded(
              child: SizedBox(
                height: _hpBarHeight,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IgnorePointer(child: damageSlot),
                  ),
                ),
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
    final int maxHp = maxHitpointsFrom(stats);

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
      // damage taken from the entity's attacks, under the row's label
      labelHit: buildDamageTaken(
        context,
        view.entityDamage,
        view.entityAttackSequence,
      ),
      stats: [
        buildPlayerStatChip(context, SkillId.DEFENCE),
        buildPlayerStatChip(context, attackSkillType),
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
          buildPlayerStatChip(context, gatheringSkill),
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
  ///
  /// [hit] is the player's last hit, floated beside the sprite.
  Widget buildPortrait(
    BuildContext context,
    CombatViewState view, {
    Widget? hit,
  }) {
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

    final dungeon = view.dungeonFloor;
    if (dungeon != null) {
      return _buildFloorStage(context, view, dungeon, hit: hit);
    }

    return StagePanel(
      tint: tint,
      sprite: sprite,
      hit: hit,
      // a creature rarer than common is outlined in its rarity, as its tile
      // was on the zone that led here
      outline: entityBorderColor(entity.id.definition.rarity),
      // it stands in a pool of the zone's own colour over the place's art
      spotlight: context.palette.scene,
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

  /// A dungeon floor's stage: shorter, since the floor's track above it
  /// carries the queue. The member's name and level sit in its corner — the
  /// header is the floor's — with how many of it are left, or a boss's gold
  /// frame and "Boss".
  Widget _buildFloorStage(
    BuildContext context,
    CombatViewState view,
    DungeonFloorView dungeon, {
    Widget? hit,
  }) {
    final palette = context.palette;
    final entity = view.entity;
    final kind = entity is CombatEntity
        ? SpriteKind.combat
        : SpriteKind.gathering;
    final tint = SpriteFrame.tintFor(context, kind);
    final boss = DungeonFloorTrack.isBoss(entity);
    final level = entity is CombatEntity ? entity.level : entity.defence;

    Widget sprite = IconRenderer(size: boss ? 96 : 84, id: entity.id);
    if (entity.count <= 0) {
      sprite = ColorFiltered(
        colorFilter: ColorFilter.mode(
          palette.bg.withValues(alpha: 0.65),
          BlendMode.srcATop,
        ),
        child: sprite,
      );
    }

    return StagePanel(
      height: 124,
      tint: tint,
      sprite: sprite,
      hit: hit,
      isBoss: boss,
      outline: entityBorderColor(entity.id.definition.rarity),
      onTap: portraitTap(context, entity),
      heading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (boss) ...[
            Text(
              'BOSS',
              style: HearthText.sectionLabel.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: GameColors.bossLabel,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            entity.name,
            style: HearthText.rowTitle.copyWith(
              fontSize: 16,
              height: 1.1,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 4),
          Semantics(
            label: 'Level $level',
            excludeSemantics: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const IconRenderer(id: SkillId.ATTACK, size: 12),
                const SizedBox(width: 4),
                Text(
                  '$level',
                  style: HearthText.timer.copyWith(
                    color: boss
                        ? GameColors.bossLabel
                        : GameColors.clearedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      corner: boss
          ? StageCountPill(
              count: entity.count,
              label: 'Boss',
              color: GameColors.bossLabel,
              borderColor: GameColors.bossFrameOuter,
            )
          : StageCountPill(
              count: entity.count,
              label: '${entity.count} of ${dungeon.currentFullCount} left',
              borderColor: tint.border,
            ),
    );
  }

  /// The floor's header chip: whether clearing it runs it again or runs on
  /// into the next floor.
  Widget _loopChip(BuildContext context, DungeonFloorView dungeon) {
    final mode = dungeon.loopsDungeon ? 'Dungeon' : 'Floor';
    return ArtHeaderChip(
      icon: Icon(
        dungeon.loopsDungeon ? Icons.repeat_on_rounded : Icons.repeat_rounded,
        size: 14,
        color: context.palette.textMuted,
      ),
      label: mode,
      semanticsLabel: 'Loop mode: ${mode.toLowerCase()}',
    );
  }

  /// A dungeon floor's one-line progress, in the track's place when the
  /// floor has come down to its boss or been cleared: a check, how far it
  /// has got, a rule running to [label] at the right.
  Widget _floorLine(
    BuildContext context, {
    required String progress,
    required String label,
    required Color labelColor,
    required Gradient rule,
  }) {
    final palette = context.palette;
    final style = HearthText.timer.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: palette.textMuted,
    );
    return Semantics(
      container: true,
      label: 'Floor progress: $progress, ${label.toLowerCase()}',
      excludeSemantics: true,
      child: SizedBox(
        height: 28,
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: GameColors.clearedColor,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(Icons.check_rounded, size: 11, color: palette.bg),
            ),
            const SizedBox(width: 8),
            // the rule gives way first, then the count, so the label at the
            // right always reads in full
            Flexible(
              child: Text(
                progress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 2,
                decoration: BoxDecoration(gradient: rule),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: style.copyWith(color: labelColor, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  /// A floor's boss fight: the members before it folded into one line, the
  /// boss alone in its arena with its hp along the arena's foot, the
  /// player's row as a card under it, and the same tabs any fight has.
  List<Widget> _bossFightContent(
    BuildContext context,
    CombatViewState view,
    DungeonFloorView dungeon,
    List<SkillId> trainedSkills,
  ) {
    final boss = view.entity as CombatEntity;
    final palette = context.palette;
    final before = dungeon.floor.members.length - 1;
    return [
      _floorLine(
        context,
        progress: 'All $before cleared',
        label: 'FINAL ENCOUNTER',
        labelColor: GameColors.bossLabel,
        rule: const LinearGradient(
          colors: [GameColors.clearedColor, GameColors.bossFrame],
        ),
      ),
      const SizedBox(height: 8),
      BossArena(
        boss: boss,
        floorNumber: dungeon.index + 1,
        onTap: portraitTap(context, boss),
        damageSlot: view.showActionFeedback
            ? buildHitNumber(context, view)
            : null,
        actionProgress: view.entityActionProgress,
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.border),
        ),
        child: buildPlayerStatusRow(context, view, boss.entityType),
      ),
      const SizedBox(height: 12),
      buildInfoPanel(context, view, trainedSkills),
    ];
  }

  /// Loot, active buffs and (per screen) trained skills or the entity's
  /// details, sharing one slot switched by tab.
  Widget buildInfoPanel(
    BuildContext context,
    CombatViewState view,
    List<SkillId> trainedSkills,
  ) {
    final entity = view.entity;
    final isCombatEntity = entity is CombatEntity;
    return EncounterInfoPanel(
      // gathering draws its rings above the panel, so the tab would only
      // repeat them; it gets the entity's details in that slot instead of
      // reaching them by popup. the placeholder entity a screen falls back to
      // has no details to build, so it gets neither
      skills: isCombatEntity ? trainedSkills : null,
      infoEntity: entity.id == EntityId.NULL ? null : entity,
      drops: view.drops,
      equipment: view.equipmentDrops,
      lootLabel: isCombatEntity ? 'Loot' : 'Gathered',
      emptyLootLabel: isCombatEntity
          ? 'No loot this session'
          : 'Nothing gathered this session',
    );
  }

  /// A cleared floor's summary, in the boss arena's place while the loop
  /// pauses before the next floor.
  List<Widget> _floorClearContent(
    BuildContext context,
    DungeonFloorView dungeon,
    FloorClearSummary cleared,
  ) {
    return [
      _floorLine(
        context,
        progress: '${cleared.defeated} / ${cleared.defeated} defeated',
        label: 'FLOOR COMPLETE',
        labelColor: GameColors.clearedColor,
        rule: const LinearGradient(
          colors: [GameColors.clearedColor, GameColors.clearedColor],
        ),
      ),
      const SizedBox(height: 8),
      FloorClearPanel(summary: cleared),
    ];
  }

  /// The dock while the loop pauses on a cleared floor: the countdown to
  /// the next floor and which one it is, then Cancel and Go now.
  Widget _floorClearDock(
    BuildContext context,
    DungeonFloorView dungeon,
    FloorClearSummary cleared,
  ) {
    final encounter = context.read<EncounterController>();
    final dungeons = context.read<DungeonController>();
    return ActionDock(
      topRow: FloorCountdownRow(
        endsAt: cleared.endsAt,
        total: encounter.floorIntermission,
        nextFloorNumber: dungeon.nextIndex + 1,
        nextFloorName: dungeon.nextName,
        repeats: dungeon.nextIndex == dungeon.index,
        loopsDungeon: dungeon.loopsDungeon,
        onLoopDungeonChanged: (on) => dungeons.setLoopDungeon(dungeon.id, on),
      ),
      buttons: FloorClearButtons(
        onCancel: encounter.cancelIntermission,
        onGoNow: encounter.finishIntermission,
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
    final dungeon = view.dungeonFloor;
    final dungeonDef = dungeon?.id.definition;
    // a floor's boss gets the screen to itself, and a floor just cleared
    // shows its summary in the boss's place until the loop runs on
    final cleared = dungeon?.cleared;
    // anything with a bar to read takes its hits on the stage. fishing and
    // herbalism show no bar, so theirs stay on the row
    final hitOnStage =
        skillType != SkillId.FISHING && skillType != SkillId.HERBALISM;
    final bossFight =
        dungeon != null &&
        entity is CombatEntity &&
        DungeonFloorTrack.isBoss(entity);

    // the place being fought in: the dungeon's own art, else the zone's
    final art = dungeonDef != null && dungeonDef.iconAsset.isNotEmpty
        ? dungeonDef.iconAsset
        : zone.iconAsset;

    // the place stands behind the whole screen, blurred and dark, and every
    // panel lies over it on glass; the top is left open, so the art runs up
    // behind the status bar as on the screen this one opens from
    return Stack(
      fit: StackFit.expand,
      children: [
        _SceneBackdrop(asset: art),
        Theme(
          data: hearthTheme(context.palette.glass()),
          child: Builder(
            builder: (context) => _layout(
              context,
              view: view,
              entity: entity,
              entityId: entityId,
              skillType: skillType,
              trainedSkills: trainedSkills,
              stances: stances,
              aboveFight: aboveFight,
              isCombatEntity: isCombatEntity,
              zone: zone,
              topPadding: topPadding,
              level: level,
              dungeon: dungeon,
              dungeonDef: dungeonDef,
              cleared: cleared,
              hitOnStage: hitOnStage,
              bossFight: bossFight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _layout(
    BuildContext context, {
    required CombatViewState view,
    required EncounterEntity entity,
    required Enum entityId,
    required SkillId skillType,
    required List<SkillId> trainedSkills,
    required List<Stance> stances,
    required Widget? aboveFight,
    required bool isCombatEntity,
    required ZoneDefinition zone,
    required double topPadding,
    required int level,
    required DungeonFloorView? dungeon,
    required DungeonDefinition? dungeonDef,
    required FloorClearSummary? cleared,
    required bool hitOnStage,
    required bool bossFight,
  }) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          SizedBox(
            height: ArtHeader.collapsedHeight(topPadding),
            // a dungeon floor's screen is the floor's: its name and place in
            // the dungeon head it, and the member fought moves to the stage
            child: dungeon != null && dungeonDef != null
                ? ArtHeader(
                    title: dungeon.floor.name,
                    subtitle:
                        '${dungeonDef.name} · Floor ${dungeon.index + 1} '
                        'of ${dungeonDef.entries.length}',
                    collapse: 1,
                    transparent: true,
                    artAsset: dungeonDef.iconAsset.isNotEmpty
                        ? dungeonDef.iconAsset
                        : zone.iconAsset.isEmpty
                        ? null
                        : zone.iconAsset,
                    backLabel: 'Back to ${dungeonDef.name} floors',
                    trailing: _loopChip(context, dungeon),
                  )
                : ArtHeader(
                    title: view.title,
                    subtitle: zone.name,
                    collapse: 1,
                    transparent: true,
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
              // no room under the tabs: a screen whose content fits springs
              // back to rest when dragged, instead of settling scrolled
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              children: [
                if (aboveFight != null) aboveFight,
                if (cleared != null)
                  ..._floorClearContent(context, dungeon!, cleared)
                else if (bossFight)
                  ..._bossFightContent(context, view, dungeon!, trainedSkills)
                else ...[
                  if (dungeon != null) ...[
                    DungeonFloorTrack(
                      floor: dungeon.floor,
                      fullCounts: dungeon.fullCounts,
                      onMemberTap: (member) =>
                          showEntityInfoDialog(context, member),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // the entity, with whatever is queued behind it. the damage
                  // the player deals floats up beside it, and the damage
                  // coming back shows under the player's label, so neither
                  // covers a bar
                  buildPortrait(
                    context,
                    view,
                    hit: view.showActionFeedback && hitOnStage
                        ? buildHitNumber(context, view)
                        : null,
                  ),
                  const SizedBox(height: 16),

                  buildEntityStatusRow(
                    context,
                    entity,
                    view.requiredLevel,
                    // a row with no bar keeps what the action did in the
                    // bar's band: what a cast caught, or the herb picked. a
                    // row with a bar has its hit on the stage instead
                    damageSlot: !view.showActionFeedback || hitOnStage
                        ? null
                        : skillType == SkillId.FISHING
                        ? buildCatchChip(
                            context,
                            entity,
                            view.playerCatchItem,
                            view.playerCatches,
                            view.playerMaxHit,
                            view.actionSequence,
                          )
                        : buildDamageNumber(
                            context,
                            view.playerDamage,
                            view.actionSequence,
                          ),
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
                        // the level reads first; with it met, the missing tool
                        view.missingTool != null &&
                                view.requiredLevel <=
                                    (view.playerStats[skillType] ?? 0)
                            ? "Needs ${toolNoun(view.missingTool!)} — equip "
                                  "one in Gear"
                            : "Requires ${skillDisplayName(skillType)} level "
                                  "${view.requiredLevel}",
                        textAlign: TextAlign.center,
                        style: HearthText.rowMeta.copyWith(
                          color: context.gameColors.hp,
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),

                  // loot, active buffs and (per screen) trained skills or the
                  // entity's details share one slot, switched by tab
                  buildInfoPanel(context, view, trainedSkills),
                ],
              ],
            ),
          ),

          // the style switch rides in the dock with the buttons, so it stays
          // reachable mid-action. an entity with a single stance offers no
          // choice, so the row is left out entirely. while the loop pauses on
          // a cleared floor, the dock counts down to the next one instead
          if (cleared != null)
            _floorClearDock(context, dungeon!, cleared)
          else
            ActionDock(
              // a fight a zone away is walked to first: the road rides above
              // the style switch, which can be set before arriving
              banner: context.watch<WorldController>().isViewingCurrentZone
                  ? null
                  : const TravelRow(),
              topRow: stances.length > 1
                  ? StanceButton(stances: stances)
                  : null,
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
      playerCatches: controller.latestActionResult.catches,
      playerMaxHit: controller.latestActionResult.maxHit,
      playerMaxRoll: controller.latestActionResult.maxRoll,
      playerCatchItem: controller.latestActionResult.items
          .map((stack) => stack.id)
          .whereType<ItemId>()
          .firstOrNull,
      actionSequence: controller.actionSequence,
      entityDamage: controller.latestEntityDamage,
      entityAttackSequence: controller.entityAttackSequence,
      // damage feedback belongs only to the encounter the actions fire on
      showActionFeedback: controller.isViewingActiveEncounter(),
      drops: controller.itemDrops(),
      equipmentDrops: controller.equipmentDrops(),
      // a dungeon card's queue; empty for a zone entity
      queueRemaining: controller.queueRemaining(),
      dungeonFloor: _dungeonFloor(context, controller),
      foodItemId: controller.getEquipedFoodItemId(),
      foodItemCount: controller.getEquipedFoodItemCount(),
      // herbalism level gate: locked herbs stay visible but can't be picked
      requiredLevel: controller.viewedRequiredLevel(),
      locked: controller.viewedLocked(),
      missingTool: controller.viewedMissingTool(),
      entityActionProgress: controller.entityAttackProgress,
      // both gated on this screen being the one the actions fire on
      playerActionProgress: controller.playerActionProgress,
      playerActionInterval: controller.playerActionInterval,
    );
  }

  /// The dungeon floor on screen, or null for a world encounter.
  DungeonFloorView? _dungeonFloor(
    BuildContext context,
    EncounterController controller,
  ) {
    // the loop mode lives on the dungeon's progress, which the encounter
    // controller never hears change
    final dungeons = context.watch<DungeonController>();
    final inView = controller.floorInView();
    if (inView == null || !inView.id.isReal) return null;
    final cleared = controller.summaryShowing ? controller.intermission : null;
    final next = dungeons.nextFloorAfter(inView.id, inView.index);
    final entries = inView.id.definition.entries;
    return DungeonFloorView(
      id: inView.id,
      index: inView.index,
      floor: inView.floor,
      fullCounts: DungeonFloorTrack.fullCountsFor(
        inView.id,
        inView.index,
        inView.floor,
      ),
      loopsDungeon: dungeons.loopsDungeon(inView.id),
      // the pause belongs to the floor it cleared, which is still the one
      // in view until the loop runs on
      cleared:
          cleared != null &&
              cleared.dungeonId == inView.id &&
              cleared.floorIndex == inView.index
          ? cleared
          : null,
      nextIndex: next,
      nextName: next < entries.length ? entries[next].name : '',
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
        isActive: controller.isActingOnViewedEntity,
        startActionFunction: () {
          // a dungeon floor entered but not yet started begins here; once it
          // runs, a press carries on with it like any other encounter
          if (context.read<DungeonController>().startViewedFloor()) return;
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

/// The place a fight or gathering happens in, behind the whole screen:
/// its art, cropped to fill, blurred past detail and sunk into the page, so
/// the place is felt rather than read and the spotlit subject on the stage
/// stays the thing to look at. Undrawn art leaves the plain page.
class _SceneBackdrop extends StatelessWidget {
  const _SceneBackdrop({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    final bg = context.palette.bg;
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: bg),
          if (asset.isNotEmpty)
            ImageFiltered(
              key: const ValueKey('scene-backdrop'),
              imageFilter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Image.asset(
                asset,
                fit: BoxFit.cover,
                // zone art is pixel art; smoothing it blurs the pixels
                filterQuality: FilterQuality.none,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ColoredBox(color: bg.withValues(alpha: 0.68)),
        ],
      ),
    );
  }
}
