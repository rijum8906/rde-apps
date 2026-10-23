import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:core/core.dart';

/// Reads the persisted calculation history, newest first.
class LoadHistory {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that owns history persistence.
  final CalculatorRepository repository;

  /// Loads every stored calculation.
  Future<Result<List<Calculation>, CalculatorFailure>> call(NoParams params) =>
      repository.loadHistory();
}
