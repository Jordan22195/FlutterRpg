import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rpg/controllers/player_data_controller.dart';
import 'package:rpg/controllers/world_controller.dart';
import 'explore_screen.dart';
import 'dungeon_screen.dart';
import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/zones/zones.dart';
import '../data/skill_data.dart';
import '../services/entity_screen_router_service.dart';
import '../widgets/map_detail_pane.dart';
import '../widgets/map_edge_painter.dart';
import '../widgets/map_node_token.dart';
import '../widgets/pixel_sprites.dart';
import '../theme/hearth_text.dart';
import '../utilities/shell_page_route.dart';

/// The world map: a graph of places you can walk between, and what walking
/// there costs.
///
/// The split of duties is the whole design. A node says what a place *is*
/// (its pixel token: wilderness diamond, town shield, skilling round),
/// whether it is shut (the padlock) and whether you're standing in it (the
/// YOU flag). An edge says what the trip costs, once, and the picked
/// place's route is drawn in gold. Every sentence of detail — names of
/// gates, what's in town, the way in — lives in the pane docked underneath,
/// which never covers the map.
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Below this zoom the map's minor wilderness labels are dropped, so a
  /// zoomed-out overview reads as a shape rather than as a wall of text.
  /// Towns, lairs, where you are and what you've picked keep their names.
  static const double _labelZoomFloor = 0.7;

  final TransformationController _view = TransformationController();
  final GlobalKey _viewport = GlobalKey();
  MapNode? _selected;
  double _scale = 1;

  /// Kinds of place the filter rail has switched off. Their tokens fade
  /// back rather than vanish, so the roads through them still make sense.
  final Set<MapNodeType> _hidden = {};

  /// The zone the view is currently framed on, so opening the map and
  /// coming back from a trip both start you looking at where you are
  /// rather than at the map's top-left corner.
  ZoneId? _framedOn;

  @override
  void initState() {
    super.initState();
    _view.addListener(_onViewChanged);
  }

  @override
  void dispose() {
    _view.removeListener(_onViewChanged);
    _view.dispose();
    super.dispose();
  }

  void _onViewChanged() {
    final scale = _view.value.getMaxScaleOnAxis();
    if ((scale - _scale).abs() < 0.01) return;
    setState(() => _scale = scale);
  }

  /// Slides the canvas so the player's zone sits in the middle of the
  /// viewport. Only when the zone actually changes, so it never yanks the
  /// map out from under someone who is panning around it.
  ///
  /// Panning only. How far in the player is zoomed is their setting, not
  /// something travelling gets to reset, so the current scale is carried
  /// through and only the translation is recomputed.
  static final Size _paddedSize = Size(
    kWorldMapSize.width + 2 * kWorldMapPadding,
    kWorldMapSize.height + 2 * kWorldMapPadding,
  );

  void _frameCurrentZone(ZoneId zone) {
    if (_framedOn == zone || !mounted) return;
    final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final target =
        (zoneNodeCenter(zone) ??
            Offset(kWorldMapSize.width / 2, kWorldMapSize.height / 2)) +
        const Offset(kWorldMapPadding, kWorldMapPadding);
    _framedOn = zone;

    // the canvas draws at scale*p + translation, so putting `target` under
    // the viewport's centre means translation = centre - scale * target
    final scale = _view.value.getMaxScaleOnAxis();
    _view.value = Matrix4.identity()
      ..translateByDouble(
        _clampAxis(
          box.size.width / 2 - target.dx * scale,
          box.size.width,
          _paddedSize.width * scale,
        ),
        _clampAxis(
          box.size.height / 2 - target.dy * scale,
          box.size.height,
          _paddedSize.height * scale,
        ),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  /// Keeps one axis of the framing translation inside the map's bounds: the
  /// map's edge never pulls in past the viewport's edge, and a map smaller
  /// than the viewport is centred instead.
  double _clampAxis(double translation, double viewport, double content) {
    if (content <= viewport) return (viewport - content) / 2;
    return translation.clamp(viewport - content, 0.0);
  }

  /// Opens a zone — any zone, not just the one you're standing in. Looking
  /// at a place costs nothing and moves nobody, so this deliberately leaves
  /// the running action alone: you can read a town while an axe keeps
  /// swinging back home. The trip is offered by the travel button on the
  /// screen this opens, and taken only if the player asks for it.
  void _enterZone(WorldController world, ZoneId zoneId) {
    world.setViewedZone(zoneId);

    // This pushes onto the MAP TAB's nested navigator, so switching
    // tabs and coming back returns to ExploreScreen.
    Navigator.of(context)
        .push(
          ShellPageRoute(
            settings: const RouteSettings(
              name: EntityScreenRouterService.exploreRouteName,
            ),
            builder: (_) => ExploreScreen(),
          ),
        )
        // back out to the map and you are looking at the world again, not at
        // one place in it. leaving the view pointed somewhere the player has
        // walked away from would keep travel buttons on screens that have
        // nothing to do with that zone.
        .then((_) {
          if (mounted) world.setViewedZone(world.currentZoneId);
        });
  }

  void _enterLandmark(DungeonId dungeonId) {
    Navigator.of(context).push(
      ShellPageRoute(
        settings: RouteSettings(
          name: EntityScreenRouterService.dungeonRouteName,
          arguments: dungeonId,
        ),
        builder: (_) => DungeonScreen(dungeonId: dungeonId),
      ),
    );
  }

  /// The skill gate a locked zone shows on its token. Exploration is the
  /// baseline gate, so it wins when both are unmet: it's the one you work
  /// off by playing rather than by training something else.
  (SkillId, int) _lockGate(WorldController world, ZoneId zoneId) {
    final def = zoneId.definition;
    if (!world.meetsZoneExplorationRequirement(zoneId)) {
      return (SkillId.EXPLORATION, def.explorationLevel);
    }
    return (def.requiredSkill, def.requiredLevel);
  }

  /// The hops of the quickest way from where the player stands to the
  /// picked zone, as (from, to) pairs. Empty when nothing (or a landmark,
  /// which isn't on the travel graph) is picked.
  Set<(ZoneId, ZoneId)> _routeLegs(WorldController world) {
    final picked = _selected;
    if (picked is! ZoneNode) return const {};
    final path = ZoneTravelGraph.travelPath(world.currentZoneId, picked.id);
    return {for (var i = 0; i < path.length - 1; i++) (path[i], path[i + 1])};
  }

  List<MapEdge> _edges(WorldController world) {
    final edges = <MapEdge>[];
    final route = _routeLegs(world);

    for (final (end, otherEnd) in world.travelEdges()) {
      final endCenter = zoneNodeCenter(end);
      final otherCenter = zoneNodeCenter(otherEnd);
      if (endCenter == null || otherCenter == null) continue;

      // orient each edge away from the player: the badge then sits toward
      // the far end and clears the near node's label. It also decides which
      // way the hop is timed, and the road is not symmetric — the climb
      // back up from the mine takes ten times the walk down.
      final endHops = world.travelHopsTo(end);
      final otherHops = world.travelHopsTo(otherEnd);
      final nearIsEnd = endHops >= 0 && (otherHops < 0 || endHops <= otherHops);
      final (near, far) = nearIsEnd ? (end, otherEnd) : (otherEnd, end);

      edges.add(
        MapEdge(
          from: nearIsEnd ? endCenter : otherCenter,
          to: nearIsEnd ? otherCenter : endCenter,
          time: ZoneTravelGraph.edgeTravelTime(near, far),
          onRoute:
              route.contains((end, otherEnd)) ||
              route.contains((otherEnd, end)),
        ),
      );
    }
    return edges;
  }

  bool _showLabel(MapNode node) {
    if (_scale >= _labelZoomFloor) return true;
    if (node.type != MapNodeType.WILDERNESS) return true;
    if (identical(node, _selected) || node.key == _selected?.key) return true;
    if (node is ZoneNode) {
      return context.read<WorldController>().currentZoneId == node.id;
    }
    return false;
  }

  Widget _tokenFor(WorldController world, MapNode node) {
    // only zones carry gates and a "you are here"; a landmark is just a
    // door you walk through from wherever you're standing
    final zone = node is ZoneNode ? node.id : null;
    final locked = zone != null && !world.meetsZoneRequirement(zone);
    final (gateSkill, gateLevel) = locked
        ? _lockGate(world, zone)
        : (SkillId.NULL, 0);

    return MapNodeToken(
      key: ValueKey(node.key),
      name: node.name,
      type: node.type,
      isCurrent: zone != null && world.currentZoneId == zone,
      isSelected: _selected?.key == node.key,
      isLocked: locked,
      lockSkill: gateSkill,
      lockLevel: gateLevel,
      showLabel: _showLabel(node),
      dimmed: _hidden.contains(node.type.group),
      onTap: () => _select(node),
    );
  }

  /// Picks [node] (null clears the pick). A picked zone recolours the whole
  /// app — this map, the bars over it and the nav bar under it — in its own
  /// palette, crossfading as the pick moves, so reading about a place
  /// already looks like being there. A landmark belongs to no zone and
  /// leaves the colours as they are.
  void _select(MapNode? node) {
    setState(() => _selected = node);
    context.read<WorldController>().previewOnMap(
      node is ZoneNode ? node.id : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = context.watch<WorldController>();
    // stamina changes (ambient recovery, action drain) re-price travel and
    // re-colour the hops the player can no longer pay for
    context.watch<PlayerDataController>();

    // after layout, so the viewport's size is known
    final zone = world.currentZoneId;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _frameCurrentZone(zone),
    );

    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  key: _viewport,
                  child: InteractiveViewer(
                    transformationController: _view,
                    constrained: false,
                    minScale: 0.5,
                    maxScale: 2.5,
                    boundaryMargin: EdgeInsets.zero,
                    child: SizedBox.fromSize(
                      size: _paddedSize,
                      child: Stack(
                        children: [
                          // pixel-art terrain: nearest-neighbour keeps it
                          // crisp when the canvas is zoomed. The surface
                          // colour behind it covers any load gap.
                          Positioned.fill(
                            child: ColoredBox(color: scheme.surface),
                          ),
                          Positioned.fill(
                            child: Image.asset(
                              'assets/images/map/world_map.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.none,
                            ),
                          ),

                          // tapping bare map clears the selection
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _select(null),
                            ),
                          ),

                          // roads and tokens live in the unpadded space
                          Positioned(
                            left: kWorldMapPadding,
                            top: kWorldMapPadding,
                            width: kWorldMapSize.width,
                            height: kWorldMapSize.height,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: CustomPaint(
                                      painter: MapEdgePainter(
                                        edges: _edges(world),
                                        lineColor: const Color(0xBFF1E4C3),
                                        badgeFill: const Color(0xF0171210),
                                      ),
                                    ),
                                  ),
                                ),

                                for (final node in kWorldMapNodes)
                                  Positioned(
                                    left:
                                        node.center.dx -
                                        MapNodeToken.slotWidth / 2,
                                    top:
                                        node.center.dy -
                                        MapNodeToken.tokenCenterY,
                                    child: _tokenFor(world, node),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // what kinds of place to show: one toggle per node type
                Positioned(
                  left: 12,
                  top: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final type in MapNodeType.mapGroups) ...[
                        _FilterButton(
                          type: type,
                          on: !_hidden.contains(type),
                          onTap: () => setState(() {
                            if (!_hidden.remove(type)) _hidden.add(type);
                          }),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),

                // with nothing picked, the foot of the map says where you
                // are and lets you step straight back in
                if (_selected == null)
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: _LocationBar(
                      zone: zone,
                      onEnter: () => _enterZone(world, zone),
                    ),
                  ),
              ],
            ),
          ),

          // no selection, no pane: an empty strip of chrome earns nothing,
          // and the map would rather have the room
          if (_selected != null)
            MapDetailPane(
              node: _selected!,
              onEnter: (zoneId) => _enterZone(world, zoneId),
              onEnterLandmark: _enterLandmark,
            ),
        ],
      ),
    );
  }
}

