import 'package:rpg/catalogs/items/definition/weapon_item_definition.dart';
import 'package:rpg/catalogs/items/model/equipment_item.dart';
import 'package:rpg/catalogs/items/model/item.dart';

/// Equipment that swings on a clock. Adds no state of its own — the swing
/// interval is a property of the weapon, not of the copy in the bag.
class WeaponItem extends EquipmentItem {
  WeaponItem({
    required super.id,
    super.quality,
    super.enchantName,
    super.enchantBonus,
  });

  @override
  WeaponItemDefinition get definition => id.definition as WeaponItemDefinition;

  Duration get actionInterval => definition.actionInterval;

  /// What one swing of this piece deals before the attack multiplier, at
  /// the quality it rolled.
  double get damage => definition.damageAt(quality);

  /// [damage] over the swing's length: the damage it deals a second, before the
  /// attack multiplier. 0 for a
  /// piece that does not swing at a pool.
  double get damagePerSecond {
    final seconds = actionInterval.inMicroseconds / 1e6;
    return seconds <= 0 ? 0 : damage / seconds;
  }

  /// Parses an equipment instance. The class is decided by the definition,
  /// so a weapon comes back as a [WeaponItem] whether or not the save said
  /// so; an id that is not equipment at all is a malformed save.
  static EquipmentItem equipmentFromJson(Map<String, dynamic> json) {
    final item = Item.fromJson(json);
    if (item is! EquipmentItem) {
      throw FormatException('ItemId "${item.id.name}" is not equipment.');
    }
    return item;
  }
}
