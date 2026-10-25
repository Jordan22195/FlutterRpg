import '../catalogs/items/items.dart';
import '../services/equipment_service.dart';
import '../services/inventory_service.dart';
import '../data/equipment_data.dart';
import '../data/gear_set.dart';
import '../data/inventory_data.dart';
import '../data/skill_data.dart';

class EquipmentSystem {
  final InventoryService _inventoryService;
  final EquipmentService _equipmentService;

  EquipmentSystem({
    required InventoryService inventoryService,
    required EquipmentService equipmentService,
  }) : _equipmentService = equipmentService,
       _inventoryService = inventoryService;

  /// Takes one item off the inventory stack and equips it; anything
  /// displaced by the swap goes back into the inventory. [toSlot] picks
  /// between the slots the item accepts (which ring finger it goes on).
  ///
  /// [skillLevels] are the player's levels earned from xp, which the piece's
  /// own requirement is checked against before anything moves — a refused
  /// equip leaves the inventory exactly as it was.
  bool equipItem(
    EquipmentItem item,
    EquipmentData equipmentState,
    InventoryData inventoryState, {
    required Map<SkillId, int> skillLevels,
    ArmorSlots? toSlot,
  }) {
    if (!_equipmentService.meetsRequirement(item, skillLevels)) return false;

    final taken = _inventoryService.takeOneEquipment(
      inventoryState,
      item.instanceId,
    );
    if (taken == null) return false;

    final displaced = _equipmentService.equipItem(
      taken,
      equipmentState,
      toSlot: toSlot,
    );
    if (displaced == null) {
      // couldn't equip; return the item to the inventory
      _inventoryService.addEquipment(inventoryState, taken);
      return false;
    }

    for (final old in displaced) {
      _inventoryService.addEquipment(inventoryState, old);
    }
    return true;
  }

