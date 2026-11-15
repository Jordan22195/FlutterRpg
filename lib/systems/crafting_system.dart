import 'dart:math';
import 'package:rpg/catalogs/entities/entities.dart';
import 'package:rpg/catalogs/items/items.dart';
import 'package:rpg/data/buff_data.dart';
import '../data/action_result.dart';
import '../data/player_data.dart';
import '../data/skill_data.dart';
import '../data/crafting_state.dart';
import '../data/recipe_details.dart';
import '../data/world_data.dart';
import '../data/inventory_data.dart';
import '../catalogs/recipes/recipes.dart';
import '../services/player_data_service.dart';
import '../services/crafting_service.dart';
import '../services/inventory_service.dart';
import '../services/weighted_drop_table_service.dart';
import 'firemaking_system.dart';

class CraftingSystem {
  // catalogs
  final RecipeCatalog _recipeCatalog;

  // services
  final PlayerDataService _playerDataService;
  final CraftingService _craftingService;
  final InventoryService _inventoryService;
  final WeightedDropTableService _weightedDropTableService;

  // systems
  final FiremakingSystem _firemakingSystem;

  CraftingSystem({
    required PlayerData playerState,
    required InventoryData inventoryData,
    required CraftingState craftingState,
    required WorldData worldState,
    required RecipeCatalog recipeCatalog,
    required PlayerDataService playerDataService,
    required CraftingService craftingService,
    required InventoryService inventoryService,
    required WeightedDropTableService weightedDropTableService,
    required FiremakingSystem firemakingSystem,
  }) : _recipeCatalog = recipeCatalog,
       _playerDataService = playerDataService,
       _craftingService = craftingService,
       _inventoryService = inventoryService,
       _weightedDropTableService = weightedDropTableService,
       _firemakingSystem = firemakingSystem;

