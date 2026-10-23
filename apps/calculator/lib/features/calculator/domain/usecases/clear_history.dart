import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:core/core.dart';

/// Use case for clearing the entire history from storage.
class ClearHistory {
  new(this.repository);
  final CalculatorRepository repository;

  /// Returns [Right] (Ok) on success, or [Left] (Err) on error.
  /// Using core's [Result] class instead of dartz [Either].
  Future<Result<void, CalculatorFailure>> call(NoParams params) async {
    return repository.clearHistory();
  }
}
