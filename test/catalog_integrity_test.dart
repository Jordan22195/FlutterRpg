import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:rpg/catalogs/drop_tables.dart';
import 'package:rpg/catalogs/dungeons/dungeons.dart';
import 'package:rpg/catalogs/enchantments/enchantments.dart';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/catalogs/recipes/recipes.dart';
import 'package:rpg/catalogs/zones/zones.dart';
import 'package:rpg/data/item_drop_type.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/services/weighted_drop_table_service.dart';
import 'package:rpg/data/equipment_data.dart';

/// Content invariants for the catalogs.
///
/// "Every id has a definition" is now a compile-time guarantee — the
/// definition rides on the enum constant — so these assert the things the
/// compiler still cannot: that the content is sane, that it references only
/// things that exist, and that the save format has not shifted underfoot.

/// Art that is referenced but not drawn yet. This is the backlog, and it
/// should only ever shrink: `python3 tools/generate_assets_rd.py --list`
/// prints the same set. Adding to it is a deliberate act.
const knownMissingArt = <String>{
  // Scene art: zone headers and dungeon splashes. These are the last of the
  // backlog because they are the one kind the generator will not draw —
  // assets/images/{zones,dungeons}/** has no style picked, so
  // generate_assets_rd.py reports them and skips them until it is passed
  // --scene-style and --scene-size. Prompts for all seven are already written
  // in tools/rd_prompt_overrides.json.
  'assets/images/zones/south_haven.png',
  'assets/images/zones/farm.png',
  'assets/images/zones/forest.png',
  'assets/images/zones/mine.png',
  'assets/images/dungeons/goblin_camp.png',
  'assets/images/dungeons/goblin_queen_lair.png',
  'assets/images/dungeons/spider_den.png',
  'assets/images/zones/darkwood_forest.png',
  'assets/images/zones/swamp.png',
  'assets/images/zones/foothills.png',
  // Darkwood Forest's tier 3 gathering nodes and the log they drop. These
  // three are generatable — unlike the scene art above, they are an entity
  // and an icon, whose styles are settled — so they leave this list as soon
  // as generate_assets_rd.py is run. Prompts are already written.
  'assets/images/entities/willow_tree.png',
  'assets/images/entities/gold_vein.png',
  'assets/icons/items/willow_logs.png',
  // the tier 4 mining node, and the first source of mithril ore
  'assets/images/entities/mithril_vein.png',
  // The BACK slot's first two pieces. The slot had no catalog items at all
  // until the equipment models moved onto their definitions and the back
  // slot's tests needed real ones to build.
  'assets/icons/items/wool_cloak.png',
  'assets/icons/items/linen_cape.png',
  'assets/images/entities/willow_cookfire.png',
  'assets/images/entities/willow_campfire.png',
  'assets/images/entities/willow_bonfire.png',
  // The 47-monster combat roster. Eight of its rows reuse art that already
  // exists (chicken, cow, scarecrow, spider, wolf, goblin, mudlurc); these
  // forty are new and undrawn. All five rarity variants of a monster share
  // one portrait, so this is one line per monster, not per EntityId.
  // Prompts are written in tools/rd_prompt_overrides.json, so they leave
  // this list as soon as generate_assets_rd.py is run.
  'assets/images/entities/giant_rat.png',
  'assets/images/entities/giant_bat.png',
  'assets/images/entities/slime.png',
  'assets/images/entities/bear.png',
  'assets/images/entities/fungal_monster.png',
  'assets/images/entities/kobold.png',
  'assets/images/entities/skeleton.png',
  'assets/images/entities/zombie.png',
  'assets/images/entities/harpy.png',
  'assets/images/entities/naga.png',
  'assets/images/entities/giant_scorpion.png',
  'assets/images/entities/imp.png',
  'assets/images/entities/orc.png',
  'assets/images/entities/wraith.png',
  'assets/images/entities/banshee.png',
  'assets/images/entities/troll.png',
  'assets/images/entities/minotaur.png',
  'assets/images/entities/basilisk.png',
  'assets/images/entities/dark_wizard.png',
  'assets/images/entities/gargoyle.png',
  'assets/images/entities/moss_golem.png',
  'assets/images/entities/hill_giant.png',
  'assets/images/entities/earth_elemental.png',
  'assets/images/entities/ogre.png',
  'assets/images/entities/stone_golem.png',
  'assets/images/entities/griffin.png',
  'assets/images/entities/fire_elemental.png',
  'assets/images/entities/water_elemental.png',
  'assets/images/entities/yeti.png',
  'assets/images/entities/iron_golem.png',
  'assets/images/entities/steel_golem.png',
  'assets/images/entities/lich.png',
  'assets/images/entities/cloud_giant.png',
  'assets/images/entities/roc.png',
  'assets/images/entities/wyvern.png',
  'assets/images/entities/drake.png',
  'assets/images/entities/kraken.png',
  'assets/images/entities/dragon.png',
  'assets/images/entities/lesser_demon.png',
  'assets/images/entities/greater_demon.png',
};

