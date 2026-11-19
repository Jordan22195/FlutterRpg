import 'package:flutter/material.dart';

import '../catalogs/dungeons/dungeons.dart';
import '../catalogs/items/items.dart';
import '../data/skill_data.dart';
import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../theme/zone_palette.dart';
import 'equipment_info_dialog.dart';
import 'equipment_picker.dart';
import 'icon_renderer.dart';
import 'item_stack_tile.dart';
import 'place_tile.dart';

/// A zone's dungeon, drawn full width over the zone's tiles so it reads as
/// a place to go into rather than one more thing to fight: its scene art
/// filling the card behind a scrim, as the map's zone preview wears its
/// zone's, its name and combat level, and the uniques it's farmed for: each
/// lit once collected, and checked once collected at the best rarity it
/// drops at. A tap on the card goes in; a tap on a piece opens its details.
class DungeonBanner extends StatelessWidget {
  const DungeonBanner({
    super.key,
    required this.dungeonId,
    required this.name,
    required this.level,
    required this.levelMet,
    required this.uniques,
    required this.obtainedRarities,
    required this.onTap,
    this.active = false,
  });

  /// The dungeon, whose own scene art fills the card.
  final DungeonId dungeonId;
  final String name;

  /// The dungeon's combat level, or null for one with no fights.
  final int? level;

  /// Whether the player's combat level meets [level].
  final bool levelMet;

  /// The uniques the dungeon drops, in the order they're shown.
  final List<ItemId> uniques;

  /// The rarities the player has had [id] at, or null when they've never
  /// had it. Empty means had, at no rarity known.
  final Set<Rarity>? Function(ItemId id) obtainedRarities;

  final VoidCallback onTap;

  /// Whether one of the dungeon's floors is what the action loop is
  /// running: an accent edge and the action's progress along the foot, as
  /// an active tile wears.
  final bool active;

  /// At most this many slots show; past it, the last is a "+N".
  static const maxSlots = 5;

