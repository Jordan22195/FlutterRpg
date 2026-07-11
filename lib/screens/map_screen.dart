import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'explore_screen.dart';
import 'dungeon_screen.dart';
import '../catalogs/dungeon_catalog.dart';
import '../catalogs/zone_catalog.dart';
import '../controllers/dungeon_controller.dart';
import '../data/skill_data.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Anchor (top-left) of each zone's button, laid out along the travel
  /// path: farm > forest > mine, with the dev forest off to the side.
  static const Map<ZoneId, Offset> _zoneAnchors = {
    ZoneId.TUTORIAL_FARM: Offset(80, 120),
    ZoneId.STARTING_FOREST: Offset(80, 220),
    ZoneId.FOREST_MINE: Offset(80, 320),
    ZoneId.DEV_FOREST: Offset(220, 420),
  };

  static const Map<ZoneId, String> _zoneLabels = {
    ZoneId.TUTORIAL_FARM: 'Farm',
    ZoneId.STARTING_FOREST: 'Forest',
    ZoneId.FOREST_MINE: 'Mine',
    ZoneId.DEV_FOREST: 'Dev Forest',
  };

  /// Landmark dungeons sit on the map from the start as aspirational
  /// targets; tapping one opens its (free) inspect screen.
  static const Map<DungeonId, Offset> _dungeonAnchors = {
    DungeonId.GOBLIN_QUEEN_LAIR: Offset(220, 220),
  };

  // approximate center of a zone button relative to its anchor, used to
  // attach the painted graph edges
  static const Offset _buttonCenter = Offset(55, 28);

  ZoneId? _selected;

  void _travelTo(WorldController world, ZoneId zoneId) {
    if (world.travelToZone(zoneId)) {
      setState(() => _selected = null);
      // This pushes onto the MAP TAB's nested navigator, so switching
      // tabs and coming back returns to ExploreScreen.
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ExploreScreen()));
    }
  }

  Widget _zoneButton(WorldController world, ZoneId zoneId) {
    final scheme = Theme.of(context).colorScheme;
    final def = world.zoneDefinition(zoneId);
    final isCurrent = world.currentZoneId == zoneId;
    final isSelected = _selected == zoneId;
    final cost = world.travelCostTo(zoneId);
    final affordable = world.canAffordTravelTo(zoneId);
    final meetsRequirement = world.meetsZoneRequirement(zoneId);
    final hasRequirement =
        def.requiredSkill != SkillId.NULL && def.requiredLevel > 0;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        side: isSelected
            ? BorderSide(color: scheme.secondary, width: 2)
            : isCurrent
            ? BorderSide(color: scheme.primary, width: 2)
            : null,
      ),
      // selecting a zone only selects it; the travel button in the
      // bottom panel is what actually takes you there
      onPressed: () => setState(() => _selected = zoneId),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // marks the zone the player is currently in
              if (isCurrent)
                Icon(Icons.location_on, size: 16, color: scheme.primary),
              Text(_zoneLabels[zoneId] ?? def.name),
            ],
          ),

          // stamina cost to travel here from the current zone
          if (!isCurrent)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt,
                  size: 12,
                  color: affordable ? null : Colors.red,
                ),
                Text(
                  cost.isInfinite ? '-' : cost.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 11,
                    color: affordable ? null : Colors.red,
                  ),
                ),
              ],
            ),

          // level requirement, red when unmet
          if (hasRequirement)
            Text(
              '${def.requiredSkill.name} ${def.requiredLevel}',
              style: TextStyle(
                fontSize: 10,
                color: meetsRequirement ? null : Colors.red,
              ),
            ),
        ],
      ),
    );
  }

  Widget _landmarkMarker(DungeonId dungeonId) {
    final scheme = Theme.of(context).colorScheme;
    final dungeons = context.read<DungeonController>();
    final def = dungeons.definitionFor(dungeonId);
    if (def == null) return const SizedBox.shrink();

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: scheme.tertiaryContainer,
        side: BorderSide(color: scheme.tertiary, width: 2),
      ),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DungeonScreen(dungeonId: dungeonId),
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.castle, size: 16, color: scheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            def.name,
            style: TextStyle(color: scheme.onTertiaryContainer, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _travelPanel(WorldController world, ZoneId zoneId) {
    final def = world.zoneDefinition(zoneId);
    final isCurrent = world.currentZoneId == zoneId;
    final cost = world.travelCostTo(zoneId);
    final affordable = world.canAffordTravelTo(zoneId);
    final meetsRequirement = world.meetsZoneRequirement(zoneId);
    final hasRequirement =
        def.requiredSkill != SkillId.NULL && def.requiredLevel > 0;
    final canGo =
        isCurrent || (meetsRequirement && affordable && !cost.isInfinite);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    def.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (!isCurrent)
                    Row(
                      children: [
                        Icon(
                          Icons.bolt,
                          size: 14,
                          color: affordable ? null : Colors.red,
                        ),
                        Text(
                          cost.isInfinite
                              ? 'unreachable'
                              : cost.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 12,
                            color: affordable ? null : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  if (hasRequirement)
                    Text(
                      'Requires ${def.requiredSkill.name} ${def.requiredLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: meetsRequirement ? null : Colors.red,
                      ),
                    ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: canGo ? () => _travelTo(world, zoneId) : null,
              child: Text(isCurrent ? 'Enter' : 'Travel'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = context.watch<WorldController>();
    // stamina changes (ambient recovery, action drain) re-price travel
    context.watch<PlayerDataController>();

    final scheme = Theme.of(context).colorScheme;
    final edges = <(Offset, Offset, double)>[
      for (final (from, to, cost) in world.travelEdges())
        if (_zoneAnchors.containsKey(from) && _zoneAnchors.containsKey(to))
          (
            _zoneAnchors[from]! + _buttonCenter,
            _zoneAnchors[to]! + _buttonCenter,
            cost,
          ),
    ];

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/map.png', fit: BoxFit.cover),
          ),

          // travel path edges between connected zones
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ZoneEdgePainter(
                  edges: edges,
                  lineColor: scheme.onSurface.withOpacity(0.5),
                  labelColor: scheme.onSurface,
                  labelBackground: scheme.surface.withOpacity(0.8),
                ),
              ),
            ),
          ),

          Positioned(
            left: 16,
            top: 8,
            right: 16,
            child: Text(
              'World Map',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),

          for (final entry in _zoneAnchors.entries)
            Positioned(
              left: entry.value.dx,
              top: entry.value.dy,
              child: _zoneButton(world, entry.key),
            ),

          for (final entry in _dungeonAnchors.entries)
            Positioned(
              left: entry.value.dx,
              top: entry.value.dy,
              child: _landmarkMarker(entry.key),
            ),

          // travel panel for the selected zone
          if (_selected != null)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _travelPanel(world, _selected!),
            ),
        ],
      ),
    );
  }
}

/// Draws the zone graph's edges as lines with their stamina cost at the
/// midpoint.
class _ZoneEdgePainter extends CustomPainter {
  const _ZoneEdgePainter({
    required this.edges,
    required this.lineColor,
    required this.labelColor,
    required this.labelBackground,
  });

  final List<(Offset, Offset, double)> edges;
  final Color lineColor;
  final Color labelColor;
  final Color labelBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2;
    final labelPaint = Paint()..color = labelBackground;

    for (final (a, b, cost) in edges) {
      canvas.drawLine(a, b, linePaint);

      // per-edge cost at the midpoint
      final mid = Offset.lerp(a, b, 0.5)!;
      final text = TextPainter(
        text: TextSpan(
          text: cost.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: labelColor,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      canvas.drawCircle(mid, 10, labelPaint);
      canvas.drawCircle(
        mid,
        10,
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.stroke,
      );
      text.paint(canvas, mid - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_ZoneEdgePainter oldDelegate) {
    return oldDelegate.edges != edges || oldDelegate.lineColor != lineColor;
  }
}
