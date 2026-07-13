import 'package:flutter/material.dart';
import '../catalogs/entity_catalog.dart';
import '../data/skill_data.dart';
import '../screens/crafting_screen.dart';
import '../screens/dungeon_screen.dart';
import '../screens/enchanting_screen.dart';
import '../screens/encounter_screen.dart';
import '../screens/shop_screen.dart';

class EntityScreenRouterService {
  // route names let navigator observers identify which screen is on top
  // (and let the saved ui state rebuild the stack on relaunch)
  static const String exploreRouteName = 'explore';
  static const String encounterRouteName = 'encounter';
  static const String craftingRouteName = 'crafting';
  static const String enchantingRouteName = 'enchanting';
  static const String shopRouteName = 'shop';
  static const String dungeonRouteName = 'dungeon';

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
    } else if (enitity is DungeonEntity) {
      Navigator.of(context).push(
        MaterialPageRoute(
          // the dungeon id rides in the route arguments so the saved ui
          // state knows which dungeon screen to restore
          settings: RouteSettings(
            name: dungeonRouteName,
            arguments: enitity.dungeonId,
          ),
          builder: (_) => DungeonScreen(dungeonId: enitity.dungeonId),
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
