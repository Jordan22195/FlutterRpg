import 'package:flutter/material.dart';

import '../catalogs/zones/map_node_type.dart';
import '../data/skill_data.dart';
import 'icon_renderer.dart';

/// One place on the world map: a fixed-size circular token with its name
/// underneath.
///
/// Every token is the same size whatever the place is called, so "Goblin
/// Queen's Lair" takes up exactly as much map as "Forest" and the layout's
/// spacing means what it says. The name wraps below the token instead of
/// inflating it.
///
/// The token carries three things and no more: what kind of place this is
/// (the type glyph), whether it is shut to you (the padlock), and whether
/// you are standing in it (the ring and the pip). What a trip there *costs*
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

  /// Diameter of the circular token. Sized past the 44px touch-target floor
  /// the action bar works to, since a map is tapped at arm's length.
  static const double tokenSize = 48;

  /// Width of the whole slot: the token plus the room its label may wrap
  /// into. Wider than the token so a long name doesn't shove its neighbours.
  static const double slotWidth = 96;

  /// Height of the whole slot: token, gap, and two lines of label.
  static const double slotHeight = 92;

  /// Distance from the top of the slot to the token's centre, so callers can
  /// position a slot by the centre the layout data gives them.
  static const double tokenCenterY = 26;

  static const double _pipSize = 7;

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
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: slotWidth,
      height: slotHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: tokenCenterY + tokenSize / 2,
              width: tokenSize + _pipSize,
              child: Center(child: _token(scheme)),
            ),
            const SizedBox(height: 4),
            if (showLabel) Expanded(child: _label(context, scheme)),
          ],
        ),
      ),
    );
  }

  Widget _token(ColorScheme scheme) {
    // a locked place is shut, and that is all the token says about it: no
    // type glyph, because you haven't been told what's in there yet
    final border = isCurrent
        ? BorderSide(color: scheme.primary, width: 2)
        : isSelected
        ? BorderSide(color: scheme.onSurface.withValues(alpha: 0.7), width: 2)
        : BorderSide(color: scheme.outline, width: 1);

    final circle = Container(
      width: tokenSize,
      height: tokenSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: Border.fromBorderSide(border),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.35),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isLocked ? _lockedFace(scheme) : _typeFace(scheme),
    );

    if (!isCurrent) return circle;

    // "you are here": a pip on the token's bottom rim, half outside the
    // circle so it reads as a marker planted on the place rather than as
    // another glyph inside it
    return SizedBox(
      width: tokenSize + _pipSize,
      height: tokenSize + _pipSize,
      child: Stack(
        alignment: Alignment.topCenter,
        // the ring's glow spills past the pip's box, and a Stack clips to
        // its bounds by default — which turned the halo into a grey square
        clipBehavior: Clip.none,
        children: [
          Positioned(top: 0, child: circle),
          Positioned(
            top: tokenSize - _pipSize / 2,
            child: Container(
              width: _pipSize,
              height: _pipSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeFace(ColorScheme scheme) {
    return Center(child: Icon(type.glyph, size: 22, color: scheme.onSurface));
  }

  Widget _lockedFace(ColorScheme scheme) {
    return Opacity(
      opacity: 0.55,
      child: CustomPaint(
        painter: _HatchPainter(color: scheme.outline.withValues(alpha: 0.5)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock, size: 18, color: scheme.onSurface),
              if (lockSkill != SkillId.NULL && lockLevel > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconRenderer<SkillId>(size: 12, id: lockSkill),
                    Text(
                      '$lockLevel',
                      style: TextStyle(
                        fontSize: 10,
                        height: 1,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(BuildContext context, ColorScheme scheme) {
    // map art and edges run behind these, so the name carries its own halo
    // in the background colour rather than sitting on a hard plate
    final glow = [
      Shadow(blurRadius: 3, color: scheme.surface),
      Shadow(blurRadius: 6, color: scheme.surface),
      Shadow(blurRadius: 9, color: scheme.surface),
    ];

    return Text(
      name,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: scheme.onSurface.withValues(alpha: isLocked ? 0.5 : 0.9),
        height: 1.15,
        shadows: glow,
      ),
    );
  }
}

/// Diagonal hatching across a locked token's face.
class _HatchPainter extends CustomPainter {
  const _HatchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipPath(Path()..addOval(Offset.zero & size));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_HatchPainter oldDelegate) => oldDelegate.color != color;
}