  /// Crafts the active recipe, once by default and [craftCount] times when a
  /// stretch of time away is being settled in one go. Returns what it
  /// produced so callers can report it. An empty result means nothing was
  /// made - the level, the materials or the fire were not there.
  ///
  /// With [offline] set the whole batch is settled in a single pass: every
  /// craft's inputs are consumed at once, and the output table is rolled
  /// through [WeightedDropTableService.rollMulitpleTimes] rather than once
  /// per craft. That pays the same xp and the same expected output as
  /// looping, which is what lets hours of offline progress resolve in one
  /// call - and it holds for a batch of one, so a settle can measure its own
  /// rate off a single deterministic craft.
  ///
  /// [at] is the instant being crafted at, which for a settle is the segment
  /// being replayed rather than the wall clock hours later. It is what the
  /// cooking fire is judged against.
  ///
  /// The batch is capped at what the inventory can actually pay for, so a
  /// long stretch away crafts until the materials run out rather than on
  /// credit - which is exactly where the loop would have stopped.
  EncounterActionResult craftActiveRecipe(
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    BuffData buffState,
    WorldData worldState, {
    int craftCount = 1,
    bool offline = false,
    DateTime? at,
  }) {
    final result = EncounterActionResult();
    final r = _recipeCatalog.recipeById(craftingState.activeRecipeId);

    if (!checkRecipeLevelRequirement(r.id, playerState, at: at)) {
      return result;
    }

    // the firepit's reagent mix throws its reagents together
    if (r.isReagentMix) {
      return _throwMix(
        craftCount,
        craftingState,
        playerState,
        inventoryState,
        buffState,
        result,
        at: at,
      );
    }

    // Check again. this comes before the fire check so a cook with nothing
    // left to cook never burns logs on a fire it will not use
    final craftable = craftableCount(r.id, inventoryState);
    final crafts = craftCount < craftable ? craftCount : craftable;
    if (crafts <= 0) return result;

    // a reagent goes on the station's fire rather than into the bag, and
    // only on a campfire or bonfire already burning
    final reagent = r.tendReagent;
    if (reagent != null) {
      final fire = _firemakingSystem.activeFire(
        craftingState.craftingEntityId,
        playerState.currentZoneId,
        playerState.buffData,
        at: at,
      );
      if (fire == null || !fire.tendable) return result;
      // only as many as the fire has room for: past its end a reagent
      // would burn for nothing. a full ring throws none
      final room = _reagentRoom(fire, reagent, at ?? DateTime.now());
      final thrown = crafts < room ? crafts : room;
      if (thrown <= 0) return result;
      for (final entry in r.inputs.entries) {
        _inventoryService.removeItems(
          inventoryState,
          entry.key,
          entry.value * thrown,
        );
      }
      fire.tend(
        (reagent.definition as FireReagentDefinition).stat,
        at ?? DateTime.now(),
        count: thrown,
      );
      result.actionsPerformed = thrown;
      result.xp = {r.skill: r.xp * thrown};
      _playerDataService.applyXp(playerState, result.xp);
      return result;
    }

    // cooking needs a fire that can cook, at the moment being crafted. a
    // live craft asks about now; a settle asks about the segment it is
    // replaying, when the fire may still have been burning. a cook tick
    // without one spends itself lighting the station's cookfire instead.
    if (r.skill == SkillId.COOKING &&
        !_firemakingSystem.canCookAt(
          craftingState.craftingEntityId,
          playerState.currentZoneId,
          playerState.buffData,
          at: at,
        )) {
      return _relightTick(
        cookFireRecipeAt(craftingState.craftingEntityId, craftingState),
        craftingState,
        playerState,
        inventoryState,
        buffState,
        result,
        at: at,
      );
    }

    // Consume inputs, a whole batch's worth at a time
    for (final entry in r.inputs.entries) {
      _inventoryService.removeItems(
        inventoryState,
        entry.key,
        entry.value * crafts,
      );
    }

    final outputTable = adjustDropTable(r.id, playerState, at: at);

    // a bonus-output recipe rolls the quality ladder first: each craft is
    // worth one output roll per tier step, so a legendary smelt pays five
    // bars. live that is one roll's stack scaled; a batch rolls the output
    // table once per craft's worth
    final multiplier = r.rollsBonusOutput
        ? _bonusOutputUnits(r, playerState, crafts, offline: offline, at: at)
        : (offline ? crafts : 1);

    // one stack per distinct output. a live craft still rolls its own stack
    // size rather than taking the table's mean, so nothing about normal
    // play changes.
    final rolled = offline
        ? _weightedDropTableService.rollMulitpleTimes(multiplier, outputTable)
        : [
            for (final stack in [_weightedDropTableService.roll(outputTable)])
              stack..count = stack.count * multiplier,
          ];

    for (final craftedItemObjectStack in rolled) {
      if (craftedItemObjectStack.count <= 0) continue;

      // a fire is not an item: it becomes a buff on the firepit being worked
      // at. that is the session's station, not whatever the player happens to
      // be looking at — crafting keeps running after you navigate away.
      if (r.skill == SkillId.FIREMAKING) {
        _firemakingSystem.lightOrExtend(
          craftedItemObjectStack.id,
          craftingState.craftingEntityId,
          playerState.currentZoneId,
          buffState,
          count: craftedItemObjectStack.count,
          burnScale: _burnScaleFor(r, playerState, at: at),
        );
        continue;
      }

      // equipment takes its own path: it is a unique instance carrying a
      // rolled quality, and never stacks with a plain item
      if (craftedItemObjectStack.id.build() is EquipmentItem) {
        _addCraftedEquipment(
          craftedItemObjectStack.id,
          craftedItemObjectStack.count,
          r,
          craftingState,
          playerState,
          inventoryState,
          result,
          offline: offline,
          at: at,
        );
      } else {
        _inventoryService.addItems(inventoryState, [craftedItemObjectStack]);
        _inventoryService.addItems(craftingState.craftedItems, [
          craftedItemObjectStack,
        ]);
        result.items.add(craftedItemObjectStack);
      }
    }

    result.actionsPerformed = crafts;
    result.xp = {r.skill: r.xp * crafts};
    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }

