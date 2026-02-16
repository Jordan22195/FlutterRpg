import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:rpg/data/entity.dart';
import 'package:rpg/data/skill.dart';
import 'package:rpg/data/item.dart';
import '../utilities/image_resolver.dart';

enum ZoneLocationId { NULL, ANVIL, INN, SHOP, POND_1, CAMPFIRE }

class ZoneLocation {
  final String name;
  final String iconAsset;
  final ZoneLocationId id;
  final Enum typeForIcon;

  ZoneLocation({
    required this.id,
    required this.name,
    required this.iconAsset,
    required this.typeForIcon,
  });
}

class CraftingLocation extends ZoneLocation {
  final Skills craftingSkill;

  CraftingLocation({
    required super.name,
    required super.iconAsset,
    required super.id,
    required this.craftingSkill,
  }) : super(typeForIcon: craftingSkill);
}

// location exists while campfire buff is active, and disappears when buff expires. Icon is based on the fire item used to create the buff.
class CampfireLocation extends CraftingLocation {
  Items fireId;
  CampfireLocation({required super.id, required this.fireId})
    : super(
        name: ItemController.definitionFor(fireId)?.name ?? "Error",
        craftingSkill: Skills.COOKING,
        iconAsset:
            ItemController.definitionFor(fireId)?.iconAsset ??
            'assets/icons/campfire.png',
      );
}

class FishingLocation extends ZoneLocation {
  final Entities fishingSpotEntity;

  FishingLocation({
    required super.name,
    required super.id,
    required this.fishingSpotEntity,
  }) : super(
         typeForIcon: Skills.FISHING,
         iconAsset:
             EntityController.definitionFor(fishingSpotEntity)?.iconAsset ??
             'assets/icons/anvil.png',
       ) {
    print("object created with icon ${iconAsset}");
  }
}

class ZoneLocationController {
  static Map<ZoneLocationId, ZoneLocation> locations = {
    ZoneLocationId.ANVIL: CraftingLocation(
      craftingSkill: Skills.BLACKSMITHING,
      name: 'Anvil',
      id: ZoneLocationId.ANVIL,
      iconAsset: 'assets/icons/anvil.png',
    ),

    ZoneLocationId.POND_1: FishingLocation(
      fishingSpotEntity: Entities.TRANQUIL_POND,
      id: ZoneLocationId.POND_1,
      name: 'Tranquil Pond',
    ),

    ZoneLocationId.CAMPFIRE: CampfireLocation(
      id: ZoneLocationId.CAMPFIRE,
      fireId: Items.BASIC_CAMPFIRE,
    ),
  };

  static ZoneLocation definitionFor(ZoneLocationId id) {
    return locations[id] ??
        ZoneLocation(
          id: ZoneLocationId.NULL,
          name: "",
          iconAsset: "",
          typeForIcon: ZoneLocationId.NULL,
        );
  }

  static void init() {
    // Register the image resolver for Items.
    EnumImageProviderLookup.register<ZoneLocationId>(
      ZoneLocationController.imageProviderFor,
    );
  }

  static ImageProvider? imageProviderFor(dynamic objectId) {
    {
      if (objectId is! ZoneLocationId) {
        return null;
      }
      final location =
          locations[objectId] ??
          ZoneLocation(
            id: ZoneLocationId.NULL,
            name: "",
            iconAsset: "",
            typeForIcon: ZoneLocationId.NULL,
          );
      return AssetImage(location.iconAsset);
    }
  }
}
