import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:core/core.dart';

/// Use case for loading the calculation history from persistent storage.
class LoadHistory {
  new(this.repository);
  final CalculatorRepository repository;

  /// Returns [Right] (Ok) on success, or [Left] (Err) on error.
  /// Using core's [Result] class instead of dartz [Either].
  Future<Result<List<Calculation>, CalculatorFailure>> call(
    NoParams params,
  ) async {
    return repository.loadHistory();
  }
}
