import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../catalogs/entity_catalog.dart';
import '../controllers/world_controller.dart';
import '../data/entity_details.dart';
import '../data/skill_data.dart';
import 'explore_card.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';

/// Details popup for a world entity: its stats, its drop table with
/// per-kill odds, and the rolls both ways against the player's current
/// stats (hit / miss / block chances and damage). Also carries the dev
/// control for forcing the entity's remaining count.
void showEntityInfoDialog(BuildContext context, EncounterEntity entity) {
  if (entity.id == EntityId.NULL) return;

  final worldController = context.read<WorldController>();
  final details = worldController.entityDetails(entity);
  final devCountController = TextEditingController(text: '${entity.count}');

  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(entity.name),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 320,
          child: Column(
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
                      controller: devCountController,
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
                      final count = int.tryParse(devCountController.text);
                      if (count != null) {
                        worldController.devSetEntityCount(entity.id, count);
                      }
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Set'),
                  ),
                ],
              ),
            ],
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

String _percent(double value) => '${(value * 100).toStringAsFixed(1)}%';

String _decimal(double value) => value.toStringAsFixed(1);

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

    return _Section(
      title: 'Stats',
      children: [
        _StatRow(label: 'Remaining', value: '${entity.count}'),
        if (details.usesDamage)
          _StatRow(
            label: 'Hitpoints',
            value: '${entity.hitpoints} / ${entity.maxHitPoints}',
          ),
        _StatRow(label: 'Defence', value: '${entity.defence}'),
        if (entity is CombatEntity) ...[
          _StatRow(label: 'Attack', value: '${entity.attack}'),
          _StatRow(
            label: 'Attack speed',
            value: '${_decimal(entity.attackInterval)}s',
          ),
        ],
        _StatRow(
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

    return _Section(
      title: _title,
      children: [
        _StatRow(
          label: 'Your ${skillDisplayName(details.skill).toLowerCase()}',
          value: '${details.playerSkillLevel}',
        ),

        // herbs are never missed: the roll only decides how much the pick
        // yields, so hit/miss and damage don't apply
        if (details.skill == SkillId.HERBALISM) ...[
          _StatRow(
            label: 'Bonus yield chance',
            value: _percent(details.playerHitChance),
          ),
          _StatRow(
            label: 'Expected yield',
            value: _decimal(details.expectedYield),
          ),
        ] else ...[
          _StatRow(
            label: details.isCombat ? 'Hit chance' : 'Success chance',
            value: _percent(details.playerHitChance),
          ),
          _StatRow(
            label: details.isCombat ? 'Miss chance' : 'Fail chance',
            value: _percent(details.playerMissChance),
          ),
          _StatRow(label: 'Max hit', value: '${details.playerMaxHit}'),
          _StatRow(
            label: 'Avg damage',
            value: _decimal(details.playerAverageDamage),
          ),
          if (details.usesDamage)
            _StatRow(
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
    return _Section(
      title: 'Incoming',
      children: [
        _StatRow(label: 'Your defence', value: '${details.playerDefence}'),
        _StatRow(
          label: 'Their hit chance',
          value: _percent(details.entityHitChance),
        ),
        _StatRow(
          label: 'Your block chance',
          value: _percent(details.blockChance),
        ),
        _StatRow(label: 'Their max hit', value: '${details.entityMaxHit}'),
        _StatRow(
          label: 'Avg damage taken',
          value: _decimal(details.entityAverageDamage),
        ),
        _StatRow(
          label: 'Damage per second',
          value: _decimal(details.entityDamagePerSecond),
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

    return _Section(
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
                    _percent(drop.chance),
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
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 4),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              letterSpacing: 0.8,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// One label/value line. Values are right-aligned so a column of numbers
/// stays readable.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
