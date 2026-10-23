import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:core/core.dart';

/// Abstract base class for all use cases in the calculator feature.
/// All use cases implement this interface with a `call` method that returns
/// either a [Result] success or a [CalculatorFailure] error.
abstract class UseCase<Out, In> {
  /// Executes the use case with the given parameters.
  /// Returns [Result.ok] with the success value or [Result.err] with a [CalculatorFailure].
  Future<Result<Out, CalculatorFailure>> call(In params);
}
