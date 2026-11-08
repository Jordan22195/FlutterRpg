import 'package:flutter/material.dart';

/// The colours a zone sets: its backgrounds, text and its accent. Every
/// screen inside a zone (exploring, combat, crafting stations) draws with
/// that zone's palette, read through `context.palette`.
///
/// [accent] belongs to the primary action button and nothing else.
@immutable
class ZonePalette extends ThemeExtension<ZonePalette> {
  const ZonePalette({
    required this.bg,
    required this.surface,
    required this.surfaceSunken,
    required this.raised,
    required this.track,
    required this.border,
    required this.borderStrong,
    required this.borderOverArt,
    required this.divider,
    required this.text,
    required this.textMuted,
    required this.textSubtitle,
    required this.textNavInactive,
    required this.chevron,
    required this.accent,
    required this.onAccent,
    required this.accentLip,
    required this.titleShadow,
    required this.gatherTintFill,
    required this.gatherTintBorder,
  });

  /// Screen and dock background.
  final Color bg;

  /// Cards, list rows, ring fill, Stop / Eat buttons.
  final Color surface;

  /// Tab bar and segmented-control container.
  final Color surfaceSunken;

  /// Selected tab or segment, active nav pill.
  final Color raised;

  /// Empty progress-bar track.
  final Color track;

  /// 1px card borders.
  final Color border;

  /// Chip / Stop / Eat borders, ring track, dashed empty state.
  final Color borderStrong;

  /// Borders on chips and buttons laid over the zone art.
  final Color borderOverArt;

  /// Dock and nav top borders, collapsed header bottom edge.
  final Color divider;

  final Color text;
  final Color textMuted;

  /// Subtitle under a title on the art strip.
  final Color textSubtitle;
  final Color textNavInactive;

  /// Row chevrons and the recipe arrow.
  final Color chevron;

  /// The primary action button's fill — used nowhere else.
  final Color accent;

  /// Icon and text on the primary button.
  final Color onAccent;

  /// The 4px lip under the primary button.
  final Color accentLip;

  /// Drop shadow under the Pixelify titles.
  final Color titleShadow;

  /// Sprite-frame tint for gathering spots (ponds, rivers), which follows
  /// the zone; the other frame tints are fixed in `GameColors`.
  final Color gatherTintFill;
  final Color gatherTintBorder;

  /// Southglen Meadow: accent is the grass green in the meadow art.
  static const meadow = ZonePalette(
    bg: Color(0xFF15130F),
    surface: Color(0xFF211C16),
    surfaceSunken: Color(0xFF1D1914),
    raised: Color(0xFF342C22),
    track: Color(0xFF2D261D),
    border: Color(0xFF2F281F),
    borderStrong: Color(0xFF3A3226),
    borderOverArt: Color(0xFF4A3F30),
    divider: Color(0xFF2A241C),
    text: Color(0xFFF2EADB),
    textMuted: Color(0xFFB0A38C),
    textSubtitle: Color(0xFFC9BDA6),
    textNavInactive: Color(0xFFA0937C),
    chevron: Color(0xFF8F836E),
    accent: Color(0xFF9BCB4F),
    onAccent: Color(0xFF16200A),
    accentLip: Color(0xFF6A9133),
    titleShadow: Color(0xFF0B0A08),
    gatherTintFill: Color(0xFF1A241D),
    gatherTintBorder: Color(0xFF2E4233),
  );

  /// Southwood Forest: the art's deep blue-greens in the shade, the
  /// sunlight on the path as the accent.
  static const forest = ZonePalette(
    bg: Color(0xFF0B130F),
    surface: Color(0xFF13211A),
    surfaceSunken: Color(0xFF0F1A14),
    raised: Color(0xFF1F3427),
    track: Color(0xFF1A2B21),
    border: Color(0xFF1C2E23),
    borderStrong: Color(0xFF2A4333),
    borderOverArt: Color(0xFF3A5340),
    divider: Color(0xFF182A20),
    text: Color(0xFFEBF0DC),
    textMuted: Color(0xFFA3B59B),
    // ~38% of the way from textMuted to text
    textSubtitle: Color(0xFFC1CCB3),
    textNavInactive: Color(0xFF93A58B),
    chevron: Color(0xFF7A8D74),
    accent: Color(0xFFD6DE5C),
    onAccent: Color(0xFF1A1E06),
    accentLip: Color(0xFF959C33),
    titleShadow: Color(0xFF050A07),
    gatherTintFill: Color(0xFF12261C),
    gatherTintBorder: Color(0xFF284637),
  );

