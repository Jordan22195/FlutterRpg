import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../catalogs/items/items.dart';
import '../data/chest_loot.dart';
import '../theme/hearth_text.dart';
import '../theme/hearth_theme.dart';
import '../theme/zone_palette.dart';
import 'item_stack_tile.dart';
import 'loot_pop.dart';
import 'primary_button.dart';
import 'segmented_tabs.dart';

/// Opens up to [max] waiting chests (all when null), returning what came out.
typedef OpenChests = List<ChestLoot> Function({int? max});

/// The chest dialog: pick one or all, watch the pixel chest shake and burst,
/// then see the haul laid out as tiles. Waiting chests are opened through
/// [open], and [remaining] reads how many are left afterwards.
class ChestLootDialog extends StatefulWidget {
  const ChestLootDialog({
    super.key,
    required this.title,
    required this.remaining,
    required this.open,
  });

  /// "Wolf Den Chest" — the dungeon's name for what it is opening.
  final String title;

  /// Chests still waiting to be opened.
  final int Function() remaining;
  final OpenChests open;

  /// How long the shake-and-burst runs before the results show.
  static const Duration openingTime = Duration(milliseconds: 1800);

  @override
  State<ChestLootDialog> createState() => _ChestLootDialogState();
}

enum _View { select, opening, results }

// the chest's own browns and golds; they belong to the art, not the zone
const Color _gold = Color(0xFFE8C766);
const Color _ink = Color(0xFF2A1A0C);
const Color _flashColor = Color(0xFFFFF3C4);

