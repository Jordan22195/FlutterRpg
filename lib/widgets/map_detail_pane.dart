import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeons/dungeon_id.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/zones/world_map_layout.dart';
import '../catalogs/zones/zone_id.dart';
import '../controllers/world_controller.dart';
import '../data/skill_category.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../theme/zone_palette.dart';
import '../utilities/util.dart';
import 'art_header.dart';
import 'item_stack_tile.dart';
import 'recipe_card.dart';

/// The selected place, shown as its own banner: the zone's scene art under
/// a scrim, its name in the same pixel title the zone screen wears, what
/// kind of place it is and how far off, and what's standing there.
///
/// It is the zone header in miniature, drawn in the zone's own palette, so
/// picking a node on the map already looks like arriving there.
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
  static const double height = 176;

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
    // a zone wears its own colours; a landmark stands outside any zone and
    // keeps the default palette
    final palette = switch (node) {
      final ZoneNode zone => zone.id.definition.palette,
      LandmarkNode() => ZonePalette.meadow,
    };

    return Theme(
      data: hearthTheme(palette),
      child: Builder(
        builder: (context) => SizedBox(
          height: height,
          width: double.infinity,
          child: switch (node) {
            final ZoneNode zone => _zoneBanner(context, zone),
            final LandmarkNode landmark => _landmarkBanner(context, landmark),
          },
        ),
      ),
    );
  }

  Widget _zoneBanner(BuildContext context, ZoneNode node) {
    final world = context.watch<WorldController>();
    final def = node.id.definition;
    final isCurrent = world.currentZoneId == node.id;
    final reachable = world.canReach(node.id);
    final locked = !world.meetsZoneRequirement(node.id);

    // one button, and it only ever opens the place. walking there is free,
    // so the only thing that shuts the door is a locked or roadless zone:
    // there is nothing to show.
    return _banner(
      context: context,
      artAsset: def.iconAsset,
      name: def.name,
      type: node.type.label,
      distance: _distanceLine(
        isCurrent,
        reachable,
        world.travelHopsTo(node.id),
        world.travelTimeTo(node.id),
      ),
      levelChip: def.explorationLevel > 0
          ? ArtHeaderChip(
              icon: Icon(
                Icons.explore_outlined,
                size: 16,
                color: context.gameColors.exploration,
              ),
              label: '${def.explorationLevel}',
              semanticsLabel: 'Zone exploration level ${def.explorationLevel}',
            )
          : null,
      foot: locked
          ? _requirements(context, world, node.id)
          : _entityPreview(context, world.zoneEntities(node.id)),
      enabled: !locked && reachable,
      onPressed: () => onEnter(node.id),
    );
  }

  Widget _landmarkBanner(BuildContext context, LandmarkNode node) {
    final def = node.id.definition;
    return _banner(
      context: context,
      artAsset: def.iconAsset,
      name: def.name,
      type: node.type.label,
      // landmarks aren't on the travel graph: you walk in from wherever you
      // are, and the run itself is what costs you
      distance: 'No stamina to enter',
      levelChip: null,
      foot: const SizedBox.shrink(),
      enabled: true,
      onPressed: () => onEnterLandmark(node.id),
    );
  }

  String _distanceLine(
    bool isCurrent,
    bool reachable,
    int hops,
    Duration time,
  ) {
    if (isCurrent) return 'You are here';
    if (!reachable) return 'Unreachable';
    final hopWord = hops == 1 ? 'hop' : 'hops';
    return '$hops $hopWord · ${Util.formatShortDuration(time)} walk';
  }

  /// The banner itself: art, scrim, title block and the foot row, laid out
  /// the way [ArtHeader] lays out an open zone header.
  Widget _banner({
    required BuildContext context,
    required String artAsset,
    required String name,
    required String type,
    required String distance,
    required Widget? levelChip,
    required Widget foot,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final palette = context.palette;
    final bg = palette.bg;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: palette.divider)),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (artAsset.isNotEmpty)
            Image.asset(
              artAsset,
              fit: BoxFit.cover,
              // the middle of the scene, below the sky, the way the zone
              // header's strip sits
              alignment: const Alignment(0, 0.2),
              // zone art is pixel art; smoothing it blurs the pixels
              filterQuality: FilterQuality.none,
              // undrawn art: the banner is the palette's background alone
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),

          // light over the scene, heavy under the text, so the art reads
          // at the top and the name and icons read at the foot
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    bg.withValues(alpha: 0.1),
                    bg.withValues(alpha: 0.6),
                    bg.withValues(alpha: 0.94),
                  ],
                  stops: const [0, 0.42, 0.78],
                ),
              ),
            ),
          ),

          if (levelChip != null)
            Positioned(top: 10, right: 12, child: levelChip),

          Positioned(
            left: 14,
            right: 12,
            bottom: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _titleBlock(context, name, type, distance)),
                    const SizedBox(width: 12),
                    _enterButton(context, enabled, onPressed),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(height: tileSize, child: foot),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleBlock(
    BuildContext context,
    String name,
    String type,
    String distance,
  ) {
    final palette = context.palette;
    final meta = HearthText.rowMeta.copyWith(
      fontSize: 12,
      color: palette.textSubtitle,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          // the zone screen's own title, a size down to fit the pane
          style: HearthText.title.copyWith(
            fontSize: 24,
            color: palette.text,
            shadows: [
              Shadow(offset: const Offset(0, 2), color: palette.titleShadow),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              type,
              style: meta.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: palette.text,
              ),
            ),
            Text('  ·  ', style: meta),
            Flexible(
              child: Text(
                distance,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: meta,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// The zone's accent, the way the primary action button wears it inside
  /// the zone.
  Widget _enterButton(
    BuildContext context,
    bool enabled,
    VoidCallback onPressed,
  ) {
    final palette = context.palette;
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: palette.accent,
        foregroundColor: palette.onAccent,
        disabledBackgroundColor: palette.raised,
        disabledForegroundColor: palette.textMuted,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Text('Enter'),
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
  Widget _entityPreview(BuildContext context, List<Entity> entities) {
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
              color: context.palette.borderOverArt,
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

    // two gates can be unmet at once; the pair scales down rather than
    // spilling out of the foot row
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            Text(
              line,
              style: HearthText.rowMeta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RecipeCard.missingMaterialColor,
              ),
            ),
        ],
      ),
    );
  }
}