  /// Blackmire Swamp: the misty teal-greens of the water and moss, the
  /// glowing orange mushrooms as the accent.
  static const swamp = ZonePalette(
    bg: Color(0xFF0A1514),
    surface: Color(0xFF122321),
    surfaceSunken: Color(0xFF0E1B1A),
    raised: Color(0xFF1E3733),
    track: Color(0xFF1A2E2B),
    border: Color(0xFF1C312D),
    borderStrong: Color(0xFF2B4A44),
    borderOverArt: Color(0xFF3C5F57),
    divider: Color(0xFF172A27),
    text: Color(0xFFE4F2EC),
    textMuted: Color(0xFF9BB9AE),
    // ~38% of the way from textMuted to text
    textSubtitle: Color(0xFFBBD4CA),
    textNavInactive: Color(0xFF8BA99E),
    chevron: Color(0xFF739388),
    accent: Color(0xFFF0A24A),
    onAccent: Color(0xFF2A1604),
    accentLip: Color(0xFFA9692A),
    titleShadow: Color(0xFF050B0A),
    gatherTintFill: Color(0xFF11282A),
    gatherTintBorder: Color(0xFF2A4D4C),
  );

  /// Darkwood Forest: the art's midnight blues and cold teals, the moon
  /// glowing through the canopy as the accent.
  static const darkwood = ZonePalette(
    bg: Color(0xFF060D14),
    surface: Color(0xFF0D1A24),
    surfaceSunken: Color(0xFF09141C),
    raised: Color(0xFF16293A),
    track: Color(0xFF122231),
    border: Color(0xFF14283A),
    borderStrong: Color(0xFF1F3B4F),
    borderOverArt: Color(0xFF2C5163),
    divider: Color(0xFF102130),
    text: Color(0xFFE0EEF0),
    textMuted: Color(0xFF93AFB8),
    // ~38% of the way from textMuted to text
    textSubtitle: Color(0xFFB4CCD2),
    textNavInactive: Color(0xFF82A0AA),
    chevron: Color(0xFF6A8994),
    accent: Color(0xFF9DE6CF),
    onAccent: Color(0xFF062119),
    accentLip: Color(0xFF4F9A85),
    titleShadow: Color(0xFF020609),
    gatherTintFill: Color(0xFF0C2229),
    gatherTintBorder: Color(0xFF1F4A52),
  );

  @override
  ZonePalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceSunken,
    Color? raised,
    Color? track,
    Color? border,
    Color? borderStrong,
    Color? borderOverArt,
    Color? divider,
    Color? text,
    Color? textMuted,
    Color? textSubtitle,
    Color? textNavInactive,
    Color? chevron,
    Color? accent,
    Color? onAccent,
    Color? accentLip,
    Color? titleShadow,
    Color? gatherTintFill,
    Color? gatherTintBorder,
  }) {
    return ZonePalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      raised: raised ?? this.raised,
      track: track ?? this.track,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      borderOverArt: borderOverArt ?? this.borderOverArt,
      divider: divider ?? this.divider,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      textSubtitle: textSubtitle ?? this.textSubtitle,
      textNavInactive: textNavInactive ?? this.textNavInactive,
      chevron: chevron ?? this.chevron,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      accentLip: accentLip ?? this.accentLip,
      titleShadow: titleShadow ?? this.titleShadow,
      gatherTintFill: gatherTintFill ?? this.gatherTintFill,
      gatherTintBorder: gatherTintBorder ?? this.gatherTintBorder,
    );
  }

  /// Blends every token, so moving between zones crossfades the palette.
  @override
  ZonePalette lerp(ThemeExtension<ZonePalette>? other, double t) {
    if (other is! ZonePalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ZonePalette(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      raised: l(raised, other.raised),
      track: l(track, other.track),
      border: l(border, other.border),
      borderStrong: l(borderStrong, other.borderStrong),
      borderOverArt: l(borderOverArt, other.borderOverArt),
      divider: l(divider, other.divider),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textSubtitle: l(textSubtitle, other.textSubtitle),
      textNavInactive: l(textNavInactive, other.textNavInactive),
      chevron: l(chevron, other.chevron),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentLip: l(accentLip, other.accentLip),
      titleShadow: l(titleShadow, other.titleShadow),
      gatherTintFill: l(gatherTintFill, other.gatherTintFill),
      gatherTintBorder: l(gatherTintBorder, other.gatherTintBorder),
    );
  }
}
