import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/zones/zone_id.dart';
import 'package:rpg/theme/game_colors.dart';
import 'package:rpg/theme/hearth_text.dart';
import 'package:rpg/theme/hearth_theme.dart';
import 'package:rpg/theme/zone_palette.dart';

/// WCAG contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  final palettes = {for (final z in ZoneId.values) z: z.definition.palette};

  group('every zone palette reads at 4.5:1', () {
    for (final MapEntry(key: zone, value: p) in palettes.entries) {
      test(zone.name, () {
        final pairs = {
          'onAccent on accent': (p.onAccent, p.accent),
          'text on surface': (p.text, p.surface),
          'text on bg': (p.text, p.bg),
          'textMuted on surface': (p.textMuted, p.surface),
          'textMuted on bg': (p.textMuted, p.bg),
          'textSubtitle on bg': (p.textSubtitle, p.bg),
          'textNavInactive on bg': (p.textNavInactive, p.bg),
          'xp on surface': (GameColors.standard.xp, p.surface),
        };
        for (final MapEntry(key: name, value: (fg, bg)) in pairs.entries) {
          expect(
            contrast(fg, bg),
            greaterThanOrEqualTo(4.5),
            reason: '$name in ${zone.name}',
          );
        }
        // the lip is a darker shade of the accent, never a lighter one
        expect(
          p.accentLip.computeLuminance(),
          lessThan(p.accent.computeLuminance()),
        );
      });
    }
  });

  test('the meadow and the forest wear their own palettes', () {
    expect(ZoneId.TUTORIAL_FARM.definition.palette, ZonePalette.meadow);
    expect(ZoneId.SOUTHWOOD_FOREST.definition.palette, ZonePalette.forest);
  });

  test('palettes crossfade between zones', () {
    const a = ZonePalette.meadow;
    const b = ZonePalette.forest;
    expect(a.lerp(b, 0).bg, a.bg);
    expect(a.lerp(b, 1).bg, b.bg);
    expect(a.lerp(b, 1).accent, b.accent);
    expect(a.lerp(b, 0.5).bg, Color.lerp(a.bg, b.bg, 0.5));
  });

  test('the theme carries both extensions and keeps the accent to itself', () {
    final theme = hearthTheme(ZonePalette.forest);
    expect(theme.extension<ZonePalette>(), ZonePalette.forest);
    expect(theme.extension<GameColors>(), GameColors.standard);
    expect(theme.scaffoldBackgroundColor, ZonePalette.forest.bg);

    // accent belongs to the primary button alone: no scheme role may carry
    // it, or every Material widget reading that role would wear it too
    final s = theme.colorScheme;
    final roles = [
      s.primary,
      s.secondary,
      s.tertiary,
      s.primaryContainer,
      s.secondaryContainer,
      s.surface,
      s.surfaceContainerHighest,
    ];
    expect(roles, isNot(contains(ZonePalette.forest.accent)));
  });

  testWidgets('a widget under a bare MaterialApp falls back to the meadow', (
    tester,
  ) async {
    late ZonePalette palette;
    late GameColors colors;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            palette = context.palette;
            colors = context.gameColors;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(palette, ZonePalette.meadow);
    expect(colors, GameColors.standard);
  });

  testWidgets('a widget under the zone theme reads that zone', (tester) async {
    late ZonePalette palette;
    await tester.pumpWidget(
      MaterialApp(
        theme: hearthTheme(ZonePalette.forest),
        home: Builder(
          builder: (context) {
            palette = context.palette;
            return const SizedBox();
          },
        ),
      ),
    );
    expect(palette, ZonePalette.forest);
  });

  test(
    'the Hearth fonts are bundled at every weight the type scale uses',
    () async {
      final manifest =
          jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
      Map<String, Set<int>> weights = {
        for (final family in manifest.cast<Map<String, dynamic>>())
          family['family'] as String: {
            for (final font in (family['fonts'] as List).cast<Map>())
              (font['weight'] as int?) ?? 400,
          },
      };
      expect(weights[HearthText.body], containsAll([500, 600, 700, 800]));
      expect(weights[HearthText.pixel], contains(600));
      for (final family in manifest.cast<Map<String, dynamic>>()) {
        for (final font in (family['fonts'] as List).cast<Map>()) {
          // every declared file actually loads
          await rootBundle.load(font['asset'] as String);
        }
      }
    },
  );
}
