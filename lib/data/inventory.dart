import 'dart:math';

import 'package:rpg/data/ObjectStack.dart';
import 'package:rpg/data/armor_equipment.dart';
import '../data/item.dart';

import 'item.dart';

class Inventory {
  Map<Items, int> itemMap = {};

  Inventory({required this.itemMap});

  List<Items> getItemsListForEquipmentSlot(ArmorSlots slot) {
    // This is a placeholder implementation. You can replace it with actual logic based on your game's design.
    List<Items> itemsForSlot = [];
    for (MapEntry entry in itemMap.entries) {
      final def = ItemController.definitionFor(entry.key);
      print(
        "Checking item ${entry.key} for slot ${slot.name}: definition is ${def.runtimeType}",
      );
      if (def is EquipmentItemDefition && def.armorSlot == slot) {
        itemsForSlot.add(entry.key);
      }
    }
    return itemsForSlot;
  }

  int countOf(Items id) {
    return itemMap[id] ?? 0;
  }

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
        (key, count) => MapEntry(
          key.name, // enum → string
          count,
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
