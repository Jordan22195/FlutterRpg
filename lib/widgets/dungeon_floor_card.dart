import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/game_colors.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import 'empty_state.dart';
import 'place_tile.dart';
import 'primary_button.dart';

/// Where a floor stands, which decides its rail node and its card's look.
enum FloorStanding {
  /// Cleared at least once; open for good.
  cleared,

  /// The floor the list is about: the one running, or the next to clear.
  current,

  /// Open, but neither cleared nor current — a floor beside the critical
  /// path.
  open,

  /// Shut until something else is done.
  locked,
}

/// One floor of a dungeon's list. Collapsed it is a single 64pt row — its
/// number, name and a status pill, with a chevron that opens it. Open it is
/// a card holding the floor's creatures as a 3-column grid of [tiles], its
/// [boss] as a wide row beneath them and an [action] button at the foot.
///
/// A [lockReason] blurs the grid and the boss past reading, with the lock
/// and the reason laid over them, and shuts them to taps: what a sealed
/// floor holds stays hidden until it opens.
class DungeonFloorCard extends StatelessWidget {
  const DungeonFloorCard({
    super.key,
    required this.label,
    required this.title,
    required this.standing,
    required this.expanded,
    required this.tiles,
    this.boss,
    this.pill,
    this.lockReason,
    this.stats,
    this.note,
    this.action,
    this.onToggle,
    this.active = false,
  });

  /// The small caps line over the title, e.g. "FLOOR 2 · 7 + BOSS". Pass it
  /// in plain case; it is uppercased here.
  final String label;
  final String title;
  final FloorStanding standing;

  /// Open as a card, or collapsed to a row.
  final bool expanded;

  /// The floor's creatures in queue order, boss excluded.
  final List<Widget> tiles;

  /// The floor's boss, drawn as a row under the grid.
  final Widget? boss;

  /// The status on the right of the title, e.g. "Cleared".
  final Widget? pill;

  /// Why the floor can't be entered, or null when it can.
  final String? lockReason;

  /// A tally line under the title — how much of this floor has been done.
  final String? stats;

  /// Anything else the floor has to say, e.g. the key it is about to charge.
  final Widget? note;

  /// At the foot of the open card, e.g. the button that enters the floor.
  final Widget? action;

  /// Opens or closes the card. Null leaves it as it is — the current floor
  /// always stays open.
  final VoidCallback? onToggle;

  /// The action running right now is this floor's: the card is ringed in
  /// the accent and a thin bar along its foot fills with each action.
  final bool active;

  static const double collapsedHeight = 64;
  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    return expanded ? _card(context) : _row(context);
  }

  // ---- collapsed ----

  Widget _row(BuildContext context) {
    final palette = context.palette;
    final locked = standing == FloorStanding.locked;
    final radius = BorderRadius.circular(_radius);

    Widget row = SizedBox(
      height: collapsedHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(child: _heading(context, titleSize: 16)),
            if (pill != null) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: pill!,
              ),
            ],
            const SizedBox(width: 8),
            Icon(Icons.expand_more, size: 20, color: palette.chevron),
          ],
        ),
      ),
    );

    row = Material(
      color: locked
          ? Color.lerp(palette.bg, palette.surfaceSunken, 0.6)
          : palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: locked ? BorderSide.none : BorderSide(color: palette.border),
      ),
      child: InkWell(onTap: onToggle, borderRadius: radius, child: row),
    );

    if (locked) {
      // a sealed floor's outline is dashed, as an empty slot's is
      row = CustomPaint(
        foregroundPainter: DashedBorderPainter(
          color: palette.borderStrong,
          radius: _radius,
        ),
        child: row,
      );
    }

    return Semantics(
      expanded: false,
      button: onToggle != null,
      hint: 'Show enemies',
      child: row,
    );
  }

  // ---- open ----

  Widget _card(BuildContext context) {
    final palette = context.palette;
    final current = standing == FloorStanding.current;
    final locked = lockReason != null;

    final Color fill;
    final Color border;
    if (current) {
      // a breath of the accent, so the floor in hand reads first
      fill = Color.alphaBlend(
        palette.accent.withValues(alpha: 0.025),
        palette.surface,
      );
      border = Color.alphaBlend(
        palette.accent.withValues(alpha: 0.28),
        palette.surface,
      );
    } else if (locked) {
      fill = Color.lerp(palette.bg, palette.surfaceSunken, 0.6)!;
      border = palette.borderStrong;
    } else {
      fill = palette.surface;
      border = palette.border;
    }

    Widget contents = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tiles.isNotEmpty) PlaceGrid(tiles: tiles),
        if (tiles.isNotEmpty && boss != null)
          const SizedBox(height: PlaceGrid.gap),
        if (boss != null) boss!,
      ],
    );
    if (locked) {
      // sealed: blurred past reading and shut to taps, as an undiscovered
      // tile is, with why it is shut laid over it
      contents = Stack(
        children: [
          IgnorePointer(
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: contents,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: Center(child: _LockBadge(reason: lockReason!)),
            ),
          ),
        ],
      );
    }

    final header = SizedBox(
      height: 40,
      child: Row(
        children: [
          Expanded(child: _heading(context, titleSize: 17)),
          if (pill != null) ...[
            const SizedBox(width: 8),
            Flexible(child: pill!),
          ],
          if (onToggle != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_less, size: 20, color: palette.chevron),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(_radius),
        border: active
            ? Border.all(color: palette.accent, width: 2)
            : Border.all(color: border),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(active ? 11 : 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  expanded: true,
                  button: onToggle != null,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onToggle,
                    child: header,
                  ),
                ),
                if (stats != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    stats!,
                    overflow: TextOverflow.ellipsis,
                    style: HearthText.rowMeta.copyWith(
                      fontSize: 12,
                      color: palette.textMuted,
                    ),
                  ),
                ],
                if (note != null) ...[const SizedBox(height: 6), note!],
                const SizedBox(height: 10),
                contents,
                if (action != null) ...[const SizedBox(height: 12), action!],
              ],
            ),
          ),
          // in the card's own padding, so starting a floor doesn't grow the
          // card and shift the list under the player's thumb
          if (active)
            const Positioned(
              left: 18,
              right: 18,
              bottom: 3,
              child: ActiveProgressBar(key: ValueKey('queue-card-progress')),
            ),
        ],
      ),
    );
  }

  Widget _heading(BuildContext context, {required double titleSize}) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HearthText.sectionLabel.copyWith(
            fontSize: 11,
            letterSpacing: 11 * 0.12,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: HearthText.rowTitle.copyWith(
            fontSize: titleSize,
            height: 1.1,
            color: standing == FloorStanding.locked
                ? palette.textSubtitle
                : palette.text,
          ),
        ),
      ],
    );
  }
}