  /// A cook or tend tick with no fire it can work under it spends itself
  /// lighting [fire], the one the station has picked: the logs are paid, the
  /// fire is lit at [at] and
  /// firemaking is trained, exactly as a manual craft of that fire would.
  /// Nothing is cooked, so the session grid and the report's items stay
  /// food-only.
  ///
  /// It ignores the batch's craft count: a relight is exactly one fire, and
  /// the rest of the stretch is handed back to the loop via
  /// [EncounterActionResult.handedOff], so a settle charges the tick and
  /// cuts the remainder around the fire it just lit.
  ///
  /// The fire lands in [PlayerData.currentZoneId], as the firemaking output
  /// path above does - not the session's craftingZoneId. A cook left
  /// running while the player travels would light the wrong pit, which is
  /// the same pre-existing gap as that path's.
  EncounterActionResult _relightTick(
    CraftingRecipe? fire,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    BuffData buffState,
    EncounterActionResult result, {
    DateTime? at,
  }) {
    final station = craftingState.craftingEntityId;
    if (fire == null) return result;
    if (!checkRecipeLevelRequirement(fire.id, playerState, at: at)) {
      return result;
    }
    if (craftableCount(fire.id, inventoryState) <= 0) return result;

    for (final entry in fire.inputs.entries) {
      _inventoryService.removeItems(inventoryState, entry.key, entry.value);
    }

    // a fire recipe is a single weight-one entry, so the output is read off
    // the table rather than rolled: it is the same fire a manual craft lights
    _firemakingSystem.lightOrExtend(
      fire.output.first.id,
      station,
      playerState.currentZoneId,
      buffState,
      at: at,
      burnScale: _burnScaleFor(fire, playerState, at: at),
    );

    result.actionsPerformed = 1;
    result.handedOff = true;
    result.xp = {SkillId.FIREMAKING: fire.xp};
    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }

  /// How much longer a fire laid from [fireRecipe] burns for the player's
  /// firemaking at [at]: the stat total, gear and buffs included and
  /// uncapped, against the recipe's level (see [FireItem.burnScaleFor]).
  double _burnScaleFor(
    CraftingRecipe fireRecipe,
    PlayerData playerState, {
    DateTime? at,
  }) {
    final level =
        _playerDataService.getStatTotals(
          playerState,
          at: at,
        )[SkillId.FIREMAKING] ??
        1;
    return FireItem.burnScaleFor(level, fireRecipe.levelRequirement);
  }

  /// The cookfire recipe [station] has picked, or null when its firemaking
  /// selection is empty, not a fire, or a fire that cannot cook on.
  ///
  /// Cooking lights only the fire the player chose: a campfire selection is
  /// never upgraded into a cookfire behind their back.
  CraftingRecipe? cookFireRecipeAt(
    EntityId station,
    CraftingState craftingState,
  ) {
    final r = _pickedFireRecipeAt(station, craftingState);
    final definition = r?.output.first.id.definition;
    if (definition is! FireItemDefinition || !definition.canCook) return null;
    return r;
  }

  /// The campfire or bonfire recipe [station] has picked, or null when its
  /// fire selection is empty or a cookfire. It is what a tend tick lights
  /// when there is no fire to throw its reagent on.
  CraftingRecipe? tendFireRecipeAt(
    EntityId station,
    CraftingState craftingState,
  ) {
    final r = _pickedFireRecipeAt(station, craftingState);
    final definition = r?.output.first.id.definition;
    if (definition is! FireItemDefinition || !definition.tendable) return null;
    return r;
  }

