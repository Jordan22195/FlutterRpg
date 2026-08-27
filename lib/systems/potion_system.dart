import '../catalogs/items/items.dart';
import '../data/buff_data.dart';
import '../data/inventory_data.dart';
import '../services/buff_service.dart';
import '../services/inventory_service.dart';

/// Potions: an inventory item turning into a buff on the player.
///
/// This is FiremakingSystem's counterpart, and the difference is where the
/// buff lands. A fire is owned by the firepit it burns in, so it is a zone
/// buff and stays behind when the player leaves. A potion is in the player,
/// so it is a global buff and travels with them.
class PotionSystem {
  final BuffService _buffService;
  final InventoryService _inventoryService;

  PotionSystem({
    required BuffService buffService,
    required InventoryService inventoryService,
  }) : _buffService = buffService,
       _inventoryService = inventoryService;

  /// Whether [id] is something the player can drink.
  ///
  /// FireItemDefinition is a ZoneBuffItemDefinition is a BuffItemDefinition,
  /// so a bare `is BuffItemDefinition` would offer a bonfire as a drink. A
  /// zone buff belongs to an entity, not to a throat.
  bool isDrinkable(ItemId id) {
    final definition = id.definition;
    return definition is BuffItemDefinition &&
        definition is! ZoneBuffItemDefinition;
  }

  /// Drinks one [id]: takes it off the stack and puts its buff up. Drinking
  /// the same potion again extends it rather than restarting it, which is
  /// [BuffService.addBuff]'s rule for every global buff.
  ///
  /// Returns false and changes nothing when [id] is not a potion or the
  /// player has none — [InventoryService.removeItems] reports neither, so
  /// the guard has to live here.
  bool drink(ItemId id, InventoryData inventoryState, BuffData buffState) {
    if (!isDrinkable(id)) return false;
    if (_inventoryService.getItemCount(inventoryState, id) <= 0) return false;

    // built here rather than held anywhere: a BuffItem stamps its
    // expirationTime in its constructor, so the instance has to be born at
    // the moment it is drunk or the buff arrives part-spent
    final potion = id.build();
    if (potion is! BuffItem) return false;

    _inventoryService.removeItems(inventoryState, id, 1);
    _buffService.addBuff(potion, buffState);
    return true;
  }
}
