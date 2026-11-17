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
    Color? scene,
  }) : _scene = scene;

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

  final Color? _scene;

  /// The art's own dominant mid-tone — the reeds and river in Reedwater,
  /// the grass in the meadow. Never drawn flat: it is washed into the
  /// surfaces below the art ([washed]) and glows behind creature sprites, so
  /// the list under a zone's picture still looks like that place. Falls back
  /// to [borderOverArt] for a palette that names none.
  Color get scene => _scene ?? borderOverArt;

  /// This palette with [scene] washed through its backgrounds, borders and
  /// tracks — lightly into the page, more into the cards and selected tabs,
  /// most into the borders, so cards read apart from the page they sit on.
  /// Text, accent and the tints that mean something stay as they are.
  /// The palette for panels laid over the zone's art: cards, tabs and
  /// tracks let the art through, enough to see the place, not enough to
  /// lose a name.
  ZonePalette glass() => copyWith(
    surface: surface.withValues(alpha: 0.86),
    surfaceSunken: surfaceSunken.withValues(alpha: 0.8),
    raised: raised.withValues(alpha: 0.9),
    track: track.withValues(alpha: 0.8),
  );

  ZonePalette washed() {
    Color mix(Color c, double t) =>
        Color.alphaBlend(scene.withValues(alpha: t), c);
    return copyWith(
      bg: mix(bg, 0.10),
      surface: mix(surface, 0.22),
      surfaceSunken: mix(surfaceSunken, 0.14),
      raised: mix(raised, 0.32),
      track: mix(track, 0.2),
      border: mix(border, 0.4),
      borderStrong: mix(borderStrong, 0.4),
      divider: mix(divider, 0.25),
    );
  }

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
    scene: Color(0xFF5C8A3A),
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
    scene: Color(0xFF2F6B4A),
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
    scene: Color(0xFF2E6B62),
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
    scene: Color(0xFF2A4F6E),
  );

  /// South Haven: the slate and plum of the stone cottages in shade, the
  /// terracotta roofs as the accent.
  static const southHaven = ZonePalette(
    bg: Color(0xFF0E0D11),
    surface: Color(0xFF19161E),
    surfaceSunken: Color(0xFF141118),
    raised: Color(0xFF28242F),
    track: Color(0xFF211E27),
    border: Color(0xFF24202A),
    borderStrong: Color(0xFF35303D),
    borderOverArt: Color(0xFF45404D),
    divider: Color(0xFF201C26),
    text: Color(0xFFE5E1EB),
    textMuted: Color(0xFFA6A1AF),
    textSubtitle: Color(0xFFBEB9C6),
    textNavInactive: Color(0xFF96919F),
    chevron: Color(0xFF7F7A87),
    accent: Color(0xFFE89464),
    onAccent: Color(0xFF1C0F07),
    accentLip: Color(0xFFA0572E),
    titleShadow: Color(0xFF070609),
    gatherTintFill: Color(0xFF161E22),
    gatherTintBorder: Color(0xFF2F3A3F),
    scene: Color(0xFF5A4E6E),
  );

  /// Maplewater Lake: the deep blue of the lake, the maple reds on the
  /// far shore as the accent.
  static const maplewater = ZonePalette(
    bg: Color(0xFF0B1013),
    surface: Color(0xFF131B21),
    surfaceSunken: Color(0xFF0F151A),
    raised: Color(0xFF1F2B34),
    track: Color(0xFF1A242B),
    border: Color(0xFF1C262E),
    borderStrong: Color(0xFF2A3943),
    borderOverArt: Color(0xFF3A4953),
    divider: Color(0xFF18222A),
    text: Color(0xFFDCE8F0),
    textMuted: Color(0xFF9BAAB5),
    textSubtitle: Color(0xFFB3C2CC),
    textNavInactive: Color(0xFF8B9AA5),
    chevron: Color(0xFF74838D),
    accent: Color(0xFFF2697C),
    onAccent: Color(0xFF1E0609),
    accentLip: Color(0xFFAF283B),
    titleShadow: Color(0xFF05080A),
    gatherTintFill: Color(0xFF122126),
    gatherTintBorder: Color(0xFF283F46),
    scene: Color(0xFF2E5C7A),
  );

  /// Forest Mine: the tunnel's indigo dark, a lantern's amber as the
  /// accent.
  static const mine = ZonePalette(
    bg: Color(0xFF0C0B13),
    surface: Color(0xFF151420),
    surfaceSunken: Color(0xFF101019),
    raised: Color(0xFF222033),
    track: Color(0xFF1C1B2A),
    border: Color(0xFF1E1D2D),
    borderStrong: Color(0xFF2D2B42),
    borderOverArt: Color(0xFF3D3B52),
    divider: Color(0xFF1A1929),
    text: Color(0xFFDEDDEF),
    textMuted: Color(0xFF9E9CB4),
    textSubtitle: Color(0xFFB6B4CB),
    textNavInactive: Color(0xFF8E8CA4),
    chevron: Color(0xFF77758C),
    accent: Color(0xFFEBB75E),
    onAccent: Color(0xFF1D1507),
    accentLip: Color(0xFFA2762A),
    titleShadow: Color(0xFF06050A),
    gatherTintFill: Color(0xFF131F25),
    gatherTintBorder: Color(0xFF293C45),
    scene: Color(0xFF3E3A66),
  );

  /// Stormgrass Prairie: the storm front's blue-teal, the golden tallgrass
  /// as the accent.
  static const prairie = ZonePalette(
    bg: Color(0xFF0B1113),
    surface: Color(0xFF131D21),
    surfaceSunken: Color(0xFF0F171A),
    raised: Color(0xFF202D33),
    track: Color(0xFF1A262B),
    border: Color(0xFF1C282E),
    borderStrong: Color(0xFF2B3B42),
    borderOverArt: Color(0xFF3B4B52),
    divider: Color(0xFF18242A),
    text: Color(0xFFDCEAF0),
    textMuted: Color(0xFF9CADB4),
    textSubtitle: Color(0xFFB4C4CB),
    textNavInactive: Color(0xFF8C9DA4),
    chevron: Color(0xFF75858C),
    accent: Color(0xFFF2C94C),
    onAccent: Color(0xFF1E1806),
    accentLip: Color(0xFFA38323),
    titleShadow: Color(0xFF05080A),
    gatherTintFill: Color(0xFF122226),
    gatherTintBorder: Color(0xFF294045),
    scene: Color(0xFF3E6672),
  );

  /// Mistgrave Hollow: fog lying grey-green over dark slate headstones, and
  /// the pale green of a grave lantern as the accent.
  static const mistgrave = ZonePalette(
    bg: Color(0xFF0B0F0E),
    surface: Color(0xFF141A19),
    surfaceSunken: Color(0xFF101514),
    raised: Color(0xFF1F2826),
    track: Color(0xFF19211F),
    border: Color(0xFF1B2422),
    borderStrong: Color(0xFF2A3633),
    borderOverArt: Color(0xFF3A4844),
    divider: Color(0xFF172020),
    text: Color(0xFFDDE8E3),
    textMuted: Color(0xFF98A9A3),
    // ~38% of the way from textMuted to text
    textSubtitle: Color(0xFFB2C1BB),
    textNavInactive: Color(0xFF889993),
    chevron: Color(0xFF71827C),
    accent: Color(0xFFB8F0C8),
    onAccent: Color(0xFF0C2013),
    accentLip: Color(0xFF6FA882),
    titleShadow: Color(0xFF040606),
    gatherTintFill: Color(0xFF132320),
    gatherTintBorder: Color(0xFF2A4540),
    scene: Color(0xFF4A6660),
  );

  /// Reedwater Vale: the green-teal of slow river water under reeds, a
  /// dragonfly's gold as the accent.
  static const reedwater = ZonePalette(
    bg: Color(0xFF0A130F),
    surface: Color(0xFF122119),
    surfaceSunken: Color(0xFF0E1A14),
    raised: Color(0xFF1D3629),
    track: Color(0xFF19291F),
    border: Color(0xFF1B2D23),
    borderStrong: Color(0xFF29453A),
    borderOverArt: Color(0xFF39594B),
    divider: Color(0xFF16281F),
    text: Color(0xFFE3F1E6),
    textMuted: Color(0xFF9CB8A6),
    textSubtitle: Color(0xFFBBD4C2),
    textNavInactive: Color(0xFF8CA896),
    chevron: Color(0xFF749282),
    accent: Color(0xFFE8C95A),
    onAccent: Color(0xFF1E1806),
    accentLip: Color(0xFFA38A2A),
    titleShadow: Color(0xFF040A07),
    gatherTintFill: Color(0xFF10261F),
    gatherTintBorder: Color(0xFF28483E),
    scene: Color(0xFF2F7A5E),
  );

  /// Mudmouth Delta: silt-brown channels spreading through olive reed beds,
  /// a heron's pale blue as the accent.
  static const mudmouth = ZonePalette(
    bg: Color(0xFF110F0B),
    surface: Color(0xFF1C1912),
    surfaceSunken: Color(0xFF16140E),
    raised: Color(0xFF2E2A1E),
    track: Color(0xFF26231A),
    border: Color(0xFF29251B),
    borderStrong: Color(0xFF3B3627),
    borderOverArt: Color(0xFF4C4636),
    divider: Color(0xFF231F17),
    text: Color(0xFFECE8D8),
    textMuted: Color(0xFFADA68F),
    textSubtitle: Color(0xFFC6BFA8),
    textNavInactive: Color(0xFF9D967F),
    chevron: Color(0xFF857F6A),
    accent: Color(0xFF8CC8DC),
    onAccent: Color(0xFF08181E),
    accentLip: Color(0xFF4F8A9E),
    titleShadow: Color(0xFF080705),
    gatherTintFill: Color(0xFF1B2218),
    gatherTintBorder: Color(0xFF353F2B),
    scene: Color(0xFF6B6038),
  );

  /// Saltwind Coast: open-sea blue under a bright sky, coral and sea foam as
  /// the accent.
  static const saltwind = ZonePalette(
    bg: Color(0xFF080F16),
    surface: Color(0xFF0F1B26),
    surfaceSunken: Color(0xFF0B1620),
    raised: Color(0xFF1A2D3F),
    track: Color(0xFF15253A),
    border: Color(0xFF172B3D),
    borderStrong: Color(0xFF244259),
    borderOverArt: Color(0xFF335871),
    divider: Color(0xFF12243A),
    text: Color(0xFFE2EEF5),
    textMuted: Color(0xFF94AEC0),
    textSubtitle: Color(0xFFB4CAD8),
    textNavInactive: Color(0xFF849FB2),
    chevron: Color(0xFF6C889B),
    accent: Color(0xFFFF8E78),
    onAccent: Color(0xFF260C06),
    accentLip: Color(0xFFB04E39),
    titleShadow: Color(0xFF03070B),
    gatherTintFill: Color(0xFF0E2433),
    gatherTintBorder: Color(0xFF254A60),
    scene: Color(0xFF2A6A9A),
  );

  /// Iron Gate City: the night-purple shadows behind the brick, the gold
  /// dome as the accent.
  static const ironGateCity = ZonePalette(
    bg: Color(0xFF110C12),
    surface: Color(0xFF1E1420),
    surfaceSunken: Color(0xFF181019),
    raised: Color(0xFF302132),
    track: Color(0xFF281B2A),
    border: Color(0xFF2B1D2D),
    borderStrong: Color(0xFF3E2C41),
    borderOverArt: Color(0xFF4E3C51),
    divider: Color(0xFF271929),
    text: Color(0xFFECDEEE),
    textMuted: Color(0xFFB09DB3),
    textSubtitle: Color(0xFFC7B5CA),
    textNavInactive: Color(0xFFA08DA3),
    chevron: Color(0xFF88768B),
    accent: Color(0xFFE9CF8C),
    onAccent: Color(0xFF1C1608),
    accentLip: Color(0xFFAF8E39),
    titleShadow: Color(0xFF09050A),
    gatherTintFill: Color(0xFF141424),
    gatherTintBorder: Color(0xFF2A2A44),
    scene: Color(0xFF5E3E66),
  );

  /// Ironroot Hills: the maroon of the rock walls in shade, rust-red iron
  /// as the accent.
  static const ironroot = ZonePalette(
    bg: Color(0xFF130B0D),
    surface: Color(0xFF201417),
    surfaceSunken: Color(0xFF191012),
    raised: Color(0xFF332025),
    track: Color(0xFF2A1B1F),
    border: Color(0xFF2D1D21),
    borderStrong: Color(0xFF422B31),
    borderOverArt: Color(0xFF523B41),
    divider: Color(0xFF29191D),
    text: Color(0xFFEFDDE2),
    textMuted: Color(0xFFB49CA2),
    textSubtitle: Color(0xFFCBB4BA),
    textNavInactive: Color(0xFFA48C92),
    chevron: Color(0xFF8C757B),
    accent: Color(0xFFEA7452),
    onAccent: Color(0xFF1D0C07),
    accentLip: Color(0xFF9C4228),
    titleShadow: Color(0xFF0A0506),
    gatherTintFill: Color(0xFF131C25),
    gatherTintBorder: Color(0xFF293745),
    scene: Color(0xFF6E3440),
  );

  /// Copperdust Flats: burnt-umber desert shadow, the setting sun's
  /// copper gold as the accent.
  static const copperdust = ZonePalette(
    bg: Color(0xFF130E0B),
    surface: Color(0xFF201714),
    surfaceSunken: Color(0xFF191310),
    raised: Color(0xFF332620),
    track: Color(0xFF2A1F1B),
    border: Color(0xFF2D221D),
    borderStrong: Color(0xFF42322B),
    borderOverArt: Color(0xFF52423B),
    divider: Color(0xFF291E19),
    text: Color(0xFFEFE2DD),
    textMuted: Color(0xFFB4A39C),
    textSubtitle: Color(0xFFCBBBB4),
    textNavInactive: Color(0xFFA4938C),
    chevron: Color(0xFF8C7C75),
    accent: Color(0xFFFCA43C),
    onAccent: Color(0xFF201304),
    accentLip: Color(0xFFA7671A),
    titleShadow: Color(0xFF0A0705),
    gatherTintFill: Color(0xFF132225),
    gatherTintBorder: Color(0xFF294045),
    scene: Color(0xFF7A4A2E),
  );

  /// Redwall Bluffs: the wine-red of the canyon walls, the river's teal
  /// far below as the accent.
  static const redwall = ZonePalette(
    bg: Color(0xFF130B0E),
    surface: Color(0xFF211319),
    surfaceSunken: Color(0xFF1A0F14),
    raised: Color(0xFF332028),
    track: Color(0xFF2B1A21),
    border: Color(0xFF2E1C24),
    borderStrong: Color(0xFF422B35),
    borderOverArt: Color(0xFF523B45),
    divider: Color(0xFF2A1820),
    text: Color(0xFFF0DCE5),
    textMuted: Color(0xFFB49CA6),
    textSubtitle: Color(0xFFCBB4BE),
    textNavInactive: Color(0xFFA48C96),
    chevron: Color(0xFF8C757F),
    accent: Color(0xFF72D8C4),
    onAccent: Color(0xFF0A1A17),
    accentLip: Color(0xFF3B9281),
    titleShadow: Color(0xFF0A0507),
    gatherTintFill: Color(0xFF122526),
    gatherTintBorder: Color(0xFF294545),
    scene: Color(0xFF7A3046),
  );

  /// Greyspine Mountain: the slate blue of granite in shade, the high sky over
  /// the snowline as the accent.
  static const greyspine = ZonePalette(
    bg: Color(0xFF0C0E12),
    surface: Color(0xFF15181F),
    surfaceSunken: Color(0xFF111318),
    raised: Color(0xFF232630),
    track: Color(0xFF1D2028),
    border: Color(0xFF1F222B),
    borderStrong: Color(0xFF2F333F),
    borderOverArt: Color(0xFF3E424E),
    divider: Color(0xFF1B1E27),
    text: Color(0xFFDFE3ED),
    textMuted: Color(0xFFA0A4B1),
    textSubtitle: Color(0xFFB8BCC8),
    textNavInactive: Color(0xFF8F94A1),
    chevron: Color(0xFF797D88),
    accent: Color(0xFF7FB2F0),
    onAccent: Color(0xFF07111D),
    accentLip: Color(0xFF306EBB),
    titleShadow: Color(0xFF05060A),
    gatherTintFill: Color(0xFF131E26),
    gatherTintBorder: Color(0xFF293945),
    scene: Color(0xFF485670),
  );

  /// Ashridge Mountains: ash-dark charcoal, the ember glowing in the fissures
  /// as the accent.
  static const ashridge = ZonePalette(
    bg: Color(0xFF0C0F12),
    surface: Color(0xFF151A1F),
    surfaceSunken: Color(0xFF101418),
    raised: Color(0xFF222931),
    track: Color(0xFF1C2229),
    border: Color(0xFF1E252C),
    borderStrong: Color(0xFF2D3640),
    borderOverArt: Color(0xFF3D464F),
    divider: Color(0xFF1A2127),
    text: Color(0xFFDEE6EE),
    textMuted: Color(0xFF9EA8B2),
    textSubtitle: Color(0xFFB6BFC9),
    textNavInactive: Color(0xFF8E98A2),
    chevron: Color(0xFF77808A),
    accent: Color(0xFFFF6B2E),
    onAccent: Color(0xFF1D0E07),
    accentLip: Color(0xFF933A15),
    titleShadow: Color(0xFF05070A),
    gatherTintFill: Color(0xFF131F26),
    gatherTintBorder: Color(0xFF293C45),
    scene: Color(0xFF4A5560),
  );

  /// Saddlegate: the cold slate of the pass, the brick of its chimneys as the
  /// accent.
  static const saddlegate = ZonePalette(
    bg: Color(0xFF0C0D12),
    surface: Color(0xFF15171F),
    surfaceSunken: Color(0xFF111218),
    raised: Color(0xFF232630),
    track: Color(0xFF1D1F28),
    border: Color(0xFF1F212B),
    borderStrong: Color(0xFF2F323F),
    borderOverArt: Color(0xFF3E424E),
    divider: Color(0xFF1B1D27),
    text: Color(0xFFDFE2ED),
    textMuted: Color(0xFFA0A3B1),
    textSubtitle: Color(0xFFB8BBC8),
    textNavInactive: Color(0xFF8F93A1),
    chevron: Color(0xFF797C88),
    accent: Color(0xFFE07A4F),
    onAccent: Color(0xFF1D0E07),
    accentLip: Color(0xFF824328),
    titleShadow: Color(0xFF05060A),
    gatherTintFill: Color(0xFF131F26),
    gatherTintBorder: Color(0xFF293C45),
    scene: Color(0xFF4A5068),
  );

  /// Frostcrown Peaks: deep glacier navy, ice cyan as the accent.
  static const frostcrown = ZonePalette(
    bg: Color(0xFF0B0E14),
    surface: Color(0xFF131821),
    surfaceSunken: Color(0xFF0F131A),
    raised: Color(0xFF1F2734),
    track: Color(0xFF1A202B),
    border: Color(0xFF1C222E),
    borderStrong: Color(0xFF2A3343),
    borderOverArt: Color(0xFF3A4353),
    divider: Color(0xFF181E2A),
    text: Color(0xFFDCE3F0),
    textMuted: Color(0xFF9BA4B5),
    textSubtitle: Color(0xFFB3BCCC),
    textNavInactive: Color(0xFF8A94A6),
    chevron: Color(0xFF747D8D),
    accent: Color(0xFF7FE6FF),
    onAccent: Color(0xFF07191D),
    accentLip: Color(0xFF1FB6DA),
    titleShadow: Color(0xFF05070A),
    gatherTintFill: Color(0xFF132126),
    gatherTintBorder: Color(0xFF293E45),
    scene: Color(0xFF3A5A80),
  );

  /// Stormcrown Peaks: storm-cloud blue-grey, the pale violet of the lightning
  /// as the accent.
  static const stormcrown = ZonePalette(
    bg: Color(0xFF0B0E13),
    surface: Color(0xFF141820),
    surfaceSunken: Color(0xFF101319),
    raised: Color(0xFF212632),
    track: Color(0xFF1B202A),
    border: Color(0xFF1D222D),
    borderStrong: Color(0xFF2C3241),
    borderOverArt: Color(0xFF3C4251),
    divider: Color(0xFF191E28),
    text: Color(0xFFDDE3EF),
    textMuted: Color(0xFF9DA4B3),
    textSubtitle: Color(0xFFB5BBCA),
    textNavInactive: Color(0xFF8D94A3),
    chevron: Color(0xFF767C8B),
    accent: Color(0xFFC3B5FF),
    onAccent: Color(0xFF0B071D),
    accentLip: Color(0xFF684AE5),
    titleShadow: Color(0xFF05060A),
    gatherTintFill: Color(0xFF131E26),
    gatherTintBorder: Color(0xFF293945),
    scene: Color(0xFF4E4E80),
  );

  /// Moltenspire Peaks: scorched crimson-black, molten gold as the accent.
  static const moltenspire = ZonePalette(
    bg: Color(0xFF130B0C),
    surface: Color(0xFF211415),
    surfaceSunken: Color(0xFF1A0F10),
    raised: Color(0xFF332022),
    track: Color(0xFF2A1B1C),
    border: Color(0xFF2D1C1E),
    borderStrong: Color(0xFF422B2D),
    borderOverArt: Color(0xFF523B3D),
    divider: Color(0xFF29191A),
    text: Color(0xFFF0DDDE),
    textMuted: Color(0xFFB49C9E),
    textSubtitle: Color(0xFFCBB4B6),
    textNavInactive: Color(0xFFA48C8E),
    chevron: Color(0xFF8C7577),
    accent: Color(0xFFFFB02E),
    onAccent: Color(0xFF1D1507),
    accentLip: Color(0xFF936415),
    titleShadow: Color(0xFF0A0505),
    gatherTintFill: Color(0xFF132226),
    gatherTintBorder: Color(0xFF294145),
    scene: Color(0xFF7A2E2A),
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
    Color? scene,
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
      scene: scene ?? _scene,
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
      scene: l(scene, other.scene),
    );
  }
}
