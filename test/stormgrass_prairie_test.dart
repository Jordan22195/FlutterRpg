import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/enchantments/enchantments.dart';
import 'package:rpg/catalogs/entities/combat_type.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/data/alchemy_recipes.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';

/// Stormgrass Prairie is the rung above the swamp: open grassland with no
/// trees to cut, monsters at 55 and 89, and a dungeon whose bosses stand at
/// 144. It is the only place mithril is mined, the first adamantite, and
/// the source of the greater and utility potions.
///
/// Its enum is still FOOTHILLS — the name is the save format — so this
/// file is where the zone's new identity is pinned down.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final prairie = ZoneId.FOOTHILLS.definition;
  final reach = DungeonId.TEMPEST_REACH.definition;

  WeightedDropTableEntry<EntityId>? entryFor(ZoneId zone, EntityId entity) {
    for (final e in zone.definition.discoverableEntities) {
      if (e.id == entity) return e;
    }
    return null;
  }

  CombatEntityDefinition combat(EntityId id) =>
      id.definition as CombatEntityDefinition;
  int levelOf(EntityId id) => combat(id).level;

  /// Every item an encounter entity can drop, bonus rolls included.
  Set<ItemId> dropsOf(EntityId id) {
    final def = id.definition as EncounterEntityDefinition;
    return {
      ...def.itemDrops.flattened.map((d) => d.id),
      for (final roll in def.bonusDrops)
        ...roll.entries.flattened.map((d) => d.id),
    };
  }

  group('Stormgrass Prairie', () {
    test('sits beyond the swamp, which is how you get there', () {
      final graph = ZoneTravelGraph();

      expect(ZoneTravelGraph.travelHops(ZoneId.SWAMP, ZoneId.FOOTHILLS), 1);
      expect(
        ZoneTravelGraph.travelPath(ZoneId.TUTORIAL_FARM, ZoneId.FOOTHILLS),
        [
          ZoneId.TUTORIAL_FARM,
          ZoneId.SOUTHWOOD_FOREST,
          ZoneId.SOUTH_HAVEN,
          ZoneId.SWAMP,
          ZoneId.FOOTHILLS,
        ],
      );
      expect(ZoneTravelGraph.isFreeZone(ZoneId.FOOTHILLS), isFalse);
      expect(
        graph.travelTime(ZoneId.SWAMP, ZoneId.FOOTHILLS),
        greaterThan(Duration.zero),
      );
    });

    test('is drawn on the world map, inside the canvas', () {
      final centre = zoneNodeCenter(ZoneId.FOOTHILLS);
      expect(centre, isNotNull, reason: 'the zone needs a map node');
      expect(centre!.dx, inInclusiveRange(0, kWorldMapSize.width));
      expect(centre.dy, inInclusiveRange(0, kWorldMapSize.height));
    });

    test('goes by its new name', () {
      expect(prairie.name, 'Stormgrass Prairie');
    });

    test('outranks the swamp the road reaches it through', () {
      expect(
        prairie.explorationLevel,
        greaterThan(ZoneId.SWAMP.definition.explorationLevel),
      );
      expect(prairie.xpPerExplore, greaterThan(0));
    });

    test('has a firepit and the way into Tempest Reach', () {
      expect(prairie.permanentEntities, contains(EntityId.FIREPIT));
      expect(
        prairie.permanentEntities,
        contains(EntityId.TEMPEST_REACH_ENTRANCE),
      );
    });

    test('holds the prairie roster and none of the old foothills one', () {
      for (final id in [
        EntityId.ORC,
        EntityId.RATTLESNAKE,
        EntityId.SABERTOOTH,
        EntityId.CENTAUR,
        EntityId.DUST_DEVIL,
      ]) {
        expect(
          entryFor(ZoneId.FOOTHILLS, id),
          isNotNull,
          reason: '${id.name} should live on the prairie',
        );
      }
      for (final id in [
        EntityId.HARPY,
        EntityId.IMP,
        EntityId.TROLL,
        EntityId.HILL_GIANT,
      ]) {
        expect(
          entryFor(ZoneId.FOOTHILLS, id),
          isNull,
          reason: '${id.name} was cut from the zone',
        );
      }
    });

    test('its monsters stand at 55 and 89', () {
      expect(levelOf(EntityId.ORC), 55);
      expect(levelOf(EntityId.RATTLESNAKE), 55);
      expect(levelOf(EntityId.SABERTOOTH), 89);
      expect(levelOf(EntityId.CENTAUR), 89);
      expect(levelOf(EntityId.DUST_DEVIL), 89);
    });

    test('every orc shares one archetype, the 89 orc its uncommon', () {
      expect(
        combat(EntityId.ORC_UNCOMMON).archetype,
        combat(EntityId.ORC).archetype,
      );
      expect(levelOf(EntityId.ORC_UNCOMMON), 89);
    });

    test('the dust devil fights like a caster', () {
      expect(combat(EntityId.DUST_DEVIL).combatType, CombatType.CLOTH_DPS);
    });

    test('the dust devil waits well past the zone door', () {
      expect(
        entryFor(ZoneId.FOOTHILLS, EntityId.DUST_DEVIL)!.unlockLevel,
        greaterThan(prairie.explorationLevel),
      );
    });

    test('has no trees to cut', () {
      for (final e in prairie.discoverableEntities) {
        final def = e.id.definition;
        if (def is! EncounterEntityDefinition) continue;
        expect(
          def.entityType,
          isNot(SkillId.WOODCUTTING),
          reason: '${e.id.name} is a tree on the treeless prairie',
        );
      }
    });

    test('grows bluestem, the greater potions\' combat herb', () {
      // sweetgrass's utility potions moved onto the ladder
      expect(entryFor(ZoneId.FOOTHILLS, EntityId.SWEETGRASS), isNull);
      expect(entryFor(ZoneId.FOOTHILLS, EntityId.BLUESTEM), isNotNull);
      expect(dropsOf(EntityId.BLUESTEM), {ItemId.BLUESTEM});
    });
  });

  group('the prairie monsters drop their reagents', () {
    const families = {
      EntityId.ORC: ReagentFamily.HORN,
      EntityId.RATTLESNAKE: ReagentFamily.VENOM,
      EntityId.SABERTOOTH: ReagentFamily.FANG,
      EntityId.CENTAUR: ReagentFamily.HORN,
      EntityId.DUST_DEVIL: ReagentFamily.ICHOR,
    };

    for (final MapEntry(key: monster, value: family) in families.entries) {
      test('${monster.name} drops a ${family.name} part', () {
        final part = combat(monster).reagentDrop!.entries.single.id;
        expect((part.definition as ReagentPartDefinition).family, family);
      });
    }

    test('the rattlesnake keeps its venom gland for the alchemist', () {
      expect(dropsOf(EntityId.RATTLESNAKE), contains(ItemId.VENOM_GLAND));
    });

    test('an orc can carry steel kit, on a tenth of kills', () {
      final rolls = combat(EntityId.ORC).bonusDrops;
      expect(rolls, hasLength(1));
      expect(rolls.single.chance, 0.1);
      final steel = rolls.single.entries.flattened.map((d) => d.id);
      expect(steel, isNotEmpty);
      for (final id in steel) {
        expect(id.name, startsWith('STEEL_'));
      }
    });

    test('the dust devil feeds enchanting', () {
      expect(dropsOf(EntityId.DUST_DEVIL), contains(ItemId.ENCHANTING_ESSENCE));
    });
  });

  group('mining', () {
    test('the mithril vein is here, and it is tier 4 mining', () {
      expect(entryFor(ZoneId.FOOTHILLS, EntityId.MITHRIL_VEIN), isNotNull);

      final coal = EntityId.COAL_VEIN.definition as EncounterEntityDefinition;
      final mithril =
          EntityId.MITHRIL_VEIN.definition as EncounterEntityDefinition;

      expect(mithril.entityType, SkillId.MINING);
      expect(
        mithril.defence,
        greaterThan(coal.defence),
        reason: 'mithril is the rung above the darkwood coal',
      );
    });

    test('the mithril vein drops the ore it is named for', () {
      expect(dropsOf(EntityId.MITHRIL_VEIN), contains(ItemId.MITHRIL_ORE));
    });

    test('and nothing else in the game yields mithril ore', () {
      final sources = <String>[];
      for (final id in EntityId.values) {
        if (id.definition is! EncounterEntityDefinition) continue;
        if (dropsOf(id).contains(ItemId.MITHRIL_ORE)) sources.add(id.name);
      }
      expect(sources, ['MITHRIL_VEIN']);
    });

    test('adamantite is the rare find past it', () {
      final entry = entryFor(ZoneId.FOOTHILLS, EntityId.ADAMANTITE_VEIN);
      expect(entry, isNotNull);
      expect(
        entry!.weight,
        lessThan(entryFor(ZoneId.FOOTHILLS, EntityId.MITHRIL_VEIN)!.weight),
      );

      final mithril =
          EntityId.MITHRIL_VEIN.definition as EncounterEntityDefinition;
      final adamant =
          EntityId.ADAMANTITE_VEIN.definition as EncounterEntityDefinition;
      expect(adamant.entityType, SkillId.MINING);
      expect(adamant.defence, greaterThan(mithril.defence));
      expect(
        dropsOf(EntityId.ADAMANTITE_VEIN),
        contains(ItemId.ADAMANTITE_ORE),
      );
    });

    test('both ores smelt, and their bars forge every piece', () {
      final recipes = RecipeCatalog();
      CraftingRecipe? making(ItemId item) {
        for (final r in recipes.recipes) {
          if (r.output.any((o) => o.id == item)) return r;
        }
        return null;
      }

      const tiers = {
        'MITHRIL_': (ItemId.MITHRIL_ORE, ItemId.MITHRIL_BAR),
        'ADAMANT_': (ItemId.ADAMANTITE_ORE, ItemId.ADAMANTITE_BAR),
      };
      for (final MapEntry(key: prefix, value: (ore, bar)) in tiers.entries) {
        final smelt = making(bar);
        expect(smelt, isNotNull, reason: 'nothing smelts ${bar.name}');
        expect(smelt!.inputs.keys, contains(ore));

        final gear = ItemId.values.where(
          (i) => i.name.startsWith(prefix) && i != bar && i != ore,
        );
        expect(gear, isNotEmpty);
        for (final item in gear) {
          expect(
            making(item),
            isNotNull,
            reason: 'nothing forges ${item.name}',
          );
        }
      }
    });
  });

  group('Tempest Reach', () {
    test('is entered from the prairie', () {
      final entrance =
          EntityId.TEMPEST_REACH_ENTRANCE.definition as DungeonEntityDefinition;
      expect(entrance.dungeonId, DungeonId.TEMPEST_REACH);
      expect(reach.type, DungeonType.ZONE);
    });

    test('runs three cards of twenty-five fights', () {
      expect(reach.entries.map((c) => c.name), [
        "Raider's Camp",
        'The Matted Grass',
        'The Storm Front',
      ]);
      for (final card in reach.entries) {
        final fights = card.entities.fold(0, (sum, e) => sum + e.count);
        expect(fights, 25, reason: card.name);
      }
    });

    test('its mobs run L55-89 and its bosses all stand at 144', () {
      final bosses = [for (final card in reach.entries) card.entities.last];
      expect(bosses.map((b) => b.entityId), [
        EntityId.ORC_WARLORD,
        EntityId.SABERTOOTH_ALPHA,
        EntityId.TEMPEST,
      ]);
      for (final b in bosses) {
        expect(levelOf(b.entityId), 144, reason: b.entityId.name);
        expect(combat(b.entityId).isDungeonBoss, isTrue);
      }

      for (final card in reach.entries) {
        for (final mob in card.entities.take(card.entities.length - 1)) {
          expect(
            levelOf(mob.entityId),
            inInclusiveRange(55, 89),
            reason: '${card.name}: ${mob.entityId.name}',
          );
        }
      }
    });

    test('the bosses fight the way the plan has them', () {
      expect(combat(EntityId.ORC_WARLORD).combatType, CombatType.PLATE_TANK);
      expect(
        combat(EntityId.SABERTOOTH_ALPHA).combatType,
        CombatType.LEATHER_DPS,
      );
      expect(combat(EntityId.TEMPEST).combatType, CombatType.CLOTH_DPS);
      expect(
        combat(EntityId.TEMPEST).archetype,
        isNot(combat(EntityId.DUST_DEVIL).archetype),
        reason: 'Tempest is its own entity, not a big dust devil',
      );
    });

    test('each boss drops its own weapon and armour piece', () {
      const uniques = {
        EntityId.ORC_WARLORD: [
          ItemId.WARLORDS_CLEAVER,
          ItemId.WARLORDS_WARHELM,
        ],
        EntityId.SABERTOOTH_ALPHA: [ItemId.ALPHAS_FANG, ItemId.ALPHAS_MANTLE],
        EntityId.TEMPEST: [
          ItemId.STORMCALLERS_SCEPTER,
          ItemId.GALEWRAP_GAUNTLETS,
        ],
      };
      for (final MapEntry(key: boss, value: items) in uniques.entries) {
        expect(dropsOf(boss), containsAll(items), reason: boss.name);
      }
      expect(dropsOf(EntityId.TEMPEST), contains(ItemId.STORM_SHARD));
    });

    test('nothing but Tempest drops the storm shard', () {
      final sources = [
        for (final id in EntityId.values)
          if (id.definition is EncounterEntityDefinition &&
              dropsOf(id).contains(ItemId.STORM_SHARD))
            id.name,
      ];
      expect(sources, ['TEMPEST']);
    });

    test('its gear sits a rung past the Drowned Fen', () {
      EquipmentItemDefinition eq(ItemId id) =>
          id.definition as EquipmentItemDefinition;

      expect(eq(ItemId.WARLORDS_WARHELM).fibLevel, 4);
      expect(eq(ItemId.ALPHAS_MANTLE).fibLevel, 4);
      expect(eq(ItemId.GALEWRAP_GAUNTLETS).fibLevel, 5);
      // the Fen's own trims and major, one rung down
      expect(
        eq(ItemId.WARLORDS_WARHELM).fibLevel,
        eq(ItemId.OOZE_SLICK_BELT).fibLevel + 1,
      );
      expect(
        eq(ItemId.GALEWRAP_GAUNTLETS).fibLevel,
        eq(ItemId.MURKJAW_PAULDRONS).fibLevel + 1,
      );

      expect(eq(ItemId.WARLORDS_WARHELM).armorSlot, ArmorSlots.HEAD);
      expect(eq(ItemId.ALPHAS_MANTLE).armorSlot, ArmorSlots.BACK);
      expect(eq(ItemId.GALEWRAP_GAUNTLETS).armorSlot, ArmorSlots.HANDS);
      // defence-led, with attack second: no boss unique is pure defence
      expect(eq(ItemId.GALEWRAP_GAUNTLETS).statWeights, {
        SkillId.DEFENCE: 8,
        SkillId.ATTACK: 4,
      });
    });

    test('its weapons hit at adamant damage, and Tempest\'s at rune', () {
      WeaponItemDefinition w(ItemId id) =>
          id.definition as WeaponItemDefinition;
      expect(w(ItemId.WARLORDS_CLEAVER).materialRung, 4);
      expect(w(ItemId.ALPHAS_FANG).materialRung, 4);
      expect(w(ItemId.STORMCALLERS_SCEPTER).materialRung, 5);
    });
  });

  group('greater potions', () {
    const greaters = {
      ItemId.GREATER_STRENGTH_POTION: SkillId.STRENGTH,
      ItemId.GREATER_ATTACK_POTION: SkillId.ATTACK,
      ItemId.GREATER_DEFENCE_POTION: SkillId.DEFENCE,
      ItemId.GREATER_RECOVERY_POTION: SkillId.RECOVERY,
      ItemId.GREATER_STAMINA_POTION: SkillId.STAMINA,
      ItemId.GREATER_SPEED_POTION: SkillId.SPEED,
    };

    test('give +21, the Fibonacci rung past the super tier', () {
      for (final MapEntry(key: id, value: skill) in greaters.entries) {
        final def = id.definition as BuffItemDefinition;
        expect(def.skillBonus, {skill: 21}, reason: id.name);
      }
    });

    test('are brewed from saltwort or bluestem and a heavy part', () {
      for (final id in greaters.keys) {
        // the attack potion is off the ladder: no recipe brews it now
        if (id == ItemId.GREATER_ATTACK_POTION) continue;
        final recipe = alchemyRecipes.singleWhere(
          (r) => r.output.any((o) => o.id == id),
        );
        expect(recipe.inputs, hasLength(2), reason: id.name);
        final herb = recipe.inputs.keys.firstWhere(
          (i) => i == ItemId.SALTWORT || i == ItemId.BLUESTEM,
        );
        final part = recipe.inputs.keys.singleWhere((i) => i != herb);
        expect(
          (part.definition as ReagentPartDefinition).grade,
          ReagentGrade.HEAVY,
          reason: id.name,
        );
      }
    });
  });

  group('utility potions', () {
    const utilities = {
      ItemId.PROSPECTORS_POTION: SkillId.MINING,
      ItemId.FORAGERS_POTION: SkillId.HERBALISM,
      ItemId.SMITHS_POTION: SkillId.BLACKSMITHING,
      ItemId.ALCHEMISTS_POTION: SkillId.ALCHEMY,
    };

    test('give +13 to a gathering or crafting skill', () {
      for (final MapEntry(key: id, value: skill) in utilities.entries) {
        final def = id.definition as BuffItemDefinition;
        expect(def.skillBonus, {skill: 13}, reason: id.name);
      }
    });

    test('are brewed from a super-tier herb and one other input', () {
      for (final id in utilities.keys) {
        final recipe = alchemyRecipes.singleWhere(
          (r) => r.output.any((o) => o.id == id),
        );
        expect(
          recipe.inputs.keys.any(
            (i) => i == ItemId.SILT_LILY || i == ItemId.MIRECAP,
          ),
          isTrue,
          reason: id.name,
        );
        expect(recipe.inputs, hasLength(2), reason: id.name);
      }
    });
  });

  group('the storm shard', () {
    test('stands in for the prisms of a grand enchant', () {
      final catalog = EnchantmentCatalog();
      final grand = catalog.recipeById('grand_enchant')!;
      final storm = catalog.recipeById('storm_enchant')!;
      expect(storm.inputs, contains(ItemId.STORM_SHARD));
      expect(storm.inputs, isNot(contains(ItemId.ENCHANTING_PRISM)));
      expect(storm.statTotal, grand.statTotal);
      expect(storm.levelRequirement, grand.levelRequirement);
    });
  });
}
