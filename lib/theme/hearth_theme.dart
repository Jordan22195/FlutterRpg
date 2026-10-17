import 'package:flutter/material.dart';

import 'game_colors.dart';
import 'hearth_text.dart';
import 'zone_palette.dart';

/// The app theme for a zone: its [ZonePalette] and the fixed [GameColors]
/// as extensions, plus a Material colour scheme mapped onto the palette so
/// widgets still reading `colorScheme` pick up the zone's warmth.
///
/// The scheme deliberately never uses the palette's accent: that colour
/// belongs to the primary action button alone, so `primary` is the
/// palette's text colour rather than the accent.
ThemeData hearthTheme(ZonePalette p) {
  const game = GameColors.standard;
  final scheme = ColorScheme.dark(
    surface: p.bg,
    onSurface: p.text,
    onSurfaceVariant: p.textMuted,
    surfaceDim: p.bg,
    surfaceBright: p.raised,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surfaceSunken,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surface,
    surfaceContainerHighest: p.raised,
    primary: p.text,
    onPrimary: p.bg,
    primaryContainer: p.raised,
    onPrimaryContainer: p.text,
    secondary: p.textMuted,
    onSecondary: p.bg,
    secondaryContainer: p.raised,
    onSecondaryContainer: p.text,
    tertiary: game.xp,
    onTertiary: p.bg,
    error: game.hp,
    onError: p.text,
    outline: p.borderStrong,
    outlineVariant: p.border,
    shadow: Colors.black,
    scrim: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    dividerColor: p.divider,
    fontFamily: HearthText.body,
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: p.bg,
      selectedItemColor: p.text,
      unselectedItemColor: p.textNavInactive,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.divider, thickness: 1),
    extensions: <ThemeExtension<dynamic>>[p, game],
  );
}

extension HearthThemeX on BuildContext {
  /// The current zone's palette. Falls back to the meadow's so a widget
  /// pumped under a bare MaterialApp (as most widget tests do) still draws.
  ZonePalette get palette =>
      Theme.of(this).extension<ZonePalette>() ?? ZonePalette.meadow;

  GameColors get gameColors =>
      Theme.of(this).extension<GameColors>() ?? GameColors.standard;
}
