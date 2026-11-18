// ignore_for_file: constant_identifier_names

import 'dart:ui' show Color;

import 'package:rpg/catalogs/items/definition/equipment_item_definition.dart';
import 'package:rpg/catalogs/items/item_id.dart';
import 'package:rpg/catalogs/rarity.dart';
import 'package:rpg/data/equipment_data.dart';
import 'package:rpg/data/skill_data.dart';
import 'package:rpg/utilities/util.dart';

/// How a gem is cut. The cut is the jewelcrafting ladder: each one is a rung
/// of the Fibonacci ladder, so a round stone is worth 3 and a radiant one 34
/// before rarity and the setting's offset — the same [fibLevel] budget
/// armour reads off its material.
///
/// The overlay is drawn in greyscale and tinted per gem (see
/// `JewelleryIcon`), so six sprites cover every stone.
enum GemCut {
  ROUND('Round', 2, 'assets/icons/jewellery/cut_round.png'),
  SQUARE('Square', 3, 'assets/icons/jewellery/cut_square.png'),
  CUSHION('Cushion', 4, 'assets/icons/jewellery/cut_cushion.png'),
  MARQUISE('Marquise', 5, 'assets/icons/jewellery/cut_marquise.png'),
  ASSCHER('Asscher', 6, 'assets/icons/jewellery/cut_asscher.png'),
  RADIANT('Radiant', 7, 'assets/icons/jewellery/cut_radiant.png');

  const GemCut(this.label, this.rung, this.overlayAsset);

  final String label;

  /// The rung of `Util.fibonacciCache` a ring of this cut sits on.
  final int rung;

  final String overlayAsset;
}

/// What a gem does once set, where it unlocks, and the colour its cut
/// overlay is tinted.
///
/// The four colored gems are the core stats and drop commonly; diamond and
/// dragonstone are the combat pair and drop rarely; onyx is the rarest and
/// carries no stat at all — it boosts xp in every skill instead, so it sits
/// a rung lower on the ladder than the stat gems (see [rungOffset]).
enum GemType {
  TOPAZ(
    gemItem: ItemId.TOPAZ,
    stat: SkillId.SPEED,
    cutLevels: [1, 15, 30, 45, 60, 75],
    color: Color(0xFFF2B53A),
    valueScale: 1,
  ),
  SAPPHIRE(
    gemItem: ItemId.SAPPHIRE,
    stat: SkillId.STAMINA,
    cutLevels: [3, 17, 32, 47, 62, 77],
    color: Color(0xFF3A6CF2),
    valueScale: 1,
  ),
  EMERALD(
    gemItem: ItemId.EMERALD,
    stat: SkillId.RECOVERY,
    cutLevels: [5, 19, 34, 49, 64, 79],
    color: Color(0xFF34C25A),
    valueScale: 1,
  ),
  RUBY(
    gemItem: ItemId.RUBY,
    stat: SkillId.STRENGTH,
    cutLevels: [7, 21, 36, 51, 66, 81],
    color: Color(0xFFE0303A),
    valueScale: 1,
  ),
  DIAMOND(
    gemItem: ItemId.DIAMOND,
    stat: SkillId.DEFENCE,
    cutLevels: [24, 40, 54, 68, 84, 92],
    color: Color(0xFFD8F0FF),
    valueScale: 2,
  ),
  DRAGONSTONE(
    gemItem: ItemId.DRAGONSTONE,
    stat: SkillId.ATTACK,
    cutLevels: [26, 42, 56, 70, 86, 94],
    color: Color(0xFFD23ED8),
    valueScale: 2,
  ),
  ONYX(
    gemItem: ItemId.ONYX,
    stat: null,
    cutLevels: [50, 58, 72, 83, 90, 99],
    color: Color(0xFF6A5C78),
    valueScale: 4,
  );

  const GemType({
    required this.gemItem,
    required this.stat,
    required this.cutLevels,
    required this.color,
    required this.valueScale,
  });

  /// How much dearer a piece set with this gem sells for than a core gem's.
  final int valueScale;

  /// The uncut stone a setting consumes.
  final ItemId gemItem;

  /// The stat a piece set with this gem carries; null for onyx, whose
  /// budget is read as an xp percent instead.
  final SkillId? stat;

  /// The jewelcrafting level each [GemCut] unlocks at, in cut order.
  final List<int> cutLevels;

