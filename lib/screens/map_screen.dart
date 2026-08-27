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
import '../widgets/recipe_card.dart';

/// The world map: a graph of places you can walk between, and what walking
/// there costs.
///
/// The split of duties is the whole design. A node says what a place *is*
/// (its type glyph), whether it is shut (the padlock) and whether you're
/// standing in it (the ring). An edge says what the trip costs, once. Every
/// sentence of detail — names of gates, what's in town, the travel button —
/// lives in the pane docked underneath, which never covers the map.
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
  void _frameCurrentZone(ZoneId zone) {
    if (_framedOn == zone || !mounted) return;
    final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final target =
        zoneNodeCenter(zone) ??
        Offset(kWorldMapSize.width / 2, kWorldMapSize.height / 2);
    _framedOn = zone;

    // the canvas draws at scale*p + translation, so putting `target` under
    // the viewport's centre means translation = centre - scale * target
    final scale = _view.value.getMaxScaleOnAxis();
    _view.value = Matrix4.identity()
      ..translateByDouble(
        box.size.width / 2 - target.dx * scale,
        box.size.height / 2 - target.dy * scale,
        0,
        1,
      )
      ..scaleByDouble(scale, scale, scale, 1);
  }

  /// Moves the player and stops there. Arriving somewhere and going into it
  /// are two different decisions — you might walk to a town to look at what
  /// it has and go no further — so travelling leaves you on the map with
  /// the pane now offering Enter.
  void _travelTo(WorldController world, ZoneId zoneId) {
    world.travelToZone(zoneId);
  }

  void _enterCurrentZone() {
    // This pushes onto the MAP TAB's nested navigator, so switching
    // tabs and coming back returns to ExploreScreen.
    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(
          name: EntityScreenRouterService.exploreRouteName,
        ),
        builder: (_) => ExploreScreen(),
      ),
    );
  }

  void _enterLandmark(DungeonId dungeonId) {
    Navigator.of(context).push(
      MaterialPageRoute(
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

  List<MapEdge> _edges(WorldController world) {
    final edges = <MapEdge>[];

    for (final (end, otherEnd, _) in world.travelEdges()) {
      final endCenter = zoneNodeCenter(end);
      final otherCenter = zoneNodeCenter(otherEnd);
      if (endCenter == null || otherCenter == null) continue;

      // orient each edge away from the player: the badge then sits toward
      // the far end and clears the near node's label. It also decides which
      // way the hop is priced, and the road is not symmetric — the climb
      // back up from the mine costs ten times the walk down.
      final endHops = world.travelHopsTo(end);
      final otherHops = world.travelHopsTo(otherEnd);
      final nearIsEnd = endHops >= 0 && (otherHops < 0 || endHops <= otherHops);
      final (near, far) = nearIsEnd ? (end, otherEnd) : (otherEnd, end);

      edges.add(
        MapEdge(
          from: nearIsEnd ? endCenter : otherCenter,
          to: nearIsEnd ? otherCenter : endCenter,
          cost: ZoneTravelGraph.edgeCost(near, far),
          affordable: world.canAffordHop(near, far),
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
      onTap: () => setState(() => _selected = node),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = context.watch<WorldController>();
    // stamina changes (ambient recovery, action drain) re-price travel and
    // re-colour the hops the player can no longer pay for
    context.watch<PlayerDataController>();

    final scheme = Theme.of(context).colorScheme;

    // after layout, so the viewport's size is known
    final zone = world.currentZoneId;
    //WidgetsBinding.instance.addPostFrameCallback(
    //  (_) => _frameCurrentZone(zone),
    //);

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
                    boundaryMargin: const EdgeInsets.all(80),
                    child: SizedBox.fromSize(
                      size: kWorldMapSize,
                      child: Stack(
                        children: [
                          // the seam map art drops into later: nothing above
                          // it assumes an opaque backdrop, because the labels
                          // carry their own halo and the badges their own fill
                          Positioned.fill(
                            child: ColoredBox(color: scheme.surface),
                          ),

                          // tapping bare map clears the selection
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(() => _selected = null),
                            ),
                          ),

                          Positioned.fill(
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: MapEdgePainter(
                                  edges: _edges(world),
                                  lineColor: scheme.onSurface.withValues(
                                    alpha: 0.35,
                                  ),
                                  badgeFill: scheme.surface.withValues(
                                    alpha: 0.85,
                                  ),
                                  warningColor: RecipeCard.missingMaterialColor,
                                ),
                              ),
                            ),
                          ),

                          for (final node in kWorldMapNodes)
                            Positioned(
                              left: node.center.dx - MapNodeToken.slotWidth / 2,
                              top: node.center.dy - MapNodeToken.tokenCenterY,
                              child: _tokenFor(world, node),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // the canvas pans under the title, so the title sits on a
                // scrim that fades the map out beneath it rather than
                // letting labels collide with it
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            scheme.surface,
                            scheme.surface.withValues(alpha: 0.9),
                            scheme.surface.withValues(alpha: 0),
                          ],
                          stops: const [0, 0.45, 1],
                        ),
                      ),
                      child: Text(
                        'World Map',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
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
              onTravel: (zoneId) => _travelTo(world, zoneId),
              onEnter: _enterCurrentZone,
              onEnterLandmark: _enterLandmark,
            ),
        ],
      ),
    );
  }
}
