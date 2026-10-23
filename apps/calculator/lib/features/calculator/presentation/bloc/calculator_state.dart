import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:core/core.dart';

class CalculatorState {
  const new({
    this.expression = '',
    this.resultText,
    this.errorMessage,
    this.history = const [],
    this.angleMode = AngleMode.degrees,
    this.justEvaluated = false,
  });
  final String expression;
  final String? resultText;
  final String? errorMessage;
  final List<Calculation> history;
  final AngleMode angleMode;
  final bool justEvaluated;

  CalculatorState copyWith({
    String? expression,
    String? resultText,
    String? errorMessage,
    List<Calculation>? history,
    AngleMode? angleMode,
    bool? justEvaluated,
    bool clearResult = false,
    bool clearError = false,
  }) => CalculatorState(
    expression: expression ?? this.expression,
    resultText: clearResult ? null : resultText ?? this.resultText,
    errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    history: history ?? this.history,
    angleMode: angleMode ?? this.angleMode,
    justEvaluated: justEvaluated ?? this.justEvaluated,
  );
}
