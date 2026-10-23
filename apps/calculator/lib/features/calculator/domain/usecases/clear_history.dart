import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:core/core.dart';

/// Removes every stored calculation.
class ClearHistory {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that owns history persistence.
  final CalculatorRepository repository;

  /// Clears the stored history.
  Future<Result<void, CalculatorFailure>> call(NoParams params) =>
      repository.clearHistory();
}
