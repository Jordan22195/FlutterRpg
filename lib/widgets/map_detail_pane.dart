import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeons/dungeon_id.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/zones/world_map_layout.dart';
import '../catalogs/zones/zone_id.dart';
import '../controllers/world_controller.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';
import 'recipe_card.dart';

/// Everything the map used to try to write on its nodes: what a place is,
/// how far off it is, what the trip will cost, what's waiting when you
/// arrive, and why you can't go yet.
///
/// It is docked below the map rather than floated over it, and it exists
/// only while a node is picked: selecting swaps the contents, and clearing
/// the selection gives the room back to the map. The map is never covered —
/// you can keep reading the graph while you read about a place.
class MapDetailPane extends StatelessWidget {
  const MapDetailPane({
    super.key,
    required this.node,
    required this.onEnter,
    required this.onEnterLandmark,
  });

  /// Fixed height, reserved whether or not anything is selected, so the map
  /// canvas never resizes under the player's finger.
  static const double height = 136;

  /// Size of an entity preview tile.
  static const double tileSize = 30;

  final MapNode node;

  /// Opens a zone. Looking at a place and going to it are two different
  /// decisions, so this only ever shows you the place — the trip is offered
  /// by the travel button on the screen it opens, and costs nothing until
  /// you take it.
  final void Function(ZoneId) onEnter;
  final void Function(DungeonId) onEnterLandmark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: height,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: switch (node) {
        final ZoneNode zone => _zoneBody(context, scheme, zone),
        final LandmarkNode landmark => _landmarkBody(context, scheme, landmark),
      },
    );
  }

  Widget _zoneBody(BuildContext context, ColorScheme scheme, ZoneNode node) {
    final world = context.watch<WorldController>();
    final def = node.id.definition;
    final isCurrent = world.currentZoneId == node.id;
    final cost = world.travelCostTo(node.id);
    final hops = world.travelHopsTo(node.id);
    final locked = !world.meetsZoneRequirement(node.id);
    final affordable = world.canAffordTravelTo(node.id);
    final reachable = !cost.isInfinite;

    // one button, and it only ever opens the place. a trip you cannot
    // afford yet is still a place worth reading about, so the fare being
    // out of reach reddens the cost chip rather than shutting the door —
    // the travel button inside is the one that has to wait for stamina.
    // a locked or roadless zone is the exception: there is nothing to show.
    return _layout(
      context: context,
      scheme: scheme,
      name: def.name,
      type: node.type.label,
      distance: _distanceLine(isCurrent, reachable, hops, cost),
      body: locked
          ? _requirements(context, scheme, world, node.id)
          : _entityPreview(context, scheme, world.zoneEntities(node.id)),
      buttonLabel: 'Enter',
      enabled: !locked && reachable,
      warnCost: !affordable && reachable && !isCurrent,
      cost: isCurrent || !reachable ? null : cost,
      onPressed: () => onEnter(node.id),
    );
  }

  Widget _landmarkBody(
    BuildContext context,
    ColorScheme scheme,
    LandmarkNode node,
  ) {
    final def = node.id.definition;

    return _layout(
      context: context,
      scheme: scheme,
      name: def.name,
      type: node.type.label,
      // landmarks aren't on the travel graph: you walk in from wherever you
      // are, and the run itself is what costs you
      distance: 'No stamina to enter',
      body: const SizedBox.shrink(),
      buttonLabel: 'Enter',
      enabled: true,
      warnCost: false,
      cost: null,
      onPressed: () => onEnterLandmark(node.id),
    );
  }

  String _distanceLine(bool isCurrent, bool reachable, int hops, double cost) {
    if (isCurrent) return 'You are here';
    if (!reachable) return 'Unreachable';
    final hopWord = hops == 1 ? 'hop' : 'hops';
    return '$hops $hopWord · ${cost.toStringAsFixed(0)} stamina';
  }

  Widget _layout({
    required BuildContext context,
    required ColorScheme scheme,
    required String name,
    required String type,
    required String distance,
    required Widget body,
    required String buttonLabel,
    required bool enabled,
    required bool warnCost,
    required double? cost,
    required VoidCallback onPressed,
  }) {
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: text.titleMedium, maxLines: 1),
              Text(
                type,
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                distance,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: body),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: enabled ? onPressed : null,
              child: Text(buttonLabel),
            ),
            if (cost != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const IconRenderer<SkillId>(size: 13, id: SkillId.STAMINA),
                  const SizedBox(width: 3),
                  Text(
                    cost.toStringAsFixed(0),
                    style: text.labelSmall?.copyWith(
                      color: warnCost
                          ? RecipeCard.missingMaterialColor
                          : scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// What's standing in the place, laid out the way the zone itself lays it
  /// out: the permanent structures, then a rule, then whatever exploring
  /// there has turned up, each with its count.
  ///
  /// This is a preview of the zone screen you'd land on, so it splits the
  /// same way that screen does — fishing spots side with the structures,
  /// because they are fixtures that never deplete rather than nodes you
  /// work through. A node worked down to nothing is no longer there, so an
  /// empty count drops out of the row rather than showing a zero.
  Widget _entityPreview(
    BuildContext context,
    ColorScheme scheme,
    List<Entity> entities,
  ) {
    final structures = <Entity>[];
    final discovered = <EncounterEntity>[];
    for (final e in entities) {
      if (e is EncounterEntity && e is! FishingEntity) {
        if (e.count > 0) discovered.add(e);
      } else {
        structures.add(e);
      }
    }
    if (structures.isEmpty && discovered.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final e in structures) _entityTile(e.id, 1),
          if (structures.isNotEmpty && discovered.isNotEmpty)
            Container(
              width: 1,
              height: tileSize * 0.7,
              margin: const EdgeInsets.symmetric(horizontal: 7),
              color: scheme.outline,
            ),
          for (final e in discovered) _entityTile(e.id, e.count),
        ],
      ),
    );
  }

  Widget _entityTile(EntityId id, int count) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: ItemStackTile<EntityId>(
        size: tileSize,
        id: id,
        count: count,
        showInfoDialogOnTap: false,
        // a preview row: the reader wants "lots of trees", not 115,599
        compactCount: true,
      ),
    );
  }

  /// Why a locked place is locked, and how far off you are. A locked node
  /// still opens this pane — being told "Requires Mining 5" is the point.
  Widget _requirements(
    BuildContext context,
    ColorScheme scheme,
    WorldController world,
    ZoneId zoneId,
  ) {
    final def = zoneId.definition;
    final lines = <String>[];

    if (!world.meetsZoneExplorationRequirement(zoneId)) {
      lines.add(
        'Requires Exploration ${def.explorationLevel} '
        '— you have ${world.playerExplorationLevel}',
      );
    }
    if (!world.meetsZoneSkillRequirement(zoneId)) {
      lines.add(
        'Requires ${skillLabel(def.requiredSkill)} ${def.requiredLevel} '
        '— you have ${world.skillLevelFor(def.requiredSkill)}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Text(
            line,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: RecipeCard.missingMaterialColor,
            ),
          ),
      ],
    );
  }
}
