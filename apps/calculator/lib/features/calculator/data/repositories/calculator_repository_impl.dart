import 'package:calculator/features/calculator/data/datasources/calculator_local_data_source.dart';
import 'package:calculator/features/calculator/domain/entities/calculation.dart';
import 'package:calculator/features/calculator/domain/failures.dart';
import 'package:calculator/features/calculator/domain/repositories/calculator_repository.dart';
import 'package:core/core.dart';

/// Repository implementation joining core's math engine with local storage.
class CalculatorRepositoryImpl implements CalculatorRepository {
  /// Creates the repository over `local`.
  new(this._local);

  final CalculatorLocalDataSource _local;

  @override
  Future<Result<Calculation, CalculatorFailure>> evaluateExpression(
    String expression, {
    AngleMode angleMode = AngleMode.degrees,
  }) async =>
      switch (MathEvaluator.evaluate(expression, angleMode: angleMode)) {
        Ok(:final value) => Result.ok(
          Calculation(expression: expression, result: value),
        ),
        Err(:final error) => Result.err(_mapMathFailure(error.code)),
      };

  @override
  Future<Result<List<Calculation>, CalculatorFailure>> loadHistory() async {
    try {
      return Result.ok(await _local.loadHistory());
    } on Object catch (_) {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<Result<void, CalculatorFailure>> addToHistory(
    Calculation calculation,
  ) async {
    try {
      final current = await _local.loadHistory();
      await _local.saveHistory(
        [
          calculation,
          ...current,
        ].take(CalculatorLocalDataSource.maxEntries).toList(),
      );
      return const Result.ok(null);
    } on Object catch (_) {
      return const Result.err(StorageFailure());
    }
  }

  @override
  Future<Result<void, CalculatorFailure>> clearHistory() async {
    try {
      await _local.clearHistory();
      return const Result.ok(null);
    } on Object catch (_) {
      return const Result.err(StorageFailure());
    }
  }

  CalculatorFailure _mapMathFailure(MathErrorCode code) => switch (code) {
    MathErrorCode.emptyExpression => const EmptyExpressionFailure(),
    MathErrorCode.divisionByZero => const DivisionByZeroFailure(),
    MathErrorCode.domainError ||
    MathErrorCode.invalidFactorial => const DomainFailure(),
    _ => const ParseFailure(),
  };
}