/// One switch on the map's filter rail: the type's pixel glyph on a dark
/// square, with a bar in the type's colour along its foot while it's on.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.type,
    required this.on,
    required this.onTap,
  });

  static const double size = 44;

  final MapNodeType type;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = type.label[0] + type.label.substring(1).toLowerCase();
    return Semantics(
      button: true,
      toggled: on,
      label: '$name places',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xF21B1511),
            border: Border.all(color: PixelSprites.outline, width: 2),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: on ? 1 : 0.35,
                child: PixelArt(PixelSprites.glyph(type), unit: 1.5),
              ),
              if (on)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 3,
                  child: ColoredBox(color: type.color),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The foot of the map when nothing is picked: the type glyph and name of
/// the place you're standing in, and a way straight back into it.
class _LocationBar extends StatelessWidget {
  const _LocationBar({required this.zone, required this.onEnter});

  final ZoneId zone;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    final def = zone.definition;
    return Container(
      height: 56,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      decoration: BoxDecoration(
        color: const Color(0xF2171210),
        border: Border.all(color: PixelSprites.outline, width: 3),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0B08),
              border: Border(
                bottom: BorderSide(color: def.type.color, width: 3),
              ),
            ),
            child: PixelArt(PixelSprites.glyph(def.type), unit: 1.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOU ARE AT',
                  style: TextStyle(
                    fontFamily: HearthText.pixel,
                    fontSize: 11,
                    height: 1.1,
                    color: Color(0xFFA8977A),
                  ),
                ),
                Text(
                  def.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: HearthText.pixel,
                    fontSize: 17,
                    height: 1.2,
                    color: Color(0xFFF1E4C3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEnter,
            style: TextButton.styleFrom(
              backgroundColor: PixelSprites.gold,
              foregroundColor: const Color(0xFF1A1208),
              minimumSize: const Size(72, 40),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: PixelSprites.outline, width: 2),
              ),
              textStyle: const TextStyle(
                fontFamily: HearthText.pixel,
                fontSize: 16,
              ),
            ),
            child: const Text('Enter'),
          ),
        ],
      ),
    );
  }
}
