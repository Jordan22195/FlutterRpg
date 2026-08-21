import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/zones/zones.dart';
import '../controllers/world_controller.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../data/zone_details.dart';

/// What a zone holds and what it takes to find it: the zone's difficulty,
/// how many things an explore currently turns up, and every discovery in
/// its tables — including the ones still locked, so the player can see
/// what levelling Exploration here still has to offer.
///
/// Reached by tapping the zone image on the explore screen.
class ZoneDetailScreen extends StatelessWidget {
  const ZoneDetailScreen({super.key, required this.zoneId});

  final ZoneId zoneId;

  @override
  Widget build(BuildContext context) {
    final worldController = context.watch<WorldController>();
    final details = worldController.zoneDetails(zoneId);

    return Scaffold(
      appBar: AppBar(title: Text(details.zone.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        children: [
          _ZoneBanner(details: details),
          const SizedBox(height: 12),
          _SummaryCard(details: details),
          if (details.entities.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DiscoveryCard(
              label: 'Discoveries',
              emptyMessage: 'Nothing to find here.',
              discoveries: details.entities,
              showXp: true,
            ),
          ],
          if (details.items.isNotEmpty) ...[
            const SizedBox(height: 12),
            _DiscoveryCard(
              label: 'Finds',
              emptyMessage: 'Nothing turns up here.',
              discoveries: details.items,
              showXp: false,
            ),
          ],
          if (!details.hasDiscoveries) ...[
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'There is nothing to discover here. Somewhere this settled '
                  'keeps no secrets.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ZoneBanner extends StatelessWidget {
  const _ZoneBanner({required this.details});

  final ZoneDetails details;

  @override
  Widget build(BuildContext context) {
    final asset = details.zone.iconAsset;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: 120,
        child: asset.isEmpty
            ? const ColoredBox(color: Colors.black26)
            : Image.asset(
                asset,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: Colors.black26),
              ),
      ),
    );
  }
}

/// The zone's gates and the player's standing in it.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.details});

  final ZoneDetails details;

  @override
  Widget build(BuildContext context) {
    final zone = details.zone;
    final locked = details.explorationLevel < details.zoneLevel;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // the headline number: what one explore is worth here right now
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  details.findsPerExplore.toStringAsFixed(2),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 6),
                Text(
                  'finds per explore',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _statRow(
              context,
              'Zone difficulty',
              zone.explorationLevel <= 0
                  ? 'None'
                  : 'Exploration ${zone.explorationLevel}',
              warn: locked,
            ),
            _statRow(
              context,
              'Your Exploration',
              '${details.explorationLevel}'
                  '${details.levelsAboveZone > 0 ? '  (+${details.levelsAboveZone})' : ''}',
            ),
            if (zone.requiredSkill != SkillId.NULL && zone.requiredLevel > 0)
              _statRow(
                context,
                'Also requires',
                '${skillLabel(zone.requiredSkill)} ${zone.requiredLevel}',
              ),
            if (zone.xpPerExplore > 0)
              _statRow(
                context,
                'Exploration xp',
                '${_trim(zone.xpPerExplore)} per explore',
              ),
            if (details.lockedCount > 0)
              _statRow(
                context,
                'Still hidden',
                '${details.lockedCount} '
                    '${details.lockedCount == 1 ? 'discovery' : 'discoveries'}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(
    BuildContext context,
    String label,
    String value, {
    bool warn = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: warn ? Colors.redAccent : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// One table's worth of discoveries, baseline entries first and then in
/// unlock order. Locked rows stay visible — seeing what is still out there
/// is the point of the screen.
class _DiscoveryCard extends StatelessWidget {
  const _DiscoveryCard({
    required this.label,
    required this.emptyMessage,
    required this.discoveries,
    required this.showXp,
  });

  final String label;
  final String emptyMessage;
  final List<ZoneDiscovery> discoveries;

  /// Item finds pay no exploration xp, so their rows leave the column out.
  final bool showXp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 4),
            if (discoveries.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              )
            else
              ...discoveries.map(
                (d) => _DiscoveryRow(discovery: d, showXp: showXp),
              ),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryRow extends StatelessWidget {
  const _DiscoveryRow({required this.discovery, required this.showXp});

  final ZoneDiscovery discovery;
  final bool showXp;

  @override
  Widget build(BuildContext context) {
    final d = discovery;
    // matches the skill detail screen's locked-unlock styling
    return Opacity(
      opacity: d.locked ? 0.45 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: d.iconAsset.isEmpty
                  ? const Icon(Icons.help_outline, size: 18)
                  : Image.asset(
                      d.iconAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined, size: 18),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.hasCountRange
                        ? '${d.name}  ${d.minCount}-${d.maxCount}'
                        : d.name,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (d.locked)
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 11,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Exploration ${d.unlockLevel}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!d.locked) ...[
              Text(
                '${(d.chance * 100).toStringAsFixed(d.chance < 0.01 ? 2 : 1)}%',
                style: const TextStyle(fontSize: 12),
              ),
              if (showXp && d.xp > 0) ...[
                const SizedBox(width: 10),
                SizedBox(
                  width: 62,
                  child: Text(
                    '${_trim(d.xp)} xp',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

/// Drops a trailing ".0" so whole numbers read as "8 xp", not "8.0 xp".
String _trim(double value) {
  final rounded = value.toStringAsFixed(1);
  return rounded.endsWith('.0')
      ? rounded.substring(0, rounded.length - 2)
      : rounded;
}
