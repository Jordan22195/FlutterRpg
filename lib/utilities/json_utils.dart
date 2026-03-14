import '../catalogs/item_catalog.dart';
import '../catalogs/zone_catalog.dart';

class JsonUtils {
  static Map<String, dynamic> requireMap(
    Map<String, dynamic> json,
    String key,
  ) {
    final value = json[key];
    if (value is! Map) {
      throw FormatException('Missing or invalid "$key". Expected object.');
    }
    return Map<String, dynamic>.from(value);
  }

  static String requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String) {
      throw FormatException('Missing or invalid "$key". Expected String.');
    }
    return value;
  }

  static int requireInt(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! int) {
      throw FormatException('Missing or invalid "$key". Expected int.');
    }
    return value;
  }

  static double requireDouble(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    throw FormatException('Missing or invalid "$key". Expected double.');
  }

  static bool requireBool(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! bool) {
      throw FormatException('Missing or invalid "$key". Expected bool.');
    }
    return value;
  }

  static List<dynamic> requireList(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! List) {
      throw FormatException('Missing or invalid "$key". Expected list.');
    }
    return value;
  }

  static T parseEnumByName<T extends Enum>(
    List<T> values,
    String rawValue,
    String fieldName,
  ) {
    try {
      return values.firstWhere((e) => e.name == rawValue);
    } catch (_) {
      throw FormatException(
        'Invalid value "$rawValue" for "$fieldName". '
        'Valid values: ${values.map((e) => e.name).join(', ')}',
      );
    }
  }

  static ItemId parseItemId(String rawValue, {String fieldName = 'itemId'}) {
    return parseEnumByName(ItemId.values, rawValue, fieldName);
  }

  static ZoneId parseZoneId(String rawValue, {String fieldName = 'zoneId'}) {
    return parseEnumByName(ZoneId.values, rawValue, fieldName);
  }

  static Map<K, V> parseMap<K, V>(
    Map<dynamic, dynamic> rawMap, {
    required K Function(String key) parseKey,
    required V Function(Map<String, dynamic> value) parseValue,
    required String fieldName,
  }) {
    final result = <K, V>{};

    for (final entry in rawMap.entries) {
      if (entry.key is! String) {
        throw FormatException(
          'Invalid key in "$fieldName". Expected String keys.',
        );
      }

      if (entry.value is! Map) {
        throw FormatException(
          'Invalid value in "$fieldName" for key "${entry.key}". Expected object.',
        );
      }

      final parsedKey = parseKey(entry.key as String);
      final parsedValue = parseValue(
        Map<String, dynamic>.from(entry.value as Map),
      );

      result[parsedKey] = parsedValue;
    }

    return result;
  }
}
