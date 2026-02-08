import 'package:rpg/data/ObjectStack.dart';

import 'item.dart';

class Inventory {
  Map<Items, int> itemMap = {};

  Inventory({required this.itemMap});

  void addOtherInventory(Inventory otherInv) {
    final iList = otherInv.getObjectStackList();
    for (ObjectStack i in iList) {
      addItems(i.id, i.count);
    }
  }

  void clear() {
    itemMap.clear();
  }

  bool addItems(Items id, int count) {
    itemMap[id] = (itemMap[id] ?? 0) + count;
    return true;
  }

  void removeItems(Items id, int count) {
    if (itemMap[id] == null || itemMap[id]! < count) {
      throw ArgumentError('Not enough items to remove');
    }
    itemMap[id] = itemMap[id]! - count;
    if (itemMap[id] == 0) {
      itemMap.remove(id);
    }
  }

  List<ObjectStack> getObjectStackList() {
    List<ObjectStack> ret = [];
    for (final pair in itemMap.entries) {
      ret.add(ObjectStack(id: pair.key, count: pair.value));
    }
    return ret;
  }

  String getString() {
    final buffer = StringBuffer();
    if (itemMap == null) {
      return "";
    }

    for (final entry in itemMap.entries) {
      buffer.writeln('${entry.key} : ${entry.value}');
    }

    return buffer.toString();
  }

  Map<String, dynamic> toJson() {
    return {
      'items': itemMap.map(
        (key, value) => MapEntry(
          key.name, // enum → string
          value,
        ),
      ),
    };
  }

  factory Inventory.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as Map<String, dynamic>? ?? {};

    return Inventory(
      itemMap: rawItems.map(
        (key, value) => MapEntry(
          Items.values.firstWhere((e) => e.name == key),
          value as int,
        ),
      ),
    );
  }
}
