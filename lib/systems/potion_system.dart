import '../catalogs/items/items.dart';
import '../data/buff_data.dart';
import '../data/inventory_data.dart';
import '../services/buff_service.dart';
import '../services/inventory_service.dart';
import '../data/player_data.dart';

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
  ///
  /// [at] is the instant it is drunk at, defaulting to now. An offline
  /// settle drinks at the segment it is replaying, and a buff stamped from
  /// the wall clock instead would read as up until long after the gap.
  bool drink(
    ItemId id,
    InventoryData inventoryState,
    BuffData buffState, {
    DateTime? at,
  }) {
    if (!isDrinkable(id)) return false;
    if (_inventoryService.getItemCount(inventoryState, id) <= 0) return false;

    // built here rather than held anywhere: a BuffItem stamps its
    // expirationTime in its constructor, so the instance has to be born at
    // the moment it is drunk or the buff arrives part-spent
    final potion = id.build();
    if (potion is! BuffItem) return false;
    if (at != null) potion.expirationTime = at.add(potion.duration);

    _inventoryService.removeItems(inventoryState, id, 1);
    _buffService.addBuff(potion, buffState, at: at);
    return true;
  }

  /// Drinks one of every potion in [PlayerData.autoDrinkPotions] whose buff
  /// is not up at [at] and that the player still holds. Returns what was
  /// drunk, in catalog order.
  ///
  /// "Not up" is [BuffService.getGlobalBuff]'s rule, which matches the
  /// sweep's: a buff expiring exactly at [at] has gone, so the instant a
  /// settle sweeps one is the instant this puts it back.
  List<ItemId> autoDrink(
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) {
    final drunk = <ItemId>[];
    for (final id in ItemId.values) {
      if (!playerState.autoDrinkPotions.contains(id)) continue;
      if (_buffService.getGlobalBuff(playerState.buffData, id, at: at) !=
          null) {
        continue;
      }
      if (drink(id, inventoryState, playerState.buffData, at: at)) {
        drunk.add(id);
      }
    }
    return drunk;
  }
}
