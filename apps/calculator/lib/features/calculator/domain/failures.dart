/// Base class for every calculator failure.
///
/// Each concrete failure owns the message shown to the user, so the
/// presentation layer never has to switch on a runtime type.
sealed class CalculatorFailure {
  /// Creates a failure.
  const new();

  /// The user-facing explanation of what went wrong.
  String get message;
}

/// The typed expression could not be parsed.
final class ParseFailure extends CalculatorFailure {
  /// Creates the failure.
  const new();

  @override
  String get message => 'Check the expression and try again.';
}

/// The expression divided by zero.
final class DivisionByZeroFailure extends CalculatorFailure {
  /// Creates the failure.
  const new();

  @override
  String get message => 'Cannot divide by zero.';
}

/// History could not be read or written.
final class StorageFailure extends CalculatorFailure {
  /// Creates the failure.
  const new();

  @override
  String get message => 'Could not save history.';
}

/// Nothing was entered before evaluating.
final class EmptyExpressionFailure extends CalculatorFailure {
  /// Creates the failure.
  const new();

  @override
  String get message => 'Enter an expression.';
}

/// The operation has no real value, for example `sqrt(-1)`.
final class DomainFailure extends CalculatorFailure {
  /// Creates the failure.
  const new();

  @override
  String get message => 'That operation is undefined for this value.';
}
