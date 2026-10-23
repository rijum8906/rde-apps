import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:core/core.dart';

/// Everything the calculator bloc reacts to.
sealed class CalculatorEvent {
  /// Creates an event.
  const new();
}

/// Loads the persisted history.
class CalculatorStarted extends CalculatorEvent {
  /// Creates the event.
  const new();
}

/// Appends [token] to the expression.
class AppendToken extends CalculatorEvent {
  /// Creates the event.
  const new(this.token);

  /// The raw token, for example `7`, `sin(`, or `pi`.
  final String token;
}

/// Clears the expression and any inline error.
class ClearExpression extends CalculatorEvent {
  /// Creates the event.
  const new();
}

/// Removes the last character of the expression.
class DeleteLastToken extends CalculatorEvent {
  /// Creates the event.
  const new();
}

/// Evaluates the expression with the current [angleMode].
class EvaluateExpression extends CalculatorEvent {
  /// Creates the event.
  const new({this.angleMode = AngleMode.degrees});

  /// The unit used by trigonometric functions.
  final AngleMode angleMode;
}

/// Restores a previous [calculation] into the display.
class LoadCalculation extends CalculatorEvent {
  /// Creates the event.
  const new(this.calculation);

  /// The calculation to restore.
  final Calculation calculation;
}

/// Removes every stored calculation.
class ClearHistory extends CalculatorEvent {
  /// Creates the event.
  const new();
}
