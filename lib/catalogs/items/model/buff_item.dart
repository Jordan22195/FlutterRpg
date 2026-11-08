import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/definition/buff_item_definition.dart';
import 'package:rpg/catalogs/items/model/item.dart';
import 'package:rpg/data/skill_data.dart';

/// A buff the player (or a zone) is currently under.
///
/// What it does and how long one application lasts are the definition's
/// business. What is unique to this one is when it runs out and how many
/// applications went into it — a fire lit from four logs burns for four
/// times the definition's duration.
class BuffItem extends Item {
  /// How many applications of the definition's [BuffItemDefinition.duration]
  /// this instance is worth. Firemaking lights n logs at once, and an
  /// offline stretch settles as one instance worth the whole batch.
  int fuelUnits;

  DateTime expirationTime;

  BuffItem({required super.id, this.fuelUnits = 1})
    : expirationTime = DateTime.now() {
    expirationTime = DateTime.now().add(duration);
  }

  @override
  BuffItemDefinition get definition => id.definition as BuffItemDefinition;

  Map<SkillId, int> get skillBonus => Map.unmodifiable(definition.skillBonus);

  /// The stats this buff is lending at [at]. A plain buff lends its
  /// definition's bonus for as long as it lasts; a fire lends whatever
  /// reagents are burning on it (see FireItem).
  Map<SkillId, int> bonusAt(DateTime at) =>
      expirationTime.isAfter(at) ? skillBonus : const {};

  /// Every instant at which [bonusAt] can change - what an offline settle
  /// cuts its segments on.
  Iterable<DateTime> get changeTimes => [expirationTime];

  /// The whole burn this instance is worth: the definition's duration times
  /// however many applications went into it. Derived rather than stored, so
  /// retuning a fire's burn time reaches one already alight.
  Duration get duration => definition.duration * fuelUnits;

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson();
    json['fuelUnits'] = fuelUnits;
    json['expirationTime'] = expirationTime.toIso8601String();
    return json;
  }

  /// Restores instance state (tolerating its absence in older saves, which
  /// stored a materialized duration instead of the unit count).
  void readBuffStateFromJson(Map<String, dynamic> json) {
    final rawFuelUnits = json['fuelUnits'];
    if (rawFuelUnits is int && rawFuelUnits > 0) {
      fuelUnits = rawFuelUnits;
    }
    expirationTime = dateTimeFromJson(json, 'expirationTime');
  }

  factory BuffItem.fromJson(Map<String, dynamic> json) {
    final item = Item.fromJson(json);
    if (item is! BuffItem) {
      throw FormatException('ItemId "${item.id.name}" is not a buff.');
    }
    return item;
  }
}
