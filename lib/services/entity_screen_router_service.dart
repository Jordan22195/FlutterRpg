import 'package:flutter/material.dart';
import '../catalogs/entity_catalog.dart';
import '../data/skill_data.dart';
import '../screens/crafting_screen.dart';
import '../screens/enchanting_screen.dart';
import '../screens/encounter_screen.dart';
import '../screens/shop_screen.dart';

class EntityScreenRouterService {
  // route names let navigator observers identify which screen is on top
  static const String encounterRouteName = 'encounter';
  static const String craftingRouteName = 'crafting';
  static const String enchantingRouteName = 'enchanting';
  static const String shopRouteName = 'shop';

  final EntityCatalog _entityCatalog;

  EntityScreenRouterService({required EntityCatalog entityCatalog})
    : _entityCatalog = entityCatalog;

  //
  void navigateToEntity(EntityId entityId, BuildContext context) {
    final enitity = _entityCatalog
        .getDefinitionFor(entityId)
        .toEntity(entityId);

    if (enitity is ShopEntity) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: shopRouteName),
          builder: (_) => const ShopScreen(),
        ),
      );
    } else if (enitity is EncounterEntity) {
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: encounterRouteName),
          builder: (_) => EncounterScreen(),
        ),
      );
    } else if (enitity is CraftingEntity) {
      // the enchanting bench has its own screen (disenchant/enchant
      // instances rather than recipe crafting)
      if (enitity.craftingSkill == SkillId.ENCHANTING) {
        Navigator.of(context).push(
          MaterialPageRoute(
            settings: const RouteSettings(name: enchantingRouteName),
            builder: (_) => const EnchantingScreen(),
          ),
        );
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          settings: const RouteSettings(name: craftingRouteName),
          builder: (_) => CraftingScreen(),
        ),
      );
    }
  }
}
