import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:core/core.dart';

/// Evaluates a raw expression through the repository's math engine.
class EvaluateExpression {
  /// Creates the use case over [repository].
  const new(this.repository);

  /// The repository that parses and evaluates expressions.
  final CalculatorRepository repository;

  /// Evaluates [params] and returns the result or a failure.
  Future<Result<Calculation, CalculatorFailure>> call(
    EvaluationParams params,
  ) => repository.evaluateExpression(
    params.expression,
    angleMode: params.angleMode,
  );
}

/// Input for [EvaluateExpression].
class EvaluationParams {
  /// Creates evaluation parameters.
  const new({required this.expression, required this.angleMode});

  /// The raw expression typed by the user.
  final String expression;

  /// The unit used by trigonometric functions.
  final AngleMode angleMode;
}
