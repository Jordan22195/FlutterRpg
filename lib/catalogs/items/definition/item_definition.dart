import 'package:rpg/catalogs/items/item_id.dart';
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

  const ItemDefinition({
    required this.name,
    required this.value,
    this.description,
    this.iconAsset,
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
  }) {
    return ItemDefinition(
      name: name ?? this.name,
      value: value ?? this.value,
      description: description ?? this.description,
      iconAsset: iconAsset ?? this.iconAsset,
      xpValue: xpValue ?? this.xpValue,
    );
  }

  Item toItem(ItemId id) => Item(id: id, name: name, value: value);
}
