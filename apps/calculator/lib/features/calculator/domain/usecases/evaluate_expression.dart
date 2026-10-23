import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:core/core.dart';

/// Use case for evaluating a mathematical expression.
/// Accepts a raw expression string, delegates parsing/evaluation to the repository,
/// and returns either a [Calculation] success or a [CalculatorFailure] error.
class EvaluateExpression {
  const new(this.repository);
  final CalculatorRepository repository;

  /// Returns [Right] with a [Calculation] on success, or [Left] with a [CalculatorFailure] on error.
  /// Using core's [Result] class instead of dartz [Either] to avoid version compatibility issues.
  Future<Result<Calculation, CalculatorFailure>> call(
    EvaluationParams params,
  ) async {
    return repository.evaluateExpression(
      params.expression,
      angleMode: params.angleMode,
    );
  }
}

/// Input for an evaluation, including the selected angular unit.
class EvaluationParams {
  const new({required this.expression, required this.angleMode});
  final String expression;
  final AngleMode angleMode;
}
