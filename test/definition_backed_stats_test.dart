import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/inventory_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/game_session.dart';

/// Instances read their stats off their definition, and a save carries only
/// what is unique to the instance.
///
/// The point is tuning: before this, an entity or item wrote every stat it
/// had into the save and read it straight back, so a catalog change reached
/// nothing that was already standing in a zone or sitting in a bag. The
/// regression test for that is 'a legacy save's stale stats are ignored'
/// below — everything else is the model that makes it true.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  T roundTrip<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) parse,
  ) => parse(jsonDecode(jsonEncode(json)) as Map<String, dynamic>);

  group('stats are read off the definition', () {
    test('an entity reports what its definition says', () {
      final chicken = EntityId.CHICKEN.build() as CombatEntity;
      final def = EntityId.CHICKEN.definition as CombatEntityDefinition;

      expect(chicken.name, def.name);
      expect(chicken.rarity, def.rarity);
      expect(chicken.defence, def.defence);
      expect(chicken.maxHitPoints, def.hitpoints);
      expect(chicken.attack, def.attack);
      expect(chicken.attackInterval, def.attackInterval);
      expect(chicken.level, def.level);
      expect(chicken.entityType, def.entityType);
    });

    test('equipment reports what its definition says', () {
      final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
      final def = ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;

      expect(helmet.name, def.name);
      expect(helmet.value, def.value);
      expect(helmet.armorSlot, def.armorSlot);
      expect(helmet.skillBonus, def.skillBonus);

      final pickaxe = ItemId.COPPER_PICKAXE.build() as WeaponItem;
      final pickaxeDef =
          ItemId.COPPER_PICKAXE.definition as WeaponItemDefinition;
      expect(pickaxe.actionInterval, pickaxeDef.actionInterval);
    });

    test('a fire is worth its definition times the logs that lit it', () {
      final def = ItemId.COOKFIRE.definition as FireItemDefinition;
      final fire = ItemId.COOKFIRE.build() as FireItem;

      expect(fire.duration, def.duration);
      expect(fire.canCook, def.canCook);
      expect(fire.skillBonus, def.skillBonus);

      fire.fuelUnits = 4;
      expect(fire.duration, def.duration * 4);
    });

    test('the class comes from the definition, not from a stored type', () {
      // every id builds the class its definition calls for, which is what
      // lets deserialization drop the runtimeType it used to store
      expect(EntityId.CHICKEN.build(), isA<CombatEntity>());
      expect(EntityId.TREE.build(), isA<EncounterEntity>());
      expect(EntityId.TRANQUIL_POND.build(), isA<FishingEntity>());
      expect(EntityId.ANVIL.build(), isA<CraftingEntity>());
      expect(ItemId.COPPER_PICKAXE.build(), isA<WeaponItem>());
      expect(ItemId.COPPER_HELMET.build(), isA<EquipmentItem>());
      expect(ItemId.COPPER_ORE.build(), isA<Item>());
    });
  });

  group('a round trip carries the instance state and nothing else', () {
    test('an entity keeps its count and its current hp', () {
      final chicken = EntityId.CHICKEN.build() as CombatEntity;
      chicken.count = 7;
      chicken.hitpoints = chicken.maxHitPoints - 3;

      final restored =
          roundTrip(chicken.toJson(), Entity.fromJson) as CombatEntity;

      expect(restored.id, EntityId.CHICKEN);
      expect(restored.count, 7);
      expect(restored.hitpoints, chicken.maxHitPoints - 3);
      // and nothing but the id and that state was written
      expect(
        chicken.toJson().keys,
        unorderedEquals(['id', 'count', 'hitpoints']),
      );
    });

    test('equipment keeps its instance id, quality and enchant', () {
      final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
      helmet.count = 3;
      helmet.quality = Rarity.EPIC;
      helmet.enchantName = 'Boar';
      helmet.enchantBonus = {SkillId.STRENGTH: 4};

      final restored =
          roundTrip(helmet.toJson(), Item.fromJson) as EquipmentItem;

      expect(restored.id, ItemId.COPPER_HELMET);
      expect(restored.count, 3);
      expect(restored.instanceId, helmet.instanceId);
      expect(restored.quality, Rarity.EPIC);
      expect(restored.enchantName, 'Boar');
      expect(restored.enchantBonus, {SkillId.STRENGTH: 4});
      expect(restored.displayName, helmet.displayName);
      expect(restored.stackKey, helmet.stackKey);
      expect(
        helmet.toJson().keys,
        unorderedEquals([
          'id',
          'count',
          'instanceId',
          'quality',
          'enchantName',
          'enchantBonus',
        ]),
      );
    });
  });

  group('tuning reaches what is already instantiated', () {
    test("a legacy save's stale stats are ignored", () {
      // exactly the shape older saves wrote: every stat materialized onto
      // the instance, and all of it wrong for the catalog as it stands now.
      // reading these back is the bug this model exists to fix.
      final legacyEntity = <String, dynamic>{
        'runtimeType': 'CombatEntity',
        'id': 'CHICKEN',
        'name': 'Chicken (as it was tuned in 2025)',
        'entityType': 'ATTACK',
        'defence': 999,
        'count': 4,
        'hitpoints': 2,
        'maxHitPoints': 4242,
        'attack': 999,
        'attackInterval': 99.0,
      };

      final restored = Entity.fromJson(legacyEntity) as CombatEntity;
      final def = EntityId.CHICKEN.definition as CombatEntityDefinition;

      expect(restored.name, def.name);
      expect(restored.defence, def.defence);
      expect(restored.attack, def.attack);
      expect(restored.attackInterval, def.attackInterval);
      expect(restored.maxHitPoints, def.hitpoints);
      // the runtime state it really did own still comes back
      expect(restored.count, 4);
      expect(restored.hitpoints, 2);

      final legacyHelmet = <String, dynamic>{
        'runtimeType': 'EquipmentItem',
        'id': 'COPPER_HELMET',
        'name': 'Copper Helmet (as it was tuned in 2025)',
        'value': 9999,
        'count': 1,
        'armorSlot': 'HEAD',
        'skillBonus': {'DEFENCE': 999},
        'instanceId': '[#legacy]',
        'quality': 'RARE',
        'enchantName': 'Owl',
        'enchantBonus': {'DEFENCE': 2},
      };

      final helmet = Item.fromJson(legacyHelmet) as EquipmentItem;
      final helmetDef =
          ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;

      expect(helmet.name, helmetDef.name);
      expect(helmet.value, helmetDef.value);
      expect(helmet.skillBonus, helmetDef.skillBonus);
      // and the roll that really was this piece's own survives
      expect(helmet.instanceId, '[#legacy]');
      expect(helmet.quality, Rarity.RARE);
      expect(helmet.enchantBonus, {SkillId.DEFENCE: 2});
    });

    test(
      'current hp above a lowered maximum clamps instead of overflowing',
      () {
        final chicken = EntityId.CHICKEN.build() as CombatEntity;
        final max = chicken.maxHitPoints;

        // what a save written before the definition was cut down looks like
        chicken.hitpoints = max + 500;

        expect(chicken.hitpoints, max);
        expect(
          chicken.hitpoints / chicken.maxHitPoints,
          lessThanOrEqualTo(1.0),
        );
      },
    );

    test('a legacy weapon stored as a plain item comes back a weapon', () {
      // the stored runtimeType is not consulted, so an item the catalog has
      // since promoted resolves to the class its definition now calls for
      final restored = Item.fromJson({
        'runtimeType': 'Item',
        'id': 'COPPER_PICKAXE',
        'count': 1,
      });

      expect(restored, isA<WeaponItem>());
      expect(
        (restored as WeaponItem).actionInterval,
        (ItemId.COPPER_PICKAXE.definition as WeaponItemDefinition)
            .actionInterval,
      );
    });
  });

  group('the whole save loads', () {
    test('a legacy inventory and worn gear survive the load', () {
      final factory = GameSessionFactory();
      final save = factory.newGame(factory.catalog1());

      final raw = jsonDecode(jsonEncode(save.toJson())) as Map<String, dynamic>;
      // splice in the legacy shapes the reader has to tolerate
      raw['inventoryData'] = {
        'items': {'COPPER_ORE': 12},
        'equipment': [
          {
            'runtimeType': 'WeaponItem',
            'id': 'COPPER_PICKAXE',
            'name': 'stale',
            'value': 1,
            'count': 1,
            'armorSlot': 'TOOL',
            'skillBonus': {'MINING': 99},
            'actionIntervalMs': 999999,
            'instanceId': '[#legacy]',
            'quality': 'LEGENDARY',
          },
        ],
      };

      final restored = SaveGameData.fromJson(raw);
      final pickaxe = restored.inventoryData.equipment.single as WeaponItem;

      expect(restored.inventoryData.itemMap[ItemId.COPPER_ORE], 12);
      expect(pickaxe.instanceId, '[#legacy]');
      expect(pickaxe.quality, Rarity.LEGENDARY);
      expect(
        pickaxe.actionInterval,
        (ItemId.COPPER_PICKAXE.definition as WeaponItemDefinition)
            .actionInterval,
      );
      expect(
        pickaxe.skillBonus,
        (ItemId.COPPER_PICKAXE.definition as EquipmentItemDefinition)
            .skillBonus,
      );
    });

    test('an equipped item round trips through EquipmentData', () {
      final equipment = EquipmentData();
      final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
      helmet.quality = Rarity.UNCOMMON;
      equipment.armorEquipment[ArmorSlots.HEAD] = helmet;

      final restored = EquipmentData.fromJson(
        jsonDecode(jsonEncode(equipment.toJson())) as Map<String, dynamic>,
      );
      final worn = restored.armorEquipment[ArmorSlots.HEAD]!;

      expect(worn.quality, Rarity.UNCOMMON);
      expect(worn.instanceId, helmet.instanceId);
      expect(worn.effectiveSkillBonus, helmet.effectiveSkillBonus);
    });

    test('an inventory of stacked equipment round trips', () {
      final inventory = InventoryData(itemMap: {});
      final first = ItemId.COPPER_HELMET.build() as EquipmentItem;
      first.count = 2;
      inventory.equipment.add(first);

      final restored = InventoryData.fromJson(
        jsonDecode(jsonEncode(inventory.toJson())) as Map<String, dynamic>,
      );

      expect(restored.equipment.single.count, 2);
      expect(restored.equipment.single.stackKey, first.stackKey);
    });
  });
}
