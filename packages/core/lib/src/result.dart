import 'package:core/src/typedefs.dart';
import 'package:meta/meta.dart';

/// The outcome of an operation that can either succeed with [T] or fail with
/// [E].
///
/// [Result] is `sealed`, so a `switch` over it is checked for exhaustiveness:
///
/// ```dart
/// switch (result) {
///   case Ok(:final value):
///     return 'ok: $value';
///   case Err(:final error):
///     return 'error: $error';
/// }
/// ```
sealed class Result<T, E> {
  const new _();

  /// Creates a successful [Result] holding [value].
  // Analyzer false positive: a redirecting factory must repeat the class
  // name, otherwise it is not a valid factory declaration.
  // ignore: unnecessary_type_name_in_constructor
  const factory Result.ok(T value) = Ok;

  /// Creates a failed [Result] holding [error].
  // ignore: unnecessary_type_name_in_constructor
  const factory Result.err(E error, {StackTrace? stackTrace}) = Err;

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T, E>;

  /// Whether this is an [Err].
  bool get isErr => this is Err<T, E>;

  /// The success value, or `null` when this is an [Err].
  T? get valueOrNull => switch (this) {
    Ok(:final value) => value,
    Err<T, E>() => null,
  };

  /// The error, or `null` when this is an [Ok].
  E? get errorOrNull => switch (this) {
    Ok<T, E>() => null,
    Err(:final error) => error,
  };

  /// Transforms a success value with [mapper], leaving errors untouched.
  Result<R, E> map<R>(Mapper<T, R> mapper) => switch (this) {
    Ok(:final value) => Ok<R, E>(mapper(value)),
    Err(:final error, :final stackTrace) => Err<R, E>(
      error,
      stackTrace: stackTrace,
    ),
  };

  /// Transforms an error with [mapper], leaving success values untouched.
  Result<T, F> mapError<F>(Mapper<E, F> mapper) => switch (this) {
    Ok(:final value) => Ok<T, F>(value),
    Err(:final error, :final stackTrace) => Err<T, F>(
      mapper(error),
      stackTrace: stackTrace,
    ),
  };

  /// Chains another fallible operation on a success value.
  Result<R, E> flatMap<R>(Result<R, E> Function(T value) mapper) =>
      switch (this) {
        Ok(:final value) => mapper(value),
        Err(:final error, :final stackTrace) => Err<R, E>(
          error,
          stackTrace: stackTrace,
        ),
      };

  /// Collapses both branches into a single value of type [R].
  R fold<R>({required Mapper<T, R> onOk, required Mapper<E, R> onErr}) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final error) => onErr(error),
      };

  /// Returns the success value or [fallback] when this is an [Err].
  T getOrElse(T fallback) => valueOrNull ?? fallback;

  /// Returns the success value or computes one from the error.
  T getOrElseCompute(Mapper<E, T> fallback) => switch (this) {
    Ok(:final value) => value,
    Err(:final error) => fallback(error),
  };
}

/// A successful [Result].
@immutable
final class Ok<T, E> extends Result<T, E> {
  /// Creates a successful result holding [value].
  const new(this.value) : super._();

  /// The success value.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T, E> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok<T, E>, value);

  @override
  String toString() => 'Ok<$T, $E>($value)';
}

/// A failed [Result].
@immutable
final class Err<T, E> extends Result<T, E> {
  /// Creates a failed result holding [error] and an optional [stackTrace].
  const new(this.error, {this.stackTrace}) : super._();

  /// The failure value.
  final E error;

  /// The stack trace captured when the failure happened, if any.
  final StackTrace? stackTrace;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Err<T, E> &&
          other.error == error &&
          other.stackTrace == stackTrace;

  @override
  int get hashCode => Object.hash(Err<T, E>, error, stackTrace);

  @override
  String toString() => 'Err<$T, $E>($error)';
}
