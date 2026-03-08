import 'package:flutter/widgets.dart';
import 'package:rpg/catalogs/entity_catalog.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/catalogs/item_catalog.dart';
import '../utilities/image_resolver.dart';

enum LocationId { NULL, ANVIL, INN, SHOP, POND_1, CAMPFIRE }

class ZoneLocation {
  final String name;
  final String iconAsset;
  final LocationId id;
  final Enum typeForIcon;

  ZoneLocation({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.typeForIcon,
  });
}

class CraftingLocation extends ZoneLocation {
  final SkillId craftingSkill;

  CraftingLocation({
    required super.name,
    required super.iconAsset,
    required super.id,
    required this.craftingSkill,
  }) : super(typeForIcon: craftingSkill);
}

// location exists while campfire buff is active, and disappears when buff expires. Icon is based on the fire item used to create the buff.
class CampfireLocation extends CraftingLocation {
  ItemId fireId;
  CampfireLocation({required super.id, required this.fireId})
    : super(
        name: ItemCatalog.definitionFor(fireId)?.name ?? "Error",
        craftingSkill: SkillId.COOKING,
        iconAsset:
            ItemCatalog.definitionFor(fireId)?.iconAsset ??
            'assets/icons/campfire.png',
      );
}

class FishingLocation extends ZoneLocation {
  final EntityId fishingSpotEntity;

  FishingLocation({
    required super.name,
    required super.id,
    required this.fishingSpotEntity,
  }) : super(
         typeForIcon: SkillId.FISHING,
         iconAsset:
             EntityCatalog.definitionFor(fishingSpotEntity)?.iconAsset ??
             'assets/icons/anvil.png',
       ) {}
}

class LocationCatalog {
  static Map<LocationId, ZoneLocation> locations = {
    LocationId.ANVIL: CraftingLocation(
      craftingSkill: SkillId.BLACKSMITHING,
      name: 'Anvil',
      id: LocationId.ANVIL,
      iconAsset: 'assets/icons/anvil.png',
    ),

    LocationId.POND_1: FishingLocation(
      fishingSpotEntity: EntityId.TRANQUIL_POND,
      id: LocationId.POND_1,
      name: 'Tranquil Pond',
    ),

    LocationId.CAMPFIRE: CampfireLocation(
      id: LocationId.CAMPFIRE,
      fireId: ItemId.BASIC_CAMPFIRE,
    ),
  };

  static ZoneLocation definitionFor(LocationId id) {
    return locations[id] ??
        ZoneLocation(
          id: LocationId.NULL,
          name: "",
          iconAsset: "",
          typeForIcon: LocationId.NULL,
        );
  }

  static void init() {
    // Register the image resolver for Items.
    EnumImageProviderLookup.register<LocationId>(
      LocationCatalog.imageProviderFor,
    );
  }

  static ImageProvider? imageProviderFor(dynamic objectId) {
    {
      if (objectId is! LocationId) {
        return null;
      }
      final location =
          locations[objectId] ??
          ZoneLocation(
            id: LocationId.NULL,
            name: "",
            iconAsset: "",
            typeForIcon: LocationId.NULL,
          );
      return AssetImage(location.iconAsset);
    }
  }
}
