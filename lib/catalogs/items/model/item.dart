import 'package:rpg/catalogs/json_codec.dart';
import 'package:rpg/catalogs/items/item_id.dart';

class Item {
  final ItemId id;
  final String name;
  final int value;
  int count = 1;

  Item({required this.id, required this.name, required this.value});

  Map<String, dynamic> toJson() {
    return {
      'runtimeType': 'Item',
      'id': id.name,
      'name': name,
      'value': value,
      'count': count,
    };
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawName = json['name'];
    final rawValue = json['value'];
    final rawCount = json['count'];

    if (rawId is! String) {
      throw FormatException('Missing or invalid "id". Expected String.');
    }
    if (rawName is! String) {
      throw FormatException('Missing or invalid "name". Expected String.');
    }
    if (rawValue is! int) {
      throw FormatException('Missing or invalid "value". Expected int.');
    }
    if (rawCount is! int) {
      throw FormatException('Missing or invalid "count". Expected int.');
    }

    final item = Item(id: parseItemId(rawId), name: rawName, value: rawValue);
    item.count = rawCount;
    return item;
  }
}
