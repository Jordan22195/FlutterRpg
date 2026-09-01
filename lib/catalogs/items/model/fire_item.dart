import 'package:rpg/catalogs/items/definition/fire_item_definition.dart';
import 'package:rpg/catalogs/items/model/zone_buff_item.dart';

/// A fire burning in a firepit. [canCook] is what opens the cooking half of
/// the firepit screen; the COOKING entry in [skillBonus] is what makes a
/// better fire burn less food, via the buffed stat totals.
class FireItem extends ZoneBuffItem {
  FireItem({
    required super.id,
    super.fuelUnits,
    super.zoneId,
    super.ownerEntityId,
  });

  @override
  FireItemDefinition get definition => id.definition as FireItemDefinition;

  bool get canCook => definition.canCook;
}
