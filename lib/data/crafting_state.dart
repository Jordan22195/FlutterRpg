import 'package:rpg/catalogs/entity_catalog.dart';

import 'inventory_data.dart';

class CraftingState {
  CraftingState();
  EntityId craftingEntityId = EntityId.NULL;

  // each crafting entity remembers its own selected recipe; a selection
  // made at the anvil must not show up at the campfire
  Map<EntityId, String> selectedRecipeByEntity = {};

  String activeRecipeId = "";

  InventoryData craftedItems = InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'selectedRecipeByEntity': selectedRecipeByEntity.map(
        (id, recipeId) => MapEntry(id.name, recipeId),
      ),
      'craftingEntityId': craftingEntityId.name,
      'activeRecipeId': activeRecipeId,
      'craftedItems': craftedItems.toJson(),
    };
  }

  factory CraftingState.fromJson(Map<String, dynamic> json) {
    final rawSelectedByEntity = json['selectedRecipeByEntity'];
    final rawActive = json['activeRecipeId'];
    final rawItems = json['craftedItems'];

    if (rawActive is! String) {
      throw FormatException(
        'Missing or invalid "activeRecipeId". Expected String.',
      );
    }

    if (rawItems is! Map<String, dynamic>) {
      throw FormatException(
        'Missing or invalid "craftedItems". Expected object.',
      );
    }

    final state = CraftingState();
    state.activeRecipeId = rawActive;
    state.craftedItems = InventoryData.fromJson(rawItems);

    // tolerated when missing: older saves have no session station
    final rawCraftingEntity = json['craftingEntityId'];
    if (rawCraftingEntity is String) {
      state.craftingEntityId =
          EntityId.values.asNameMap()[rawCraftingEntity] ?? EntityId.NULL;
    }

    // tolerated when missing: older saves stored a single global
    // "selectedRecipeId", which is simply dropped
    if (rawSelectedByEntity is Map<String, dynamic>) {
      for (final entry in rawSelectedByEntity.entries) {
        final id = EntityId.values.asNameMap()[entry.key];
        final recipeId = entry.value;
        if (id != null && recipeId is String) {
          state.selectedRecipeByEntity[id] = recipeId;
        }
      }
    }

    return state;
  }
}
