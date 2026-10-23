import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:core/core.dart';

/// Persists one completed calculation, trimming the list to the history limit.
class AddToHistory {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that owns history persistence.
  final CalculatorRepository repository;

  /// Stores [calculation] and returns the storage outcome.
  Future<Result<void, CalculatorFailure>> call(Calculation calculation) =>
      repository.addToHistory(calculation);
}
