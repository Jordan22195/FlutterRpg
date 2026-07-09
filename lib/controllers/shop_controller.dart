import 'package:flutter/foundation.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/player_data.dart';
import 'package:rpg/data/world_data.dart';
import 'package:rpg/services/inventory_service.dart';
import 'package:rpg/services/shop_service.dart';
import 'package:rpg/services/world_service.dart';

// controllers coordinate between ui and systems or services

class ShopController extends ChangeNotifier {
  // data
  final PlayerData _playerState;
  final WorldData _worldState;
  final InventoryData _inventoryState;

  // catalogs
  final EntityCatalog _entityCatalog;
  final ItemCatalog _itemCatalog;

  // services
  final WorldService _worldService;
  final InventoryService _inventoryService;
  final ShopService _shopService;

  ShopController({
    required PlayerData playerState,
    required WorldData worldState,
    required InventoryData inventoryState,
    required EntityCatalog entityCatalog,
    required ItemCatalog itemCatalog,
    required WorldService worldService,
    required InventoryService inventoryService,
    required ShopService shopService,
  }) : _playerState = playerState,
       _worldState = worldState,
       _inventoryState = inventoryState,
       _entityCatalog = entityCatalog,
       _itemCatalog = itemCatalog,
       _worldService = worldService,
       _inventoryService = inventoryService,
       _shopService = shopService;

  // the shop the player is viewing, restocked first when its timer is
  // due. null when the viewed entity isn't a shop
  ShopEntity? _currentShop() {
    final entity = _worldService.getSelectedEntity(_playerState, _worldState);
    if (entity is! ShopEntity) return null;

    final def = _shopDefinition(entity.id);
    if (def != null) {
      _shopService.restockIfDue(entity, def, _itemCatalog);
    }
    return entity;
  }

  ShopEntityDefinition? _shopDefinition(EntityId id) {
    final def = _entityCatalog.getDefinitionFor(id);
    return def is ShopEntityDefinition ? def : null;
  }

  String shopName() {
    return _currentShop()?.name ?? "";
  }

  String shopIconAsset() {
    return _entityCatalog
        .getDefinitionFor(_playerState.currentEntityViewId)
        .iconAsset;
  }

  List<ShopStockEntry> stock() {
    return List.unmodifiable(_currentShop()?.stock ?? const []);
  }

  DateTime? nextRestockAt() {
    return _currentShop()?.nextRestockAt;
  }

  int playerCoins() {
    return _inventoryService.getItemCount(_inventoryState, ItemId.COINS);
  }

  String itemName(ItemId itemId) {
    return ItemCatalog.buildItem(itemId).name;
  }

  int buyPrice(ItemId itemId) {
    final def = _shopDefinition(_playerState.currentEntityViewId);
    if (def == null) return 0;
    return _shopService.buyPrice(itemId, def);
  }

  int sellPrice(ItemId itemId) {
    return _shopService.sellPrice(itemId);
  }

  bool canAfford(ItemId itemId) {
    return playerCoins() >= buyPrice(itemId);
  }

  bool buy(ShopStockEntry entry) {
    final shop = _currentShop();
    final def = _shopDefinition(_playerState.currentEntityViewId);
    if (shop == null || def == null) return false;

    final bought = _shopService.buyItem(shop, entry, def, _inventoryState);
    if (bought) {
      notifyListeners();
    }
    return bought;
  }

  bool sellOne(ItemId itemId) {
    final sold = _shopService.sellItem(itemId, _inventoryState);
    if (sold) {
      notifyListeners();
    }
    return sold;
  }

  bool sellOneEquipment(String instanceId) {
    final sold = _shopService.sellEquipment(instanceId, _inventoryState);
    if (sold) {
      notifyListeners();
    }
    return sold;
  }

  // stackable inventory the player can sell (everything but coins)
  List<ObjectStack<ItemId>> sellableItems() {
    return [
      for (final entry in _inventoryState.itemMap.entries)
        if (entry.key != ItemId.COINS && entry.value > 0)
          ObjectStack(id: entry.key, count: entry.value),
    ];
  }

  // unique equipment stacks the player can sell
  List<EquipmentItem> sellableEquipment() {
    return List.unmodifiable(_inventoryState.equipment);
  }
}
