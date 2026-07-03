import 'package:flutter/material.dart';
import '../catalogs/entity_catalog.dart';
import '../screens/crafting_screen.dart';
import '../screens/encounter_screen.dart';

class EntityScreenRouterService {
  final EntityCatalog _entityCatalog;

  EntityScreenRouterService({required EntityCatalog entityCatalog})
    : _entityCatalog = entityCatalog;

  //
  void navigateToEntity(EntityId entityId, BuildContext context) {
    final enitity = _entityCatalog
        .getDefinitionFor(entityId)
        .toEntity(entityId);

    if (enitity is EncounterEntity) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => EncounterScreen()));
    } else if (enitity is CraftingEntity) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => CraftingScreen()));
    }
  }
}
