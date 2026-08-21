import 'package:rpg/catalogs/dungeons/dungeon_id.dart';
import 'package:rpg/catalogs/entities/entity_id.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/utilities/image_resolver.dart';

/// Wires each catalog id enum into [EnumImageProviderLookup], so a widget
/// handed a bare id can render its icon without knowing which enum it is.
///
/// Call once at startup, and in any widget test that renders an icon. Skill
/// icons are registered separately — they come from `SkillController`, not
/// from a catalog.
void registerCatalogIconResolvers() {
  EnumImageProviderLookup.register<ItemId>(ItemId.providerFor);
  EnumImageProviderLookup.register<EntityId>(EntityId.providerFor);
  EnumImageProviderLookup.register<DungeonId>(DungeonId.providerFor);
}