/// A floor's 26pt status pill: "Cleared", "Up next · 65 kills", or what a
/// sealed floor waits on.
class FloorPill extends StatelessWidget {
  const FloorPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fill,
    this.border,
  });

  final String label;

  /// The text and icon colour.
  final Color color;
  final IconData? icon;
  final Color? fill;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 9),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(13),
        border: border == null ? null : Border.all(color: border!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: HearthText.rowMeta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// "Cleared", in the cleared green.
  static Widget cleared() => const FloorPill(
    label: 'Cleared',
    icon: Icons.check,
    color: GameColors.clearedColor,
    fill: Color(0x247FC08A),
  );
}

/// A floor's node on the rail down the left of the list: a check once
/// cleared, the accent dot on the current floor, a lock while sealed.
class FloorRailNode extends StatelessWidget {
  const FloorRailNode({super.key, required this.standing});

  final FloorStanding standing;

  static const double size = 24;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (Color ring, Color fill, Widget? mark) = switch (standing) {
      FloorStanding.cleared => (
        GameColors.clearedColor,
        GameColors.clearedFill,
        const Icon(Icons.check, size: 14, color: GameColors.clearedColor),
      ),
      FloorStanding.current => (
        palette.accent,
        palette.raised,
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: palette.accent,
            shape: BoxShape.circle,
          ),
        ),
      ),
      FloorStanding.open => (palette.borderStrong, palette.surface, null),
      FloorStanding.locked => (
        palette.borderStrong,
        palette.surfaceSunken,
        Icon(Icons.lock, size: 12, color: palette.chevron),
      ),
    };

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(color: ring, width: 2),
      ),
      child: mark,
    );
  }
}

/// The open floor's big accent button — the same raised face as the action
/// bar's primary button, so it reads as the thing that gets you fighting.
class FloorActionButton extends StatefulWidget {
  const FloorActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Widget? icon;
  final VoidCallback onPressed;

  static const double height = 56;

  @override
  State<FloorActionButton> createState() => _FloorActionButtonState();
}