  CraftingRecipe? _pickedFireRecipeAt(
    EntityId station,
    CraftingState craftingState,
  ) {
    final id =
        craftingState.selectedRecipeByEntity[station]?[SkillId.FIREMAKING] ??
        '';
    if (id.isEmpty) return null;
    final r = _recipeCatalog.recipeById(id);
    if (r.skill != SkillId.FIREMAKING || r.output.isEmpty) return null;
    if (r.tendReagent != null) return null;
    return r;
  }

  /// Whether a cook at [station] could light its selected cookfire at [at]:
  /// a cookfire is picked, its firemaking level is met and its logs are on
  /// hand.
  bool canRelight(
    EntityId station,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) => _canLight(
    cookFireRecipeAt(station, craftingState),
    playerState,
    inventoryState,
    at: at,
  );

  /// Whether a tend can proceed at [station] at [at]: a campfire or bonfire
  /// is burning there. Reagents never light a fire of their own - the pit
  /// has to be lit first.
  bool tendingConditionsMet(
    EntityId station,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) {
    final fire = _firemakingSystem.activeFire(
      station,
      playerState.currentZoneId,
      playerState.buffData,
      at: at,
    );
    return fire != null && fire.tendable;
  }

  bool _canLight(
    CraftingRecipe? fire,
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) {
    if (fire == null) return false;
    if (!checkRecipeLevelRequirement(fire.id, playerState, at: at)) {
      return false;
    }
    return craftableCount(fire.id, inventoryState) > 0;
  }

  /// Whether cooking can proceed at [station] at [at]: a cookfire is
  /// burning there, or the cook could light one on its next tick.
  bool cookingConditionsMet(
    EntityId station,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) {
    if (_firemakingSystem.canCookAt(
      station,
      playerState.currentZoneId,
      playerState.buffData,
      at: at,
    )) {
      return true;
    }
    return canRelight(
      station,
      craftingState,
      playerState,
      inventoryState,
      at: at,
    );
  }

  /// Builds [count] crafted copies of equipment [itemId] into the player's
  /// inventory, the session grid and [result].
  ///
  /// Equipment is a unique instance with a rolled quality, so a batch rolls
  /// the quality table [count] times and builds one instance per tier that
  /// came up - the same pieces the loop would produce, and the same stacks
  /// they merge into, without a random draw each.
  void _addCraftedEquipment(
    ItemId itemId,
    int count,
    CraftingRecipe recipe,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    EncounterActionResult result, {
    required bool offline,
    DateTime? at,
  }) {
    // higher crafting levels raise the odds of the upper tiers
    final skillLevel =
        _playerDataService.getStatTotals(playerState, at: at)[recipe.skill] ??
        1;
    final entries = qualityEntries(skillLevel, recipe.levelRequirement);
    final qualityRollResult = offline
        ? _weightedDropTableService.rollMulitpleTimes(count, entries)
        : [_weightedDropTableService.roll(entries)];

    for (final tier in qualityRollResult) {
      if (tier.count <= 0) continue;
      // every inventory gets its own instance: sharing one object between
      // two of them would double-count when stacks merge
      for (final target in [inventoryState, craftingState.craftedItems]) {
        final piece = itemId.build() as EquipmentItem;
        piece.quality = tier.id;
        piece.count = tier.count;
        _inventoryService.addEquipment(target, piece);
      }
      final reported = itemId.build() as EquipmentItem;
      reported.quality = tier.id;
      reported.count = tier.count;
      result.equipment.add(reported);
    }
  }

  /// How many crafts' worth of output [crafts] bonus-output crafts pay:
  /// each one rolls [qualityEntries] and is worth its tier's step on the
  /// ladder plus one - common 1 up to legendary 5.
  int _bonusOutputUnits(
    CraftingRecipe recipe,
    PlayerData playerState,
    int crafts, {
    required bool offline,
    DateTime? at,
  }) {
    final skillLevel =
        _playerDataService.getStatTotals(playerState, at: at)[recipe.skill] ??
        1;
    final entries = qualityEntries(skillLevel, recipe.levelRequirement);
    final tiers = offline
        ? _weightedDropTableService.rollMulitpleTimes(crafts, entries)
        : [_weightedDropTableService.roll(entries)];
    return tiers.fold(0, (sum, t) => sum + t.count * bonusOutputFor(t.id));
  }

