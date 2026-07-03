import 'package:rpg/catalogs/entity_catalog.dart';

import 'inventory_data.dart';

class CraftingState {
  CraftingState();
  EntityId craftingEntityId = EntityId.NULL;
  String selectedRecipeId = "";
  String activeRecipeId = "";

  InventoryData craftedItems = InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'selectedRecipeId': selectedRecipeId,
      'activeRecipeId': activeRecipeId,
      'craftedItems': craftedItems.toJson(),
    };
  }

  factory CraftingState.fromJson(Map<String, dynamic> json) {
    final rawSelected = json['selectedRecipeId'];
    final rawActive = json['activeRecipeId'];
    final rawItems = json['craftedItems'];

    if (rawSelected is! String) {
      throw FormatException(
        'Missing or invalid "selectedRecipeId". Expected String.',
      );
    }

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
    state.selectedRecipeId = rawSelected;
    state.activeRecipeId = rawActive;
    state.craftedItems = InventoryData.fromJson(rawItems);

    return state;
  }
}