class _FloorActionButtonState extends State<FloorActionButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onPressed,
        child: RaisedSurface(
          pressed: _pressed,
          height: FloorActionButton.height,
          depth: kActionBarLip,
          radius: 14,
          color: palette.accent,
          lipColor: palette.accentLip,
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 10),
              ],
              Text(
                widget.label,
                style: HearthText.rowTitle.copyWith(
                  fontWeight: FontWeight.w800,
                  color: palette.onAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The lock and the reason a floor is shut, on a wash that reads over the
/// blurred grid — the same badge an undiscovered tile wears.
class _LockBadge extends StatelessWidget {
  const _LockBadge({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: palette.bg.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.borderOverArt),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 18, color: palette.text),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              reason,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: HearthText.rowMeta.copyWith(
                fontSize: 13,
                color: palette.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The dungeon's full-clear chest at the foot of the floor list: earned
/// once a run by clearing every main floor, and claimed here. Earned chests
/// stack, so laps a dungeon loop ran while the player was away all wait
/// for the one claim.
class DungeonChestCard extends StatelessWidget {
  const DungeonChestCard({
    super.key,
    required this.title,
    required this.floorsCleared,
    required this.floorCount,
    required this.waiting,
    required this.earned,
    required this.onClaim,
  });

  /// E.g. "Wolf Den Chest".
  final String title;

  /// Main floors cleared this run, of [floorCount].
  final int floorsCleared;
  final int floorCount;

  /// Chests earned and not yet claimed.
  final int waiting;

  /// This run's chest has been earned, claimed or not — another needs a
  /// reset (or a dungeon loop coming back round).
  final bool earned;

  final VoidCallback onClaim;

  /// The collapsed height, which centres the rail node on the card.
  static const double height = 88;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ready = waiting > 0;
    final subtitle = ready
        ? (waiting == 1 ? 'Ready to open' : '$waiting chests ready to open')
        : earned
        ? 'Claimed · Reset to earn it again'
        : 'Clear all $floorCount floors in one run';

    return Semantics(
      container: true,
      label: 'Full-clear chest',
      child: Container(
        decoration: BoxDecoration(
          color: GameColors.chestFill,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GameColors.chestBorder),
        ),
        padding: const EdgeInsets.fromLTRB(12, 0, 14, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: height - 2,
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: GameColors.chestBoxFill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GameColors.chestBoxBorder),
                    ),
                    alignment: Alignment.center,
                    child: const CustomPaint(
                      size: Size.square(34),
                      painter: _ChestGlyph(color: GameColors.chestColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FULL CLEAR',
                          style: HearthText.sectionLabel.copyWith(
                            fontSize: 11,
                            letterSpacing: 11 * 0.12,
                            color: palette.textMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HearthText.rowTitle.copyWith(
                            height: 1.1,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: HearthText.rowMeta.copyWith(
                            fontSize: 12,
                            color: palette.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ready
                      ? FloorPill(
                          label: '×$waiting',
                          color: palette.onAccent,
                          fill: GameColors.chestColor,
                        )
                      : earned
                      ? FloorPill(
                          label: '$floorCount / $floorCount',
                          icon: Icons.check,
                          color: GameColors.chestColor,
                          border: GameColors.chestBorder,
                        )
                      : FloorPill(
                          label: '$floorsCleared / $floorCount',
                          color: GameColors.chestColor,
                          border: GameColors.chestBorder,
                        ),
                ],
              ),
            ),
            if (ready) ...[
              FloorActionButton(
                label: waiting == 1 ? 'Claim chest' : 'Claim $waiting chests',
                onPressed: onClaim,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }
}

/// The chest's node on the rail: a gold star.
class ChestRailNode extends StatelessWidget {
  const ChestRailNode({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: FloorRailNode.size,
      height: FloorRailNode.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.palette.surfaceSunken,
        shape: BoxShape.circle,
        border: Border.all(color: GameColors.chestBoxBorder, width: 2),
      ),
      child: const Icon(
        Icons.star_border_rounded,
        size: 14,
        color: GameColors.chestColor,
      ),
    );
  }
}

/// A chest in outline: domed lid, band, and lock plate.
class _ChestGlyph extends CustomPainter {
  const _ChestGlyph({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // drawn on a 24-unit grid, scaled to the box
    canvas.scale(size.width / 24, size.height / 24);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final body = Path()
      ..moveTo(3, 10)
      ..arcToPoint(const Offset(8, 5), radius: const Radius.circular(5))
      ..lineTo(16, 5)
      ..arcToPoint(const Offset(21, 10), radius: const Radius.circular(5))
      ..lineTo(21, 19)
      ..lineTo(3, 19)
      ..close()
      ..moveTo(3, 11)
      ..lineTo(21, 11)
      ..moveTo(10, 11)
      ..lineTo(10, 14)
      ..lineTo(14, 14)
      ..lineTo(14, 11);
    canvas.drawPath(body, paint);
  }

  @override
  bool shouldRepaint(_ChestGlyph old) => old.color != color;
}

/// Reset beside the loop selector: a 44pt key on the card surface.
class DungeonResetButton extends StatelessWidget {
  const DungeonResetButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: 'Reset run to Floor 1',
      excludeSemantics: true,
      onTap: onPressed,
      child: Material(
        color: palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: palette.borderStrong),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 88,
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restart_alt, size: 16, color: palette.textMuted),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Reset',
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: HearthText.rowMeta.copyWith(
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
