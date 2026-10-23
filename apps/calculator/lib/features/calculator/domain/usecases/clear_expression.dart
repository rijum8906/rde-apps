import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:core/core.dart';

/// Use case for clearing the current expression and resetting state.
class ClearExpression {
  const new();

  /// Returns [Right] (Ok) on success, or [Left] (Err) on error.
  /// Using core's [Result] class instead of dartz [Either].
  Future<Result<dynamic, CalculatorFailure>> call(NoParams params) async {
    return const Result.ok('cleared');
  }
}
