import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/entities/entities.dart';
import '../controllers/world_controller.dart';
import '../data/entity_details.dart';
import '../data/skill_data.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'info_section.dart';
import 'item_stack_tile.dart';

/// Details popup for a world entity, used where there is no room to show
/// them inline — the explore screen's entity icons, and combat encounters.
/// Gathering encounters render [EntityInfoBody] in their info tab instead.
void showEntityInfoDialog(BuildContext context, EncounterEntity entity) {
  if (entity.id == EntityId.NULL) return;

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(entity.name),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: EntityInfoBody(
            entity: entity,
            onDevSetCount: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Everything there is to say about a world entity: its stats, its drop
/// table with per-action odds, and the rolls both ways against the player's
/// current stats (hit / miss / block chances and damage). Also carries the
/// dev control for forcing the entity's remaining count.
///
/// Sizes to its content, so it can be dropped into a scrolling page as
/// readily as into the details dialog.
class EntityInfoBody extends StatefulWidget {
  const EntityInfoBody({super.key, required this.entity, this.onDevSetCount});

  final EncounterEntity entity;

  /// Called after the dev count is applied — the dialog closes on it, an
  /// inline panel has nothing to do.
  final VoidCallback? onDevSetCount;

  @override
  State<EntityInfoBody> createState() => _EntityInfoBodyState();
}

class _EntityInfoBodyState extends State<EntityInfoBody> {
  late final TextEditingController _devCountController = TextEditingController(
    text: '${widget.entity.count}',
  );

  @override
  void dispose() {
    _devCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final worldController = context.read<WorldController>();
    final details = worldController.entityDetails(widget.entity);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Header(details: details),
        _EntityStats(details: details),
        _PlayerRolls(details: details),
        if (details.isCombat) _IncomingDamage(details: details),
        _DropTable(details: details),

        // dev tool: force how many of this entity are left in the zone
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _devCountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  isDense: true,
                  labelText: 'Dev: entity count',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final count = int.tryParse(_devCountController.text);
                if (count != null) {
                  worldController.devSetEntityCount(widget.entity.id, count);
                }
                widget.onDevSetCount?.call();
              },
              child: const Text('Set'),
            ),
          ],
        ),
      ],
    );
  }
}

/// Portrait, plus the skill this entity trains and its level gate.
class _Header extends StatelessWidget {
  const _Header({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    final entity = details.entity;
    final gate = details.requiredLevel > 0
        ? ' · Lv ${details.requiredLevel}'
        : '';

    return Column(
      children: [
        Center(
          child: ItemStackTile(
            size: 96,
            count: entity.count,
            id: entity.id,
            showInfoDialogOnTap: false,
            depleted: entity.count <= 0,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconRenderer(size: 18, id: details.skill),
            const SizedBox(width: 4),
            Text(
              '${skillDisplayName(details.skill)}$gate',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EntityStats extends StatelessWidget {
  const _EntityStats({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    final entity = details.entity;

    return InfoSection(
      title: 'Stats',
      children: [
        InfoStatRow(label: 'Remaining', value: '${entity.count}'),
        if (details.usesDamage)
          InfoStatRow(
            label: 'Hitpoints',
            value: '${entity.hitpoints} / ${entity.maxHitPoints}',
          ),
        InfoStatRow(label: 'Defence', value: '${entity.defence}'),
        if (entity is CombatEntity) ...[
          InfoStatRow(label: 'Attack', value: '${entity.attack}'),
          InfoStatRow(
            label: 'Attack speed',
            value: '${formatDecimal(entity.attackInterval)}s',
          ),
        ],
        InfoStatRow(
          label: 'XP',
          value:
              '+${details.xpPerUnit.round()} / '
              '${skillActionVerb(details.skill)}',
        ),
      ],
    );
  }
}

/// The player's side of the roll: how often an action lands and how hard.
class _PlayerRolls extends StatelessWidget {
  const _PlayerRolls({required this.details});

  final EntityDetails details;

  String get _title {
    switch (details.skill) {
      case SkillId.ATTACK:
        return 'Your attacks';
      case SkillId.HERBALISM:
        return 'Your picks';
      case SkillId.FISHING:
        return 'Your casts';
      default:
        return 'Your actions';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionsToKill = details.actionsToKill;

    return InfoSection(
      title: _title,
      children: [
        InfoStatRow(
          label: 'Your ${skillDisplayName(details.skill).toLowerCase()}',
          value: '${details.playerSkillLevel}',
        ),

        // herbs are never missed: the roll only decides how much the pick
        // yields, so hit/miss and damage don't apply
        if (details.skill == SkillId.HERBALISM) ...[
          InfoStatRow(
            label: 'Bonus yield chance',
            value: formatPercent(details.playerHitChance),
          ),
          InfoStatRow(
            label: 'Expected yield',
            value: formatDecimal(details.expectedYield),
          ),
        ] else ...[
          InfoStatRow(
            label: details.isCombat ? 'Hit chance' : 'Success chance',
            value: formatPercent(details.playerHitChance),
          ),
          InfoStatRow(
            label: details.isCombat ? 'Miss chance' : 'Fail chance',
            value: formatPercent(details.playerMissChance),
          ),
          InfoStatRow(label: 'Max hit', value: '${details.playerMaxHit}'),
          InfoStatRow(
            label: 'Avg damage',
            value: formatDecimal(details.playerAverageDamage),
          ),
          if (details.usesDamage)
            InfoStatRow(
              label: details.isCombat ? 'Actions to kill' : 'Actions to clear',
              value: actionsToKill.isFinite
                  ? '~${actionsToKill.ceil()}'
                  : 'never',
            ),
        ],
      ],
    );
  }
}

/// What the entity does back to the player, at its own swing rate.
class _IncomingDamage extends StatelessWidget {
  const _IncomingDamage({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    return InfoSection(
      title: 'Incoming',
      children: [
        InfoStatRow(label: 'Your defence', value: '${details.playerDefence}'),
        InfoStatRow(
          label: 'Their hit chance',
          value: formatPercent(details.entityHitChance),
        ),
        InfoStatRow(
          label: 'Your block chance',
          value: formatPercent(details.blockChance),
        ),
        InfoStatRow(label: 'Their max hit', value: '${details.entityMaxHit}'),
        InfoStatRow(
          label: 'Avg damage taken',
          value: formatDecimal(details.entityAverageDamage),
        ),
        InfoStatRow(
          label: 'Damage per second',
          value: formatDecimal(details.entityDamagePerSecond),
        ),
      ],
    );
  }
}

class _DropTable extends StatelessWidget {
  const _DropTable({required this.details});

  final EntityDetails details;

  @override
  Widget build(BuildContext context) {
    if (details.drops.isEmpty) {
      return const SizedBox.shrink();
    }

    final subtleStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
    );

    return InfoSection(
      title: 'Drop table',
      children: [
        for (final drop in details.drops)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                IconRenderer(size: 28, id: drop.itemId),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(drop.name, overflow: TextOverflow.ellipsis),
                      // a layered roll lands on top of the main drop, so
                      // its odds are independent of the rows above
                      if (drop.bonus) Text('bonus roll', style: subtleStyle),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  drop.hasCountRange
                      ? '${drop.minCount}-${drop.maxCount}'
                      : '${drop.minCount}',
                  style: subtleStyle,
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 56,
                  child: Text(
                    formatPercent(drop.chance),
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A labelled block of rows, matching the explore screen's section labels.

/// One label/value line. Values are right-aligned so a column of numbers
/// stays readable.
