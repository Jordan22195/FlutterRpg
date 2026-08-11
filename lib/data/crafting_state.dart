import 'package:rpg/catalogs/entity_catalog.dart';

import 'inventory_data.dart';
import 'package:rpg/catalogs/zone_catalog.dart';
import 'skill_data.dart';

class CraftingState {
  CraftingState();
  EntityId craftingEntityId = EntityId.NULL;

  // the zone that station stands in. an EntityId is a kind, not an
  // instance: a firepit sits in several zones, so the id alone would let a
  // craft running at one of them claim every other firepit's screen
  ZoneId craftingZoneId = ZoneId.NULL;

  // each crafting entity remembers its own selected recipe; a selection
  // made at the anvil must not show up at the firepit. the inner map is
  // keyed by skill because a station can offer more than one: a firepit
  // holds a fire selection and a cooking selection at the same time
  Map<EntityId, Map<SkillId, String>> selectedRecipeByEntity = {};

  // selections read from a save that predates the per-skill nesting. the
  // skill they belong to is a recipe catalog lookup, which this class has
  // no reference to, so GameSessionFactory files them and clears this.
  Map<EntityId, String> legacySelections = {};

  String activeRecipeId = "";

  InventoryData craftedItems = InventoryData(itemMap: {});

  Map<String, dynamic> toJson() {
    return {
      'selectedRecipeByEntity': selectedRecipeByEntity.map(
        (id, bySkill) => MapEntry(
          id.name,
          bySkill.map((skill, recipeId) => MapEntry(skill.name, recipeId)),
        ),
      ),
      'craftingEntityId': craftingEntityId.name,
      'craftingZoneId': craftingZoneId.name,
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

    // tolerated when missing: saves predating per-zone stations
    final rawCraftingZone = json['craftingZoneId'];
    if (rawCraftingZone is String) {
      state.craftingZoneId =
          ZoneId.values.asNameMap()[rawCraftingZone] ?? ZoneId.NULL;
    }

    // tolerated when missing: the oldest saves stored a single global
    // "selectedRecipeId", which is simply dropped
    if (rawSelectedByEntity is Map<String, dynamic>) {
      for (final entry in rawSelectedByEntity.entries) {
        final id = EntityId.values.asNameMap()[entry.key];
        if (id == null) continue;

        final value = entry.value;

        // legacy flat shape: one recipe id per entity, no skill
        if (value is String) {
          state.legacySelections[id] = value;
          continue;
        }

        if (value is! Map) continue;
        for (final bySkill in value.entries) {
          final skill = SkillId.values.asNameMap()[bySkill.key];
          final recipeId = bySkill.value;
          if (skill != null && recipeId is String) {
            (state.selectedRecipeByEntity[id] ??= {})[skill] = recipeId;
          }
        }
      }
    }

    return state;
  }
}
