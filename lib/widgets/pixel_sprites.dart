import 'dart:collection';

import 'package:flutter/material.dart';

import '../catalogs/zones/map_node_type.dart';

/// A small pixel image: [width] x [height] cells, each a colour or empty.
///
/// The map's tokens are drawn from these rather than from image assets, so a
/// type's colour, a selected rim or a locked face is a change of palette
/// rather than another file to draw and keep in step.
@immutable
class PixelGrid {
  const PixelGrid(this.width, this.height, this.cells);

  /// One string per row, one character per cell; characters missing from
  /// [palette] (conventionally '.') are empty.
  factory PixelGrid.fromRows(List<String> rows, Map<String, Color> palette) {
    final width = rows.fold<int>(0, (w, r) => r.length > w ? r.length : w);
    final cells = <Color?>[];
    for (final row in rows) {
      for (var x = 0; x < width; x++) {
        cells.add(x < row.length ? palette[row[x]] : null);
      }
    }
    return PixelGrid(width, rows.length, List.unmodifiable(cells));
  }

  final int width;
  final int height;
  final List<Color?> cells;

  Color? at(int x, int y) => cells[y * width + x];
}

/// Paints a [PixelGrid] at [unit] logical pixels per cell, hard-edged.
class PixelGridPainter extends CustomPainter {
  const PixelGridPainter(this.grid, this.unit);

  final PixelGrid grid;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    for (var y = 0; y < grid.height; y++) {
      var x = 0;
      while (x < grid.width) {
        final c = grid.at(x, y);
        if (c == null) {
          x++;
          continue;
        }
        // one rect per run of a colour, not per cell
        var end = x;
        while (end + 1 < grid.width && grid.at(end + 1, y) == c) {
          end++;
        }
        paint.color = c;
        canvas.drawRect(
          Rect.fromLTRB(x * unit, y * unit, (end + 1) * unit, (y + 1) * unit),
          paint,
        );
        x = end + 1;
      }
    }
  }

  @override
  bool shouldRepaint(PixelGridPainter oldDelegate) =>
      !identical(oldDelegate.grid, grid) || oldDelegate.unit != unit;
}

/// A [PixelGrid] as a widget. [trimBottom] rows are painted but left out of
/// the widget's size, so a drop shadow spills below the box instead of
/// pushing its centre off the shape's.
class PixelArt extends StatelessWidget {
  const PixelArt(
    this.grid, {
    super.key,
    required this.unit,
    this.trimBottom = 0,
    this.semanticLabel,
  });

  final PixelGrid grid;
  final double unit;
  final int trimBottom;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final art = CustomPaint(
      size: Size(grid.width * unit, (grid.height - trimBottom) * unit),
      painter: PixelGridPainter(grid, unit),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: art);
    return Semantics(label: semanticLabel, image: true, child: art);
  }
}

/// The map token for a node type, cut to its frame, as one widget.
///
/// Sized to the shape itself (not its pad or shadow), so centring this
/// widget centres the shape.
class MapNodeBadge extends StatelessWidget {
  const MapNodeBadge({
    super.key,
    required this.type,
    this.selected = false,
    this.locked = false,
    this.unit = PixelSprites.mapUnit,
  });

  final MapNodeType type;
  final bool selected;
  final bool locked;
  final double unit;

  @override
  Widget build(BuildContext context) {
    final grid = PixelSprites.badge(type, selected: selected, locked: locked);
    const pad = PixelSprites.pad;
    // the grid carries [pad] cells all round plus the shadow rows; the
    // widget keeps only the shape and lets the rest paint outside it
    return SizedBox(
      width: (grid.width - pad * 2) * unit,
      height: (grid.height - pad * 2 - PixelSprites.shadowRows) * unit,
      child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: Transform.translate(
          offset: Offset(-pad * unit, -pad * unit),
          child: PixelArt(grid, unit: unit),
        ),
      ),
    );
  }
}

/// The pixel art the map draws: node tokens and the small glyphs that go
/// with them. Grids are built once per look and cached.
abstract final class PixelSprites {
  /// Logical pixels per art pixel on the map canvas.
  static const double mapUnit = 1.6;

  /// Empty cells kept round a token's shape, for the selected halo.
  static const int pad = 2;

