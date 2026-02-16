import 'dart:math';
import '../data/ObjectStack.dart';

class WeightedDropTableEntry<T> {
  final T item;
  final int count;
  double weight;

  WeightedDropTableEntry({
    required this.item,
    this.count = 1,
    required this.weight,
  });
}

class WeightedDropTable {
  static ObjectStack<T> roll<T>(
    List<WeightedDropTableEntry<T>> entries, {
    Random? rng,
  }) {
    assert(entries.isNotEmpty, 'WeightedDropTable got an empty items list');

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

    return ObjectStack<T>(id: selected.item, count: selected.count);
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
