import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/entities/entities.dart';
import '../controllers/player_data_controller.dart';
import '../controllers/world_controller.dart';
import '../data/level_standing.dart';
import '../data/skill_data.dart';
import '../utilities/util.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'place_tile.dart';
import 'sprite_frame.dart';
import '../catalogs/zones/map_node_type.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';

/// Something to fight or gather, as a [PlaceTile]: its sprite on a combat
/// or gathering frame, its name, and the level it is fought at beside how
/// many are standing — or, while it is shut, what it waits on. The explore
/// screen's discoveries grid and a dungeon floor's row both draw it.
class DiscoveryTile extends StatelessWidget {
  const DiscoveryTile({
    super.key,
    required this.entity,
    this.onTap,
    this.onLongPress,
    this.active = false,
    this.boss = false,
  });

  final EncounterEntity entity;

  /// Drawn as the floor's boss: ringed and washed in [GameColors.bossColor]
  /// under a ribbon that says so.
  final bool boss;

  /// See [PlaceTile.active].
  final bool active;
  final VoidCallback? onTap;

  /// E.g. the entity's details popup.
  final VoidCallback? onLongPress;

  /// What a discovery tile says under its name: how hard it is and how
  /// many are standing ("Lv 3 · 43"), or the level it waits on.
  static String _line(int? level, int count) => [
    if (level != null) 'Lv $level',
    Util.formatShortCount(count),
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    final e = entity;
    final level = worldController.entityLevel(e);
    final missingTool = worldController.missingToolFor(e.id);
    final underLevel = !worldController.meetsEntityRequirement(e.id);
    final locked = underLevel || missingTool != null;
    final xp = worldController.xpPerUnit(e);
    // the level reads first: an herb above you is shut whatever you hold
    final requires = underLevel
        ? '${skillDisplayName(e.entityType)} '
              '${worldController.requiredLevelFor(e.id)}'
        : 'Needs ${toolNoun(missingTool ?? e.entityType)}';

    return PlaceTile(
      id: e.id,
      name: e.name,
      subtitle: locked ? requires : _line(level, e.count),
      // the level beside the skill it is fought or gathered with, and how
      // many are standing in a chip of their own
      subtitleRow: locked
          ? null
          : PlaceLine(
              skills: [e is CombatEntity ? SkillId.ATTACK : e.entityType],
              level: level,
              count: e.count,
              // a fight against the player's combat level, a node against
              // the skill that works it
              standing: LevelStanding.of(
                level,
                e is CombatEntity
                    ? context.watch<PlayerDataController>().getCombatLevel()
                    : context.watch<PlayerDataController>().getStatTotal(
                        e.entityType,
                      ),
              ),
            ),
      kind: e is CombatEntity ? SpriteKind.combat : SpriteKind.gathering,
      locked: locked,
      // a creature's art has a margin of its own; sit closer
      spriteScale: 1.25,
      // a used-up node reads like a locked one, without the lock
      dimmed: e.count <= 0,
      semanticsLabel: [
        e.name,
        if (underLevel)
          'requires $requires'
        else if (locked)
          requires.toLowerCase()
        else
          'level $level',
        '${e.count} left',
        if (xp != null) '${(xp * e.count).round()} xp',
        if (boss) 'boss',
      ].join(', '),
      onTap: onTap,
      onLongPress: onLongPress,
      active: active,
      outlineColor: boss ? GameColors.bossColor : null,
      fillColor: boss
          ? Color.alphaBlend(
              GameColors.bossColor.withValues(alpha: 0.12),
              context.palette.surface,
            )
          : null,
      banner: boss ? const BossRibbon() : null,
    );
  }
}

/// A dungeon floor's boss, as a full-width row under the floor's grid: the
/// monster in a gold boss frame, a gold "BOSS" label over its name, and the
/// level it is fought at, on a faint boss-red wash — so the one fight a
/// floor builds to stands apart from the queue in front of it.
class BossRow extends StatelessWidget {
  const BossRow({super.key, required this.entity, this.onTap});

  final EncounterEntity entity;

  /// E.g. the boss's details popup.
  final VoidCallback? onTap;

  static const double height = 72;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final colors = context.gameColors;
    final e = entity;
    final level = context.watch<WorldController>().entityLevel(e);
    final standing = LevelStanding.of(
      level,
      context.watch<PlayerDataController>().getCombatLevel(),
    );
    final radius = BorderRadius.circular(14);

    return Semantics(
      button: onTap != null,
      label: '${e.name}, boss, level $level',
      // the label replaces what the row's children would say, so the tap
      // has to be handed back to it here
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: Color.alphaBlend(
          GameColors.bossColor.withValues(alpha: 0.12),
          palette.surface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: const BorderSide(color: GameColors.bossTileBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 14, 0),
              child: Row(
                children: [
                  SpriteFrame(
                    id: e.id,
                    kind: SpriteKind.combat,
                    size: 56,
                    spriteSize: 46,
                    radius: 10,
                    depleted: e.count <= 0,
                    isBoss: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BOSS',
                          style: HearthText.rowMeta.copyWith(
                            fontSize: 11,
                            height: 1.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: GameColors.bossLabel,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HearthText.rowTitle.copyWith(
                            fontSize: 16,
                            color: palette.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconRenderer(id: SkillId.ATTACK, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    '$level',
                    style: HearthText.statusStat.copyWith(
                      fontWeight: FontWeight.w800,
                      color: switch (standing) {
                        LevelStanding.hard => colors.levelHard,
                        LevelStanding.even => colors.levelEven,
                        LevelStanding.easy => colors.levelEasy,
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The red "BOSS" pill across the top of a [DiscoveryTile] drawn as a boss.
class BossRibbon extends StatelessWidget {
  const BossRibbon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: GameColors.bossColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // the map's boss lair mark, so a boss reads the same everywhere
          Icon(
            MapNodeType.BOSS_LAIR.glyph,
            size: 10,
            color: GameColors.onBossColor,
          ),
          const SizedBox(width: 2),
          Text(
            'BOSS',
            style: HearthText.rowMeta.copyWith(
              fontSize: 9,
              height: 1.2,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: GameColors.onBossColor,
            ),
          ),
        ],
      ),
    );
  }
}
