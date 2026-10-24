import 'package:flutter/material.dart';

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
    required this.combatTint,
    required this.craftingTint,
    required this.fireTint,
    required this.shopTint,
    required this.dungeonTintFill,
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

  final SpriteTint combatTint;

  /// Crafting stations (anvil) and crafting inputs.
  final SpriteTint craftingTint;
  final SpriteTint fireTint;
  final SpriteTint shopTint;

  /// Dungeon frames keep their rarity-coloured outline; only the fill is
  /// fixed here.
  final Color dungeonTintFill;

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
    combatTint: SpriteTint(fill: Color(0xFF2A1F18), border: Color(0xFF46332A)),
    craftingTint: SpriteTint(
      fill: Color(0xFF262019),
      border: Color(0xFF43382A),
    ),
    fireTint: SpriteTint(fill: Color(0xFF2A1E16), border: Color(0xFF4A3324)),
    shopTint: SpriteTint(fill: Color(0xFF2A2416), border: Color(0xFF4A3F2A)),
    dungeonTintFill: Color(0xFF1B1D1F),
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
    SpriteTint? combatTint,
    SpriteTint? craftingTint,
    SpriteTint? fireTint,
    SpriteTint? shopTint,
    Color? dungeonTintFill,
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
      combatTint: combatTint ?? this.combatTint,
      craftingTint: craftingTint ?? this.craftingTint,
      fireTint: fireTint ?? this.fireTint,
      shopTint: shopTint ?? this.shopTint,
      dungeonTintFill: dungeonTintFill ?? this.dungeonTintFill,
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
      combatTint: SpriteTint.lerp(combatTint, other.combatTint, t),
      craftingTint: SpriteTint.lerp(craftingTint, other.craftingTint, t),
      fireTint: SpriteTint.lerp(fireTint, other.fireTint, t),
      shopTint: SpriteTint.lerp(shopTint, other.shopTint, t),
      dungeonTintFill: l(dungeonTintFill, other.dungeonTintFill),
    );
  }
}
