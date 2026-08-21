import 'dart:math';
import '../data/ObjectStack.dart';

class WeightedDropTableEntry<T> {
  final T id;
  final int count;

  /// Upper bound for a variable stack size. When greater than [count] the
  /// roll yields a random amount in count..highCount inclusive; otherwise
  /// the stack is always exactly [count].
  final int highCount;

  /// Absolute skill level this entry becomes available at; 0 means always.
  /// The table never filters itself — callers gate the list with
  /// [WeightedDropTableService.availableAt] before rolling, so an entry
  /// below the gate contributes no weight rather than a wasted roll.
  final int unlockLevel;

  final double weight;

  const WeightedDropTableEntry({
    required this.id,
    this.count = 1,
    this.highCount = 0,
    this.unlockLevel = 0,
    required this.weight,
  });

  /// A variant of this entry. Entries live inside `const` catalog
  /// definitions, so a caller that needs a different weight (a burn chance
  /// scaled to the player's level, say) builds a new entry rather than
  /// writing back into the catalog.
  WeightedDropTableEntry<T> copyWith({
    T? id,
    int? count,
    int? highCount,
    int? unlockLevel,
    double? weight,
  }) {
    return WeightedDropTableEntry<T>(
      id: id ?? this.id,
      count: count ?? this.count,
      highCount: highCount ?? this.highCount,
      unlockLevel: unlockLevel ?? this.unlockLevel,
      weight: weight ?? this.weight,
    );
  }
}

/// One layered-drop roll. The roll fires with probability [chance]; when
/// it fires it yields exactly one weighted pick from [entries]. Stack
/// several rolls to build a layered table:
/// - a guaranteed roll (chance 1.0) always yields one pick — e.g. a
///   boss's "guaranteed one of N uniques", or a guaranteed bulk stack
/// - a low-chance roll models a rare/tertiary drop on top of the main one
class DropRoll<T> {
  final List<WeightedDropTableEntry<T>> entries;
  final double chance;

  const DropRoll({required this.entries, this.chance = 1.0});
}

class WeightedDropTableService {
  /// The subset of [entries] a player at [level] can roll. Entries with no
  /// [WeightedDropTableEntry.unlockLevel] always survive, so an ungated
  /// table passes through unchanged.
  static List<WeightedDropTableEntry<T>> availableAt<T>(
    List<WeightedDropTableEntry<T>> entries,
    int level,
  ) {
    return entries.where((e) => level >= e.unlockLevel).toList();
  }

  /// Resolves [numberOfRolls] weighted rolls in one pass, aggregated into one
  /// stack per distinct id.
  ///
  /// Rather than calling [roll] N times, the whole batch is settled by a
  /// single random draw. Each entry's share of the batch is
  /// `weight / totalWeight * N`; those shares are laid end to end and cut at
  /// the integers, with one uniform offset deciding where the cuts land. An
  /// entry gets the number of integers its slice covers.
  ///
  /// That hands out exactly [numberOfRolls] rolls, always — the cuts
  /// telescope, so what one entry loses to the offset the next one gains —
  /// while still paying every entry its exact expected share. An entry worth
  /// 0.1 of a roll takes one roll a tenth of the time instead of flooring
  /// away to nothing. The one thing given up is independence between
  /// entries: the leftover roll goes wherever the offset points rather than
  /// being contested. No batch can have all three.
  ///
  /// An entry with a [WeightedDropTableEntry.highCount] range pays the mean of
  /// that range per allocated roll, not a fresh draw each time: across a batch
  /// the draws average out anyway, so this trades away variance that nobody
  /// can see for a per-roll random call. A single [roll] still varies.
  ///
  /// Note this is exactly [numberOfRolls] *rolls*, not items — a roll of a
  /// stacking entry pays a whole stack.
  List<ObjectStack<T>> rollMulitpleTimes<T>(
    int numberOfRolls,
    List<WeightedDropTableEntry<T>> entries, {
    Random? rng,
  }) {
    if (numberOfRolls <= 0 || entries.isEmpty) return [];

    final random = rng ?? Random();

    // sort a copy. the caller usually hands over a catalog's own drop table,
    // and sorting in place would permanently reorder the catalog. the order
    // does not change the allocation, only which entry the offset lands in.
    final ordered = [...entries]..sort((a, b) => a.weight.compareTo(b.weight));

    // summed over `ordered` rather than `entries` so that the running total
    // below ends on a value bitwise identical to this one. that is what lets
    // the last entry's cumulative share be exactly numberOfRolls instead of
    // a hair under it, which would quietly cost the table its final roll.
    double totalWeight = 0;
    for (final e in ordered) {
      if (e.weight <= 0) {
        throw ArgumentError('All weights must be > 0. Got weight=${e.weight}');
      }
      totalWeight += e.weight;
    }

    // 100 rolls over a 1 / 99 / 100 table lays out as
    //   a [0, 0.5)   b [0.5, 50)   c [50, 100)
    // with an offset of 0.3 the cuts fall at 0.8 / 50.3 / 100.3, giving
    // 0 / 50 / 50; at 0.7 they fall at 1.2 / 50.7 / 100.7, giving 1 / 49 / 50.
    // either way the three add to 100, and a averages its true 0.5.
    final offset = random.nextDouble();

    final outMap = <T, int>{};
    double cumulativeWeight = 0;
    // floor(0 + offset) is 0 for any offset in [0, 1), so the first cut is
    // measured from zero
    int allocated = 0;
    for (final e in ordered) {
      cumulativeWeight += e.weight;
      final cut = ((cumulativeWeight / totalWeight) * numberOfRolls + offset)
          .floor();
      final rollsForEntry = cut - allocated;
      allocated = cut;
      if (rollsForEntry <= 0) continue;

      // an entry can appear twice in one table, so accumulate rather than
      // overwrite
      final count = _meanStackSize(e, rollsForEntry);
      if (count <= 0) continue;
      outMap.update(e.id, (value) => value + count, ifAbsent: () => count);
    }

    assert(
      allocated == numberOfRolls,
      'allocated $allocated of $numberOfRolls rolls',
    );

    return [
      for (final e in outMap.entries) ObjectStack<T>(id: e.key, count: e.value),
    ];
  }