  /// The crafts' worth of output one bonus-output craft at [tier] pays.
  static int bonusOutputFor(Rarity tier) => tier.rung + 1;

  /// Rolls the quality tier for a crafted piece of equipment. Common is
  /// always the most likely outcome; levels above the recipe requirement
  /// shift weight toward the higher tiers.
  Rarity rollQuality(int skillLevel, int levelRequirement) {
    return _weightedDropTableService
        .roll(qualityEntries(skillLevel, levelRequirement))
        .id;
  }

  /// The quality table a craft at [skillLevel] rolls against. Handed out as
  /// a table rather than a single roll so a batch can settle every piece it
  /// made in one pass.
  List<WeightedDropTableEntry<Rarity>> qualityEntries(
    int skillLevel,
    int levelRequirement,
  ) {
    // the stat total against the recipe's level, uncapped: gear and buffs
    // can lift a total far past 99, and a cap there read every recipe the
    // total cleared by 99 or more as the same craft
    final levelBonus = max(0, skillLevel - levelRequirement).toDouble();
    return [
      WeightedDropTableEntry<Rarity>(id: Rarity.COMMON, weight: 100),
      WeightedDropTableEntry<Rarity>(
        id: Rarity.UNCOMMON,
        weight: 1 + levelBonus * 1,
      ),
      WeightedDropTableEntry<Rarity>(
        id: Rarity.RARE,
        weight: .1 + levelBonus * 0.2,
      ),
      WeightedDropTableEntry<Rarity>(
        id: Rarity.EPIC,
        weight: .01 + levelBonus * 0.1,
      ),
      WeightedDropTableEntry<Rarity>(
        id: Rarity.LEGENDARY,
        weight: .001 + levelBonus * 0.01,
      ),
    ];
  }

  /// Everything the bench panel's info tab shows for [recipeId]: what it
  /// makes, what it costs against the inventory on hand, and the odds
  /// behind the craft.
  ///
  /// The odds are whichever table the craft actually rolls. Equipment rolls
  /// [qualityEntries]; everything else rolls its output table through
  /// [adjustDropTable], so a cooking recipe reports the burn chance at the
  /// player's current level rather than the catalog's placeholder weight.
  RecipeDetails buildRecipeDetails(
    PlayerData playerState,
    InventoryData inventoryState,
    String recipeId, {
    DateTime? at,
  }) {
    final recipe = _recipeCatalog.recipeById(recipeId);

    // the level the craft is judged at, which is the one the quality roll
    // reads — base plus equipment plus buffs, not the bare skill level
    final skillLevel =
        _playerDataService.getStatTotals(playerState, at: at)[recipe.skill] ??
        1;

    final materials = [
      for (final input in recipe.inputs.entries)
        RecipeMaterial(
          itemId: input.key,
          name: input.key.definition.name,
          required: input.value,
          held: _inventoryService.getItemCount(inventoryState, input.key),
        ),
    ];

    // the same test the craft path uses to decide which items take the
    // equipment branch, so the tab can never claim a quality roll the
    // craft would not make
    final rollsQuality = recipe.output.any(
      (e) => e.id.build() is EquipmentItem,
    );

    return RecipeDetails(
      recipe: recipe,
      effectiveSkillLevel: skillLevel,
      craftableCount: craftableCount(recipe.id, inventoryState),
      materials: materials,
      outcomes: rollsQuality
          ? _qualityOutcomes(skillLevel, recipe.levelRequirement)
          : recipe.rollsBonusOutput
          ? _bonusOutcomes(recipe, skillLevel)
          : _outputOutcomes(recipe, playerState, at: at),
      rollsQuality: rollsQuality,
    );
  }