/// Asset directories referenced by content but not declared in pubspec.yaml,
/// so nothing in them ships even once the art exists. Declaring a directory
/// Flutter cannot find is itself a build error, so fixing this means creating
/// the directory, putting the art in it, and adding it to pubspec — a content
/// job, not a code one. Listed here so it stays visible instead of silent.
const knownUndeclaredAssetDirs = <String>{'assets/images/dungeons/'};

/// Placeholder strings that mean "nobody filled this in".
const placeholderNames = <String>{'', 'error', 'name', 'id', 'null', 'Null'};

/// Asset directories declared in pubspec.yaml. Parsed rather than hardcoded,
/// so an asset dropped into an undeclared directory still fails: it would
/// exist on disk but never ship.
Set<String> declaredAssetDirs() {
  final lines = File('pubspec.yaml').readAsLinesSync();
  final start = lines.indexWhere((l) => l.trimRight() == '  assets:');
  if (start == -1) {
    throw StateError('pubspec.yaml declares no assets');
  }
  final dirs = <String>{};
  for (final line in lines.skip(start + 1)) {
    final m = RegExp(r'^\s+- (assets/\S*/)$').firstMatch(line);
    if (m == null) break;
    dirs.add(m.group(1)!);
  }
  return dirs;
}

/// Case-sensitive existence check, matching `Asset.exists()` in
/// tools/generate_assets_rd.py. macOS is case-insensitive, so a plain
/// File.existsSync() happily matches copper_ore.png against a reference to
/// COPPER_ORE.png — which then fails to load on an Android or iOS build.
bool assetExists(String path) {
  final dir = Directory(path.substring(0, path.lastIndexOf('/')));
  if (!dir.existsSync()) return false;
  final name = path.substring(path.lastIndexOf('/') + 1);
  return dir.listSync().any(
    (e) => e.path.substring(e.path.lastIndexOf('/') + 1) == name,
  );
}

void checkIcon(String? asset, String owner, Set<String> declared) {
  if (asset == null || asset.isEmpty) return;
  final dir = '${asset.substring(0, asset.lastIndexOf('/'))}/';
  if (!knownUndeclaredAssetDirs.contains(dir)) {
    expect(
      declared,
      contains(dir),
      reason: '$owner points at $dir, which pubspec.yaml does not ship',
    );
  }
  if (knownMissingArt.contains(asset)) return;
  expect(
    assetExists(asset),
    isTrue,
    reason:
        '$owner references $asset, which is not on disk '
        '(add it to knownMissingArt only if the art is genuinely pending)',
  );
}

