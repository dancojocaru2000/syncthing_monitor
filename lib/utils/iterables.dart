Iterable<List<T>> zip<T>(List<Iterable<T>> iterables) sync* {
  final iterators = iterables.map((it) => it.iterator).toList(growable: false);

  while (iterators.map((it) => it.moveNext()).fold(true, (prev, item) => prev && item)) {
    yield iterators.map((it) => it.current).toList(growable: false);
  }
}

Iterable<List<T>> cartesianProduct<T>(List<Iterable<T>> iterables, [List<T> accumulator]) sync* {
  final _accumulator = accumulator ?? <T>[];
  if (iterables.isEmpty) {
    yield _accumulator;
    return;
  }

  final head = iterables[0];
  final tail = iterables.skip(1).toList(growable: false);

  for (var h in head) {
    yield* cartesianProduct<T>(tail, _accumulator.followedBy([h]).toList(growable: false));
  }
}

extension IterIntSum on Iterable<int> {
  int sum() => this.fold(0, (p, i) => p + i);
}

extension IterDoubleSum on Iterable<double> {
  double sum() => this.fold(0, (p, i) => p + i);
}