  /// The quality ladder as display rows, best tier last so the table reads
  /// the way the ladder does.
  List<RecipeOutcomeChance> _qualityOutcomes(
    int skillLevel,
    int levelRequirement,
  ) {
    final chances = WeightedDropTableService.chances(
      qualityEntries(skillLevel, levelRequirement),
    );
    return [
      for (final quality in Rarity.ladder)
        RecipeOutcomeChance(
          // common's label is empty, since it is the unprefixed name
          label: quality.label.isEmpty ? 'Common' : quality.label,
          quality: quality,
          chance: chances[quality] ?? 0,
        ),
    ];
  }

  /// The quality ladder read as output: one row per tier, labelled with
  /// what it pays and coloured like the tier it rolled.
  List<RecipeOutcomeChance> _bonusOutcomes(
    CraftingRecipe recipe,
    int skillLevel,
  ) {
    final chances = WeightedDropTableService.chances(
      qualityEntries(skillLevel, recipe.levelRequirement),
    );
    final perCraft = recipe.output.first.count;
    final itemId = recipe.output.first.id;
    return [
      for (final tier in Rarity.ladder)
        RecipeOutcomeChance(
          label:
              '${bonusOutputFor(tier) * perCraft}x ${itemId.definition.name}',
          itemId: itemId,
          quality: tier,
          chance: chances[tier] ?? 0,
        ),
    ];
  }

  /// The recipe's output table as display rows, commonest first — the same
  /// order an entity's drop table is shown in.
  List<RecipeOutcomeChance> _outputOutcomes(
    CraftingRecipe recipe,
    PlayerData playerState, {
    DateTime? at,
  }) {
    final table = adjustDropTable(recipe.id, playerState, at: at);
    final chances = WeightedDropTableService.chances(table);
    final seen = <ItemId>{};
    final rows = <RecipeOutcomeChance>[];
    for (final entry in table) {
      // chances already summed a repeated id, so it gets one row
      if (!seen.add(entry.id)) continue;
      rows.add(
        RecipeOutcomeChance(
          label: entry.id.definition.name,
          itemId: entry.id,
          chance: chances[entry.id] ?? 0,
          minCount: entry.count,
          maxCount: entry.highCount > entry.count
              ? entry.highCount
              : entry.count,
        ),
      );
    }
    rows.sort((a, b) => b.chance.compareTo(a.chance));
    return rows;
  }

  // right now just scales drop chance for burnt food
  // todo expand on this for all recipies and crafting qualities
  List<WeightedDropTableEntry<ItemId>> adjustDropTable(
    String recipeId,
    PlayerData playerState, {
    DateTime? at,
  }) {
    // the cooking level the burn chance reads includes the fire's own bonus,
    // so a settle has to ask for it at the segment the fire was burning in
    final skillLevels = _playerDataService.getStatTotals(playerState, at: at);
    final recipe = _recipeCatalog.recipeById(recipeId);
    return _craftingService.adjustActiveRecipeDropTable(recipe, skillLevels);
  }

  int craftableCount(String recipeId, InventoryData inventoryData) {
    final recipe = _recipeCatalog.recipeById(recipeId);
    // Minimum across all inputs
    int? min;
    for (final entry in recipe.inputs.entries) {
      final have = _inventoryService.getItemCount(inventoryData, entry.key);
      final perCraft = entry.value <= 0 ? 1 : entry.value;
      final can = have ~/ perCraft;
      min = (min == null) ? can : (can < min ? can : min);
    }
    return min ?? 0;
  }

  bool checkRecipeLevelRequirement(
    String recipeId,
    PlayerData playerState, {
    DateTime? at,
  }) {
    final r = _recipeCatalog.recipeById(recipeId);
    final skillLevel =
        _playerDataService.getStatTotals(playerState, at: at)[r.skill] ?? 0;
    if (skillLevel < r.levelRequirement) return false;
    return true;
  }