// Generic rather than raw: it serves item drops, zone discovery tables and
// recipe outputs alike, and a raw parameter would accept anything at all.
// For an ItemDropType, `count` is its own lowCount - a bonus roll holds the
// drops themselves, so there is no wrapper count to read by mistake.
void checkDropTable<T>(List<WeightedDropTableEntry<T>> entries, String owner) {
  expect(entries, isNotEmpty, reason: '$owner has an empty drop table');
  for (final e in entries) {
    // WeightedDropTableService.roll throws on a non-positive total weight,
    // so a zero here is a crash in play, not a silent no-drop
    expect(e.weight, greaterThan(0), reason: '$owner: ${e.id} has weight 0');
    expect(e.count, greaterThan(0), reason: '$owner: ${e.id} drops 0');
    expect(
      e.highCount == 0 || e.highCount >= e.count,
      isTrue,
      reason: '$owner: ${e.id} has highCount below count',
    );
    expect(e.unlockLevel, greaterThanOrEqualTo(0));
  }
}

void main() {
  group('names', () {
    test('every definition is named', () {
      for (final id in ItemId.values) {
        if (id == ItemId.NULL) continue;
        expect(
          placeholderNames.contains(id.definition.name),
          isFalse,
          reason: '${id.name} has placeholder name "${id.definition.name}"',
        );
      }
      for (final id in EntityId.values) {
        if (id == EntityId.NULL) continue;
        expect(
          placeholderNames.contains(id.definition.name),
          isFalse,
          reason: '${id.name} is unnamed',
        );
      }
      for (final id in ZoneId.values) {
        if (id == ZoneId.NULL) continue;
        expect(
          placeholderNames.contains(id.definition.name),
          isFalse,
          reason: '${id.name} is unnamed',
        );
      }
      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        expect(
          placeholderNames.contains(id.definition.name),
          isFalse,
          reason: '${id.name} is unnamed',
        );
      }
    });
  });

  group('icons', () {
    test('every referenced icon is shipped and on disk', () {
      final declared = declaredAssetDirs();
      for (final id in ItemId.values) {
        checkIcon(id.iconAsset, 'ItemId.${id.name}', declared);
      }
      for (final id in EntityId.values) {
        checkIcon(id.iconAsset, 'EntityId.${id.name}', declared);
      }
      for (final id in ZoneId.values) {
        checkIcon(id.iconAsset, 'ZoneId.${id.name}', declared);
      }
      for (final id in DungeonId.values) {
        checkIcon(id.iconAsset, 'DungeonId.${id.name}', declared);
      }
    });

    test('the missing-art backlog has no stale entries', () {
      for (final asset in knownMissingArt) {
        expect(
          assetExists(asset),
          isFalse,
          reason: '$asset now exists — drop it from knownMissingArt',
        );
      }
    });
  });

  group('combat stats', () {
    test('every combat entity sits on the level curve', () {
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! CombatEntityDefinition) continue;
        expect(
          def.level,
          greaterThanOrEqualTo(1),
          reason: 'EntityId.${id.name} has a level below 1',
        );
        expect(
          CombatType.levelOf(
            attack: def.attack,
            defence: def.defence,
            hitpoints: def.hitpoints,
          ),
          def.level,
          reason:
              'EntityId.${id.name} stats (${def.attack}/${def.defence}/'
              '${def.hitpoints}) do not read back as level ${def.level}',
        );
      }
    });
  });

  group('drop tables', () {
    test('the shared tables are rollable', () {
      checkDropTable(gemDropTable, 'gemDropTable');
      checkDropTable(herbDropTable, 'herbDropTable');
    });

    test('encounter drops are rollable', () {
      for (final id in EntityId.values) {
        if (id == EntityId.NULL_ENCOUNTER) continue;
        final def = id.definition;
        if (def is! EncounterEntityDefinition) continue;
        checkDropTable(def.itemDrops, 'EntityId.${id.name}');
        for (final roll in def.bonusDrops) {
          expect(
            roll.chance,
            inInclusiveRange(0, 1),
            reason: '${id.name} has a bonus roll outside 0..1',
          );
          checkDropTable(roll.entries, 'EntityId.${id.name} bonus');
        }
      }
    });

    test('zone discovery tables are rollable', () {
      for (final id in ZoneId.values) {
        if (id == ZoneId.NULL) continue;
        final def = id.definition;
        if (def.discoverableEntities.isNotEmpty) {
          checkDropTable(
            def.discoverableEntities,
            'ZoneId.${id.name} entities',
          );
        }
        if (def.discoverableItems.isNotEmpty) {
          checkDropTable(def.discoverableItems, 'ZoneId.${id.name} items');
        }
      }
    });

    test('recipe output tables are rollable', () {
      for (final r in RecipeCatalog().recipes) {
        checkDropTable(r.output, 'recipe ${r.id}');
      }
    });
  });

  group('shops', () {
    test('a restock can always fill every slot with a distinct item', () {
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! ShopEntityDefinition) continue;
        final pool = def.shopStockPool;
        expect(pool, isNotEmpty, reason: '${id.name} sells nothing');
        expect(
          pool.length,
          greaterThanOrEqualTo(def.stockSlots),
          reason:
              '${id.name} has ${pool.length} pool entries for '
              '${def.stockSlots} slots, so a restock cannot fill the shelf',
        );
        expect(
          pool.map((e) => e.itemId).toSet().length,
          pool.length,
          reason:
              '${id.name} lists the same item twice; restock draws '
              'without replacement and claims distinct items',
        );
        for (final e in pool) {
          expect(
            e.count,
            greaterThan(0),
            reason: '${id.name} stocks 0 ${e.itemId}',
          );
          expect(
            e.itemId,
            isNot(ItemId.COINS),
            reason: '${id.name} sells coins for coins',
          );
          expect(e.itemId, isNot(ItemId.NULL));
        }
        expect(
          def.priceMarkup,
          greaterThanOrEqualTo(1.0),
          reason: '${id.name} sells below value',
        );
        expect(def.restockInterval, greaterThan(Duration.zero));
      }
    });
  });

  group('recipes', () {
    test('ids are unique — they are the save format', () {
      final ids = RecipeCatalog().recipes.map((r) => r.id).toList();
      expect(ids.toSet().length, ids.length, reason: 'duplicate recipe id');
      final enchantIds = EnchantmentCatalog().recipes.map((r) => r.id).toList();
      expect(
        enchantIds.toSet().length,
        enchantIds.length,
        reason: 'duplicate enchant id',
      );
    });

    test('every recipe consumes and produces something', () {
      for (final r in RecipeCatalog().recipes) {
        expect(r.inputs, isNotEmpty, reason: '${r.id} has no inputs');
        for (final e in r.inputs.entries) {
          expect(
            e.value,
            greaterThan(0),
            reason: '${r.id} consumes 0 ${e.key}',
          );
          expect(e.key, isNot(ItemId.NULL));
        }
        expect(r.output, isNotEmpty, reason: '${r.id} produces nothing');
        expect(r.levelRequirement, greaterThanOrEqualTo(1));
        expect(r.xp, greaterThan(0), reason: '${r.id} pays no xp');
        expect(r.skill, isNot(SkillId.NULL));
      }
    });
  });

  group('dungeons', () {
    test('every card is named, holds something, and can be cleared', () {
      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        final def = id.definition;
        expect(def.entries, isNotEmpty, reason: '${id.name} has no cards');
        for (final entry in def.entries) {
          expect(
            entry.name,
            isNotEmpty,
            reason: '${id.name} has an unnamed card',
          );
          expect(entry.entities, isNotEmpty, reason: '${entry.name} is empty');
          for (final ref in entry.entities) {
            expect(ref.count, greaterThan(0));
            // the kill path needs a drop table, and a card that never
            // depletes never clears, so the run would soft-lock on it
            expect(
              ref.entityId.definition,
              isA<EncounterEntityDefinition>(),
              reason:
                  '${ref.entityId.name} in ${id.name}/${entry.name} '
                  'is not something you can fight down',
            );
            expect(
              ref.entityId.definition,
              isNot(isA<FishingEntityDefinition>()),
              reason: '${ref.entityId.name} never depletes',
            );
          }
        }
      }
    });

    test('only landmarks are keyed', () {
      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        final def = id.definition;
        if (def.type != DungeonType.LANDMARK) {
          expect(
            def.isKeyed,
            isFalse,
            reason: '${id.name} is not a landmark but wants a key',
          );
        }
      }
    });

    test('no dungeon lists its own entrance', () {
      // entity and dungeon definitions are const and reference each other; a
      // cycle between two constants is a compile error, so this guards the
      // content rule that keeps the graph acyclic
      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        for (final entry in id.definition.entries) {
          for (final ref in entry.entities) {
            final def = ref.entityId.definition;
            if (def is! DungeonEntityDefinition) continue;
            expect(
              def.dungeonId,
              isNot(id),
              reason: '${id.name} contains its own entrance',
            );
          }
        }
      }
    });
  });

  group('cross references', () {
    test('no zone lists a null entity', () {
      for (final id in ZoneId.values) {
        if (id == ZoneId.NULL) continue;
        final def = id.definition;
        expect(
          def.permanentEntities,
          isNot(contains(EntityId.NULL)),
          reason: '${id.name} has a null permanent entity',
        );
        for (final e in def.discoverableEntities) {
          expect(
            e.id,
            isNot(EntityId.NULL),
            reason: '${id.name} can discover nothing',
          );
        }
      }
    });

    test('ItemId.NULL appears only as a deliberate "no find"', () {
      // three zone item tables weight NULL as the empty result; nothing else
      // should ever hand the player a null item
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! EncounterEntityDefinition) continue;
        for (final e in def.itemDrops) {
          expect(
            e.id,
            isNot(ItemId.NULL),
            reason: '${id.name} drops a null item',
          );
        }
      }
      for (final r in RecipeCatalog().recipes) {
        for (final e in r.output) {
          expect(e.id, isNot(ItemId.NULL), reason: '${r.id} crafts nothing');
        }
      }
    });

    test('every zone on the travel graph has a place on the map', () {
      // a zone with an edge but no anchor is invisible: the map filters it
      // out of the drawing silently, so the graph and the layout have to be
      // kept in step here rather than noticed in play
      for (final id in ZoneId.values) {
        if (id == ZoneId.NULL || id == ZoneId.CHALLENGING_MOUNTAIN) continue;
        expect(
          zoneNodeCenter(id),
          isNotNull,
          reason: '${id.name} is not laid out on the world map',
        );
      }
    });

    test('every non-dev zone is reachable from the starting farm', () {
      final graph = ZoneTravelGraph();
      // unreleased content: it has a definition but no travel edge yet
      const notWiredUp = {ZoneId.CHALLENGING_MOUNTAIN};
      for (final id in ZoneId.values) {
        if (id == ZoneId.NULL || notWiredUp.contains(id)) continue;
        expect(
          graph.travelCost(ZoneId.TUTORIAL_FARM, id),
          isNot(double.infinity),
          reason: '${id.name} cannot be reached from TUTORIAL_FARM',
        );
      }
    });
  });

  group('the const contract', () {
    test('build() hands back an instance that cannot leave its definition', () {
      // the instance reads its stats off the const definition and hands
      // them out read-only. that is the whole point: a piece the player is
      // already carrying has nowhere to keep a stale copy of its stats, so
      // a tuning change reaches it.
      final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
      final helmetDef =
          ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;
      expect(helmet.statWeights, helmetDef.statWeights);
      expect(
        () => helmet.statWeights[SkillId.DEFENCE] = 99,
        throwsUnsupportedError,
      );
      expect(helmetDef.statWeights[SkillId.DEFENCE], isNot(99));

      final fire = ItemId.COOKFIRE.build() as FireItem;
      final def = ItemId.COOKFIRE.definition as FireItemDefinition;
      expect(fire.skillBonus, def.skillBonus);
      expect(
        () => fire.skillBonus[SkillId.COOKING] = 42,
        throwsUnsupportedError,
      );
      expect(def.skillBonus[SkillId.COOKING], isNot(42));
    });

    test('build() hands back freely mutable instance state', () {
      // what an instance does own it owns outright: the stack count, the
      // rolled quality and the enchant rolled onto it
      final helmet = ItemId.COPPER_HELMET.build() as EquipmentItem;
      helmet.count = 4;
      helmet.quality = Rarity.EPIC;
      helmet.enchantBonus[SkillId.DEFENCE] = 3;

      expect(helmet.count, 4);
      expect(helmet.quality, Rarity.EPIC);
      expect(helmet.effectiveSkillBonus[SkillId.DEFENCE], greaterThan(3));
      // and none of it reached the catalog, or the next piece to drop
      expect(ItemId.COPPER_HELMET.definition.quality, Rarity.COMMON);
      expect(
        (ItemId.COPPER_HELMET.build() as EquipmentItem).enchantBonus,
        isEmpty,
      );
    });

    test('copyWith leaves the catalog untouched', () {
      final original =
          ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;
      final buffed = original.copyWith(value: 999);
      expect(buffed.value, 999);
      expect(ItemId.COPPER_HELMET.definition.value, original.value);

      final entry = const WeightedDropTableEntry<ItemId>(
        id: ItemId.LOGS,
        weight: 1,
      );
      expect(entry.copyWith(weight: 0.5).weight, 0.5);
      expect(entry.weight, 1);
    });

    test('quality defaults to common and survives copyWith', () {
      // the default is the identity: a 1.0 multiplier and an empty label,
      // so an item that ignores quality reads as it always did. asserted
      // against a bare definition rather than the catalog, which is free to
      // tag as many items as it likes
      expect(const ItemDefinition(name: 'x', value: 1).quality, Rarity.COMMON);
      expect(Rarity.COMMON.index, 0, reason: 'common must be no rungs up');
      expect(Rarity.COMMON.label, isEmpty);

      // a declared quality has to survive a copyWith that is not about
      // quality, or every variant silently drops back to common
      final original =
          ItemId.COPPER_HELMET.definition as EquipmentItemDefinition;
      final epic = original.copyWith(quality: Rarity.EPIC);
      expect(epic.quality, Rarity.EPIC);
      expect(epic.copyWith(value: 999).quality, Rarity.EPIC);
      expect(ItemId.COPPER_HELMET.definition.quality, Rarity.COMMON);

      // a definition can still declare one, and it survives copyWith
      const declared = EquipmentItemDefinition(
        name: 'Declared',
        value: 1,
        armorSlot: ArmorSlots.HEAD,
        fibLevel: 0,
        statWeights: {SkillId.DEFENCE: 1},
        quality: Rarity.RARE,
      );
      expect(declared.quality, Rarity.RARE);
      expect(declared.copyWith(value: 9).quality, Rarity.RARE);

      // and an unrolled instance defers to its definition rather than
      // hardcoding common - which is how a declared quality would reach the
      // runtime item. No catalog item declares one today: RARE_PITCHFORK
      // was retired once a drop could carry a quality of its own, so a rare
      // pitchfork is the ordinary one at Rarity.RARE.
      for (final id in ItemId.values) {
        if (id.definition is! EquipmentItemDefinition) continue;
        expect(
          id.build().quality,
          id.definition.quality,
          reason: '${id.name} did not take its definition\'s quality',
        );
      }
    });
  });

  group('save format', () {
    // enum value names are written into save data, so a rename silently
    // orphans every existing save. these lists are frozen on purpose:
    // adding an id is fine, renaming or removing one is not.
    test('no ItemId was renamed or removed', () {
      expect(
        ItemId.values.map((e) => e.name).toSet(),
        containsAll(frozenItemIds),
      );
    });
    test('no EntityId was renamed or removed', () {
      expect(
        EntityId.values.map((e) => e.name).toSet(),
        containsAll(frozenEntityIds),
      );
    });
    test('no ZoneId was renamed or removed', () {
      expect(
        ZoneId.values.map((e) => e.name).toSet(),
        containsAll(frozenZoneIds),
      );
    });
    test('no DungeonId was renamed or removed', () {
      expect(
        DungeonId.values.map((e) => e.name).toSet(),
        containsAll(frozenDungeonIds),
      );
    });
  });
}

