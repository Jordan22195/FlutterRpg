import 'dart:math';
import '../data/ObjectStack.dart';

class WeightedDropTableEntry<T> {
  final T item;
  final int count;
  final double weight;

  const WeightedDropTableEntry({
    required this.item,
    this.count = 1,
    required this.weight,
  });
}

class WeightedDropTable<T> {
  final List<WeightedDropTableEntry<T>> entries;
  final List<double> _prefix; // cumulative weights
  final double _total;
  final Random _rng;

  WeightedDropTable({
    required List<WeightedDropTableEntry<T>> items,
    Random? rng,
  }) : assert(items.isNotEmpty, 'WeightedDropTable got an empty items list'),
       entries = List.unmodifiable(items),
       _rng = rng ?? Random(),
       _prefix = _buildPrefix<T>(items),
       _total = _buildPrefix<T>(items).last; // (see note below)
  // ^ We'll remove the duplicate build in the next snippet.

  static List<double> _buildPrefix<T>(List<WeightedDropTableEntry<T>> weights) {
    double sum = 0;
    final prefix = <double>[];
    for (final w in weights) {
      if (w.weight <= 0) {
        throw ArgumentError('All weights must be > 0. Got weight=${w.weight}');
      }
      sum += w.weight;
      prefix.add(sum);
    }
    return prefix;
  }

  ObjectStack<T> roll() {
    final r = _rng.nextDouble() * _total;
    final idx = _lowerBound(_prefix, r);
    final e = entries[idx];
    return ObjectStack<T>(id: e.item, count: e.count);
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