  /// Multiplied into the greyscale cut overlay: white becomes this.
  final Color color;

  bool get boostsXp => stat == null;

  /// Onyx's percents (2, 3, 5, 8, 13, 21) are the stat ladder one rung down.
  int get rungOffset => boostsXp ? -1 : 0;

  int levelFor(GemCut cut) => cutLevels[cut.index];
}

/// What the gem is set into. Each setting is one base sprite, and the 16x16
/// cut overlay is drawn into the square [overlayLeft], [overlayTop],
/// [overlaySize] — source pixels on the 32x32 base, measured off the
/// generated art.
///
/// The bases are bare gold — a plain band and a plain chain, no setting or
/// bezel — and the stone is drawn full size over them: on top of the band
/// (y 6 down), and hanging from the chain's point with the clasp (16, 24)
/// hidden behind it.
enum JewellerySetting {
  RING(
    label: 'Ring',
    slot: ArmorSlots.FINGER,
    goldBase: ItemId.GOLD_RING,
    baseAsset: 'assets/icons/jewellery/ring_base.png',
    overlayLeft: 8,
    overlayTop: 0,
    overlaySize: 16,
  ),
  NECKLACE(
    label: 'Necklace',
    slot: ArmorSlots.NECK,
    goldBase: ItemId.GOLD_NECKLACE,
    baseAsset: 'assets/icons/jewellery/necklace_base.png',
    overlayLeft: 8,
    overlayTop: 16,
    overlaySize: 16,
  );

  const JewellerySetting({
    required this.label,
    required this.slot,
    required this.goldBase,
    required this.baseAsset,
    required this.overlayLeft,
    required this.overlayTop,
    required this.overlaySize,
  });

  /// The base sprite's edge, in source pixels.
  static const double baseSize = 32;

  final String label;

  /// Where a piece in this setting is worn. Its [ArmorSlots.fibOffset] is
  /// the necklace's extra rung.
  final ArmorSlots slot;

  /// The plain gold piece the gem is set into.
  final ItemId goldBase;

  final String baseAsset;
  final double overlayLeft;
  final double overlayTop;
  final double overlaySize;
}

/// A gem set into gold: everything about the piece follows from [gem],
/// [cut] and [setting], the way armour follows from its material. Each
/// combination is its own [ItemId], so icons, stacking, drops and saves all
/// work off the id with nothing extra on the instance.
///
/// Rarity scales it through [budgetAt] on jewellery's own ladder — one
/// multiplier on the whole budget, no secondary rolls — onyx included,
/// whose budget is read as [xpPercentAt] instead of being split into a stat.
class JewelleryDefinition extends EquipmentItemDefinition {
  const JewelleryDefinition({
    required this.gem,
    required this.cut,
    required this.setting,
  }) : super(name: '', value: 0);

  final GemType gem;
  final GemCut cut;
  final JewellerySetting setting;

  @override
  String get name =>
      '${cut.label} ${gem.gemItem.definition.name} ${setting.label}';

  @override
  int get value => 10 * Util.fib(fibLevel) * gem.valueScale;

  /// An id-only lookup still finds a file: the empty setting. Everything
  /// that draws an icon layers the cut over it (see `JewelleryIcon`).
  @override
  String? get iconAsset => setting.baseAsset;

  @override
  ArmorSlots get defaultSlot => setting.slot;

  @override
  int get fibLevel => cut.rung + gem.rungOffset + armorSlot.fibOffset;

  /// Jewellery is gated where it is cut, at the bench, not where it is
  /// worn — so it never takes the rung-derived level a unique does.
  @override
  int get skillLevelRequirement => 0;

  /// Crafted jewellery is the one kind of gear left on the
  /// single-multiplier ladder: no secondaries, rolled or set.
  @override
  bool get rollsSecondaries => false;

  @override
  Map<SkillId, int> get statWeights {
    final stat = gem.stat;
    return stat == null ? const {} : {stat: 1};
  }

  /// The xp bonus, as a percent, a piece of this definition gives at
  /// [rarity] — zero for a stat gem.
  int xpPercentAt(Rarity rarity) {
    if (!gem.boostsXp) return 0;
    // one stat over one weight pays out exactly its budget, so the floor
    // is measured on the budget itself
    return EquipmentItemDefinition.scaledBudget(
      Util.fib(fibLevel),
      rarity,
      (budget) => budget,
    );
  }
}
