import 'package:flutter/material.dart';

import 'zone_palette.dart';

/// Fill and 1px border of the rounded frame a sprite sits in.
@immutable
class SpriteTint {
  const SpriteTint({required this.fill, required this.border});

  final Color fill;
  final Color border;

  static SpriteTint lerp(SpriteTint a, SpriteTint b, double t) => SpriteTint(
    fill: Color.lerp(a.fill, b.fill, t)!,
    border: Color.lerp(a.border, b.border, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is SpriteTint && other.fill == fill && other.border == border;

  @override
  int get hashCode => Object.hash(fill, border);
}

/// The colours that mean the same thing in every zone. Each one means one
/// thing: a stat colour appears only next to its stat, XP is always [xp]
/// and HP is always [hp]. Read through `context.gameColors`.
@immutable
class GameColors extends ThemeExtension<GameColors> {
  const GameColors({
    required this.exploration,
    required this.stamina,
    required this.speed,
    required this.recovery,
    required this.firemaking,
    required this.cooking,
    required this.xp,
    required this.hp,
    required this.onHp,
    required this.attack,
    required this.stop,
    required this.gathering,
    required this.levelHard,
    required this.levelEven,
    required this.levelEasy,
    required this.upgrade,
    required this.boostPartial,
    required this.boostFull,
    required this.maxHit,
    required this.heal,
    required this.secondaryBar,
    required this.timerFill,
    required this.travel,
  });

  final Color exploration;
  final Color stamina;
  final Color speed;
  final Color recovery;
  final Color firemaking;

  /// Darker than [firemaking] so the two rings differ in lightness.
  final Color cooking;
  final Color xp;
  final Color hp;

  /// The counter drawn on an hp bar.
  final Color onHp;
  final Color attack;

  /// The square on the Stop button.
  final Color stop;
  final Color gathering;

  /// A level read against the player's own: well above it ([levelHard]),
  /// about even ([levelEven]), or well below it ([levelEasy]).
  final Color levelHard;
  final Color levelEven;
  final Color levelEasy;

  /// The dot on a gear slot that something in the bag would improve.
  final Color upgrade;

  /// A stat a strength stance is lending points to, with the boost bar part
  /// way up ([boostPartial]) or held full ([boostFull]).
  final Color boostPartial;
  final Color boostFull;

  /// A roll that came up the top of its range: a max-hit catch.
  final Color maxHit;

  /// How much a food heals, on its tile.
  final Color heal;
  final Color secondaryBar;

  /// The thin attack-timer fill in combat.
  final Color timerFill;

  /// A trip: the travel button and the road bar counting it down.
  final Color travel;

  /// [travel]'s value, for the few places that need it as a constant.
  static const Color travelColor = Color(0xFF4FC3F7);

  /// The shortfall marker: the input a recipe is short of, the stamina a
  /// trip can't afford. A plain strong red, not a pale error pink, because
  /// it is the one thing standing between you and the action.
  static const Color missingColor = Color(0xFFE53935);

  /// A dungeon floor's boss: its tile's ring and wash, and its ribbon. A
  /// deep crimson, so it does not read as [missingColor]'s shortfall.
  static const Color bossColor = Color(0xFFB3261E);
  static const Color onBossColor = Color(0xFFFFFFFF);

  /// A boss's gold sprite frame: the 2px border and the 1px edge just
  /// outside it. The dark line just inside it follows the palette — see
  /// [DungeonSurfaces.bossFrameInner].
  static const Color bossFrame = Color(0xFFD9A441);
  static const Color bossFrameOuter = Color(0xFF5A3A14);

  /// The "BOSS" label over a boss's name.
  static const Color bossLabel = Color(0xFFE3B341);

  /// The hit you deal, by how it rolled: [hitMiss] for nothing, [hitLow]
  /// below the average hit, [hitHigh] at or above it, and [hitMax], drawn
  /// bigger and heavier, for the top of the range.
  static const Color hitMiss = Color(0xFF5AA8F0);
  static const Color hitLow = Color(0xFFE9C23A);
  static const Color hitHigh = Color(0xFFE5533D);
  static const Color hitMax = Color(0xFFA3171B);

  /// A boss fight's arena, and the floor summary that takes its place: the
  /// crimson glow the boss stands in, the dark gold edging the arena's hp
  /// bar and the tile a record was beaten on, and the boss's name. Its
  /// ground and quiet text follow the palette — see [DungeonSurfaces].
  static const Color bossGlow = Color(0xFFC4473A);
  static const Color bossBarBorder = Color(0xFF7A5A22);
  static const Color bossName = Color(0xFFF6E3B4);

  /// A dungeon floor cleared at least once: its rail node, its rail, its
  /// "Cleared" pill and its segment of the progress bar.
  static const Color clearedColor = Color(0xFF7FC08A);

  /// A dungeon's full-clear chest: its glyph and count. Its card and the
  /// box the glyph sits in follow the palette — see [DungeonSurfaces].
  static const Color chestColor = Color(0xFFE8C766);


  static const standard = GameColors(
    exploration: Color(0xFFE0A93E),
    stamina: Color(0xFF4A8FE7),
    speed: Color(0xFFE9C23A),
    recovery: Color(0xFF3DBE7A),
    firemaking: Color(0xFFEE8A3A),
    cooking: Color(0xFFB9473A),
    xp: Color(0xFFE8C766),
    hp: Color(0xFFC4473A),
    onHp: Color(0xFFFFFFFF),
    attack: Color(0xFFE8806B),
    stop: Color(0xFFE8806B),
    gathering: Color(0xFF7FC08A),
    levelHard: Color(0xFFEF6B5E),
    levelEven: Color(0xFFE9C23A),
    levelEasy: Color(0xFF6CC86F),
    upgrade: Color(0xFF6CC86F),
    boostPartial: Color(0xFFF2B866),
    boostFull: Color(0xFFFF7A45),
    maxHit: Color(0xFFFFD54F),
    heal: Color(0xFF7EE0A6),
    secondaryBar: Color(0xFFCDBF9F),
    timerFill: Color(0xFF8F836E),
    travel: travelColor,
  );

  @override
  GameColors copyWith({
    Color? exploration,
    Color? stamina,
    Color? speed,
    Color? recovery,
    Color? firemaking,
    Color? cooking,
    Color? xp,
    Color? hp,
    Color? onHp,
    Color? attack,
    Color? stop,
    Color? gathering,
    Color? levelHard,
    Color? levelEven,
    Color? levelEasy,
    Color? upgrade,
    Color? boostPartial,
    Color? boostFull,
    Color? maxHit,
    Color? heal,
    Color? secondaryBar,
    Color? timerFill,
    Color? travel,
  }) {
    return GameColors(
      exploration: exploration ?? this.exploration,
      stamina: stamina ?? this.stamina,
      speed: speed ?? this.speed,
      recovery: recovery ?? this.recovery,
      firemaking: firemaking ?? this.firemaking,
      cooking: cooking ?? this.cooking,
      xp: xp ?? this.xp,
      hp: hp ?? this.hp,
      onHp: onHp ?? this.onHp,
      attack: attack ?? this.attack,
      stop: stop ?? this.stop,
      gathering: gathering ?? this.gathering,
      levelHard: levelHard ?? this.levelHard,
      levelEven: levelEven ?? this.levelEven,
      levelEasy: levelEasy ?? this.levelEasy,
      upgrade: upgrade ?? this.upgrade,
      boostPartial: boostPartial ?? this.boostPartial,
      boostFull: boostFull ?? this.boostFull,
      maxHit: maxHit ?? this.maxHit,
      heal: heal ?? this.heal,
      secondaryBar: secondaryBar ?? this.secondaryBar,
      timerFill: timerFill ?? this.timerFill,
      travel: travel ?? this.travel,
    );
  }

  @override
  GameColors lerp(ThemeExtension<GameColors>? other, double t) {
    if (other is! GameColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return GameColors(
      exploration: l(exploration, other.exploration),
      stamina: l(stamina, other.stamina),
      speed: l(speed, other.speed),
      recovery: l(recovery, other.recovery),
      firemaking: l(firemaking, other.firemaking),
      cooking: l(cooking, other.cooking),
      xp: l(xp, other.xp),
      hp: l(hp, other.hp),
      onHp: l(onHp, other.onHp),
      attack: l(attack, other.attack),
      stop: l(stop, other.stop),
      gathering: l(gathering, other.gathering),
      levelHard: l(levelHard, other.levelHard),
      levelEven: l(levelEven, other.levelEven),
      levelEasy: l(levelEasy, other.levelEasy),
      upgrade: l(upgrade, other.upgrade),
      boostPartial: l(boostPartial, other.boostPartial),
      boostFull: l(boostFull, other.boostFull),
      maxHit: l(maxHit, other.maxHit),
      heal: l(heal, other.heal),
      secondaryBar: l(secondaryBar, other.secondaryBar),
      timerFill: l(timerFill, other.timerFill),
      travel: l(travel, other.travel),
    );
  }
}

/// The grounds the dungeon's marked things sit on — the chest card, a
/// boss's tile and arena, a cleared floor's wash. The colours that mean
/// something (boss crimson, the gold frame, chest gold, cleared green) are
/// fixed in [GameColors]; these lay a touch of them into the palette in
/// view, so a chest in an ice cave sits on ice, not on the meadow's brown.
extension DungeonSurfaces on ZonePalette {
  static Color _wash(Color tint, double amount, Color base) =>
      Color.alphaBlend(tint.withValues(alpha: amount), base);

  /// The chest card and its border.
  Color get chestFill => _wash(GameColors.chestColor, 0.05, bg);
  Color get chestBorder => _wash(GameColors.chestColor, 0.10, borderStrong);

  /// The box the chest glyph sits in, and its border.
  Color get chestBoxFill => _wash(GameColors.chestColor, 0.07, surface);
  Color get chestBoxBorder => _wash(GameColors.chestColor, 0.30, borderStrong);

  /// A boss tile's 1px border: the plain tile's weight, warmed toward the
  /// boss crimson.
  Color get bossTileBorder => _wash(GameColors.bossColor, 0.35, borderStrong);

  /// A boss fight's ground, and the floor summary's.
  Color get bossArenaFill => _wash(GameColors.bossGlow, 0.04, bg);

  /// The summary's tiles laid on that ground, and their edge.
  Color get bossTileFill => _wash(GameColors.bossColor, 0.04, surface);
  Color get bossTileEdge => _wash(GameColors.bossColor, 0.04, borderStrong);

  /// The arena hp bar's empty run.
  Color get bossBarTrack => _wash(GameColors.bossColor, 0.12, surfaceSunken);

  /// The arena's quiet text, and its quieter text.
  Color get bossMuted => textSubtitle;
  Color get bossFaint => textMuted;

  /// A cleared floor's rail-node wash.
  Color get clearedFill => _wash(GameColors.clearedColor, 0.25, bg);

  /// The 2px dark line just inside a boss's gold frame.
  Color get bossFrameInner => _wash(GameColors.bossFrame, 0.06, titleShadow);
}

/// The frames sprites sit in, by what the sprite is: the palette's own
/// card, with a breath of the colour the kind is known by, so a fight's
/// frame in an ice cave is ice with a warm edge rather than the meadow's
/// brown. Gathering spots take the palette's own [ZonePalette
/// .gatherTintFill]; a dungeon's entrance its sunken card.
extension SpriteTints on ZonePalette {
  static SpriteTint _tint(
    Color colour,
    double fill,
    double border,
    ZonePalette p,
  ) => SpriteTint(
    fill: Color.alphaBlend(colour.withValues(alpha: fill), p.surface),
    border: Color.alphaBlend(colour.withValues(alpha: border), p.borderStrong),
  );

  /// Creatures: a hint of the hp red.
  SpriteTint get combatTint => _tint(GameColors.standard.hp, 0.06, 0.09, this);

  /// Crafting stations (anvil) and crafting inputs: the palette's own
  /// card, lifted a touch toward its text.
  SpriteTint get craftingTint => _tint(text, 0.025, 0.04, this);

  /// Fires and firepits: a hint of the firemaking orange.
  SpriteTint get fireTint =>
      _tint(GameColors.standard.firemaking, 0.045, 0.09, this);

  /// Shops: a hint of the chest gold.
  SpriteTint get shopTint => _tint(GameColors.chestColor, 0.05, 0.1, this);

  /// Dungeon entrances keep their rarity-coloured outline; this is the
  /// frame under it.
  SpriteTint get dungeonTint =>
      SpriteTint(fill: surfaceSunken, border: borderStrong);
}