  /// The stack size [rolls] allocated rolls of [entry] are worth. A fixed
  /// entry is just count * rolls; a variable one pays its mean, since over
  /// a batch the individual draws average out anyway and sampling each one
  /// would cost a random draw per roll for no visible difference.
  static int _meanStackSize<T>(WeightedDropTableEntry<T> entry, int rolls) {
    if (entry.highCount <= 0 || entry.highCount <= entry.count) {
      return entry.count * rolls;
    }
    return ((entry.count + entry.highCount) / 2 * rolls).round();
  }

  ObjectStack<T> roll<T>(
    List<WeightedDropTableEntry<T>> entries, {
    Random? rng,
  }) {
    if (entries.isEmpty) {
      return ObjectStack(id: 0 as T, count: 0);
    }

    final random = rng ?? Random();

    double total = 0;
    final prefix = <double>[];

    for (final e in entries) {
      if (e.weight <= 0) {
        throw ArgumentError('All weights must be > 0. Got weight=${e.weight}');
      }
      total += e.weight;
      prefix.add(total);
    }

    final r = random.nextDouble() * total;
    final idx = _lowerBound(prefix, r);
    final selected = entries[idx];

    return ObjectStack<T>(id: selected.id, count: _rollCount(selected, random));
  }

  /// An entry's stack size: fixed at [WeightedDropTableEntry.count], or a
  /// uniform pick from count..highCount (both inclusive) when the entry
  /// declares a higher upper bound.
  static int _rollCount<T>(WeightedDropTableEntry<T> entry, Random random) {
    if (entry.highCount <= 0 || entry.highCount <= entry.count) {
      return entry.count;
    }
    return entry.count + random.nextInt(entry.highCount - entry.count + 1);
  }

  /// Rolls a layered drop table: for each [DropRoll] that fires (by its
  /// chance), adds one weighted pick. Guaranteed rolls always contribute;
  /// rare rolls contribute only when their chance succeeds. Empty rolls
  /// are skipped. Returns every stack the kill produced.
  List<ObjectStack<T>> rollBonus<T>(List<DropRoll<T>> rolls, {Random? rng}) {
    final random = rng ?? Random();
    final out = <ObjectStack<T>>[];
    for (final dropRoll in rolls) {
      if (dropRoll.entries.isEmpty) continue;
      if (random.nextDouble() <= dropRoll.chance) {
        out.add(roll<T>(dropRoll.entries, rng: random));
      }
    }
    return out;
  }

  // todo make this deterministic
  List<ObjectStack<T>> rollBonusMulitpleTimes<T>(
    int rollCount,
    List<DropRoll<T>> rolls, {
    Random? rng,
  }) {
    final random = rng ?? Random();
    final out = <ObjectStack<T>>[];
    for (int i = 0; i < rollCount; i++) {
      for (final dropRoll in rolls) {
        if (dropRoll.entries.isEmpty) continue;
        if (random.nextDouble() <= dropRoll.chance) {
          out.add(roll<T>(dropRoll.entries, rng: random));
        }
      }
    }

    return out;
  }

  static int _lowerBound(List<double> prefix, double value) {
    int lo = 0, hi = prefix.length - 1;
    while (lo < hi) {
      final mid = lo + ((hi - lo) >> 1);
      if (prefix[mid] >= value) {
        hi = mid;
      } else {
        lo = mid + 1;
      }
    }
    return lo;
  }
}