  @override
  Widget build(BuildContext context) {
    final progress = [
      for (final id in uniques)
        UniqueProgress(
          id: id,
          drops: dungeonId.definition.dropRaritiesOf(id),
          had: obtainedRarities(id),
        ),
    ];
    final complete = progress.where((p) => p.complete).length;
    final level = this.level;
    final label = [
      name,
      'dungeon',
      if (level != null) 'combat level $level',
      if (uniques.isNotEmpty)
        '$complete of ${uniques.length} unique items at their best rarity',
      if (active) 'active',
    ].join(', ');

    final palette = context.palette;
    final bg = palette.bg;
    // the card is one button; each loot slot is a button of its own inside
    // it, so the card's own text is left out of what's read
    return Semantics(
      container: true,
      button: true,
      label: label,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: palette.scene.withValues(alpha: 0.35),
              blurRadius: 22,
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          // the art and the scrim are both ink on the card's material, so
          // the tap's ripple still shows over them
          child: Ink(
            key: const ValueKey('dungeon-banner-art'),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: active ? palette.accent : _sceneBorder(palette, 0.5),
                width: 2,
              ),
              image: DecorationImage(
                image: AssetImage(dungeonId.definition.iconAsset),
                fit: BoxFit.cover,
                // the middle of the scene pushed right, where the scrim
                // lets it show
                alignment: const Alignment(0.6, 0.2),
                // pixel art: smoothing would blur it
                filterQuality: FilterQuality.none,
                // undrawn art: the card is the palette's background alone
                onError: (_, _) {},
              ),
            ),
            child: Ink(
              key: const ValueKey('dungeon-banner-scrim'),
              // heavy under the text on the left, clearing to the right so
              // the art reads there in full
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    bg.withValues(alpha: 0.96),
                    bg.withValues(alpha: 0.82),
                    bg.withValues(alpha: 0.1),
                  ],
                  stops: const [0, 0.5, 1],
                ),
              ),
              child: InkWell(
                key: const ValueKey('dungeon-banner-tap'),
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Stack(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 112),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _info(context, progress, complete),
                        ),
                      ),
                    ),
                    if (active)
                      const Positioned(
                        left: 18,
                        right: 18,
                        bottom: 5,
                        child: ActiveProgressBar(
                          key: ValueKey('dungeon-banner-progress'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _info(
    BuildContext context,
    List<UniqueProgress> progress,
    int complete,
  ) {
    final level = this.level;
    final colors = context.gameColors;
    final palette = context.palette;
    final overline = _overline(palette);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Row(
            children: [
              Icon(Icons.fort, size: 13, color: overline),
              const SizedBox(width: 4),
              Text(
                'DUNGEON',
                style: HearthText.rowMeta.copyWith(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.6,
                  color: overline,
                ),
              ),
              if (level != null) ...[
                const SizedBox(width: 8),
                _LevelChip(
                  level: level,
                  color: levelMet ? colors.levelEasy : colors.levelHard,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 2),
        ExcludeSemantics(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: HearthText.title.copyWith(
              fontSize: 22,
              height: 1.15,
              color: palette.text,
              shadows: [
                Shadow(offset: const Offset(0, 2), color: palette.titleShadow),
              ],
            ),
          ),
        ),
        if (uniques.isNotEmpty) ...[
          const SizedBox(height: 6),
          _lootRow(context, progress, complete),
        ],
      ],
    );
  }

  Widget _lootRow(
    BuildContext context,
    List<UniqueProgress> progress,
    int complete,
  ) {
    final overflow = progress.length > maxSlots;
    final shown = overflow ? progress.take(maxSlots - 1) : progress;
    return Row(
      children: [
        for (final p in shown) ...[
          _LootSlot(key: ValueKey('dungeon-loot-${p.id.name}'), progress: p),
          const SizedBox(width: 4),
        ],
        if (overflow) ...[
          _MoreSlot(
            key: const ValueKey('dungeon-loot-more'),
            count: progress.length - (maxSlots - 1),
            onTap: () => showDungeonUniquesSheet(
              context,
              name: name,
              dungeonId: dungeonId,
              uniques: uniques,
              obtainedRarities: obtainedRarities,
            ),
          ),
          const SizedBox(width: 4),
        ],
        const SizedBox(width: 2),
        ExcludeSemantics(
          child: Text(
            '$complete/${uniques.length}',
            style: HearthText.rowMeta.copyWith(
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: context.palette.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// [palette]'s strong border with the zone's [ZonePalette.scene] blended
/// through it at [t]: the banner's and the arch's edges.
Color _sceneBorder(ZonePalette palette, double t) =>
    Color.alphaBlend(palette.scene.withValues(alpha: t), palette.borderStrong);

/// The "DUNGEON" overline: the zone's scene colour lifted toward its text,
/// so it carries the place's hue and still reads on the card.
Color _overline(ZonePalette palette) =>
    Color.lerp(palette.scene, palette.text, 0.45)!;

/// The dungeon's combat level: the attack sprite and the level, coloured
/// by whether the player meets it.
class _LevelChip extends StatelessWidget {
  const _LevelChip({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const IconRenderer(id: SkillId.ATTACK, size: 14),
        const SizedBox(width: 3),
        Text(
          '$level',
          key: const ValueKey('dungeon-banner-level'),
          style: HearthText.rowMeta.copyWith(
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

/// Where the player stands with one unique: the rarities it [drops] at in
/// its dungeon, lowest first, and the ones they've [had] it at — null when
/// never.
class UniqueProgress {
  const UniqueProgress({required this.id, required this.drops, this.had});

  final ItemId id;
  final List<Rarity> drops;
  final Set<Rarity>? had;

  bool get collected => had != null;

  /// The best rarity it drops at here.
  Rarity? get best => drops.isEmpty ? null : drops.last;

  /// The best rarity the player has had it at, or null when none is known.
  Rarity? get bestHad {
    final had = this.had;
    if (had == null || had.isEmpty) return null;
    return had.reduce((a, b) => a.index >= b.index ? a : b);
  }

  /// Had at the best rarity there is to get — or, for a piece whose drop
  /// rarity can't be read, had at all.
  bool get complete {
    final had = this.had;
    if (had == null) return false;
    final best = this.best;
    if (best == null) return true;
    return had.any((r) => r.index >= best.index);
  }

  /// The rarity its details open at: the best one had, or the lowest one
  /// it drops at when nothing is known.
  Rarity get shownAt =>
      bestHad ?? (drops.isEmpty ? Rarity.COMMON : drops.first);
}

/// [id] built at [rarity], the way it would come out of a drop.
EquipmentItem? _pieceAt(ItemId id, Rarity rarity) {
  final item = id.build();
  if (item is! EquipmentItem) return null;
  item.quality = rarity;
  return item;
}

/// Opens [id]'s details at [rarity].
void _showDetails(BuildContext context, ItemId id, Rarity rarity) {
  final piece = _pieceAt(id, rarity);
  if (piece == null) {
    showItemInfoDialog(context, id);
  } else {
    showEquipmentInfoDialog(context, piece);
  }
}

/// The dark square a loot icon sits in, edged in [borderColor] when given.
class _SlotBox extends StatelessWidget {
  const _SlotBox({required this.child, this.borderColor});

  final Widget child;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final borderColor = this.borderColor;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.33),
        borderRadius: BorderRadius.circular(6),
        border: borderColor == null
            ? null
            : Border.all(color: borderColor, width: 1.5),
      ),
      child: child,
    );
  }
}

/// The check on a collected piece, marked the way a cleared dungeon floor
/// is on its rail: a cleared-green check in a green-ringed node.
class CollectedCheck extends StatelessWidget {
  const CollectedCheck({super.key});

  static const double size = 14;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.clearedFill,
        shape: BoxShape.circle,
        border: Border.all(color: GameColors.clearedColor, width: 1.5),
      ),
      child: const Icon(Icons.check, size: 10, color: GameColors.clearedColor),
    );
  }
}

/// One unique: greyed out until it's been collected; then in full colour,
/// edged in the best rarity had; and with a check on its corner once that
/// is the best rarity it drops at. A tap opens the piece's details at that
/// rarity, collected or not, so the player can see what they're farming
/// for.
class _LootSlot extends StatelessWidget {
  const _LootSlot({super.key, required this.progress});

  final UniqueProgress progress;

  /// Luminance weights on each channel: the icon in greys.
  static const _grayscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0, //
  ]);

  @override
  Widget build(BuildContext context) {
    final p = progress;
    final state = p.complete
        ? 'collected at its best rarity'
        : p.collected
        ? 'collected, ${_rarityName(p.best)} still to find'
        : 'not collected';
    return Semantics(
      container: true,
      button: true,
      label: '${p.id.definition.name}, $state',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showDetails(context, p.id, p.shownAt),
          child: _slot(context),
        ),
      ),
    );
  }

  Widget _slot(BuildContext context) {
    final p = progress;
    final icon = IconRenderer(id: p.id, size: 20);
    if (!p.collected) {
      return _SlotBox(
        child: Opacity(
          key: const ValueKey('dungeon-loot-unobtained'),
          opacity: 0.4,
          child: ColorFiltered(colorFilter: _grayscale, child: icon),
        ),
      );
    }
    final bestHad = p.bestHad;
    final box = _SlotBox(
      borderColor: bestHad == null ? null : rarityBorderColor(bestHad),
      child: icon,
    );
    if (!p.complete) return box;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        box,
        const Positioned(
          right: -4,
          bottom: -4,
          child: CollectedCheck(key: ValueKey('dungeon-loot-check')),
        ),
      ],
    );
  }
}

/// [rarity]'s name to show; common, which labels itself with nothing, too.
String _rarityName(Rarity? rarity) => switch (rarity) {
  null => 'Unknown',
  Rarity.COMMON => 'Common',
  final r => r.label,
};

/// The last slot when there are more uniques than room: how many more.
/// A tap lists them all.
class _MoreSlot extends StatelessWidget {
  const _MoreSlot({super.key, required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      label: '$count more unique items',
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: _SlotBox(
            child: Text(
              '+$count',
              style: HearthText.rowMeta.copyWith(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w800,
                color: context.palette.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Lists every unique [name] drops in a bottom sheet, a card for each
/// rarity it drops at: what the banner's "+N" stands for.
Future<void> showDungeonUniquesSheet(
  BuildContext context, {
  required String name,
  required DungeonId dungeonId,
  required List<ItemId> uniques,
  required Set<Rarity>? Function(ItemId id) obtainedRarities,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.palette.surface,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => SafeArea(
      child: DungeonUniquesList(
        name: name,
        dungeonId: dungeonId,
        uniques: uniques,
        obtainedRarities: obtainedRarities,
      ),
    ),
  );
}

/// Every unique a dungeon drops, a card for each rarity it drops at — the
/// gear picker's card, with the piece's icon, name, slot and stats at that
/// rarity — checked once had at it and dimmed until then. A tap on a card
/// opens the piece's details at that rarity.
class DungeonUniquesList extends StatelessWidget {
  const DungeonUniquesList({
    super.key,
    required this.name,
    required this.dungeonId,
    required this.uniques,
    required this.obtainedRarities,
  });

  final String name;
  final DungeonId dungeonId;
  final List<ItemId> uniques;
  final Set<Rarity>? Function(ItemId id) obtainedRarities;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final entries = [
      for (final id in uniques)
        for (final rarity in _raritiesOf(id))
          (
            id: id,
            rarity: rarity,
            had: obtainedRarities(id)?.contains(rarity) ?? false,
          ),
    ];
    final had = entries.where((e) => e.had).length;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.7,
      ),
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            '$name uniques · $had/${entries.length}',
            style: HearthText.rowTitle.copyWith(color: palette.text),
          ),
          const SizedBox(height: 8),
          for (final e in entries)
            if (_pieceAt(e.id, e.rarity) case final piece?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Opacity(
                  opacity: e.had ? 1 : 0.6,
                  child: EquipmentPickerCard(
                    key: ValueKey(
                      'dungeon-unique-${e.id.name}-${e.rarity.name}',
                    ),
                    item: piece,
                    baseline: null,
                    onTap: () => showEquipmentInfoDialog(context, piece),
                    trailing: _UniqueStatus(rarity: e.rarity, had: e.had),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// The rarities [id] drops at here; a piece whose tables don't name it
  /// shows once, at its own.
  List<Rarity> _raritiesOf(ItemId id) {
    final drops = dungeonId.definition.dropRaritiesOf(id);
    if (drops.isNotEmpty) return drops;
    final piece = id.build();
    return [if (piece is EquipmentItem) piece.quality];
  }
}

/// A card's right edge in the uniques list: the rarity it's at, in that
/// rarity's colour, over a check once had or "Not yet".
class _UniqueStatus extends StatelessWidget {
  const _UniqueStatus({required this.rarity, required this.had});

  final Rarity rarity;
  final bool had;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _rarityName(rarity),
          key: const ValueKey('dungeon-unique-rarity'),
          style: HearthText.rowMeta.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: rarityTextColor(rarity) ?? palette.text,
          ),
        ),
        const SizedBox(height: 6),
        if (had)
          const CollectedCheck(key: ValueKey('dungeon-unique-check'))
        else
          Text(
            'Not yet',
            style: HearthText.rowMeta.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: palette.textMuted,
            ),
          ),
      ],
    );
  }
}
