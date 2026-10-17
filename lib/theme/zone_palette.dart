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

  /// Southwood Forest: accent is the sunlight on the path in the forest art.
  static const forest = ZonePalette(
    bg: Color(0xFF0F130E),
    surface: Color(0xFF182016),
    surfaceSunken: Color(0xFF141B12),
    raised: Color(0xFF26311F),
    track: Color(0xFF222B1C),
    border: Color(0xFF232D1F),
    borderStrong: Color(0xFF33412C),
    borderOverArt: Color(0xFF3A4A32),
    divider: Color(0xFF1F281B),
    text: Color(0xFFECEFDD),
    textMuted: Color(0xFFA8B39A),
    // derived like the meadow's: ~38% of the way from textMuted to text
    textSubtitle: Color(0xFFC2CAB3),
    textNavInactive: Color(0xFF98A38A),
    chevron: Color(0xFF7F8A72),
    accent: Color(0xFFD6DE5C),
    onAccent: Color(0xFF1A1E06),
    accentLip: Color(0xFF959C33),
    titleShadow: Color(0xFF070906),
    gatherTintFill: Color(0xFF15231B),
    gatherTintBorder: Color(0xFF2A4033),
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