  bool recipeRequirementsMet(
    String recipeId,
    PlayerData playerState,
    InventoryData inventoryState,
    CraftingState craftingState, {
    DateTime? at,
  }) {
    if (!checkRecipeLevelRequirement(recipeId, playerState, at: at)) {
      return false;
    }

    // a reagent mix runs while any of its reagents has somewhere to go: a
    // fire to light first, or room on the one burning
    if (_recipeCatalog.recipeById(recipeId).isReagentMix) {
      return tendingConditionsMet(
            craftingState.craftingEntityId,
            craftingState,
            playerState,
            inventoryState,
            at: at,
          ) &&
          mixHasWork(
            craftingState.craftingEntityId,
            craftingState,
            playerState,
            inventoryState,
            at: at,
          );
    }

    if (craftableCount(recipeId, inventoryState) <= 0) return false;

    // cooking needs a fire that can cook, or the logs to light one. checking
    // it here is what stops a running cook loop once the fire has burnt out
    // and there is nothing left to relight it with, via the requirements
    // re-check in CraftingController.doCraftingAction
    final r = _recipeCatalog.recipeById(recipeId);
    if (r.skill == SkillId.COOKING &&
        !cookingConditionsMet(
          craftingState.craftingEntityId,
          craftingState,
          playerState,
          inventoryState,
          at: at,
        )) {
      return false;
    }

    // a reagent needs a campfire or bonfire to go on, or the logs to light
    // the picked one
    if (r.tendReagent != null &&
        !tendingConditionsMet(
          craftingState.craftingEntityId,
          craftingState,
          playerState,
          inventoryState,
          at: at,
        )) {
      return false;
    }

    // and stops once its ring is full. checking it here is what ends a
    // running tend loop the tick the buff reaches the fire's end
    if (reagentFull(
      recipeId,
      craftingState.craftingEntityId,
      playerState,
      at: at,
    )) {
      return false;
    }

    return true;
  }

  /// Whether the reagent [recipeId] throws already burns to the end of the
  /// fire at [station] at [at] - its ring is full, and another would be
  /// wasted. False for a cold pit, which the tend lights first, and for any
  /// recipe that is not a reagent.
  bool reagentFull(
    String recipeId,
    EntityId station,
    PlayerData playerState, {
    DateTime? at,
  }) {
    final reagent = _recipeCatalog.recipeById(recipeId).tendReagent;
    if (reagent == null) return false;
    final fire = _firemakingSystem.activeFire(
      station,
      playerState.currentZoneId,
      playerState.buffData,
      at: at,
    );
    if (fire == null || !fire.tendable) return false;
    return _reagentRoom(fire, reagent, at ?? DateTime.now()) <= 0;
  }

  /// The reagent recipes [station] has picked to keep topped up, in the
  /// order the stage shows their rings: by the stat each buffs ([SkillId]
  /// order - stamina, strength, recovery, attack...). The mix tile, the
  /// picker and the order they are thrown on all read it.
  List<CraftingRecipe> mixAt(EntityId station, CraftingState craftingState) {
    final ids = craftingState.reagentMixByEntity[station] ?? const [];
    return [
      for (final id in ids)
        if (_recipeCatalog.hasRecipe(id) &&
            _recipeCatalog.recipeById(id).tendReagent != null)
          _recipeCatalog.recipeById(id),
    ]..sort(compareReagentRecipes);
  }

  /// Orders reagent recipes by the stat each buffs, in [SkillId] order -
  /// the order the stage shows their rings.
  static int compareReagentRecipes(CraftingRecipe a, CraftingRecipe b) {
    final sa = (a.tendReagent!.definition as FireReagentDefinition).stat;
    final sb = (b.tendReagent!.definition as FireReagentDefinition).stat;
    return sa.index.compareTo(sb.index);
  }