class _ChestLootDialogState extends State<ChestLootDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _opening =
      AnimationController(vsync: this, duration: ChestLootDialog.openingTime)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _show();
        });

  _View _view = _View.select;
  bool _all = false;

  /// How many chests the sitting's latest open took.
  int _openedNow = 0;

  /// The latest open's haul, merged by item, in the order it first came out.
  List<ChestLoot> _loot = const [];

  int get _waiting => widget.remaining();

  @override
  void dispose() {
    _opening.dispose();
    super.dispose();
  }

  void _start() {
    final before = _waiting;
    if (before <= 0) return;
    final loot = widget.open(max: _all ? null : 1);
    setState(() {
      _openedNow = before - _waiting;
      _loot = loot;
      _view = _View.opening;
    });
    if (MediaQuery.disableAnimationsOf(context)) {
      _show();
    } else {
      _opening.forward(from: 0);
    }
  }

  void _show() {
    if (!mounted || _view == _View.results) return;
    _opening.stop();
    setState(() => _view = _View.results);
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final Widget body = switch (_view) {
      _View.select => _select(context),
      _View.opening => _openingView(context),
      _View.results => _results(context),
    };
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: _ink,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 40,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: _gold,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: _ink,
              borderRadius: BorderRadius.circular(3),
            ),
            child: ColoredBox(
              color: palette.surface,
              child: Padding(padding: const EdgeInsets.all(20), child: body),
            ),
          ),
        ),
      ),
    );
  }

  TextStyle _pixel(double size, Color color) =>
      HearthText.title.copyWith(fontSize: size, height: 1.3, color: color);

  // ---- select ----

  Widget _select(BuildContext context) {
    final palette = context.palette;
    final waiting = _waiting;
    final n = _all ? waiting : math.min(1, waiting);
    final left = waiting - n;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: _pixel(22, _gold)),
                  const SizedBox(height: 8),
                  Text(
                    '$waiting unopened',
                    style: HearthText.rowMeta.copyWith(
                      color: palette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Close',
              onPressed: _close,
              icon: Icon(Icons.close_rounded, color: palette.text),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: Stack(
            alignment: Alignment.bottomCenter,
            clipBehavior: Clip.none,
            children: [
              if (_all && waiting > 1) ...[
                for (final side in const [-1.0, 1.0])
                  Align(
                    alignment: Alignment(side * 0.62, 1),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Opacity(opacity: 0.35, child: _chest(80)),
                    ),
                  ),
              ],
              _chest(112),
              Positioned(
                left: null,
                right: 40,
                bottom: 4,
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: palette.surfaceSunken,
                    border: Border.all(color: _gold, width: 2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text('×$n', style: _pixel(14, _gold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SegmentedTabs<bool>(
          segments: const [
            TabSegment(value: false, label: 'Open one'),
            TabSegment(value: true, label: 'Open all'),
          ],
          selected: _all,
          onChanged: (v) => setState(() => _all = v),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('$n', style: _pixel(30, palette.text)),
            const SizedBox(width: 10),
            Text(
              n == 1 ? 'CHEST' : 'CHESTS',
              style: HearthText.sectionLabel.copyWith(color: palette.textMuted),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _PressButton(
          onTap: waiting > 0 ? _start : null,
          color: palette.accent,
          lipColor: palette.accentLip,
          child: Text(
            waiting == 0
                ? 'No chests left'
                : 'Open $n ${n == 1 ? 'chest' : 'chests'}',
            style: _pixel(18, palette.onAccent),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          left <= 0 ? 'None left after opening' : '$left left after opening',
          textAlign: TextAlign.center,
          style: HearthText.rowMeta.copyWith(color: palette.textMuted),
        ),
      ],
    );
  }

  // ---- opening ----

  Widget _openingView(BuildContext context) {
    final palette = context.palette;
    final n = _openedNow;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300,
          child: AnimatedBuilder(
            animation: _opening,
            builder: (context, _) =>
                CustomPaint(painter: _OpeningPainter(_opening.value)),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Opening $n ${n == 1 ? 'chest' : 'chests'}',
          textAlign: TextAlign.center,
          style: _pixel(18, palette.text),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: _show,
            style: OutlinedButton.styleFrom(
              foregroundColor: palette.text,
              side: BorderSide(color: palette.border, width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Text(
              'Skip',
              style: HearthText.rowTitle.copyWith(fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  // ---- results ----

  Widget _results(BuildContext context) {
    final palette = context.palette;
    final n = _openedNow;
    final left = _waiting;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$n ${n == 1 ? 'CHEST' : 'CHESTS'} OPENED',
          textAlign: TextAlign.center,
          style: _pixel(20, _gold),
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.title} · $left left',
          textAlign: TextAlign.center,
          style: HearthText.rowMeta.copyWith(
            fontSize: 12,
            color: palette.textMuted,
          ),
        ),
        const SizedBox(height: 14),
        Flexible(
          child: SingleChildScrollView(
            child: _loot.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Empty this time.',
                      textAlign: TextAlign.center,
                      style: HearthText.rowMeta.copyWith(color: palette.text),
                    ),
                  )
                : Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 14,
                    children: [
                      for (var i = 0; i < _loot.length; i++)
                        LootPop(
                          order: i,
                          child: SizedBox(
                            width: 84,
                            child: _lootTile(_loot[i], i, palette),
                          ),
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            if (left > 0) ...[
              Expanded(
                child: _PressButton(
                  onTap: () => setState(() {
                    _all = false;
                    _view = _View.select;
                  }),
                  color: palette.surfaceSunken,
                  lipColor: palette.border,
                  child: Text(
                    'Open more',
                    style: HearthText.rowTitle.copyWith(
                      fontSize: 15,
                      color: palette.text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: _PressButton(
                onTap: _close,
                color: palette.accent,
                lipColor: palette.accentLip,
                child: Text('Done', style: _pixel(18, palette.onAccent)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// One item of the haul: its tile, name, rarity, and a count that races up
  /// from zero as the tile pops in.
  Widget _lootTile(ChestLoot stack, int order, ZonePalette palette) {
    final rarity = stack.rarity;
    final tone = rarityBorderColor(rarity) ?? palette.textMuted;
    final delay = LootPop.delayFor(order);
    final style = HearthText.rowMeta.copyWith(fontSize: 12, height: 1.15);
    return Column(
      children: [
        ItemStackTile(size: 64, id: stack.id, count: 1, quality: stack.rarity),
        const SizedBox(height: 6),
        Text(
          stack.id.definition.name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: style.copyWith(
            fontWeight: FontWeight.w700,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          (rarity == Rarity.COMMON ? 'Common' : rarity.label).toUpperCase(),
          style: style.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 10 * 0.08,
            color: tone,
          ),
        ),
        const SizedBox(height: 4),
        _CountUp(
          target: stack.count,
          delay: delay,
          style: _pixel(16, palette.text),
        ),
      ],
    );
  }

  Widget _chest(double width) => SizedBox(
    width: width,
    height: width * 14 / 16,
    child: CustomPaint(painter: _ChestPainter()),
  );
}

/// "×N" counting up from zero to [target] in a quick run, after [delay].
class _CountUp extends StatelessWidget {
  const _CountUp({
    required this.target,
    required this.delay,
    required this.style,
  });

  final int target;
  final Duration delay;
  final TextStyle style;

  /// How long the count takes once it starts.
  static const Duration run = Duration(milliseconds: 700);

  @override
  Widget build(BuildContext context) {
    final total = delay + run;
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: target),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
      builder: (context, n, _) => Text(
        '×${_grouped(n)}',
        style: style.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }

  static String _grouped(int n) => n.toString().replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => ',',
  );
}

/// A raised button with the action bar's travel; null [onTap] greys it.
class _PressButton extends StatefulWidget {
  const _PressButton({
    required this.onTap,
    required this.color,
    required this.lipColor,
    required this.child,
  });

  final VoidCallback? onTap;
  final Color color;
  final Color lipColor;
  final Widget child;

  @override
  State<_PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<_PressButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: RaisedSurface(
            pressed: _pressed,
            height: kActionBarButtonHeight,
            color: widget.color,
            lipColor: widget.lipColor,
            padding: EdgeInsets.zero,
            child: Center(child: widget.child),
          ),
        ),
      ),
    );
  }
}

// ---- pixel art ----

/// The chest on a 16×14 grid, lid closed: body, then lid on top. Rects are
/// (x, y, w, h, color).
const List<(int, int, int, int, Color)> _body = [
  (0, 6, 16, 8, _ink),
  (1, 7, 14, 6, Color(0xFF8B5A2B)),
  (1, 12, 14, 1, Color(0xFF6B4220)),
  (7, 7, 2, 6, _gold),
  (6, 8, 4, 3, _gold),
  (7, 9, 2, 1, _ink),
];

const List<(int, int, int, int, Color)> _lid = [
  (1, 0, 14, 1, _ink),
  (0, 1, 16, 5, _ink),
  (1, 1, 14, 4, Color(0xFF8B5A2B)),
  (1, 1, 14, 1, Color(0xFFA86E38)),
  (7, 1, 2, 4, _gold),
];

void _paintRects(
  Canvas canvas,
  List<(int, int, int, int, Color)> rects,
  double unit,
) {
  final paint = Paint()..isAntiAlias = false;
  for (final (x, y, w, h, c) in rects) {
    canvas.drawRect(
      Rect.fromLTWH(x * unit, y * unit, w * unit, h * unit),
      paint..color = c,
    );
  }
}

/// A closed chest filling its box.
class _ChestPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.width / 16;
    _paintRects(canvas, _body, unit);
    _paintRects(canvas, _lid, unit);
  }

  @override
  bool shouldRepaint(_ChestPainter old) => false;
}

/// The opening, a step at a time: the chest shakes, the lid flips, a white
/// flash and a ring of square sparks burst out. [t] is 0..1 over the run.
class _OpeningPainter extends CustomPainter {
  _OpeningPainter(this.t);

  final double t;

  // (percent, dx, dy): each offset holds until the next entry
  static const List<(double, double, double)> _shake = [
    (0, 0, 0),
    (9, -4, 0),
    (14, 4, 0),
    (19, -4, 0),
    (24, 5, -3),
    (29, -6, 0),
    (34, 6, -3),
    (39, -6, 0),
    (44, 0, 0),
  ];

  // where each spark ends up, 6 steps from the chest's middle
  static const List<(double, double)> _ends = [
    (99, -13),
    (101, 30),
    (73, 75),
    (8, 56),
    (-43, 67),
    (-105, 55),
    (-95, 0),
    (-121, -38),
    (-120, -88),
    (-51, -93),
    (-10, -121),
    (51, -132),
    (73, -79),
    (116, -54),
  ];

  static const List<Color> _sparkColors = [
    _gold,
    _flashColor,
    Color(0xFF9BCB4F),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final pct = t * 100;
    const unit = 8.0; // 128 × 112 chest
    final cx = size.width / 2;
    final origin = Offset(cx - 64, 116);

    var dx = 0.0, dy = 0.0;
    for (final (p, x, y) in _shake) {
      if (pct >= p) {
        dx = x;
        dy = y;
      }
    }
    final opened = pct >= 47;

    canvas.save();
    canvas.translate(origin.dx + dx, origin.dy + dy);
    if (opened) {
      canvas.drawRect(
        const Rect.fromLTWH(1 * unit, 5 * unit, 14 * unit, unit),
        Paint()
          ..isAntiAlias = false
          ..color = _flashColor,
      );
    }
    _paintRects(canvas, _body, unit);
    if (opened) {
      // the lid hinges at its bottom-left corner
      canvas.translate(0, 6 * unit);
      canvas.translate(-1, -2);
      canvas.rotate(-16 * math.pi / 180);
      canvas.translate(0, -6 * unit);
    }
    _paintRects(canvas, _lid, unit);
    canvas.restore();

    // sparks, in 6 steps between 47% and 80%, gone by 86%
    if (pct >= 47 && pct < 86) {
      final q = pct >= 80 ? 1.0 : (((pct - 47) / 33) * 6).floor() / 6;
      final paint = Paint()..isAntiAlias = false;
      final start = Offset(cx - 3, 166);
      for (var i = 0; i < _ends.length; i++) {
        final big = i % 3 == 0;
        final s = big ? 10.0 : 8.0;
        final at = start + Offset(_ends[i].$1 * q, _ends[i].$2 * q);
        final r = Rect.fromLTWH(at.dx, at.dy, s, s);
        canvas.drawRect(r.inflate(2), paint..color = _ink);
        canvas.drawRect(r, paint..color = _sparkColors[i % 3]);
      }
    }

    // flash over the whole stage
    double flash = 0;
    if (pct >= 46 && pct < 50) {
      flash = 0.9;
    } else if (pct >= 50 && pct < 54) {
      flash = 0.45;
    }
    if (flash > 0) {
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = _flashColor.withValues(alpha: flash),
      );
    }
  }

  @override
  bool shouldRepaint(_OpeningPainter old) => old.t != t;
}