  /// Rows below the shape the drop shadow takes.
  static const int shadowRows = 2;

  static const Color outline = Color(0xFF0A0806);
  static const Color parchment = Color(0xFFF3E6C4);
  static const Color parchmentShade = Color(0xFFB8A47C);
  static const Color gold = Color(0xFFF0C04A);
  static const Color wood = Color(0xFF7A4A26);
  static const Color woodDark = Color(0xFF4A2C16);
  static const Color faceLight = Color(0xFF3A2D22);
  static const Color faceDark = Color(0xFF211913);
  static const Color selectedRim = Color(0xFFFFF6DC);
  static const Color lockedRim = Color(0xFF6B5D4D);
  static const Color lockedShade = Color(0xFF3A3128);

  static final Map<(MapNodeType, bool, bool), PixelGrid> _badges = {};
  static final Map<MapNodeType, PixelGrid> _glyphs = {};

  /// The token for [type], drawn for its map group.
  static PixelGrid badge(
    MapNodeType type, {
    bool selected = false,
    bool locked = false,
  }) {
    final group = type.group;
    return _badges.putIfAbsent(
      (group, selected, locked),
      () => _buildBadge(group, selected: selected, locked: locked),
    );
  }

  /// The 12x12 type glyph alone, for the filter rail and small chips.
  static PixelGrid glyph(MapNodeType type) =>
      _glyphs.putIfAbsent(type.group, () => _icon(type.group));

  /// A downward pointer, for the "you are here" flag.
  static final PixelGrid arrow = PixelGrid.fromRows(
    const ['xxxxxxxxx', '.xyyyyyx.', '..xyyyx..', '...xyx...', '....x....'],
    const {'x': outline, 'y': gold},
  );

  static (int, int, bool Function(int, int)) _shape(MapNodeFrame frame) {
    switch (frame) {
      case MapNodeFrame.DIAMOND:
        return (31, 31, (x, y) => (x - 15).abs() + (y - 15).abs() <= 15);
      case MapNodeFrame.SHIELD:
        return (
          32,
          34,
          (x, y) {
            final dx = (x - 15.5).abs();
            // nicked top corners, straight sides, then the taper to a point
            if (y < 2 && dx > 13.5 - (2 - y)) return false;
            if (y < 21) return dx <= 15.5;
            return dx <= 15.5 - (y - 20) * 15.5 / 13.5;
          },
        );
      case MapNodeFrame.ROUND:
        return (
          26,
          26,
          (x, y) {
            final dx = x - 12.5, dy = y - 12.5;
            return dx * dx + dy * dy <= 12.9 * 12.9;
          },
        );
    }
  }

