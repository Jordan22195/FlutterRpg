import 'dart:io';
import 'dart:math';

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
const knownMissingArt = <String>{};

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
    test('every item has an icon', () {
      // the sentinels stand for "nothing" and are never drawn
      const iconless = {ItemId.NULL, ItemId.NULL_BUFF};
      final missing = [
        for (final id in ItemId.values)
          if (!iconless.contains(id) && (id.iconAsset ?? '').isEmpty) id.name,
      ];
      expect(missing, isEmpty, reason: 'items with no iconAsset');
    });

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
        // a boss stands on ten times its level's hitpoints; with that
        // taken back out it sits on the curve like any other
        final hitpoints = def.isDungeonBoss
            ? def.hitpoints ~/ CombatEntityDefinition.bossHitpointsMultiplier
            : def.hitpoints;
        expect(
          CombatType.levelOf(
            attack: def.attack,
            defence: def.defence,
            hitpoints: hitpoints,
          ),
          def.level,
          reason:
              'EntityId.${id.name} stats (${def.attack}/${def.defence}/'
              '${def.hitpoints}) do not read back as level ${def.level}',
        );
      }
    });
  });

  group('equipment stat split', () {
    const combat = {
      SkillId.ATTACK,
      SkillId.DEFENCE,
      SkillId.RANGED,
      SkillId.MAGIC,
    };
    const secondary = {
      SkillId.SPEED,
      SkillId.STRENGTH,
      SkillId.STAMINA,
      SkillId.RECOVERY,
    };
    int top(Map<SkillId, int> stats, Set<SkillId> of) => stats.entries
        .where((e) => of.contains(e.key))
        .fold(0, (m, e) => max(m, e.value));

    test('a piece mixing combat and secondary stats leads with combat', () {
      for (final id in ItemId.values) {
        // the dev ring carries everything evenly on purpose
        if (id == ItemId.GOD_RING) continue;
        final def = id.definition;
        if (def is! EquipmentItemDefinition) continue;
        final w = def.statWeights;
        if (!w.keys.any(combat.contains) || !w.keys.any(secondary.contains)) {
          continue;
        }
        expect(
          top(w, combat),
          greaterThan(top(w, secondary)),
          reason: '${id.name} weights $w put a secondary stat first',
        );
        for (final rarity in Rarity.ladder) {
          final stats = def.statsAt(rarity);
          expect(
            top(stats, combat),
            greaterThanOrEqualTo(top(stats, secondary)),
            reason: '${id.name} at ${rarity.name}: $stats',
          );
        }
      }
    });
  });

  group('drop tables', () {
    test('the shared tables are rollable', () {
      checkDropTable(gemDropTable, 'gemDropTable');
      checkDropTable(herbDropTable, 'herbDropTable');
      checkDropTable(cookedFishDropTable, 'cookedFishDropTable');
      checkDropTable(ironToolsDropTable, 'ironToolsDropTable');
      checkDropTable(ironMinorArmorDropTable, 'ironMinorArmorDropTable');
    });

    test('encounter drops are rollable', () {
      for (final id in EntityId.values) {
        if (id == EntityId.NULL_ENCOUNTER) continue;
        final def = id.definition;
        if (def is! EncounterEntityDefinition) continue;
        // flattened, so the check reaches the leaves inside a nested table
        // rather than stopping at the reference standing in for them
        final drops = def.itemDrops.flattened;
        // an empty main table is allowed: the entity drops nothing but its
        // bonus rolls, if it has any. a non-empty one must still roll
        if (drops.isNotEmpty) checkDropTable(drops, 'EntityId.${id.name}');
        expect(
          drops.whereType<NestedDrop>(),
          isEmpty,
          reason: '${id.name} still has an unresolved nested table',
        );
        for (final roll in def.bonusDrops) {
          checkDropTable(roll.entries.flattened, 'EntityId.${id.name} bonus');
          expect(
            roll.chance,
            inInclusiveRange(0, 1),
            reason: '${id.name} has a bonus roll outside 0..1',
          );
          checkDropTable(roll.entries, 'EntityId.${id.name} bonus');
        }
      }
    });

    test('no entity drops coins', () {
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! EncounterEntityDefinition) continue;
        // the weakest thing in the game pays the smallest purse
        if (id == EntityId.FIELD_RAT) continue;
        final ids = [
          ...def.itemDrops.flattened.map((e) => e.id),
          for (final roll in def.bonusDrops)
            ...roll.entries.flattened.map((e) => e.id),
        ];
        expect(ids, isNot(contains(ItemId.COINS)), reason: id.name);
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
        // the firepit's kindling mix runs the reagent recipes; it has no
        // output of its own
        if (r.isReagentMix) continue;
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
        // the kindling mix spends and pays what its picked reagents do
        if (r.isReagentMix) continue;
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
        // flattened: a nested table's reference carries ItemId.NULL as a
        // placeholder, and it is the leaves it resolves to that have to be
        // real items
        for (final e in def.itemDrops.flattened) {
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

    // Monsters that exist but stand nowhere: no zone discovers them and no
    // dungeon card queues them, so nothing in the game can currently fight
    // them. This is the content backlog and it should only ever shrink —
    // most of it is the high ladder, written well ahead of the zones that
    // will hold it.
    //
    // Adding to it is a deliberate act. That is the point: a monster that
    // silently falls out of a zone during a rebalance has to be filed here
    // by whoever moved it, rather than quietly becoming unreachable. Two
    // already have — the darkwood's tier 4 undead, listed below.
    //
    // Rarity variants are excluded: they are placed explicitly the way the
    // common one is, and most of the catalog's are spares.
    const knownUnplaced = <EntityId>{
      // tier 1-2 spares, written before the zones were re-cut around them
      EntityId.GIANT_RAT,
      EntityId.KOBOLD,
      // the rare scarecrow. Its name predates the _RARE suffix convention,
      // so it reads as a base entity here rather than as a variant
      EntityId.ROTWOOD_SCARECROW_1,

      // tier 4. The banshee was the darkwood's, and came out of it when its
      // roster was re-cut (the wraith has since come back); the rest have
      // never been placed. darkwood_forest_test holds what the zone kept.
      EntityId.BANSHEE,

      // tier 6 and up. The mountain and peak dungeons hold their own boss
      // entities on these archetypes (STEEL_SENTINEL, CALDERA_DRAGON and
      // the rest), so the regulars themselves still stand nowhere
      EntityId.STEEL_GOLEM,
      EntityId.LICH,
      EntityId.CLOUD_GIANT,
      EntityId.KRAKEN,
      EntityId.DRAGON,
      EntityId.LESSER_DEMON,
      EntityId.GREATER_DEMON,
    };

    /// Every entity some zone or dungeon actually puts in front of a player.
    Set<EntityId> placedEntities() {
      final placed = <EntityId>{};
      for (final id in ZoneId.values) {
        placed.addAll(id.definition.permanentEntities);
        placed.addAll(id.definition.discoverableEntities.map((e) => e.id));
      }
      for (final id in DungeonId.values) {
        for (final card in id.definition.entries) {
          placed.addAll(card.entities.map((e) => e.entityId));
        }
      }
      return placed;
    }

    /// A rarity variant is placed alongside its common form, if at all.
    bool isRarityVariant(EntityId id) => const [
      '_UNCOMMON',
      '_RARE',
      '_EPIC',
      '_LEGENDARY',
    ].any(id.name.endsWith);

    test('every monster stands somewhere, or is on the backlog', () {
      final placed = placedEntities();
      final unplaced = <String>[];
      for (final id in EntityId.values) {
        if (id.definition is! CombatEntityDefinition) continue;
        if (isRarityVariant(id)) continue;
        if (placed.contains(id) || knownUnplaced.contains(id)) continue;
        unplaced.add(id.name);
      }
      expect(
        unplaced,
        isEmpty,
        reason:
            'these monsters are in no zone and no dungeon, so nothing can '
            'reach them. Place them, or add them to knownUnplaced: '
            '${unplaced.join(', ')}',
      );
    });

    test('the unplaced backlog has no stale entries', () {
      // the other half of the contract: an entry that has since been placed
      // comes back out, so the list stays an accurate to-do rather than
      // drifting into a list of exceptions nobody reads
      final placed = placedEntities();
      final stale = knownUnplaced.where(placed.contains).map((e) => e.name);
      expect(
        stale,
        isEmpty,
        reason:
            'these are placed now and should come off knownUnplaced: '
            '${stale.join(', ')}',
      );
    });

    test('every dungeon has a way in', () {
      // the mirror of the above for the containers: a dungeon nothing opens
      // is as unreachable as a monster nothing holds. [DungeonType] says
      // which door to look for — a zone or transient dungeon is entered
      // through an entrance entity standing in a zone, a landmark through
      // its own token on the world map.
      final zoneEntrances = <DungeonId>{};
      for (final id in ZoneId.values) {
        final def = id.definition;
        for (final entityId in [
          ...def.permanentEntities,
          ...def.discoverableEntities.map((e) => e.id),
        ]) {
          final entityDef = entityId.definition;
          if (entityDef is DungeonEntityDefinition) {
            zoneEntrances.add(entityDef.dungeonId);
          }
        }
      }
      final mapLandmarks = {
        for (final node in kWorldMapNodes)
          if (node is LandmarkNode) node.id,
      };

      for (final id in DungeonId.values) {
        if (id == DungeonId.NULL) continue;
        switch (id.definition.type) {
          case DungeonType.LANDMARK:
            expect(
              mapLandmarks,
              contains(id),
              reason: '${id.name} is a landmark with no token on the map',
            );
          case DungeonType.ZONE:
          case DungeonType.TRANSIENT:
            expect(
              zoneEntrances,
              contains(id),
              reason: '${id.name} has no entrance entity in any zone',
            );
        }
      }
    });

    test('a landmark on the map is a landmark in the catalog', () {
      // and the other way round, so the map cannot hold a token for a
      // dungeon that is entered some other way
      for (final node in kWorldMapNodes) {
        if (node is! LandmarkNode) continue;
        expect(
          node.id.definition.type,
          DungeonType.LANDMARK,
          reason: '${node.id.name} has a map token but is not a landmark',
        );
      }
    });

    test('every non-dev zone is reachable from the starting farm', () {
      // unreleased content: it has a definition but no travel edge yet
      const notWiredUp = {ZoneId.CHALLENGING_MOUNTAIN};
      for (final id in ZoneId.values) {
        if (id == ZoneId.NULL || notWiredUp.contains(id)) continue;
        expect(
          ZoneTravelGraph.isReachable(ZoneId.TUTORIAL_FARM, id),
          isTrue,
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
      expect(Rarity.COMMON.rung, 0, reason: 'common must be no rungs up');
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
        final def = id.definition;
        if (def is! EquipmentItemDefinition) continue;
        expect(
          id.build().quality,
          // a piece whose tier is its rarity (skilling gear) wears that
          def.fixedRarity ?? def.quality,
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

    test('every ZoneId is frozen the moment it exists', () {
      // every save writes an entry for every zone, so a zone is in the
      // player's save as soon as a build with it has run — committed or not.
      // a new zone goes on frozenZoneIds when it is added, which is what
      // makes the test above catch renaming it later. a rename that has to
      // happen keeps its old name in ZoneId.renamed.
      final unfrozen = ZoneId.values
          .map((e) => e.name)
          .where((name) => !frozenZoneIds.contains(name));
      expect(
        unfrozen,
        isEmpty,
        reason: 'add these to frozenZoneIds: ${unfrozen.join(', ')}',
      );
    });
    test('no DungeonId was renamed or removed', () {
      expect(
        DungeonId.values.map((e) => e.name).toSet(),
        containsAll(frozenDungeonIds),
      );
    });
  });

  // A unique — a piece made of nothing, dropped by a monster — is worth the
  // material whose rung it sits on (its rung less its slot and shape). The
  // catalog's material drops run about six rungs under the monster, so a
  // unique may run at most five under: a little ahead of the steel or
  // mithril dropping beside it, never a dragon piece off an L144 boss.
  group('loot curve', () {
    bool isUnique(ItemId id) {
      final def = id.definition;
      return def is EquipmentItemDefinition &&
          def is! JewelleryDefinition &&
          def.materialId == EquipmentMaterialId.NULL &&
          def.fixedStats == null &&
          !def.ungated;
    }

    int materialRung(ItemId id) {
      final def = id.definition as EquipmentItemDefinition;
      return def.fibLevel - def.fibOffset;
    }

    int ceilingFor(int monsterRung) =>
        monsterRung - 5 < 0 ? 0 : monsterRung - 5;

    Iterable<ItemDropType> dropsOf(CombatEntityDefinition def) => [
      ...def.itemDrops.flattened,
      for (final roll in def.bonusDrops) ...roll.entries.flattened,
    ];

    test('no monster drops a unique above its rung', () {
      final over = <String>[];
      for (final id in EntityId.values) {
        final def = id.definition;
        if (def is! CombatEntityDefinition) continue;
        for (final drop in dropsOf(def)) {
          if (!isUnique(drop.id)) continue;
          if (materialRung(drop.id) > ceilingFor(def.fibLevel)) {
            over.add(
              '${id.name} (rung ${def.fibLevel}) → ${drop.id.name} '
              '(worth rung ${materialRung(drop.id)}, ceiling '
              '${ceilingFor(def.fibLevel)})',
            );
          }
        }
      }
      expect(over.toSet(), isEmpty);
    });

    test('no dungeon chest holds a unique above its bosses', () {
      final over = <String>[];
      for (final id in DungeonId.values) {
        final def = id.definition;
        var top = 0;
        for (final entry in def.entries) {
          for (final ref in entry.entities) {
            final e = ref.entityId.definition;
            if (e is CombatEntityDefinition && e.fibLevel > top) {
              top = e.fibLevel;
            }
          }
        }
        for (final roll in def.chestRolls) {
          for (final drop in roll.entries.flattened) {
            if (!isUnique(drop.id)) continue;
            if (materialRung(drop.id) > ceilingFor(top)) {
              over.add('${id.name} chest → ${drop.id.name}');
            }
          }
        }
      }
      expect(over, isEmpty);
    });

    test('a unique stronger than copper asks for a level to wear', () {
      final free = [
        for (final id in ItemId.values)
          if (isUnique(id) &&
              materialRung(id) > 0 &&
              (id.definition as EquipmentItemDefinition)
                      .skillLevelRequirement <=
                  0)
            id.name,
      ];
      expect(free, isEmpty);
    });

    test('every weapon swings at its type\'s pace', () {
      // a dagger, a sword and a greatsword deal the same per second on a
      // rung; a weapon that sped its own swing up would break that
      final off = [
        for (final id in ItemId.values)
          if (id.definition case final WeaponItemDefinition def
              when def.actionInterval !=
                  def.weaponType.parameters.actionInterval)
            id.name,
      ];
      expect(off, isEmpty);
    });

    test('a shape that hits and carries stats takes a reduced hit', () {
      // a full sword's damage and an armour budget on top is two pieces in
      // one slot
      final doubled = [
        for (final type in WeaponTypeId.values)
          if (type.parameters.usesDamage &&
              type.parameters.statWeight.isNotEmpty &&
              type.parameters.damageScale > 0.5)
            type.name,
      ];
      expect(doubled, isEmpty);
    });
  });

  // The shape every dungeon's loot takes — design/DUNGEON_LOOT_GUIDE.md.
  // A boss's uniques ride its bonus rolls, each at its own rarity; its
  // main table is the material haul. A dungeon whose bosses carry no gear
  // yet is skipped until they do.
  group('loot structure', () {
    bool isBoss(EntityId id) {
      final def = id.definition;
      return def is CombatEntityDefinition && def.isDungeonBoss;
    }

    // a boss's uniques, and the rarities each one drops at
    Map<ItemId, Set<Rarity>> uniquesOf(EntityId boss) {
      final def = boss.definition as CombatEntityDefinition;
      final out = <ItemId, Set<Rarity>>{};
      for (final roll in def.bonusDrops) {
        for (final line in roll.entries.flattened) {
          if (line.id.definition is! EquipmentItemDefinition) continue;
          (out[line.id] ??= {}).add(line.rarity);
        }
      }
      return out;
    }

    final dungeons = [
      for (final id in DungeonId.values)
        if (id != DungeonId.NULL && !id.name.startsWith('DEV')) id,
    ];
    List<EntityId> bossesOf(DungeonId id) => [
      for (final entry in id.definition.entries)
        for (final ref in entry.entities)
          if (isBoss(ref.entityId)) ref.entityId,
    ];
    bool hasGear(DungeonId id) =>
        bossesOf(id).any((b) => uniquesOf(b).isNotEmpty);

    // two rarities, one step apart: the band's pair
    String? pairOf(Set<Rarity> r) {
      if (r.length != 2) return null;
      final i = r.map((x) => x.index).toList()..sort();
      if (i[1] - i[0] != 1) return null;
      return '${Rarity.values[i[0]].name}/${Rarity.values[i[1]].name}';
    }

    test('every boss owns one or two uniques, at its band\'s two rarities', () {
      final owners = <ItemId, Set<EntityId>>{};
      final wrong = <String>[];
      for (final id in dungeons.where(hasGear)) {
        final pairs = <String?>{};
        for (final boss in bossesOf(id)) {
          final uniques = uniquesOf(boss);
          if (uniques.isEmpty || uniques.length > 2) {
            wrong.add('${boss.name} has ${uniques.length} uniques');
          }
          for (final MapEntry(key: item, value: rarities) in uniques.entries) {
            (owners[item] ??= {}).add(boss);
            final pair = pairOf(rarities);
            if (pair == null) wrong.add('${boss.name} → ${item.name}');
            pairs.add(pair);
          }
        }
        if (pairs.length > 1) wrong.add('${id.name} mixes bands $pairs');
      }
      for (final MapEntry(key: item, value: bosses) in owners.entries) {
        if (bosses.length > 1) wrong.add('${item.name} shared by $bosses');
      }
      expect(wrong, isEmpty);
    });

    test('every chest has its own pieces, and only some of the bosses\', '
        'at no better than the bosses drop them', () {
      final wrong = <String>[];
      for (final id in dungeons.where(hasGear)) {
        final bossTop = <ItemId, int>{};
        final bands = <String?>{};
        for (final boss in bossesOf(id)) {
          for (final MapEntry(key: item, value: r) in uniquesOf(boss).entries) {
            bossTop[item] = r.map((x) => x.index).reduce(max);
            bands.add(pairOf(r));
          }
        }
        final chest = <ItemId, Set<Rarity>>{};
        for (final roll in id.definition.chestRolls) {
          for (final line in roll.entries.flattened) {
            if (line.id.definition is! EquipmentItemDefinition) continue;
            (chest[line.id] ??= {}).add(line.rarity);
          }
        }
        final exclusives = {
          for (final e in chest.entries)
            if (!bossTop.containsKey(e.key)) e.key: e.value,
        };
        final pieces = {
          for (final e in chest.entries)
            if (bossTop.containsKey(e.key)) e.key: e.value,
        };
        if (exclusives.isEmpty || exclusives.length > 2) {
          wrong.add('${id.name} chest has ${exclusives.length} exclusives');
        }
        for (final MapEntry(key: item, value: r) in exclusives.entries) {
          if (!bands.contains(pairOf(r))) {
            wrong.add('${id.name} chest → ${item.name} off the band');
          }
        }
        // a few of the bosses' pieces, never the whole set
        final allOfThem = bossTop.length > 1 && pieces.length >= bossTop.length;
        if (pieces.length > 3 || allOfThem) {
          wrong.add(
            '${id.name} chest gives ${pieces.length} of ${bossTop.length}',
          );
        }
        for (final MapEntry(key: item, value: r) in pieces.entries) {
          if (r.any((x) => x.index > bossTop[item]!)) {
            wrong.add('${id.name} chest → ${item.name} above its boss');
          }
        }
      }
      expect(wrong, isEmpty);
    });

    test('every boss or chest unique sets its secondaries in the catalog', () {
      final missing = <String>{};
      for (final id in dungeons.where(hasGear)) {
        final items = <ItemId>{
          for (final boss in bossesOf(id)) ...uniquesOf(boss).keys,
          for (final roll in id.definition.chestRolls)
            for (final line in roll.entries.flattened)
              if (line.id.definition is EquipmentItemDefinition) line.id,
        };
        for (final item in items) {
          final def = item.definition as EquipmentItemDefinition;
          final set = def.catalogSecondaries;
          if (set == null ||
              set.length != Rarity.LEGENDARY.secondaryRolls ||
              set.any(
                (s) => !EquipmentItemDefinition.secondaryStatPool.contains(s),
              )) {
            missing.add(item.name);
          }
        }
      }
      expect(missing, isEmpty);
    });

    test('no unique carries both strength and speed secondaries', () {
      final both = <String>{};
      for (final id in ItemId.values) {
        final def = id.definition;
        if (def is! EquipmentItemDefinition) continue;
        final set = def.catalogSecondaries;
        if (set != null &&
            set.contains(SkillId.STRENGTH) &&
            set.contains(SkillId.SPEED)) {
          both.add(id.name);
        }
      }
      expect(both, isEmpty);
    });

    test('no boss or chest unique is pure defence: that is the smith\'s', () {
      final pure = <String>{};
      for (final id in dungeons.where(hasGear)) {
        final items = <ItemId>{
          for (final boss in bossesOf(id)) ...uniquesOf(boss).keys,
          for (final roll in id.definition.chestRolls)
            for (final line in roll.entries.flattened)
              if (line.id.definition is EquipmentItemDefinition) line.id,
        };
        for (final item in items) {
          // a unique's secondaries count: a defence primary with core
          // stats set alongside it is not the smith's plain plate
          final def = item.definition as EquipmentItemDefinition;
          final weights = {...def.statWeights.keys, ...?def.catalogSecondaries};
          if (weights.length == 1 && weights.single == SkillId.DEFENCE) {
            pure.add(item.name);
          }
        }
      }
      expect(pure, isEmpty);
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
  'WOOD_SHIELD',
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
  'COPPER_FISHING_ROD',
  'IRON_FISHING_ROD',
  'STEEL_FISHING_ROD',
  'MITHRIL_FISHING_ROD',
  'ADAMANT_FISHING_ROD',
  'RUNE_FISHING_ROD',
  'DRAGON_FISHING_ROD',
  'PITCHFORK',
  'GOBLIN_CROWN',
  'GOBLIN_SCEPTER',
  'SPIDER_SILK_NECKLACE',
  'GOBLIN_QUEEN_KEY',
  // the leather ladder: nine tiers across eight slots
  'LIGHT_LEATHER_COIF',
  'MEDIUM_LEATHER_COIF',
  'HEAVY_LEATHER_COIF',
  'LIGHT_DRAGONHIDE_COIF',
  'MEDIUM_DRAGONHIDE_COIF',
  'HEAVY_DRAGONHIDE_COIF',
  'LIGHT_DEMONHIDE_COIF',
  'MEDIUM_DEMONHIDE_COIF',
  'HEAVY_DEMONHIDE_COIF',
  'LIGHT_LEATHER_SPAULDERS',
  'MEDIUM_LEATHER_SPAULDERS',
  'HEAVY_LEATHER_SPAULDERS',
  'LIGHT_DRAGONHIDE_SPAULDERS',
  'MEDIUM_DRAGONHIDE_SPAULDERS',
  'HEAVY_DRAGONHIDE_SPAULDERS',
  'LIGHT_DEMONHIDE_SPAULDERS',
  'MEDIUM_DEMONHIDE_SPAULDERS',
  'HEAVY_DEMONHIDE_SPAULDERS',
  'MEDIUM_LEATHER_CHEST',
  'HEAVY_LEATHER_CHEST',
  'LIGHT_DRAGONHIDE_CHEST',
  'MEDIUM_DRAGONHIDE_CHEST',
  'HEAVY_DRAGONHIDE_CHEST',
  'LIGHT_DEMONHIDE_CHEST',
  'MEDIUM_DEMONHIDE_CHEST',
  'HEAVY_DEMONHIDE_CHEST',
  'LIGHT_LEATHER_BELT',
  'MEDIUM_LEATHER_BELT',
  'HEAVY_LEATHER_BELT',
  'LIGHT_DRAGONHIDE_BELT',
  'MEDIUM_DRAGONHIDE_BELT',
  'HEAVY_DRAGONHIDE_BELT',
  'LIGHT_DEMONHIDE_BELT',
  'MEDIUM_DEMONHIDE_BELT',
  'HEAVY_DEMONHIDE_BELT',
  'LIGHT_LEATHER_BRACERS',
  'MEDIUM_LEATHER_BRACERS',
  'HEAVY_LEATHER_BRACERS',
  'LIGHT_DRAGONHIDE_BRACERS',
  'MEDIUM_DRAGONHIDE_BRACERS',
  'HEAVY_DRAGONHIDE_BRACERS',
  'LIGHT_DEMONHIDE_BRACERS',
  'MEDIUM_DEMONHIDE_BRACERS',
  'HEAVY_DEMONHIDE_BRACERS',
  'MEDIUM_LEATHER_PANTS',
  'HEAVY_LEATHER_PANTS',
  'LIGHT_DRAGONHIDE_PANTS',
  'MEDIUM_DRAGONHIDE_PANTS',
  'HEAVY_DRAGONHIDE_PANTS',
  'LIGHT_DEMONHIDE_PANTS',
  'MEDIUM_DEMONHIDE_PANTS',
  'HEAVY_DEMONHIDE_PANTS',
  'MEDIUM_LEATHER_BOOTS',
  'HEAVY_LEATHER_BOOTS',
  'LIGHT_DRAGONHIDE_BOOTS',
  'MEDIUM_DRAGONHIDE_BOOTS',
  'HEAVY_DRAGONHIDE_BOOTS',
  'LIGHT_DEMONHIDE_BOOTS',
  'MEDIUM_DEMONHIDE_BOOTS',
  'HEAVY_DEMONHIDE_BOOTS',
  'MEDIUM_LEATHER_GLOVES',
  'HEAVY_LEATHER_GLOVES',
  'LIGHT_DRAGONHIDE_GLOVES',
  'MEDIUM_DRAGONHIDE_GLOVES',
  'HEAVY_DRAGONHIDE_GLOVES',
  'LIGHT_DEMONHIDE_GLOVES',
  'MEDIUM_DEMONHIDE_GLOVES',
  'HEAVY_DEMONHIDE_GLOVES',
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
  'RESTLESS_SKELETON',
  'GRAVE_GHOUL',
  'WAILING_BANSHEE',
  'MIST_WRAITH',
  'FALLEN_MONK',
  'THE_GRAVEKEEPER',
  'THE_WEEPING_ABBESS',
  'THE_UNDYING_ABBOT',
  'HAUNTED_RUINS_ENTRANCE',
  'REEDMAZE_ENTRANCE',
  'SILT_WARRENS_ENTRANCE',
  'BRINEDEEP_CAVES_ENTRANCE',
};

const frozenZoneIds = <String>{
  'TUTORIAL_FARM',
  'SOUTHWOOD_FOREST',
  'SOUTH_HAVEN',
  'REEDWATER_VALE',
  'MUDMOUTH_DELTA',
  'SALTWIND_COAST',
  'FOREST_MINE',
  'FOREST_MINE_DEPTHS',
  'CHALLENGING_MOUNTAIN',
  'DARKWOOD_FOREST',
  'SWAMP',
  'MAPLEWATER_LAKE',
  'MAPLEWATER_VILLAGE',
  'YEW_GROVE',
  'MAGIC_GROVE',
  'FOOTHILLS',
  'COPPERDUST_FLATS',
  'MISTGRAVE_HOLLOW',
  'IRON_GATE_CITY',
  'IRONROOT_HILLS',
  'IRONROOT_MINE',
  'REDWALL_BLUFFS',
  'GREYSPINE_MOUNTAIN',
  'ASHRIDGE_MOUNTAINS',
  'SADDLEGATE',
  'FROSTCROWN_PEAKS',
  'STORMCROWN_PEAKS',
  'MOLTENSPIRE_PEAKS',
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
  'HAUNTED_RUINS',
  'REEDMAZE',
  'SILT_WARRENS',
  'BRINEDEEP_CAVES',
};
