import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:core/core.dart';

/// Use case for appending a calculation to history (newest first), trimming to max 20.
class AddToHistory {
  /// constructor
  new(this.repository);

  /// some
  final CalculatorRepository repository;

  /// Returns [Right] (Ok) on success, or [Left] (Err) on error.
  /// Using core's [Result] class instead of dartz [Either].
  Future<Result<void, CalculatorFailure>> call(Calculation params) async {
    return await repository.addToHistory(params);
  }
}