const frozenItemIds = <String>{
  'NULL',
  'COINS',
  'BURNT_FOOD',
  'COW_HIDE',
  'FEATHER',
  'LOGS',
  'OAK_LOGS',
  'COPPER_ORE',
  'IRON_ORE',
  'COAL',
  'GOLD_ORE',
  'MITHRIL_ORE',
  'ADAMANTITE_ORE',
  'RUNEITE_ORE',
  'COPPER_BAR',
  'IRON_BAR',
  'STEEL_BAR',
  'GOLD_BAR',
  'MITHRIL_BAR',
  'ADAMANTITE_BAR',
  'RUNITE_BAR',
  'TOPAZ',
  'SAPPHIRE',
  'EMERALD',
  'RUBY',
  'DIAMOND',
  'DRAGONSTONE',
  'ONYX',
  'GUAM_LEAF',
  'MARRENTILL',
  'TARROMIN',
  'HARRALANDER',
  'RANARR_WEED',
  'TOADFLAX',
  'IRIT_LEAF',
  'AVANTOE',
  'KWUARM',
  'SNAPDRAGON',
  'CADANTINE',
  'LANTADYME',
  'DWARF_WEED',
  'TORSTOL',
  'CHICKEN_MEAT',
  'COW_MEAT',
  'MINNOW',
  'CARP',
  'BLUEGILL',
  'TROUT',
  'PIKE',
  'SALMON',
  'CATFISH',
  'BASS',
  'WHITEFISH',
  'TUNA',
  'SWORDFISH',
  'SHARK',
  'COOKED_CHICKEN',
  'COOKED_MINNOW',
  'COOKED_CARP',
  'COOKED_BLUEGILL',
  'COOKED_TROUT',
  'COOKED_PIKE',
  'COOKED_SALMON',
  'COOKED_CATFISH',
  'COOKED_BASS',
  'COOKED_WHITEFISH',
  'COOKED_TUNA',
  'COOKED_SWORDFISH',
  'COOKED_SHARK',
  'ENCHANTING_DUST',
  'ENCHANTING_ESSENCE',
  'ENCHANTING_RUNE',
  'ENCHANTING_PRISM',
  'SOUL_SHARD',
  'GOLD_RING',
  'GOLD_NECKLACE',
  'TOPAZ_RING',
  'TOPAZ_NECKLACE',
  'SAPPHIRE_RING',
  'SAPPHIRE_NECKLACE',
  'EMERALD_RING',
  'EMERALD_NECKLACE',
  'RUBY_RING',
  'RUBY_NECKLACE',
  'DIAMOND_RING',
  'DIAMOND_NECKLACE',
  'DRAGONSTONE_RING',
  'DRAGONSTONE_NECKLACE',
  'ONYX_RING',
  'ONYX_NECKLACE',
  'COOKFIRE',
  'BASIC_CAMPFIRE',
  'BONFIRE',
  'OAK_COOKFIRE',
  'OAK_CAMPFIRE',
  'OAK_BONFIRE',
  'COPPER_HELMET',
  'IRON_HELMET',
  'STEEL_HELMET',
  'MITHRIL_HELMET',
  'LIGHT_LETHER_CHEST',
  'COPPER_CHESTPLATE',
  'IRON_CHESTPLATE',
  'STEEL_CHESTPLATE',
  'MITHRIL_CHESTPLATE',
  'LIGHT_LEATHER_PANTS',
  'COPPER_LEGS',
  'IRON_LEGS',
  'STEEL_LEGS',
  'MITHRIL_LEGS',
  'LIGHT_LEATHER_BOOTS',
  'COPPER_BOOTS',
  'IRON_BOOTS',
  'STEEL_BOOTS',
  'MITHRIL_BOOTS',
  'LIGHT_LEATHER_GLOVES',
  'COPPER_GLOVES',
  'IRON_GLOVES',
  'STEEL_GLOVES',
  'MITHRIL_GLOVES',
  'COPPER_SHIELD',
  'IRON_SHIELD',
  'STEEL_SHIELD',
  'MITHRIL_SHIELD',
  'COPPER_DAGGER',
  'IRON_DAGGER',
  'STEEL_DAGGER',
  'MITHRIL_DAGGER',
  'STONE_AXE',
  'COPPER_AXE',
  'IRON_AXE',
  'STEEL_AXE',
  'MITHRIL_AXE',
  'STONE_PICKAXE',
  'COPPER_PICKAXE',
  'IRON_PICKAXE',
  'STEEL_PICKAXE',
  'MITHRIL_PICKAXE',
  'COPPER_SICKLE',
  'IRON_SICKLE',
  'STEEL_SICKLE',
  'MITHRIL_SICKLE',
  'SIMPLE_FISHING_ROD',
  'PITCHFORK',
  'GOBLIN_CROWN',
  'GOBLIN_SCEPTER',
  'SPIDER_SILK_NECKLACE',
  'GOBLIN_QUEEN_KEY',
};

