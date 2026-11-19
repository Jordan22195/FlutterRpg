import '../catalogs/items/items.dart';
import 'skill_data.dart';

/// One stat a buff is raising, and whether it is the one being counted.
class BuffEffect {
  const BuffEffect({
    required this.stat,
    required this.amount,
    this.counted = true,
  });

  final SkillId stat;
  final int amount;

  /// False when another fire in the zone gives more to [stat]: fires don't
  /// stack, so only the strongest one on each stat counts.
  final bool counted;
}

/// A buff the player is under right now, as the buff widgets show it: what
/// it is, where it applies, when it runs out and what it is lending.
class ActiveBuff {
  const ActiveBuff({
    required this.id,
    required this.zoneBuff,
    required this.endsAt,
    required this.duration,
    required this.effects,
  });

  final ItemId id;

  /// A zone buff (a fire) applies in the zone it burns in; anything else
  /// (a potion) goes everywhere with the player.
  final bool zoneBuff;

  final DateTime endsAt;

  /// The whole burn it was put up for, what [fractionLeft] reads against.
  final Duration duration;

  /// Biggest first, so [primary] is the one that names the buff.
  final List<BuffEffect> effects;

  String get name => id.definition.name;

  /// The biggest effect that counts, else the biggest one: what colours the
  /// buff's icon.
  BuffEffect? get primary {
    for (final effect in effects) {
      if (effect.counted) return effect;
    }
    return effects.isEmpty ? null : effects.first;
  }

  /// Every one of its effects is beaten by another fire, so it is giving
  /// nothing at all.
  bool get outranked =>
      effects.isNotEmpty && effects.every((effect) => !effect.counted);

  Duration remaining(DateTime now) {
    final left = endsAt.difference(now);
    return left.isNegative ? Duration.zero : left;
  }

  /// How much of [duration] is left, 0 to 1. A fire laid on again can run
  /// past the burn it reports, so this tops out at full.
  double fractionLeft(DateTime now) {
    if (duration.inMicroseconds <= 0) return 0;
    final f = remaining(now).inMicroseconds / duration.inMicroseconds;
    return f.clamp(0.0, 1.0);
  }
}
