import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:core/core.dart';

///
sealed class CalculatorEvent {
  const new();
}

class CalculatorStarted extends CalculatorEvent {
  const new();
}

class AppendToken extends CalculatorEvent {
  const new(this.token);
  final String token;
}

class ClearExpression extends CalculatorEvent {
  const new();
}

class DeleteLastToken extends CalculatorEvent {
  const new();
}

class EvaluateExpression extends CalculatorEvent {
  const new();
}

class LoadCalculation extends CalculatorEvent {
  const new(this.calculation);
  final Calculation calculation;
}

class ClearHistory extends CalculatorEvent {
  const new();
}

class SetAngleMode extends CalculatorEvent {
  const new(this.mode);
  final AngleMode mode;
}