  /// How many of [station]'s picked reagents the bag holds, all told.
  int mixHeldCount(
    EntityId station,
    CraftingState craftingState,
    InventoryData inventoryState,
  ) {
    var held = 0;
    for (final r in mixAt(station, craftingState)) {
      held += craftableCount(r.id, inventoryState);
    }
    return held;
  }

  /// Whether a mix tick at [station] at [at] would throw anything: a
  /// campfire or bonfire is burning, and some picked reagent is unlocked,
  /// held, and has room on it.
  bool mixHasWork(
    EntityId station,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState, {
    DateTime? at,
  }) {
    final fire = _firemakingSystem.activeFire(
      station,
      playerState.currentZoneId,
      playerState.buffData,
      at: at,
    );
    if (fire == null || !fire.tendable) return false;
    for (final r in mixAt(station, craftingState)) {
      if (!checkRecipeLevelRequirement(r.id, playerState, at: at)) continue;
      if (craftableCount(r.id, inventoryState) <= 0) continue;
      if (_reagentRoom(fire, r.tendReagent!, at ?? DateTime.now()) > 0) {
        return true;
      }
    }
    return false;
  }

  /// One mix tick: one of every picked reagent that is unlocked, held and has
  /// room on the fire goes on at once, in the order the stage shows their
  /// rings - stamina, then strength, recovery, attack and so on. A batch
  /// settling time away runs [crafts] such ticks. Nothing goes on a pit that
  /// is not burning a campfire or bonfire.
  EncounterActionResult _throwMix(
    int crafts,
    CraftingState craftingState,
    PlayerData playerState,
    InventoryData inventoryState,
    BuffData buffState,
    EncounterActionResult result, {
    DateTime? at,
  }) {
    final station = craftingState.craftingEntityId;
    final fire = _firemakingSystem.activeFire(
      station,
      playerState.currentZoneId,
      playerState.buffData,
      at: at,
    );
    if (fire == null || !fire.tendable) return result;

    final now = at ?? DateTime.now();
    SkillId statOf(CraftingRecipe r) =>
        (r.tendReagent!.definition as FireReagentDefinition).stat;
    // already in stage order
    final mix = [
      for (final r in mixAt(station, craftingState))
        if (checkRecipeLevelRequirement(r.id, playerState, at: at)) r,
    ];

    var ticks = 0;
    var xp = 0.0;
    for (var i = 0; i < crafts; i++) {
      var thrownThisTick = 0;
      for (final r in mix) {
        if (craftableCount(r.id, inventoryState) <= 0) continue;
        if (_reagentRoom(fire, r.tendReagent!, now) <= 0) continue;
        for (final entry in r.inputs.entries) {
          _inventoryService.removeItems(inventoryState, entry.key, entry.value);
        }
        fire.tend(statOf(r), now);
        xp += r.xp;
        thrownThisTick++;
      }
      // every ring full, or nothing left to throw
      if (thrownThisTick == 0) break;
      ticks++;
    }
    if (ticks <= 0) return result;
    result.actionsPerformed = ticks;
    result.xp = {SkillId.FIREMAKING: xp};
    _playerDataService.applyXp(playerState, result.xp);
    return result;
  }

  /// How many more of [reagent] [fire] has room for at [at]: enough to carry
  /// its buff to the fire's end, the last one allowed to run over.
  int _reagentRoom(FireItem fire, ItemId reagent, DateTime at) {
    final stat = (reagent.definition as FireReagentDefinition).stat;
    final current = fire.reagentExpirations[stat];
    final base = current != null && current.isAfter(at) ? current : at;
    final gap = fire.expirationTime.difference(base).inMicroseconds;
    if (gap <= 0) return 0;
    // a reagent burns longer on a fire a better firemaker laid
    final burn = fire.definition.reagentBurn.inMicroseconds * fire.burnScale;
    return (gap / burn).ceil();
  }
}
