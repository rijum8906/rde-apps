import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:core/core.dart';

/// Use case for appending a token (digit or operator) to the current expression.
class AppendToken {
  const new();

  /// Returns [Right] (Ok) on success, or [Left] (Err) on error.
  /// Using core's [Result] class instead of dartz [Either].
  Future<Result<dynamic, CalculatorFailure>> call(String params) async {
    return Result.ok(params);
  }
}