const frozenEntityIds = <String>{
  'NULL',
  'ANVIL',
  'ENCHANTING_BENCH',
  'JEWELCRAFTING_BENCH',
  'FIREPIT',
  'TREE',
  'OAK_TREE',
  'COPPER',
  'IRON',
  'COAL_VEIN',
  'GEM_VEIN',
  'TRANQUIL_POND',
  'RIVER',
  'DEEP_POND',
  'LAKE',
  'OCEAN',
  'GUAM',
  'MARRENTILL',
  'TARROMIN',
  'HARRALANDER',
  'RANARR',
  'TOADFLAX',
  'IRIT',
  'AVANTOE',
  'KWUARM',
  'SNAPDRAGON',
  'CADANTINE',
  'LANTADYME',
  'DWARF_WEED',
  'TORSTOL',
  'CHICKEN',
  'COW',
  'GOBLIN',
  'BIG_RED',
  'GOBLIN_SCOUT',
  'GIANT_SPIDER',
  'ROTWOOD_SCARECROW',
  'GOBLIN_SEARGENT',
  'SPIDER_BROODMOTHER',
  'GOBLIN_QUEEN',
  'FARMER',
  'TRADING_POST',
  'WANDERING_MERCHANT',
  'SPIDER_DEN_ENTRANCE',
  'GOBLIN_CAMP',
  'DEV_DUNGEON_ENTRANCE',
};

const frozenZoneIds = <String>{
  'TUTORIAL_FARM',
  'SOUTHWOOD_FOREST',
  'SOUTH_HAVEN',
  'FOREST_MINE',
  'CHALLENGING_MOUNTAIN',
  'DEV_FOREST',
  'DEV_DUNGEON_TESTING',
  'NULL',
};

const frozenDungeonIds = <String>{
  'NULL',
  'GOBLIN_QUEEN_LAIR',
  'SPIDER_DEN',
  'GOBLIN_CAMP',
  'DEV_TRANSIENT_DUNGEON',
};
