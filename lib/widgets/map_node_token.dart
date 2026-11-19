import 'package:flutter/material.dart';

import '../catalogs/zones/map_node_type.dart';
import '../data/skill_data.dart';
import '../theme/hearth_text.dart';
import 'icon_renderer.dart';
import 'pixel_sprites.dart';

/// One place on the world map: a pixel-art token cut to its type's shape,
/// with its name on a plate underneath.
///
/// Wilderness is a diamond with crossed swords, a town is a shield with a
/// house, a skilling spot is a round token with a pickaxe. Shape says the
/// type first and colour backs it up, so the three read apart at a glance.
///
/// Every slot is the same size whatever the place is called, so "Goblin
/// Queen's Lair" takes up exactly as much map as "Forest" and the layout's
/// spacing means what it says. The name wraps below the token instead of
/// inflating it.
///
/// The token carries three things and no more: what kind of place this is
/// (the shape and glyph), whether it is shut to you (the padlock), and
/// whether you are standing in it (the YOU flag). What a trip there *costs*
/// belongs to the edge you'd walk down, and everything else belongs to the
/// detail pane.
class MapNodeToken extends StatelessWidget {
  const MapNodeToken({
    super.key,
    required this.name,
    required this.type,
    this.isCurrent = false,
    this.isSelected = false,
    this.isLocked = false,
    this.lockSkill = SkillId.NULL,
    this.lockLevel = 0,
    this.showLabel = true,
    this.onTap,
  });

  /// The square the token is centred in. The shield, the tallest of the
  /// three shapes, fits inside it; all three clear the 44px touch floor.
  static const double tokenSize = 56;

  /// Width of the whole slot: the token plus the room its label may wrap
  /// into. Wider than the token so a long name doesn't shove its neighbours.
  static const double slotWidth = 96;

  /// Height of the whole slot: token, gap, and two lines of label.
  static const double slotHeight = 96;

  /// Distance from the top of the slot to the token's centre, so callers can
  /// position a slot by the centre the layout data gives them.
  static const double tokenCenterY = 30;

  /// Room the YOU flag takes above the token. It hangs outside the slot, so
  /// it never shifts the token off the centre the layout gives it.
  static const double _flagHeight = 30;

  static const Color _plate = Color(0xE6120E0B);
  static const Color _plateText = Color(0xFFF1E4C3);

  final String name;
  final MapNodeType type;
  final bool isCurrent;
  final bool isSelected;
  final bool isLocked;

  /// The skill gating a locked node, drawn on the token beside its level.
  final SkillId lockSkill;
  final int lockLevel;

  /// False hides the name, which the map does for minor places when zoomed
  /// out far enough that every label at once would be soup.
  final bool showLabel;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Stack(
          // the YOU flag hangs above the slot
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: tokenCenterY - tokenSize / 2,
              height: tokenSize,
              child: Center(child: _token()),
            ),
            if (showLabel)
              Positioned(
                left: 0,
                right: 0,
                top: tokenCenterY + tokenSize / 2 + 2,
                bottom: 0,
                child: Align(alignment: Alignment.topCenter, child: _label()),
              ),
            if (isCurrent)
              Positioned(
                left: 0,
                right: 0,
                top: tokenCenterY - _badgeHalfHeight() - _flagHeight,
                height: _flagHeight,
                child: const Align(
                  alignment: Alignment.bottomCenter,
                  child: _YouFlag(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  double _badgeHalfHeight() {
    final rows = switch (type.frame) {
      MapNodeFrame.DIAMOND => 31,
      MapNodeFrame.SHIELD => 34,
      MapNodeFrame.ROUND => 26,
    };
    return rows * PixelSprites.mapUnit / 2;
  }

  Widget _token() {
    final badge = MapNodeBadge(
      type: type,
      selected: isSelected,
      locked: isLocked,
    );
    if (!isLocked) return badge;

    // a locked place is shut, and that is all the token says about it: the
    // padlock and the gate, no type glyph
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        badge,
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 16, color: _plateText),
            if (lockSkill != SkillId.NULL && lockLevel > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconRenderer<SkillId>(size: 12, id: lockSkill),
                  Text(
                    '$lockLevel',
                    style: const TextStyle(
                      fontFamily: HearthText.pixel,
                      fontSize: 11,
                      height: 1,
                      color: _plateText,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _label() {
    final selected = isSelected && !isLocked;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? PixelSprites.selectedRim : _plate,
        border: Border.all(color: PixelSprites.outline, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(5, 1, 5, 2),
        child: Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: HearthText.pixel,
            fontSize: 12,
            height: 1.15,
            color: selected
                ? const Color(0xFF1A1208)
                : _plateText.withValues(alpha: isLocked ? 0.55 : 1),
          ),
        ),
      ),
    );
  }
}

/// "You are here": a gold YOU tag with a pixel pointer, planted over the
/// token rather than drawn inside it, so where you are and what the place
/// is both stay readable.
class _YouFlag extends StatelessWidget {
  const _YouFlag();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: PixelSprites.gold,
            border: Border.all(color: PixelSprites.outline, width: 2),
          ),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Text(
              'YOU',
              style: TextStyle(
                fontFamily: HearthText.pixel,
                fontSize: 11,
                height: 1.2,
                color: Color(0xFF1A1208),
              ),
            ),
          ),
        ),
        const SizedBox(height: 1),
        PixelArt(PixelSprites.arrow, unit: 1.6),
      ],
    );
  }
}
