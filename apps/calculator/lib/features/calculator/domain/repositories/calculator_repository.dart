import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:core/core.dart';

/// Abstract repository that the domain layer depends on.
/// Pure Dart - no Flutter, no storage details.
abstract class CalculatorRepository {
  /// Evaluates [expression] in [angleMode].
  Future<Result<Calculation, CalculatorFailure>> evaluateExpression(
    String expression, {
    AngleMode angleMode = AngleMode.degrees,
  });

  /// Loads the history from persistent storage.
  Future<Result<List<Calculation>, CalculatorFailure>> loadHistory();

  /// Appends a calculation to history (newest first), trims to max 20.
  Future<Result<void, CalculatorFailure>> addToHistory(Calculation calculation);

  /// Clears the entire history from storage.
  Future<Result<void, CalculatorFailure>> clearHistory();
}
