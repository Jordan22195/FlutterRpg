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

  double weight;

  WeightedDropTableEntry({
    required this.id,
    this.count = 1,
    this.highCount = 0,
    this.unlockLevel = 0,
    required this.weight,
  });
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
  /// Rather than calling [roll] N times, each entry is handed its whole-number
  /// share of the rolls up front and only the leftover — always fewer rolls
  /// than there are entries — is rolled randomly. Over many rolls that lands
  /// on the same distribution as rolling individually, at a fraction of the
  /// cost, which is what makes settling thousands of offline actions cheap.
  ///
  /// Each allocated roll still draws its own stack size, so an entry with a
  /// [WeightedDropTableEntry.highCount] range varies exactly as it would when
  /// rolled one at a time.
  List<ObjectStack<T>> rollMulitpleTimes<T>(
    int numberOfRolls,
    List<WeightedDropTableEntry<T>> entries, {
    Random? rng,
  }) {
    if (numberOfRolls <= 0 || entries.isEmpty) return [];

    final random = rng ?? Random();

    double totalWeight = 0;
    for (final e in entries) {
      if (e.weight <= 0) {
        throw ArgumentError('All weights must be > 0. Got weight=${e.weight}');
      }
      totalWeight += e.weight;
    }

    final outMap = <T, int>{};
    void add(T id, int count) {
      if (count <= 0) return;
      outMap[id] = (outMap[id] ?? 0) + count;
    }

    // hand out the guaranteed whole share of the rolls
    int rollsAllocated = 0;
    for (final e in entries) {
      final rollsForEntry = (e.weight / totalWeight * numberOfRolls).floor();
      for (var i = 0; i < rollsForEntry; i++) {
        add(e.id, _rollCount(e, random));
      }
      rollsAllocated += rollsForEntry;
    }

    // a table of 6 equally weighted entries rolled a hundred times allocates
    // only 96 above, since each entry floors to 16. roll the remaining 4
    // randomly so the total is exactly [numberOfRolls] and the leftover is
    // still distributed by weight.
    for (var i = rollsAllocated; i < numberOfRolls; i++) {
      final rollResult = roll<T>(entries, rng: random);
      add(rollResult.id, rollResult.count);
    }

    return [
      for (final e in outMap.entries) ObjectStack<T>(id: e.key, count: e.value),
    ];
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
