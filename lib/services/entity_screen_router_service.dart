import 'package:flutter/material.dart';
import '../catalogs/entity_catalog.dart';
import '../screens/crafting_screen.dart';
import '../screens/encounter_screen.dart';

class EntityScreenRouterService {
  // route names let navigator observers identify which screen is on top
  static const String encounterRouteName = 'encounter';
  static const String craftingRouteName = 'crafting';

  final EntityCatalog _entityCatalog;

  EntityScreenRouterService({required EntityCatalog entityCatalog})
    : _entityCatalog = entityCatalog;

  //
  void navigateToEntity(EntityId entityId, BuildContext context) {
    final enitity = _entityCatalog
        .getDefinitionFor(entityId)
        .toEntity(entityId);

    if (enitity is EncounterEntity) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: encounterRouteName),
          builder: (_) => EncounterScreen(),
        ),
      );
    } else if (enitity is CraftingEntity) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: craftingRouteName),
          builder: (_) => CraftingScreen(),
        ),
      );
    }
  }
}
