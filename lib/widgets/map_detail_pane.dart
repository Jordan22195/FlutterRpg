import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../catalogs/dungeons/dungeon_id.dart';
import '../catalogs/entities/entities.dart';
import '../catalogs/zones/map_node_type.dart';
import '../catalogs/zones/world_map_layout.dart';
import '../catalogs/zones/zone_id.dart';
import '../controllers/world_controller.dart';
import '../data/skill_category.dart';
import '../data/skill_data.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../theme/zone_palette.dart';
import '../utilities/util.dart';
import 'icon_renderer.dart';
import 'pixel_sprites.dart';
import 'recipe_card.dart';

/// The selected place, shown as its own banner: the zone's scene art behind
/// a scrim, its name in the same pixel title the zone screen wears, and —
/// in symbols rather than words — what kind of place it is, how far off,
/// and what you'd find there, or what keeps it shut.
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
      type: node.type,
      where: [
        ..._where(context, isCurrent, reachable, world.travelTimeTo(node.id)),
        ..._combatRange(context, world.zoneCombatLevelRange(node.id)),
      ],
      chips: locked ? _requirements(world, node.id) : _contents(world, node.id),
      enabled: !locked && reachable,
      onPressed: () => onEnter(node.id),
    );
  }

  Widget _landmarkBanner(BuildContext context, LandmarkNode node) {
    final def = node.id.definition;
    // landmarks aren't on the travel graph: you walk in from wherever you
    // are, and the run itself is what costs you
    return _banner(
      context: context,
      artAsset: def.iconAsset,
      name: def.name,
      type: node.type,
      where: const [],
      chips: const [],
      enabled: true,
      onPressed: () => onEnterLandmark(node.id),
    );
  }

  /// Where the place is from you, as a symbol: a pin when you're standing
  /// in it, a bar when no road reaches it, otherwise a walker and the time.
  List<Widget> _where(
    BuildContext context,
    bool isCurrent,
    bool reachable,
    Duration time,
  ) {
    final palette = context.palette;
    Widget icon(IconData data, String tip) => Tooltip(
      message: tip,
      child: Icon(data, size: 15, color: palette.textSubtitle),
    );

    if (isCurrent) return [icon(Icons.place, 'You are here')];
    if (!reachable) return [icon(Icons.block, 'Unreachable')];
    return [
      icon(Icons.directions_walk, 'Walk'),
      const SizedBox(width: 2),
      Text(
        Util.formatShortDuration(time),
        style: HearthText.rowMeta.copyWith(
          fontSize: 12,
          color: palette.textSubtitle,
        ),
      ),
    ];
  }

  /// How hard the zone fights: the attack icon and its creatures' combat
  /// levels, low to high, in the meta row beside the walk. Shown for locked
  /// zones too — how tough a place is matters most before you can go.
  List<Widget> _combatRange(BuildContext context, ({int min, int max})? range) {
    if (range == null) return const [];
    final palette = context.palette;
    final label = range.min == range.max
        ? '${range.min}'
        : '${range.min}–${range.max}';
    return [
      const SizedBox(width: 10),
      Tooltip(
        key: const ValueKey('zone-combat-range'),
        message: 'Combat level $label',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 3,
          children: [
            const IconRenderer<SkillId>(size: 15, id: SkillId.ATTACK),
            Text(
              label,
              style: HearthText.rowMeta.copyWith(
                fontSize: 12,
                color: palette.textSubtitle,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// What the zone holds, as its own icons: the structures standing in it,
  /// then every discovery your Exploration already reaches, each with the
  /// level it asks of you. The catalog, not your finds — this is a preview
  /// of the place, not of your save. Whatever is still beyond your level is
  /// one "?" chip with a count, so the place keeps some secrets.
  List<Widget> _contents(WorldController world, ZoneId zoneId) {
    final details = world.zoneDetails(zoneId);
    final seen = <String>{};
    final chips = <Widget>[];

    void add(EntityId id) {
      final def = id.definition;
      // fire slots and the like are one thing to the eye
      if (!seen.add(def.iconAsset.isEmpty ? def.name : def.iconAsset)) return;
      final level = _levelOf(def);
      chips.add(
        _Chip(
          tooltip: def.name,
          children: [
            _asset(def.iconAsset),
            if (level > 0) _ChipLabel('$level'),
          ],
        ),
      );
    }

    for (final id in details.zone.permanentEntities) {
      add(id);
    }
    for (final d in details.entities) {
      if (!d.locked) add(d.id as EntityId);
    }

    final hidden = details.entities.where((d) => d.locked).length;
    if (hidden > 0) {
      chips.add(
        _Chip(
          tooltip: '$hidden still hidden',
          muted: true,
          children: [
            const Icon(Icons.help_outline, size: 15),
            _ChipLabel('$hidden'),
          ],
        ),
      );
    }
    return chips;
  }

  /// The level an entity asks of you: a fighter's own level, a node's
  /// gathering level. 0 for the things that ask nothing, like a shop.
  static int _levelOf(EntityDefinition def) => switch (def) {
    final CombatEntityDefinition c => c.level,
    final EncounterEntityDefinition e => e.requiredLevel,
    _ => 0,
  };

  /// Why a locked place is locked: one red chip per unmet gate, a lock, the
  /// skill's icon and the level it wants. A locked node still opens this
  /// pane — being told what it takes is the point.
  List<Widget> _requirements(WorldController world, ZoneId zoneId) {
    final def = zoneId.definition;
    return [
      if (!world.meetsZoneExplorationRequirement(zoneId))
        _lockChip(SkillId.EXPLORATION, def.explorationLevel),
      if (!world.meetsZoneSkillRequirement(zoneId))
        _lockChip(def.requiredSkill, def.requiredLevel),
    ];
  }

  Widget _lockChip(SkillId skill, int level) => _Chip(
    tooltip: 'Requires ${skillLabel(skill)} $level',
    color: RecipeCard.missingMaterialColor,
    children: [
      const Icon(Icons.lock, size: 14, color: RecipeCard.missingMaterialColor),
      IconRenderer<SkillId>(size: 18, id: skill),
      _ChipLabel('$level', color: RecipeCard.missingMaterialColor),
    ],
  );

  static Widget _asset(String path) => SizedBox.square(
    dimension: 18,
    child: path.isEmpty
        ? const Icon(Icons.help_outline, size: 15)
        : Image.asset(
            path,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.none,
            errorBuilder: (_, _, _) => const Icon(Icons.help_outline, size: 15),
          ),
  );

  /// The banner itself: art on the right under a scrim that clears toward
  /// it, and on the left the title, the meta row, the chips and Enter.
  Widget _banner({
    required BuildContext context,
    required String artAsset,
    required String name,
    required MapNodeType type,
    required List<Widget> where,
    required List<Widget> chips,
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
              // the middle of the scene, below the sky, pushed right where
              // the scrim lets it show
              alignment: const Alignment(0.6, 0.2),
              // zone art is pixel art; smoothing it blurs the pixels
              filterQuality: FilterQuality.none,
              // undrawn art: the banner is the palette's background alone
              errorBuilder: (_, _, _) => const SizedBox.shrink(),
            ),

          // heavy under the text on the left, clearing to the right so the
          // art reads there in full
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    bg.withValues(alpha: 0.96),
                    bg.withValues(alpha: 0.82),
                    bg.withValues(alpha: 0.1),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // the zone screen's own title, a size down to fit the pane
                  style: HearthText.title.copyWith(
                    fontSize: 22,
                    color: palette.text,
                    shadows: [
                      Shadow(
                        offset: const Offset(0, 2),
                        color: palette.titleShadow,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // the type wears its map token's glyph and colour, so
                    // the pane and the node you tapped plainly match
                    Tooltip(
                      message: type.label,
                      child: PixelArt(PixelSprites.glyph(type), unit: 1),
                    ),
                    if (where.isNotEmpty) const SizedBox(width: 10),
                    ...where,
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        // two rows at most; a zone with more than that
                        // keeps the rest for its own screen
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Wrap(
                              spacing: 4,
                              runSpacing: 4,
                              children: chips,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _enterButton(context, enabled, onPressed),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
}

/// One small icon-and-number tag: a thing in the zone, or a gate on it.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.tooltip,
    required this.children,
    this.color,
    this.muted = false,
  });

  final String tooltip;
  final List<Widget> children;

  /// Tints the frame, for the red lock chips.
  final Color? color;

  /// Dims the content, for the "still hidden" count.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tint = color ?? palette.text;
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: tint.withValues(alpha: color == null ? 0.08 : 0.12),
          border: Border.all(color: tint.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: IconTheme.merge(
          data: IconThemeData(
            color: muted ? palette.textMuted : palette.textSubtitle,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 3,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  const _ChipLabel(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: HearthText.rowMeta.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: color ?? context.palette.text,
    ),
  );
}
