/// Collection helpers that avoid pulling in an extra dependency.
extension IterableX<T> on Iterable<T> {
  /// The first element matching [test], or `null` when nothing matches.
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final element in this) {
      if (test(element)) {
        return element;
      }
    }
    return null;
  }

  /// Splits this iterable into consecutive lists of at most [size] elements.
  ///
  /// Throws an [ArgumentError] when [size] is not positive.
  Iterable<List<T>> chunked(int size) sync* {
    if (size <= 0) {
      throw ArgumentError.value(size, 'size', 'Must be greater than zero.');
    }
    var chunk = <T>[];
    for (final element in this) {
      chunk.add(element);
      if (chunk.length == size) {
        yield chunk;
        chunk = <T>[];
      }
    }
    if (chunk.isNotEmpty) {
      yield chunk;
    }
  }

  /// Keeps the first element for each key produced by [keyOf].
  List<T> distinctBy(Object? Function(T value) keyOf) {
    final seen = <Object?>{};
    return [
      for (final element in this)
        if (seen.add(keyOf(element))) element,
    ];
  }

  /// Maps every element together with its zero-based index.
  Iterable<R> mapIndexed<R>(R Function(int index, T value) transform) sync* {
    var index = 0;
    for (final element in this) {
      yield transform(index++, element);
    }
  }
}
