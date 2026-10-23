import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/usecases/no_params.dart';
import 'package:core/core.dart';

/// Use case for deleting the last token from the expression (backspace).
class DeleteLastToken {
  const new();

  /// Returns [Right] (Ok) on success, or [Left] (Err) on error.
  /// Using core's [Result] class instead of dartz [Either].
  Future<Result<dynamic, CalculatorFailure>> call(NoParams params) async {
    return const Result.ok('deleted');
  }
}
