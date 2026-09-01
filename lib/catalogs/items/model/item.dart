import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/json_codec.dart';

/// A runtime item.
///
/// An instance holds only what is unique to *this* one — its [id], how many
/// are on the stack, and whatever a subclass adds. Name, value and (for
/// everything but equipment) quality are read through [definition] on each
/// access rather than copied in at construction, so a catalog tuning change
/// reaches items the player already owns.
class Item {
  final ItemId id;
  int count = 1;

  Item({required this.id});

  /// The design-time template every stat is read from. Never mutate it.
  ItemDefinition get definition => id.definition;

  String get name => definition.name;
  int get value => definition.value;

  /// For most items quality is a property of the definition; only
  /// equipment rolls its own, and [EquipmentItem] overrides this with a
  /// settable per-instance value.
  Rarity get quality => definition.quality;

  Map<String, dynamic> toJson() {
    return {'id': id.name, 'count': count};
  }

  /// Rebuilds an item from the definition its id names, then overlays the
  /// instance state the save carries.
  ///
  /// Which class comes back is decided by the definition rather than by a
  /// stored `runtimeType`, so an item retyped in the catalog — a plain item
  /// promoted to a weapon, say — resolves correctly on its own. Stat fields
  /// written by older saves are ignored: reading them back is exactly what
  /// used to make a tuning change miss everything already owned.
  factory Item.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    if (rawId is! String) {
      throw FormatException('Missing or invalid "id". Expected String.');
    }

    final item = parseItemId(rawId).build();

    final rawCount = json['count'];
    if (rawCount is int) {
      item.count = rawCount;
    }

    if (item is EquipmentItem) {
      item.readInstanceFieldsFromJson(json);
    }
    if (item is BuffItem) {
      item.readBuffStateFromJson(json);
    }
    if (item is ZoneBuffItem) {
      item.readZoneStateFromJson(json);
    }

    return item;
  }
}
