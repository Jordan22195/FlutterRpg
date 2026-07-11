import 'dart:math';
import '../data/ObjectStack.dart';

class WeightedDropTableEntry<T> {
  final T id;
  final int count;
  double weight;

  WeightedDropTableEntry({
    required this.id,
    this.count = 1,
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

    return ObjectStack<T>(id: selected.id, count: selected.count);
  }

  /// Rolls a layered drop table: for each [DropRoll] that fires (by its
  /// chance), adds one weighted pick. Guaranteed rolls always contribute;
  /// rare rolls contribute only when their chance succeeds. Empty rolls
  /// are skipped. Returns every stack the kill produced.
  List<ObjectStack<T>> rollBonus<T>(
    List<DropRoll<T>> rolls, {
    Random? rng,
  }) {
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