  /// Takes one item off the inventory stack and equips it as the tool
  /// for [skill]; the previous tool goes back into the inventory. Gated on
  /// the tool's own requirement the same way [equipItem] is — a mithril
  /// pickaxe asks for a miner, not a fighter. False when it was refused.
  bool equipTool(
    SkillId skill,
    EquipmentItem item,
    EquipmentData equipmentState,
    InventoryData inventoryState, {
    required Map<SkillId, int> skillLevels,
  }) {
    if (!_equipmentService.meetsRequirement(item, skillLevels)) return false;

    final taken = _inventoryService.takeOneEquipment(
      inventoryState,
      item.instanceId,
    );
    if (taken == null) return false;

    final old = _equipmentService.equipTool(skill, taken, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
    return true;
  }

  void unequipSlot(
    ArmorSlots slot,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final old = _equipmentService.unequipSlot(slot, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
  }

  void unequipTool(
    SkillId skill,
    EquipmentData equipmentState,
    InventoryData inventoryState,
  ) {
    final old = _equipmentService.unequipTool(skill, equipmentState);
    if (old != null) {
      _inventoryService.addEquipment(inventoryState, old);
    }
  }

  /// Changes into [set]: each slot the set fills gets its piece, out of the
  /// bag or off another slot; each slot the set leaves empty is emptied;
  /// everything taken off goes back in the bag. Tools only move when the
  /// set includes them.
  ///
  /// A piece that can't be worn — gone from the bag, too high a level now,
  /// or moved to another slot by the catalog — is left out and its slot
  /// keeps whatever it had. Returns those pieces, so the player can be told.
  List<GearSetSkip> applyGearSet(
    GearSet set,
    EquipmentData equipmentState,
    InventoryData inventoryState, {
    required Map<SkillId, int> skillLevels,
  }) {
    // a place is an ArmorSlots or, for a tool, the SkillId it is worn for
    EquipmentItem? wornAt(Object place) => place is ArmorSlots
        ? equipmentState.armorEquipment[place]
        : equipmentState.equipedTools[place as SkillId];

    final wornPlaces = <Object>[
      ...equipmentState.armorEquipment.keys,
      ...equipmentState.equipedTools.keys,
    ];

    // what the set wants in each place it has a say over; null = empty
    final desired = <Object, GearSetPiece?>{
      for (final slot in equipmentState.armorEquipment.keys)
        slot: set.armor[slot],
      if (set.includesTools)
        for (final skill in {
          ...set.tools.keys,
          ...equipmentState.equipedTools.keys,
        })
          skill: set.tools[skill],
    };

    bool matches(EquipmentItem item, GearSetPiece piece) =>
        item.instanceId == piece.instanceId || item.stackKey == piece.stackKey;

    bool fits(EquipmentItem item, Object place) => place is ArmorSlots
        ? item.armorSlot == place.itemSlot
        : item.armorSlot == ArmorSlots.TOOL;

    // pieces already where the set wants them stay put, and are claimed
    // first so another place can't take them
    final inPlace = <Object>{};
    final claimedWorn = <Object>{};
    for (final entry in desired.entries) {
      final piece = entry.value;
      final worn = wornAt(entry.key);
      if (piece != null && worn != null && matches(worn, piece)) {
        inPlace.add(entry.key);
        claimedWorn.add(entry.key);
      }
    }

    // then everything else is found, by its own id before any identical
    // piece, worn elsewhere before in the bag; a stack of several can hand
    // out one per place
    final bagLeft = [for (final stack in inventoryState.equipment) stack.count];
    final claims = <Object, EquipmentItem>{};
    final skipped = <GearSetSkip>[];
    for (final entry in desired.entries) {
      final place = entry.key;
      final piece = entry.value;
      if (piece == null || inPlace.contains(place)) continue;

      Object? fromPlace;
      int? fromBag;
      for (final byId in const [true, false]) {
        bool hit(EquipmentItem item) => byId
            ? item.instanceId == piece.instanceId
            : item.stackKey == piece.stackKey;
        fromPlace = wornPlaces.cast<Object?>().firstWhere((p) {
          final worn = wornAt(p!);
          return worn != null && !claimedWorn.contains(p) && hit(worn);
        }, orElse: () => null);
        if (fromPlace != null) break;
        for (var i = 0; i < inventoryState.equipment.length; i++) {
          if (bagLeft[i] > 0 && hit(inventoryState.equipment[i])) {
            fromBag = i;
            break;
          }
        }
        if (fromBag != null) break;
      }

      final found = fromPlace != null
          ? wornAt(fromPlace)
          : fromBag != null
          ? inventoryState.equipment[fromBag]
          : null;
      if (found == null) {
        skipped.add(GearSetSkip(piece, GearSetSkipReason.missing));
        continue;
      }
      if (!fits(found, place)) {
        skipped.add(GearSetSkip(piece, GearSetSkipReason.wrongSlot));
        continue;
      }
      if (!_equipmentService.meetsRequirement(found, skillLevels)) {
        skipped.add(
          GearSetSkip(
            piece,
            GearSetSkipReason.locked,
            requirement: _equipmentService.requirementFor(found),
          ),
        );
        continue;
      }
      if (fromPlace != null) claimedWorn.add(fromPlace);
      if (fromBag != null) bagLeft[fromBag]--;
      claims[place] = found;
    }

    // a weapon left out leaves the hands as they are: the set's empty
    // two-hand slot was only empty because the set held a one-hander, so
    // it doesn't strip the two-hander being held now — and the other way
    final skippedPlaces = {
      for (final entry in desired.entries)
        if (entry.value != null &&
            !inPlace.contains(entry.key) &&
            !claims.containsKey(entry.key))
          entry.key,
    };
    bool shielded(Object place) => switch (place) {
      ArmorSlots.WEAPON_1H => skippedPlaces.contains(ArmorSlots.WEAPON_2H),
      ArmorSlots.WEAPON_2H => skippedPlaces.contains(ArmorSlots.WEAPON_1H),
      ArmorSlots.OFFHAND => skippedPlaces.contains(ArmorSlots.WEAPON_2H),
      _ => false,
    };

    // take off whatever is in the way: a place the set empties, a place
    // getting a different piece, and a piece moving to another place. A
    // place whose own piece was left out keeps what it has
    for (final place in wornPlaces) {
      if (wornAt(place) == null || inPlace.contains(place)) continue;
      final emptied =
          desired.containsKey(place) &&
          desired[place] == null &&
          !shielded(place);
      if (emptied || claims.containsKey(place) || claimedWorn.contains(place)) {
        if (place is ArmorSlots) {
          unequipSlot(place, equipmentState, inventoryState);
        } else {
          unequipTool(place as SkillId, equipmentState, inventoryState);
        }
      }
    }

    // everything claimed is in the bag now — a piece taken off may have
    // folded into an identical stack and lost its id, so find it either way
    for (final entry in claims.entries) {
      final claimed = entry.value;
      final inBag = inventoryState.equipment
          .where((s) => s.instanceId == claimed.instanceId)
          .followedBy(inventoryState.equipment.where(claimed.canStackWith))
          .firstOrNull;
      final piece = entry.key is ArmorSlots
          ? set.armor[entry.key]!
          : set.tools[entry.key]!;
      if (inBag == null) {
        skipped.add(GearSetSkip(piece, GearSetSkipReason.missing));
        continue;
      }
      final place = entry.key;
      final equipped = place is ArmorSlots
          ? equipItem(
              inBag,
              equipmentState,
              inventoryState,
              skillLevels: skillLevels,
              toSlot: place,
            )
          : equipTool(
              place as SkillId,
              inBag,
              equipmentState,
              inventoryState,
              skillLevels: skillLevels,
            );
      if (!equipped) {
        skipped.add(GearSetSkip(piece, GearSetSkipReason.wrongSlot));
      }
    }
    return skipped;
  }
}
