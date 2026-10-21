import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/entities/entities.dart';
import '../controllers/player_data_controller.dart';
import '../controllers/world_controller.dart';
import '../data/level_standing.dart';
import '../data/skill_data.dart';
import '../utilities/util.dart';
import 'explore_card.dart';
import 'place_tile.dart';
import 'sprite_frame.dart';

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
  });

  final EncounterEntity entity;

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
      ].join(', '),
      onTap: onTap,
      onLongPress: onLongPress,
      active: active,
    );
  }
}
