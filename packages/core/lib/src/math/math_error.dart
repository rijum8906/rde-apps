import 'package:meta/meta.dart';

/// The reason an expression could not be tokenized, parsed, or evaluated.
enum MathErrorCode {
  /// The source contained no expression.
  emptyExpression,

  /// The source contained a character that is not part of the grammar.
  unexpectedCharacter,

  /// A numeric literal could not be parsed.
  invalidNumber,

  /// A token appeared where the parser did not expect it.
  unexpectedToken,

  /// The expression ended before it was complete.
  unexpectedEnd,

  /// An identifier was used that is not a supported constant.
  unknownIdentifier,

  /// An operation divided by zero.
  divisionByZero,

  /// The result was infinite or not a number.
  undefinedResult,

  /// A function was called outside of its mathematical domain.
  domainError,

  /// Factorial was requested for a value that is not a non-negative integer.
  invalidFactorial,
}

/// A typed, human-readable math failure.
///
/// Errors are returned through `Result.err` instead of thrown, so the UI can
/// render them inline and callers must handle them.
@immutable
final class MathError {
  /// Creates a math error.
  const new({required this.code, required this.message, this.position});

  /// The category of the failure.
  final MathErrorCode code;

  /// A message suitable for display.
  final String message;

  /// The zero-based character offset in the source, when known.
  final int? position;

  @override
  String toString() {
    final offset = position;
    return offset == null ? message : '$message (at character ${offset + 1})';
  }
}
