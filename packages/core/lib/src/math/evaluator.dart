import 'dart:math' as math;

import 'package:core/src/math/math_error.dart';
import 'package:core/src/math/parser.dart';
import 'package:core/src/result.dart';

/// Evaluates arithmetic expressions without `eval` or third-party packages.
///
/// ```dart
/// final result = MathEvaluator.evaluate('2 + 3 * (4 - 1) / 2');
/// switch (result) {
///   case Ok(:final value):
///     print(value); // 6.5
///   case Err(:final error):
///     print(error.message);
/// }
/// ```
abstract final class MathEvaluator {
  /// Tokenizes, parses, and evaluates [source].
  ///
  /// Failures, including division by zero, are returned as
  /// `Result.err(MathError)`; nothing is thrown.
  static Result<double, MathError> evaluate(
    String source, {
    AngleMode angleMode = AngleMode.degrees,
  }) {
    return MathParser.parseSource(source).flatMap(
      (expression) => evaluateExpression(expression, angleMode: angleMode),
    );
  }

  /// Evaluates an already parsed [expression].
  static Result<double, MathError> evaluateExpression(
    Expression expression, {
    AngleMode angleMode = AngleMode.degrees,
  }) {
    return switch (expression) {
      NumberLiteral(:final value) => _finite(value),
      ConstantExpression(:final value) => _finite(value),
      UnaryExpression(:final op, :final operand) => evaluateExpression(
        operand,
        angleMode: angleMode,
      ).map((value) => op == UnaryOperator.minus ? -value : value),
      FunctionExpression(:final name, :final argument) => evaluateExpression(
        argument,
        angleMode: angleMode,
      ).flatMap((value) => _function(name, value, angleMode)),
      PostfixExpression(:final op, :final operand) => evaluateExpression(
        operand,
        angleMode: angleMode,
      ).flatMap((value) => _postfix(op, value)),
      BinaryExpression(:final op, :final left, :final right) =>
        evaluateExpression(left, angleMode: angleMode).flatMap(
          (leftValue) => evaluateExpression(
            right,
            angleMode: angleMode,
          ).flatMap((rightValue) => _apply(op, leftValue, rightValue)),
        ),
    };
  }

  static Result<double, MathError> _postfix(PostfixOperator op, double value) {
    if (op == PostfixOperator.percent) return _finite(value / 100);
    if (value < 0 || value != value.roundToDouble()) {
      return const Result.err(
        MathError(
          code: MathErrorCode.invalidFactorial,
          message: 'Factorial requires a non-negative integer.',
        ),
      );
    }
    var result = 1.0;
    for (var i = 2; i <= value; i++) {
      result *= i;
    }
    return _finite(result);
  }

  static Result<double, MathError> _function(
    String name,
    double value,
    AngleMode mode,
  ) {
    final radians = mode == AngleMode.degrees ? value * math.pi / 180 : value;
    final result = switch (name) {
      'sin' => math.sin(radians),
      'cos' => math.cos(radians),
      'tan' => math.tan(radians),
      'asin' when value < -1 || value > 1 => double.nan,
      'asin' => _fromRadians(math.asin(value), mode),
      'acos' when value < -1 || value > 1 => double.nan,
      'acos' => _fromRadians(math.acos(value), mode),
      'atan' => _fromRadians(math.atan(value), mode),
      'ln' when value <= 0 => double.nan,
      'ln' => math.log(value),
      'log' when value <= 0 => double.nan,
      'log' => math.log(value) / math.ln10,
      'sqrt' when value < 0 => double.nan,
      'sqrt' => math.sqrt(value),
      _ => double.nan,
    };
    if (result.isNaN) {
      return Result.err(
        MathError(
          code: MathErrorCode.domainError,
          message: '"$name" is undefined for this value.',
        ),
      );
    }
    return _finite(result);
  }

  static double _fromRadians(double value, AngleMode mode) =>
      mode == AngleMode.degrees ? value * 180 / math.pi : value;

  static Result<double, MathError> _apply(
    BinaryOperator op,
    double left,
    double right,
  ) {
    return switch (op) {
      BinaryOperator.add => _finite(left + right),
      BinaryOperator.subtract => _finite(left - right),
      BinaryOperator.multiply => _finite(left * right),
      BinaryOperator.divide =>
        right == 0
            ? const Result.err(
                MathError(
                  code: MathErrorCode.divisionByZero,
                  message: 'Cannot divide by zero.',
                ),
              )
            : _finite(left / right),
      BinaryOperator.modulo =>
        right == 0
            ? const Result.err(
                MathError(
                  code: MathErrorCode.divisionByZero,
                  message: 'Cannot take a remainder with a zero divisor.',
                ),
              )
            : _finite(left % right),
      BinaryOperator.power => _finite(math.pow(left, right).toDouble()),
    };
  }

  static Result<double, MathError> _finite(double value) {
    if (!value.isFinite) {
      return const Result.err(
        MathError(
          code: MathErrorCode.undefinedResult,
          message: 'The result is not a finite number.',
        ),
      );
    }
    return Result.ok(value);
  }
}

/// The angular unit supplied to trigonometric evaluation.
enum AngleMode {
  /// Degrees, where a full turn is 360.
  degrees,

  /// Radians, where a full turn is 2π.
  radians,
}
