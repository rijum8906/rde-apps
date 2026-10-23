import 'package:calculator/features/calculator/domain/entities/calculation.dart';

/// The calculator's interaction state.
class CalculatorState {
  /// Creates the state.
  const new({
    this.expression = '',
    this.resultText,
    this.errorMessage,
    this.history = const [],
    this.justEvaluated = false,
  });

  /// The expression being typed, in raw tokens (`pi`, `*`, `sqrt(`).
  final String expression;

  /// The formatted result of the last evaluation, if any.
  final String? resultText;

  /// The inline error shown under the display, if any.
  final String? errorMessage;

  /// The persisted calculations, newest first.
  final List<Calculation> history;

  /// Whether the last action was an evaluation, which makes the next digit
  /// start a new expression instead of extending the result.
  final bool justEvaluated;

  /// Returns a copy with the given fields replaced.
  CalculatorState copyWith({
    String? expression,
    String? resultText,
    String? errorMessage,
    List<Calculation>? history,
    bool? justEvaluated,
    bool clearResult = false,
    bool clearError = false,
  }) => CalculatorState(
    expression: expression ?? this.expression,
    resultText: clearResult ? null : resultText ?? this.resultText,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    history: history ?? this.history,
    justEvaluated: justEvaluated ?? this.justEvaluated,
  );
}
