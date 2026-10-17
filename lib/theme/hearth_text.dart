import 'package:flutter/painting.dart';

/// The Hearth type scale. Styles carry no colour — the widget using one
/// picks it from the palette — and every style that shows numbers uses
/// tabular figures so counts and timers don't jitter as they tick.
abstract final class HearthText {
  static const String body = 'Figtree';
  static const String pixel = 'PixelifySans';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Screen and zone titles: 30 on the expanded zone header, 24 collapsed
  /// and on combat/crafting. Pair with a `Shadow(offset: Offset(0, 2))` in
  /// the palette's titleShadow.
  static const TextStyle title = TextStyle(
    fontFamily: pixel,
    fontWeight: FontWeight.w600,
    fontSize: 30,
    height: 1.1,
  );

  static const TextStyle rowTitle = TextStyle(
    fontFamily: body,
    fontSize: 17,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  static const TextStyle rowMeta = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  static const TextStyle xpValue = TextStyle(
    fontFamily: body,
    fontSize: 17,
    fontWeight: FontWeight.w800,
    fontFeatures: _tabular,
  );

  /// The " xp" after an [xpValue].
  static const TextStyle xpSuffix = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle tab = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  static const TextStyle tabActive = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  static const TextStyle chip = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
  );

  static const TextStyle chipActive = TextStyle(
    fontFamily: body,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// "PLACES"-style headings; uppercase the string itself.
  static const TextStyle sectionLabel = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 12 * 0.12,
  );

  static const TextStyle ringNumber = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    fontFeatures: _tabular,
  );

  /// Timers such as "2.00s".
  static const TextStyle timer = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// The status row's "990 / 990" and "1.50x".
  static const TextStyle statusStat = TextStyle(
    fontFamily: body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
  );

  /// Activity labels such as "Exploring" and "Tending".
  static const TextStyle activityLabel = TextStyle(
    fontFamily: body,
    fontSize: 13,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle navLabel = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle navLabelActive = TextStyle(
    fontFamily: body,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );
}
