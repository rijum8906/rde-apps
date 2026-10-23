/// A JSON-compatible value.
///
/// Mirrors the values produced by `dart:convert` after decoding.
typedef Json = Object?;

/// A JSON object with [String] keys.
typedef JsonMap = Map<String, Object?>;

/// A JSON array.
typedef JsonList = List<Object?>;

/// A function returning a [Future] of [T].
typedef AsyncValueGetter<T> = Future<T> Function();

/// A function that maps a value of type [T] to [R].
typedef Mapper<T, R> = R Function(T value);

/// A function that decides whether a value satisfies a condition.
typedef Predicate<T> = bool Function(T value);

/// A function that is invoked with no arguments and returns nothing.
typedef VoidCallback = void Function();
