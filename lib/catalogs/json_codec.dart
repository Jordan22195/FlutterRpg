/// Shared JSON codec helpers for the catalogs.
///
/// These were private to `item_catalog.dart` when every runtime model lived
/// in that one file. The models now live one per file, so the helpers have to
/// be public and shared — a `_name` would stop resolving across the split.
library;

import '../data/equipment_data.dart';
import '../data/skill_data.dart';
import 'entities/entities.dart';
import 'items/items.dart';
import 'zones/zones.dart';

// ---- Serialization helpers ----
Map<String, int> skillBonusToJson(Map<SkillId, int> skillBonus) {
  return skillBonus.map((key, value) => MapEntry(key.name, value));
}

Map<SkillId, int> skillBonusFromJson(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw == null) {
    throw FormatException('Missing "$key". Expected object.');
  }
  if (raw is! Map) {
    throw FormatException('Invalid "$key". Expected object.');
  }

  final result = <SkillId, int>{};
  for (final entry in raw.entries) {
    final rawKey = entry.key;
    final rawValue = entry.value;

    if (rawKey is! String) {
      throw FormatException('Invalid key in "$key". Expected String key.');
    }
    if (rawValue is! int) {
      throw FormatException(
        'Invalid value in "$key" for skill "$rawKey". Expected int.',
      );
    }

    final skillId = SkillId.values.firstWhere(
      (value) => value.name == rawKey,
      orElse: () =>
          throw FormatException('Invalid SkillId "$rawKey" in "$key".'),
    );

    result[skillId] = rawValue;
  }

  return result;
}

ItemId parseItemId(String rawValue, {String fieldName = 'id'}) {
  return ItemId.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () =>
        throw FormatException('Invalid ItemId "$rawValue" for "$fieldName".'),
  );
}

ZoneId parseZoneId(String rawValue, {String fieldName = 'zoneId'}) {
  return ZoneId.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () =>
        throw FormatException('Invalid ZoneId "$rawValue" for "$fieldName".'),
  );
}

ArmorSlots parseArmorSlot(String rawValue, {String fieldName = 'armorSlot'}) {
  return ArmorSlots.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () => throw FormatException(
      'Invalid ArmorSlot "$rawValue" for "$fieldName".',
    ),
  );
}

Duration durationFromMilliseconds(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('Missing or invalid "$key". Expected int.');
  }
  return Duration(milliseconds: value);
}

DateTime dateTimeFromJson(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw FormatException('Missing or invalid "$key". Expected String.');
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Invalid DateTime for "$key": "$value".');
  }
  return parsed;
}

/// Older saves stored the field as "entityId" and pointed it at a campfire
/// entity that no longer exists, so an unreadable owner is tolerated: the
/// buff data migration re-attaches it to the firepit that owns it.
EntityId ownerEntityIdFromJson(Map<String, dynamic> json) {
  final raw = json['ownerEntityId'] ?? json['entityId'];
  if (raw is! String) return EntityId.NULL;
  return EntityId.values.asNameMap()[raw] ?? EntityId.NULL;
}