  static PixelGrid _buildBadge(
    MapNodeType type, {
    required bool selected,
    required bool locked,
  }) {
    final (w, h, inShape) = _shape(type.frame);
    bool inside(int x, int y) => x >= 0 && y >= 0 && x < w && y < h && inShape(x, y);

    // distance in from the edge: 0 is the outline, 1 the rim, 2 the shade
    // band, the rest is the face
    final depth = List.generate(h, (_) => List.filled(w, 1 << 20));
    final queue = Queue<(int, int)>();
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (!inside(x, y)) continue;
        if (!inside(x + 1, y) ||
            !inside(x - 1, y) ||
            !inside(x, y + 1) ||
            !inside(x, y - 1)) {
          depth[y][x] = 0;
          queue.add((x, y));
        }
      }
    }
    const steps = [
      (1, 0), (-1, 0), (0, 1), (0, -1),
      (1, 1), (1, -1), (-1, 1), (-1, -1),
    ];
    while (queue.isNotEmpty) {
      final (x, y) = queue.removeFirst();
      for (final (dx, dy) in steps) {
        final nx = x + dx, ny = y + dy;
        if (inside(nx, ny) && depth[ny][nx] > depth[y][x] + 1) {
          depth[ny][nx] = depth[y][x] + 1;
          queue.add((nx, ny));
        }
      }
    }

    final gw = w + pad * 2;
    final gh = h + pad * 2 + shadowRows;
    final cells = List<Color?>.filled(gw * gh, null);
    void put(int x, int y, Color c) {
      if (x >= 0 && y >= 0 && x < gw && y < gh) cells[y * gw + x] = c;
    }

    // drop shadow first, so the shape paints over all but its lower edge
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (inside(x, y)) put(x + pad, y + pad + shadowRows, const Color(0x66000000));
      }
    }

    // a selected token wears a one-pixel halo in its type's colour
    if (selected && !locked) {
      for (var y = -1; y <= h; y++) {
        for (var x = -1; x <= w; x++) {
          if (inside(x, y)) continue;
          if (inside(x + 1, y) ||
              inside(x - 1, y) ||
              inside(x, y + 1) ||
              inside(x, y - 1)) {
            put(x + pad, y + pad, type.color);
          }
        }
      }
    }

    final rim = locked
        ? lockedRim
        : selected
        ? selectedRim
        : type.color;
    final shade = locked
        ? lockedShade
        : selected
        ? type.color
        : type.shade;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (!inside(x, y)) continue;
        final d = depth[y][x];
        final c = switch (d) {
          0 => outline,
          1 => rim,
          2 => shade,
          _ => (x + y) < (w + h) / 2 - 2 ? faceLight : faceDark,
        };
        put(x + pad, y + pad, c);
      }
    }

    // a locked place shows no type glyph: you haven't been told what's in
    // there yet. The token's padlock is drawn over it as a widget.
    if (!locked) {
      final icon = _icon(type);
      final ox = pad + (w - 12) ~/ 2;
      final oy = pad + (h - 12) ~/ 2 - (type.frame == MapNodeFrame.SHIELD ? 2 : 0);
      for (var y = 0; y < 12; y++) {
        for (var x = 0; x < 12; x++) {
          final c = icon.at(x, y);
          if (c != null) put(ox + x, oy + y, c);
        }
      }
    }

    return PixelGrid(gw, gh, List.unmodifiable(cells));
  }

  static PixelGrid _icon(MapNodeType type) {
    switch (type.group) {
      case MapNodeType.TOWN:
        return PixelGrid.fromRows(
          const [
            '.....aa.....',
            '....aaaa....',
            '...aaaaaa...',
            '..aaaaaaaa..',
            '.aaaaaaaaaa.',
            'aaaaaaaaaaaa',
            '.wwwwwwwwww.',
            '.wkkwwwwkkw.',
            '.wkkwwwwkkw.',
            '.wwwwbbwwww.',
            '.wwwwbbwwww.',
            '.wwwwbbwwww.',
          ],
          const {
            'a': gold,
            'w': parchment,
            'k': Color(0xFF3A2C20),
            'b': wood,
          },
        );
      case MapNodeType.SKILLING:
        // a pickaxe: haft from the bottom-left, head across the top-right
        final cells = List<Color?>.filled(144, null);
        void put(int x, int y, Color c) {
          if (x >= 0 && y >= 0 && x < 12 && y < 12) cells[y * 12 + x] = c;
        }
        for (var k = 1; k < 8; k++) {
          put(7 - k, 4 + k, wood);
          if (k < 7) put(8 - k, 4 + k, woodDark);
        }
        for (var t = -4; t <= 4; t++) {
          put(7 + t, 4 + t, parchment);
          if (t.abs() <= 3) put(8 + t, 3 + t, parchmentShade);
        }
        put(2, 1, parchment);
        put(10, 9, parchment);
        return PixelGrid(12, 12, List.unmodifiable(cells));
      default:
        // crossed swords: two blades from the top corners, guards and
        // grips below the cross
        final cells = List<Color?>.filled(144, null);
        void put(int x, int y, Color c) {
          if (x >= 0 && y >= 0 && x < 12 && y < 12) cells[y * 12 + x] = c;
        }
        for (final mirror in const [false, true]) {
          int f(int x) => mirror ? 11 - x : x;
          for (var i = 0; i < 9; i++) {
            put(f(i), i, parchment);
          }
          for (var i = 0; i < 8; i++) {
            put(f(i + 1), i, parchmentShade);
          }
          for (final (x, y) in const [(7, 11), (8, 10), (9, 9), (10, 8), (11, 7)]) {
            put(f(x), y, gold);
          }
          put(f(10), 10, wood);
          put(f(11), 11, gold);
        }
        return PixelGrid(12, 12, List.unmodifiable(cells));
    }
  }
}
