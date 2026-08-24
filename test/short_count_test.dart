import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/utilities/util.dart';

void main() {
  group('formatShortCount', () {
    test('leaves a number that already fits alone', () {
      expect(Util.formatShortCount(0), '0');
      expect(Util.formatShortCount(7), '7');
      expect(Util.formatShortCount(123), '123');
      expect(Util.formatShortCount(999), '999');
    });

    test('writes three significant digits with a magnitude suffix', () {
      expect(Util.formatShortCount(1453), '1.45k');
      expect(Util.formatShortCount(12345), '12.3k');
      expect(Util.formatShortCount(115599), '115k');
      expect(Util.formatShortCount(1234567), '1.23m');
      expect(Util.formatShortCount(1234567890), '1.23b');
      expect(Util.formatShortCount(1234567890123), '1.23t');
    });

    test('truncates, so it never claims more than you hold', () {
      // rounding would call this 116k, which is more than there is
      expect(Util.formatShortCount(115599), '115k');
      expect(Util.formatShortCount(1999), '1.99k');
      expect(Util.formatShortCount(19999), '19.9k');
    });

    test('never spills into the next magnitude', () {
      // the failure rounding would produce here is "1000k"
      expect(Util.formatShortCount(999999), '999k');
      expect(Util.formatShortCount(999999999), '999m');
    });

    test('drops a trailing zero that says nothing', () {
      expect(Util.formatShortCount(1000), '1k');
      expect(Util.formatShortCount(1500), '1.5k');
      expect(Util.formatShortCount(10000), '10k');
      expect(Util.formatShortCount(2000000), '2m');
    });

    test('keeps its shape past the largest suffix', () {
      // nothing in the game should reach this, but it must not crash or
      // invent a suffix
      expect(Util.formatShortCount(5000000000000000), '5000t');
    });

    test('carries a sign through', () {
      expect(Util.formatShortCount(-42), '-42');
      expect(Util.formatShortCount(-1453), '-1.45k');
    });
  });
}
