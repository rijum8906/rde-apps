/// Sealed class for all calculator-related failures.
/// Domain layer - pure Dart, no Flutter imports.
sealed class CalculatorFailure {
  const new();

  List<Object> get equality => [runtimeType, toString()];

  @override
  String toString() => _failureToString();

  String _failureToString() {
    switch (runtimeType) {
      case ParseFailure:
        return 'Parse failure';
      case DivisionByZeroFailure:
        return 'Division by zero';
      case StorageFailure:
        return 'Storage error';
      case EmptyExpressionFailure:
        return 'Empty expression';
      default:
        return 'Unknown calculator failure';
    }
  }
}

/// Failure when the expression cannot be parsed/evaluated.
class ParseFailure extends CalculatorFailure {
  @override
  String toString() => 'ParseFailure';
}

/// Failure when division by zero occurs.
class DivisionByZeroFailure extends CalculatorFailure {
  @override
  String toString() => 'DivisionByZeroFailure';
}

/// Failure when storage operations fail.
class StorageFailure extends CalculatorFailure {
  @override
  String toString() => 'StorageFailure';
}

/// Failure when the expression is empty.
class EmptyExpressionFailure extends CalculatorFailure {
  @override
  String toString() => 'EmptyExpressionFailure';
}

/// Failure when an operation has no value in the real-number domain.
class DomainFailure extends CalculatorFailure {
  @override
  String toString() => 'DomainFailure';
}
