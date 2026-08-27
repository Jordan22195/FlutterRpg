import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/catalogs/items/model/item.dart';

class ItemDefinition {
  final String name;
  final int value;
  final String? description;

  /// Asset path like: assets/images/items/copper_ore.png
  final String? iconAsset;

  /// XP granted when this item is obtained (e.g., fishing catch).
  /// Always non-null; if a null value is provided (e.g., from JSON/dynamic), it defaults to 0.
  final int xpValue;

  /// The quality this item is defined at. Defaults to common, which is the
  /// identity — a 1.0 stat multiplier and an empty label — so an item that
  /// does not care about quality reads exactly as it did before.
  ///
  /// Most quality is *rolled*, not declared: crafting rolls it against the
  /// player's skill and writes it onto the runtime [EquipmentItem]. This is
  /// for the other case — an item that is a particular quality by
  /// definition, such as a fixed reward or a named drop.
  final Rarity quality;

  const ItemDefinition({
    required this.name,
    required this.value,
    this.description,
    this.iconAsset,
    this.quality = Rarity.COMMON,
    int? xpValue,
  }) : xpValue = xpValue ?? 0;

  /// A variant of this definition. Definitions are `const` and shared by
  /// every consumer, so anything that needs a tweaked one builds a new
  /// value here rather than writing through a field. For a *mutable*
  /// object, call [toItem] (or `ItemId.build()`) instead — that is what
  /// runtime instances are for.
  ItemDefinition copyWith({
    String? name,
    int? value,
    String? description,
    String? iconAsset,
    int? xpValue,
    Rarity? quality,
  }) {
    return ItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      xpValue: xpValue ?? this.xpValue,
      quality: quality ?? this.quality,
    );
  }

  Item toItem(ItemId id) =>
      Item(id: id, name: name, value: value, quality: quality);
}
